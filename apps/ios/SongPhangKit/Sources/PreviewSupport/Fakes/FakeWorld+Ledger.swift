#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    // MARK: - Transactions & Preview

    public func lastKnownTransactionsFirstPage(
      groupId: ExpenseGroup.ID
    ) -> Page<LedgerTransaction>? {
      guard behavior.hasSnapshot, let list = transactionsByGroup[groupId] else { return nil }
      let firstPageItems = Array(list.prefix(50))
      let nextCursor = list.count > 50 ? "50" : nil
      return Page(items: firstPageItems, nextCursor: nextCursor)
    }

    public func fetchTransactionsPage(
      groupId: ExpenseGroup.ID,
      cursor: String?
    ) async throws(AppError) -> Page<LedgerTransaction> {
      try await simulateNetwork()
      guard let list = transactionsByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let offset = cursor.flatMap(Int.init) ?? 0
      guard offset < list.count else {
        return Page(items: [], nextCursor: nil)
      }
      let end = min(offset + 50, list.count)
      let slice = Array(list[offset..<end])
      let nextCursor = end < list.count ? String(end) : nil
      return Page(items: slice, nextCursor: nextCursor)
    }

    public func fetchTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      guard let list = transactionsByGroup[groupId],
        let tx = list.first(where: { $0.id == id })
      else {
        if let deleted = deletedTransactionsByGroup[groupId]?[id] {
          return deleted
        }
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return tx
    }

    public func previewTransaction(
      groupId _: ExpenseGroup.ID,
      draft: TransactionDraft
    ) async throws(AppError) -> SharePreview {
      try await simulateNetwork()
      guard let shares = scriptedShares(for: draft) else {
        throw .api(code: "FAKE_UNSCRIPTED", status: 422)
      }
      return SharePreview(shares: shares)
    }

    public func createTransaction(
      groupId: ExpenseGroup.ID,
      draft: TransactionDraft,
      key: IdempotencyKey
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      if seenIdempotencyKeys.contains(key),
        let first = transactionsByGroup[groupId]?.first
      {
        return first
      }
      guard let matched = matchScriptedWrite(groupId: groupId, draft: draft) else {
        throw .api(code: "FAKE_UNSCRIPTED", status: 422)
      }
      seenIdempotencyKeys.insert(key)

      var list = transactionsByGroup[groupId] ?? []
      list.insert(matched.transaction, at: 0)
      transactionsByGroup[groupId] = list
      if let newBalances = matched.balances {
        balancesByGroup[groupId] = newBalances
      }
      var actList = activityByGroup[groupId] ?? []
      actList.insert(matched.activity, at: 0)
      activityByGroup[groupId] = actList
      syncGroupSummary(groupId: groupId)
      return matched.transaction
    }

    public func updateTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      draft: TransactionDraft,
      version: Int
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      guard var list = transactionsByGroup[groupId],
        let idx = list.firstIndex(where: { $0.id == id })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let current = list[idx]
      guard current.version == version else {
        throw .conflict
      }

      let updated: LedgerTransaction
      switch draft {
      case .split(let payload):
        let shares: [MemberAmount]
        if let scripted = scriptedShares(for: draft) {
          shares = scripted
        } else if payload.amount == current.amount && payload.split == current.split {
          shares = current.shares
        } else {
          throw .api(code: "FAKE_UNSCRIPTED", status: 422)
        }
        updated = LedgerTransaction(
          id: current.id,
          type: payload.isIncome ? .income : .expense,
          description: payload.description,
          amount: payload.amount,
          currency: current.currency,
          occurredAt: payload.occurredAt,
          category: payload.category,
          payers: payload.payers,
          split: payload.split,
          shares: shares,
          version: current.version + 1,
          updatedBy: TripScenario.actorMinh,
          createdBy: current.createdBy ?? TripScenario.actorMinh,
          createdAt: current.createdAt,
          updatedAt: "2026-11-16T15:10:00.000Z",
          deletedAt: nil
        )
      case .transfer(let payload):
        updated = LedgerTransaction(
          id: current.id,
          type: .transfer,
          description: payload.description ?? "Chuyển khoản",
          amount: payload.amount,
          currency: current.currency,
          occurredAt: payload.occurredAt,
          category: nil,
          payers: [MemberAmount(memberId: payload.fromMemberId, amount: payload.amount)],
          split: .equal(members: [payload.toMemberId]),
          shares: [MemberAmount(memberId: payload.toMemberId, amount: payload.amount)],
          version: current.version + 1,
          updatedBy: TripScenario.actorMinh,
          createdBy: current.createdBy ?? TripScenario.actorMinh,
          createdAt: current.createdAt,
          updatedAt: "2026-11-16T15:10:00.000Z",
          deletedAt: nil
        )
      }

      list[idx] = updated
      transactionsByGroup[groupId] = list
      var actList = activityByGroup[groupId] ?? []
      actList.insert(
        ActivityItem(
          id: ActivityItem.ID("act-edit-\(UUID().uuidString)"),
          actor: TripScenario.activityActorMinh,
          action: "update",
          entityType: .transaction,
          entityId: updated.id.rawValue,
          summary: updated.description,
          before: ActivityItem.SnapshotValues(
            transactionType: current.type,
            amount: current.amount,
            description: current.description,
            occurredAt: current.occurredAt,
            category: current.category,
            payers: current.payers,
            shares: current.shares,
            split: current.split
          ),
          after: ActivityItem.SnapshotValues(
            transactionType: updated.type,
            amount: updated.amount,
            description: updated.description,
            occurredAt: updated.occurredAt,
            category: updated.category,
            payers: updated.payers,
            shares: updated.shares,
            split: updated.split
          ),
          createdAt: "2026-11-16T15:10:00.000Z",
          canRestore: false
        ),
        at: 0
      )
      activityByGroup[groupId] = actList
      return updated
    }

    public func deleteTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard var list = transactionsByGroup[groupId],
        let idx = list.firstIndex(where: { $0.id == id })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      var removed = list.remove(at: idx)
      removed.deletedAt = "2026-11-16T15:15:00.000Z"
      transactionsByGroup[groupId] = list
      var deletedMap = deletedTransactionsByGroup[groupId] ?? [:]
      deletedMap[id] = removed
      deletedTransactionsByGroup[groupId] = deletedMap
      if let currentBalances = balancesByGroup[groupId] {
        var prevBalMap = deletedPrevBalancesByGroup[groupId] ?? [:]
        prevBalMap[id] = currentBalances
        deletedPrevBalancesByGroup[groupId] = prevBalMap
      }
      // If deleting T4 on trip step 4, step back to step 3 literal balances
      if id == TripScenario.t4Transaction.id {
        balancesByGroup[groupId] = TripScenario.step3Balances
      }
      var actList = activityByGroup[groupId] ?? []
      actList.insert(
        ActivityItem(
          id: ActivityItem.ID("act-del-\(id.rawValue)"),
          actor: TripScenario.activityActorMinh,
          action: "delete",
          entityType: .transaction,
          entityId: id.rawValue,
          summary: removed.description,
          before: ActivityItem.SnapshotValues(
            transactionType: removed.type,
            amount: removed.amount,
            description: removed.description
          ),
          after: nil,
          createdAt: "2026-11-16T15:15:00.000Z",
          canRestore: true
        ),
        at: 0
      )
      activityByGroup[groupId] = actList
      syncGroupSummary(groupId: groupId)
    }

    public func restoreTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      guard var deleted = deletedTransactionsByGroup[groupId]?[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      deleted.deletedAt = nil
      deletedTransactionsByGroup[groupId]?.removeValue(forKey: id)
      var list = transactionsByGroup[groupId] ?? []
      list.insert(deleted, at: 0)
      transactionsByGroup[groupId] = list
      if let prevBal = deletedPrevBalancesByGroup[groupId]?[id] {
        balancesByGroup[groupId] = prevBal
      }
      var actList = activityByGroup[groupId] ?? []
      for idx in actList.indices where actList[idx].entityId == id.rawValue {
        actList[idx].canRestore = false
      }
      actList.insert(
        ActivityItem(
          id: ActivityItem.ID("act-rest-\(UUID().uuidString)"),
          actor: TripScenario.activityActorMinh,
          action: "restore",
          entityType: .transaction,
          entityId: id.rawValue,
          summary: deleted.description,
          after: ActivityItem.SnapshotValues(
            transactionType: deleted.type,
            amount: deleted.amount,
            description: deleted.description
          ),
          createdAt: "2026-11-16T15:16:00.000Z",
          canRestore: false
        ),
        at: 0
      )
      activityByGroup[groupId] = actList
      syncGroupSummary(groupId: groupId)
      return deleted
    }

    // MARK: - Balances, Activity, QuickEntry

    public func lastKnownBalances(groupId: ExpenseGroup.ID) -> GroupBalances? {
      guard behavior.hasSnapshot else { return nil }
      return balancesByGroup[groupId]
    }

    public func fetchBalances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances {
      try await simulateNetwork()
      guard let bal = balancesByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return bal
    }

    public func lastKnownActivityFirstPage(
      groupId: ExpenseGroup.ID
    ) -> Page<ActivityItem>? {
      guard behavior.hasSnapshot, let list = activityByGroup[groupId] else { return nil }
      return Page(items: Array(list.prefix(50)), nextCursor: nil)
    }

    public func fetchActivityPage(
      groupId: ExpenseGroup.ID,
      cursor: String?
    ) async throws(AppError) -> Page<ActivityItem> {
      try await simulateNetwork()
      guard let list = activityByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if cursor != nil {
        return Page(items: [], nextCursor: nil)
      }
      return Page(items: list, nextCursor: nil)
    }

    public func parseSentence(
      groupId _: ExpenseGroup.ID,
      text: String
    ) async throws(AppError) -> QuickEntryReading {
      try await simulateNetwork()
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if let reading = QuickEntryFixtures.readingsByText[trimmed] {
        return reading
      }
      return QuickEntryFixtures.unparsedReading(for: trimmed)
    }

    // MARK: - Literal matching

    private func scriptedShares(for draft: TransactionDraft) -> [MemberAmount]? {
      switch draft {
      case .transfer(let payload):
        return [MemberAmount(memberId: payload.toMemberId, amount: payload.amount)]
      case .split(let payload):
        // Check T1..T4
        if matchesT1(payload) { return TripScenario.t1Shares }
        if matchesT2(payload) { return TripScenario.t2Shares }
        if matchesT3(payload) { return TripScenario.t3Shares }
        if matchesT4(payload) { return TripScenario.t4Shares }

        // Check quick-entry ok readings (30, 32, 34, 36, 38, 40)
        for reading in QuickEntryFixtures.readingsByText.values {
          if let readingAmount = reading.draft.amount,
            let readingSplit = reading.draft.split,
            let shares = reading.shares,
            !payload.isIncome,
            payload.amount == readingAmount,
            payload.payers == reading.draft.payers,
            payload.split == readingSplit
          {
            return shares
          }
        }
        return nil
      }
    }

    private struct ScriptedMatch {
      let transaction: LedgerTransaction
      let balances: GroupBalances?
      let activity: ActivityItem
    }

    private func matchScriptedWrite(
      groupId: ExpenseGroup.ID,
      draft: TransactionDraft
    ) -> ScriptedMatch? {
      switch draft {
      case .split(let payload):
        if matchesT1(payload) {
          return ScriptedMatch(
            transaction: TripScenario.t1Transaction,
            balances: TripScenario.step1Balances,
            activity: TripScenario.activityItems[3]
          )
        }
        if matchesT2(payload) {
          return ScriptedMatch(
            transaction: TripScenario.t2Transaction,
            balances: TripScenario.step2Balances,
            activity: TripScenario.activityItems[2]
          )
        }
        if matchesT3(payload) {
          return ScriptedMatch(
            transaction: TripScenario.t3Transaction,
            balances: TripScenario.step3Balances,
            activity: TripScenario.activityItems[1]
          )
        }
        if matchesT4(payload) {
          return ScriptedMatch(
            transaction: TripScenario.t4Transaction,
            balances: TripScenario.step4Balances,
            activity: TripScenario.activityItems[0]
          )
        }
        for reading in QuickEntryFixtures.readingsByText.values {
          if let readingAmount = reading.draft.amount,
            let readingSplit = reading.draft.split,
            let shares = reading.shares,
            !payload.isIncome,
            payload.amount == readingAmount,
            payload.payers == reading.draft.payers,
            payload.split == readingSplit
          {
            let tx = LedgerTransaction(
              id: LedgerTransaction.ID("qe-\(UUID().uuidString)"),
              type: .expense,
              description: payload.description,
              amount: payload.amount,
              currency: "VND",
              occurredAt: payload.occurredAt,
              category: payload.category,
              payers: payload.payers,
              split: payload.split,
              shares: shares,
              version: 1,
              updatedBy: TripScenario.actorMinh,
              createdBy: TripScenario.actorMinh
            )
            let act = ActivityItem(
              id: ActivityItem.ID("act-\(UUID().uuidString)"),
              actor: TripScenario.activityActorMinh,
              action: "create",
              entityType: .transaction,
              entityId: tx.id.rawValue,
              summary: tx.description,
              after: ActivityItem.SnapshotValues(
                transactionType: .expense,
                amount: tx.amount,
                description: tx.description,
                occurredAt: tx.occurredAt,
                category: tx.category,
                payers: tx.payers,
                shares: tx.shares,
                split: tx.split
              ),
              createdAt: "2026-11-16T15:00:00.000Z",
              canRestore: false
            )
            return ScriptedMatch(transaction: tx, balances: nil, activity: act)
          }
        }
        return nil

      case .transfer(let payload):
        guard let currentBal = balancesByGroup[groupId],
          let matchedTransfer = currentBal.transfers.first(where: {
            $0.fromMemberId == payload.fromMemberId
              && $0.toMemberId == payload.toMemberId
              && $0.amount == payload.amount
          })
        else {
          return nil
        }

        let remainingTransfers = currentBal.transfers.filter { $0 != matchedTransfer }
        let updatedBalances = currentBal.balances.map { item -> Balance in
          if item.memberId == payload.fromMemberId {
            return Balance(memberId: item.memberId, balance: item.balance + payload.amount)
          }
          if item.memberId == payload.toMemberId {
            return Balance(memberId: item.memberId, balance: item.balance - payload.amount)
          }
          return item
        }
        let nextBalances = GroupBalances(
          currency: currentBal.currency,
          minimized: currentBal.minimized,
          balances: updatedBalances,
          transfers: remainingTransfers
        )
        let tx = LedgerTransaction(
          id: LedgerTransaction.ID("settle-\(UUID().uuidString)"),
          type: .transfer,
          description: payload.description ?? "Chuyển khoản",
          amount: payload.amount,
          currency: "VND",
          occurredAt: payload.occurredAt,
          category: nil,
          payers: [MemberAmount(memberId: payload.fromMemberId, amount: payload.amount)],
          split: .equal(members: [payload.toMemberId]),
          shares: [MemberAmount(memberId: payload.toMemberId, amount: payload.amount)],
          version: 1,
          updatedBy: TripScenario.actorMinh,
          createdBy: TripScenario.actorMinh
        )
        let act = ActivityItem(
          id: ActivityItem.ID("act-settle-\(UUID().uuidString)"),
          actor: TripScenario.activityActorMinh,
          action: "create",
          entityType: .transaction,
          entityId: tx.id.rawValue,
          summary: tx.description,
          after: ActivityItem.SnapshotValues(
            transactionType: .transfer,
            amount: tx.amount,
            description: tx.description,
            occurredAt: tx.occurredAt,
            payers: tx.payers,
            shares: tx.shares,
            split: tx.split
          ),
          createdAt: "2026-11-16T15:05:00.000Z",
          canRestore: false
        )
        return ScriptedMatch(transaction: tx, balances: nextBalances, activity: act)
      }
    }

    private func matchesT1(_ payload: TransactionDraft.SplitPayload) -> Bool {
      !payload.isIncome
        && payload.amount == TripScenario.t1Transaction.amount
        && payload.payers == TripScenario.t1Transaction.payers
        && payload.split == TripScenario.t1Transaction.split
    }

    private func matchesT2(_ payload: TransactionDraft.SplitPayload) -> Bool {
      !payload.isIncome
        && payload.amount == TripScenario.t2Transaction.amount
        && payload.payers == TripScenario.t2Transaction.payers
        && payload.split == TripScenario.t2Transaction.split
    }

    private func matchesT3(_ payload: TransactionDraft.SplitPayload) -> Bool {
      payload.isIncome
        && payload.amount == TripScenario.t3Transaction.amount
        && payload.payers == TripScenario.t3Transaction.payers
        && payload.split == TripScenario.t3Transaction.split
    }

    private func matchesT4(_ payload: TransactionDraft.SplitPayload) -> Bool {
      !payload.isIncome
        && payload.amount == TripScenario.t4Transaction.amount
        && payload.payers == TripScenario.t4Transaction.payers
        && payload.split == TripScenario.t4Transaction.split
    }
  }
#endif
