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
      filter: TransactionFilter? = nil,
      cursor: String?
    ) async throws(AppError) -> Page<LedgerTransaction> {
      try await simulateNetwork()
      guard var list = transactionsByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let filter, !filter.isEmpty {
        list = list.filter { tx in
          Self.matches(transaction: tx, filter: filter)
        }
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

    private nonisolated static func matches(
      transaction tx: LedgerTransaction,
      filter: TransactionFilter
    ) -> Bool {
      if let q = filter.query,
        !tx.description.localizedCaseInsensitiveContains(q)
      {
        return false
      }
      if let memberId = filter.memberId,
        !tx.payers.contains(where: { $0.memberId == memberId })
          && !tx.shares.contains(where: { $0.memberId == memberId })
      {
        return false
      }
      if let category = filter.category, tx.category != category {
        return false
      }
      if let categoryId = filter.categoryId, tx.categoryId != categoryId {
        return false
      }
      if filter.uncategorized && (tx.category != nil || tx.categoryId != nil) {
        return false
      }
      if filter.spendingOnly && tx.type == .transfer {
        return false
      }
      if let type = filter.type, tx.type != type {
        return false
      }
      let dateStr = String(tx.occurredAt.prefix(10))
      if let from = filter.from, dateStr < from {
        return false
      }
      if let to = filter.to, dateStr > to {
        return false
      }
      if let cycleFilter = filter.cycleId {
        switch cycleFilter {
        case .current:
          if tx.cycleId != nil { return false }
        case .cycle(let id):
          if tx.cycleId != id { return false }
        }
      }
      return true
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

    public func previewExtras(
      groupId _: ExpenseGroup.ID,
      input: PreviewExtrasInput
    ) async throws(AppError) -> PreviewExtrasResult {
      try await simulateNetwork()
      if input.extras.isEmpty {
        var resolvedShares: [MemberAmount]?
        if let split = input.split,
          let payerId = input.payerMemberId ?? input.payers?.first?.memberId
        {
          let draft = TransactionDraft.split(
            TransactionDraft.SplitPayload(
              isIncome: false,
              description: "preview",
              amount: input.baseAmount,
              occurredAt: "2026-11-26T00:00:00.000Z",
              payers: [MemberAmount(memberId: payerId, amount: input.baseAmount)],
              split: split
            )
          )
          guard let shares = scriptedShares(for: draft) else {
            throw .api(code: "FAKE_UNSCRIPTED", status: 422)
          }
          resolvedShares = shares
        }
        return PreviewExtrasResult(
          baseAmount: input.baseAmount,
          resolvedExtras: [],
          netExtras: .zero,
          computedAmount: input.baseAmount,
          shares: resolvedShares,
          issues: [],
          warnings: []
        )
      }

      if input.baseAmount == Money(346_000),
        input.extras.count == 1,
        let first = input.extras.first,
        first.kind == .tax,
        first.ratePercent == "8"
      {
        let resolvedExtra = SplitSpec.ItemsExtra(
          kind: .tax,
          label: first.label,
          amount: Money(27_680),
          ratePercent: "8"
        )
        let shares: [MemberAmount]?
        if let split = input.split {
          guard case .exact(_, let entries, let remainder, _, _) = split,
            remainder == .none,
            entries.count == 2,
            entries[0].amount == Money(168_000),
            entries[1].amount == Money(178_000)
          else {
            throw .api(code: "FAKE_UNSCRIPTED", status: 422)
          }
          switch input.extrasAllocation {
          case .proportional:
            shares = [
              MemberAmount(memberId: entries[0].memberId, amount: Money(181_440)),
              MemberAmount(memberId: entries[1].memberId, amount: Money(192_240)),
            ]
          case .equal, nil:
            shares = [
              MemberAmount(memberId: entries[0].memberId, amount: Money(181_840)),
              MemberAmount(memberId: entries[1].memberId, amount: Money(191_840)),
            ]
          case .unknown:
            throw .api(code: "FAKE_UNSCRIPTED", status: 422)
          }
        } else {
          shares = nil
        }
        return PreviewExtrasResult(
          baseAmount: Money(346_000),
          resolvedExtras: [resolvedExtra],
          netExtras: Money(27_680),
          computedAmount: Money(373_680),
          shares: shares,
          issues: [],
          warnings: []
        )
      }

      if input.baseAmount == Money(220_000),
        input.extras.count == 1,
        let first = input.extras.first,
        first.kind == .discount,
        first.amount == Money(50_000)
      {
        let resolvedExtra = SplitSpec.ItemsExtra(
          kind: .discount,
          label: first.label,
          amount: Money(50_000),
          ratePercent: first.ratePercent
        )
        let shares: [MemberAmount]?
        if let split = input.split {
          guard case .exact(_, let entries, let remainder, _, _) = split,
            remainder == .none,
            entries.count == 2,
            entries[0].amount == Money(20_000),
            entries[1].amount == Money(200_000)
          else {
            throw .api(code: "FAKE_UNSCRIPTED", status: 422)
          }
          switch input.extrasAllocation {
          case .proportional:
            shares = [
              MemberAmount(memberId: entries[0].memberId, amount: Money(15_455)),
              MemberAmount(memberId: entries[1].memberId, amount: Money(154_545)),
            ]
          case .equal, nil:
            shares = [
              MemberAmount(memberId: entries[0].memberId, amount: .zero),
              MemberAmount(memberId: entries[1].memberId, amount: Money(170_000)),
            ]
          case .unknown:
            throw .api(code: "FAKE_UNSCRIPTED", status: 422)
          }
        } else {
          shares = nil
        }
        return PreviewExtrasResult(
          baseAmount: Money(220_000),
          resolvedExtras: [resolvedExtra],
          netExtras: Money(-50_000),
          computedAmount: Money(170_000),
          shares: shares,
          issues: [],
          warnings: []
        )
      }

      throw .api(code: "FAKE_UNSCRIPTED", status: 422)
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
          deletedAt: nil,
          cycleId: current.cycleId
        )
      case .transfer(let payload):
        let linked = (payload.attachmentIds ?? []).compactMap {
          attachmentsByGroup[groupId]?[$0]
        }
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
          deletedAt: nil,
          attachments: linked.isEmpty ? current.attachments : linked,
          paymentChannel: payload.paymentChannel,
          paymentNote: payload.paymentNote,
          cycleId: current.cycleId
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
      text: String,
      ai: Bool = false
    ) async throws(AppError) -> QuickEntryReading {
      try await simulateNetwork()
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if let reading = QuickEntryFixtures.readingsByText[trimmed] {
        return reading
      }
      if ai && trimmed == "cà phê 180k và bánh 50k" {
        let allFour = [
          TripScenario.minhId, TripScenario.lanId, TripScenario.hungId, TripScenario.thuId,
        ]
        let equal45k = allFour.map { MemberAmount(memberId: $0, amount: Money(45_000)) }
        let equal12k5 = [
          MemberAmount(memberId: TripScenario.minhId, amount: Money(12_500)),
          MemberAmount(memberId: TripScenario.lanId, amount: Money(12_500)),
          MemberAmount(memberId: TripScenario.hungId, amount: Money(12_500)),
          MemberAmount(memberId: TripScenario.thuId, amount: Money(12_500)),
        ]
        return QuickEntryReading(
          status: .ok,
          text: trimmed,
          draft: QuickEntryReading.Draft(
            description: "cà phê",
            amount: Money(180_000),
            payers: [MemberAmount(memberId: TripScenario.minhId, amount: Money(180_000))],
            split: .equal(members: allFour)
          ),
          shares: equal45k,
          spans: [],
          issues: [],
          reader: .ai,
          moreDrafts: [
            QuickEntryReading.ParsedDraft(
              status: .ok,
              draft: QuickEntryReading.Draft(
                description: "bánh",
                amount: Money(50_000),
                payers: [MemberAmount(memberId: TripScenario.minhId, amount: Money(50_000))],
                split: .equal(members: allFour)
              ),
              issues: [],
              shares: equal12k5
            )
          ]
        )
      }
      return QuickEntryFixtures.unparsedReading(for: trimmed)
    }

    // MARK: - Literal matching

    private func scriptedShares(for draft: TransactionDraft) -> [MemberAmount]? {
      switch draft {
      case .transfer(let payload):
        return [MemberAmount(memberId: payload.toMemberId, amount: payload.amount)]
      case .split(let payload):
        if matchesT1(payload) { return TripScenario.t1Shares }
        if matchesT2(payload) { return TripScenario.t2Shares }
        if matchesT3(payload) { return TripScenario.t3Shares }
        if matchesT4(payload) { return TripScenario.t4Shares }

        if !payload.isIncome,
          payload.amount == Money(180_000),
          case .equal(let ids, _, _) = payload.split,
          ids.count == 3
        {
          return ids.map { MemberAmount(memberId: $0, amount: Money(60_000)) }
        }

        if !payload.isIncome,
          payload.amount == Money(340_000),
          case .items = payload.split
        {
          return [
            MemberAmount(memberId: TripScenario.minhId, amount: Money(170_000)),
            MemberAmount(memberId: TripScenario.lanId, amount: Money(170_000)),
          ]
        }

        if !payload.isIncome, payload.amount == Money(50_000),
          case .equal(let ids, _, _) = payload.split, ids.count == 4
        {
          return ids.map { MemberAmount(memberId: $0, amount: Money(12_500)) }
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
        if let shares = scriptedShares(for: draft) {
          let linked = (payload.attachmentIds ?? []).compactMap {
            attachmentsByGroup[groupId]?[$0]
          }
          let tx = LedgerTransaction(
            id: LedgerTransaction.ID("qe-\(UUID().uuidString)"),
            type: payload.isIncome ? .income : .expense,
            description: payload.description,
            amount: payload.amount,
            currency: "VND",
            occurredAt: payload.occurredAt,
            category: payload.category,
            categoryId: payload.categoryId,
            payers: payload.payers,
            split: payload.split,
            shares: shares,
            version: 1,
            updatedBy: TripScenario.actorMinh,
            createdBy: TripScenario.actorMinh,
            attachments: linked
          )
          let act = ActivityItem(
            id: ActivityItem.ID("act-\(UUID().uuidString)"),
            actor: TripScenario.activityActorMinh,
            action: "create",
            entityType: .transaction,
            entityId: tx.id.rawValue,
            summary: tx.description,
            after: ActivityItem.SnapshotValues(
              transactionType: tx.type,
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
        let linked = (payload.attachmentIds ?? []).compactMap {
          attachmentsByGroup[groupId]?[$0]
        }
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
          createdBy: TripScenario.actorMinh,
          attachments: linked,
          paymentChannel: payload.paymentChannel,
          paymentNote: payload.paymentNote
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

    public func fetchComments(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      cursor: String?,
      limit: Int
    ) async throws(AppError) -> (comments: [Comment], nextCursor: String?) {
      try await simulateNetwork()
      let all = commentsByTx[id] ?? []
      let offset = cursor.flatMap(Int.init) ?? 0
      guard offset < all.count else {
        return ([], nil)
      }
      let end = min(offset + limit, all.count)
      let slice = Array(all[offset..<end])
      let nextCursor = end < all.count ? String(end) : nil
      return (slice, nextCursor)
    }

    public func addComment(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      body: String,
      key: IdempotencyKey
    ) async throws(AppError) -> Comment {
      try await simulateNetwork()
      let comment = Comment(
        id: Comment.ID(UUID().uuidString),
        body: body,
        authorName: "Minh",
        createdAt: "2026-11-23T01:00:00.000Z",
        mine: true
      )
      var list = commentsByTx[id] ?? []
      list.insert(comment, at: 0)
      commentsByTx[id] = list
      if var txs = transactionsByGroup[groupId], let idx = txs.firstIndex(where: { $0.id == id }) {
        txs[idx].commentCount += 1
        transactionsByGroup[groupId] = txs
      }
      return comment
    }

    public func deleteComment(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      commentId: Comment.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      var list = commentsByTx[id] ?? []
      if let idx = list.firstIndex(where: { $0.id == commentId }) {
        list.remove(at: idx)
        commentsByTx[id] = list
        if var txs = transactionsByGroup[groupId],
          let txIdx = txs.firstIndex(where: { $0.id == id })
        {
          txs[txIdx].commentCount = max(0, txs[txIdx].commentCount - 1)
          transactionsByGroup[groupId] = txs
        }
      }
    }

    public func openDispute(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      reason: String
    ) async throws(AppError) -> LedgerTransaction.TransactionDispute {
      try await simulateNetwork()
      let dispute = LedgerTransaction.TransactionDispute(
        id: LedgerTransaction.TransactionDispute.ID(UUID().uuidString),
        reason: reason,
        openedByName: "Minh",
        openedAt: "2026-11-23T01:00:00.000Z",
        mine: true
      )
      if var txs = transactionsByGroup[groupId], let idx = txs.firstIndex(where: { $0.id == id }) {
        txs[idx].dispute = dispute
        transactionsByGroup[groupId] = txs
      }
      return dispute
    }

    public func resolveDispute(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      if var txs = transactionsByGroup[groupId], let idx = txs.firstIndex(where: { $0.id == id }) {
        txs[idx].dispute = nil
        transactionsByGroup[groupId] = txs
      }
    }

    public nonisolated static let samplePendingApprovalTransactionId = LedgerTransaction.ID(
      "01a1e4bd-ce0f-7000-8000-000000000a01"
    )

    public nonisolated static let samplePendingApprovalTransaction = LedgerTransaction(
      id: samplePendingApprovalTransactionId,
      type: .expense,
      description: "Vé máy bay khứ hồi",
      amount: Money(850_000),
      currency: "VND",
      occurredAt: "2026-11-22T09:30:00.000Z",
      category: .transport,
      payers: [MemberAmount(memberId: TripScenario.lanId, amount: Money(850_000))],
      split: .equal(members: [
        TripScenario.minhId,
        TripScenario.lanId,
        TripScenario.hungId,
        TripScenario.thuId,
      ]),
      shares: [
        MemberAmount(memberId: TripScenario.minhId, amount: Money(212_500)),
        MemberAmount(memberId: TripScenario.lanId, amount: Money(212_500)),
        MemberAmount(memberId: TripScenario.hungId, amount: Money(212_500)),
        MemberAmount(memberId: TripScenario.thuId, amount: Money(212_500)),
      ],
      version: 1,
      updatedBy: LedgerTransaction.ActorRef(id: TripScenario.lanUserId, name: "Lan"),
      createdBy: LedgerTransaction.ActorRef(id: TripScenario.lanUserId, name: "Lan"),
      createdAt: "2026-11-22T09:30:00.000Z",
      updatedAt: "2026-11-22T09:30:00.000Z",
      approval: LedgerTransaction.TransactionApproval(status: .pending)
    )

    public func seedSamplePendingApproval(groupId: ExpenseGroup.ID = TripScenario.groupId) {
      let targetGroupId = groupsById[groupId] != nil ? groupId : (groupOrder.first ?? groupId)
      if var group = groupsById[targetGroupId] {
        group.approvalThreshold = Money(500_000)
        groupsById[targetGroupId] = group
      }
      var list = transactionsByGroup[targetGroupId] ?? []
      list.removeAll { $0.id == Self.samplePendingApprovalTransactionId }
      list.insert(Self.samplePendingApprovalTransaction, at: 0)
      transactionsByGroup[targetGroupId] = list
    }

    public func approveTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      guard var txs = transactionsByGroup[groupId], let idx = txs.firstIndex(where: { $0.id == id })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      txs[idx].approval = LedgerTransaction.TransactionApproval(
        status: .approved,
        note: nil,
        decidedByName: "Minh",
        decidedAt: "2026-11-23T01:00:00.000Z"
      )
      transactionsByGroup[groupId] = txs
      return txs[idx]
    }

    public func rejectTransaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      note: String?
    ) async throws(AppError) -> LedgerTransaction {
      try await simulateNetwork()
      guard var txs = transactionsByGroup[groupId], let idx = txs.firstIndex(where: { $0.id == id })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      txs[idx].approval = LedgerTransaction.TransactionApproval(
        status: .rejected,
        note: note,
        decidedByName: "Minh",
        decidedAt: "2026-11-23T01:00:00.000Z"
      )
      transactionsByGroup[groupId] = txs
      return txs[idx]
    }
  }
#endif
