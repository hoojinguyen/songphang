#if DEBUG
  public import Domain
  public import Foundation

  extension FakeWorld {
    public func fetchBreakdowns(
      groupId: ExpenseGroup.ID,
      cycleId: BreakdownCycleSelection
    ) async throws(AppError) -> MemberBreakdownsResult {
      try await simulateNetwork()
      guard let members = membersByGroup[groupId],
        let balances = balancesByGroup[groupId]
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let cycles = settlementCyclesByGroup[groupId] ?? []
      let txs = transactionsByGroup[groupId] ?? []
      let targetCycle: SettlementCycle? = {
        switch cycleId {
        case .auto:
          let openHasExpense = txs.contains {
            $0.cycleId == nil
              && $0.deletedAt == nil
              && ($0.type == .expense || $0.type == .income)
              && ($0.approval.status == .none || $0.approval.status == .approved)
          }
          if openHasExpense || cycles.isEmpty { return nil }
          return cycles.first
        case .current:
          return nil
        case .cycle(let id):
          return cycles.first { $0.id == id }
        }
      }()

      let focus: MemberBreakdownsResolvedFocus = {
        if let targetCycle {
          return MemberBreakdownsResolvedFocus(
            kind: .cycle,
            cycleId: targetCycle.id,
            label: targetCycle.title
          )
        }
        return MemberBreakdownsResolvedFocus(
          kind: cycles.isEmpty ? .all : .current,
          cycleId: nil,
          label: cycles.isEmpty ? "Tất cả" : "Đợt hiện tại"
        )
      }()

      let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
      let breakdowns: [MemberDebtBreakdown] = members.filter { $0.kind == .person }.map { member in
        let netBalance =
          balances.balances.first(where: { $0.memberId == member.id })?.balance ?? .zero
        let focusTxs = txs.filter { tx in
          tx.deletedAt == nil
            && (tx.approval.status == .none || tx.approval.status == .approved)
            && (targetCycle == nil
              ? tx.cycleId == nil
              : (tx.cycleId == targetCycle?.id || (tx.cycleId == nil && tx.type == .transfer)))
        }
        var lines: [MemberBreakdownLine] = []
        var expenseDelta = Money.zero
        var transferDelta = Money.zero
        for tx in focusTxs.reversed() {
          let paid = tx.payers.first(where: { $0.memberId == member.id })?.amount ?? .zero
          let share = tx.shares.first(where: { $0.memberId == member.id })?.amount ?? .zero
          let signedDelta =
            tx.type == .income
            ? Money(share.amount - paid.amount) : Money(paid.amount - share.amount)
          if signedDelta.isZero { continue }
          if tx.type == .transfer {
            transferDelta = transferDelta + signedDelta
          } else {
            expenseDelta = expenseDelta + signedDelta
          }
          let payerSummary = tx.payers.compactMap { memberById[$0.memberId]?.name }
            .joined(separator: ", ")
          lines.append(
            MemberBreakdownLine(
              transactionId: tx.id,
              type: tx.type,
              description: tx.description,
              occurredAt: tx.occurredAt,
              totalAmount: tx.amount,
              payerSummary: payerSummary,
              memberPaid: paid,
              memberShare: share,
              delta: signedDelta,
              isPostCloseoutTransfer: targetCycle != nil && tx.cycleId == nil
                && tx.type == .transfer
            )
          )
        }
        let carryOver = Money(netBalance.amount - expenseDelta.amount - transferDelta.amount)
        return MemberDebtBreakdown(
          memberId: member.id,
          memberName: member.name,
          shape: member.shape,
          color: member.color,
          carryOverBalance: carryOver,
          focusExpenseDelta: expenseDelta,
          focusTransferDelta: transferDelta,
          postCycleDelta: .zero,
          netBalance: netBalance,
          lines: lines
        )
      }

      return MemberBreakdownsResult(
        hasClosedCycles: !cycles.isEmpty,
        resolvedFocus: focus,
        breakdowns: breakdowns
      )
    }

    public func fetchSettlementVault(
      groupId: ExpenseGroup.ID,
      filter: SettlementVaultFilter,
      cycleId: TransactionCycleFilter?,
      cursor _: String?,
      limit: Int
    ) async throws(AppError) -> SettlementVaultPage {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let transfers = (transactionsByGroup[groupId] ?? []).filter {
        $0.type == .transfer && $0.deletedAt == nil
      }
      let requests = settlementRequestsByGroup[groupId] ?? []

      var allItems: [SettlementVaultItem] = []
      var confirmedTotal = Money.zero
      var confirmedCount = 0
      var pendingCount = 0
      var proofCount = 0

      for req in requests where req.status == .pending {
        pendingCount += 1
        if req.proofAttachment != nil { proofCount += 1 }
        allItems.append(
          SettlementVaultItem(
            id: req.id,
            kind: .request,
            status: req.status,
            transactionId: req.transactionId,
            settlementRequestId: req.id,
            fromMemberId: req.fromMemberId,
            toMemberId: req.toMemberId,
            amount: req.amount,
            channel: req.channel,
            note: req.note,
            description: nil,
            attachments: req.proofAttachment.map { [$0] } ?? [],
            createdBy: req.createdByUserId.map {
              LedgerTransaction.ActorRef(id: $0, name: req.createdByName ?? "")
            },
            resolvedBy: nil,
            occurredAt: req.createdAt,
            resolvedAt: req.resolvedAt,
            cycleId: nil
          )
        )
      }

      for tx in transfers {
        let matchesCycle: Bool = {
          guard let cycleId else { return true }
          switch cycleId {
          case .current: return tx.cycleId == nil
          case .cycle(let id): return tx.cycleId == id
          }
        }()
        guard matchesCycle else { continue }
        confirmedCount += 1
        confirmedTotal = confirmedTotal + tx.amount
        if !tx.attachments.isEmpty || tx.attachmentCount > 0 { proofCount += 1 }
        if let from = tx.payers.first?.memberId, let to = tx.shares.first?.memberId {
          allItems.append(
            SettlementVaultItem(
              id: tx.id.rawValue,
              kind: .transfer,
              status: .confirmed,
              transactionId: tx.id,
              settlementRequestId: nil,
              fromMemberId: from,
              toMemberId: to,
              amount: tx.amount,
              channel: tx.paymentChannel,
              note: tx.paymentNote,
              description: tx.description,
              attachments: tx.attachments,
              createdBy: tx.createdBy,
              resolvedBy: tx.updatedBy,
              occurredAt: tx.occurredAt,
              resolvedAt: tx.createdAt,
              cycleId: tx.cycleId
            )
          )
        }
      }

      for req in requests where req.status == .rejected || req.status == .cancelled {
        if req.proofAttachment != nil { proofCount += 1 }
        allItems.append(
          SettlementVaultItem(
            id: req.id,
            kind: .request,
            status: req.status,
            transactionId: req.transactionId,
            settlementRequestId: req.id,
            fromMemberId: req.fromMemberId,
            toMemberId: req.toMemberId,
            amount: req.amount,
            channel: req.channel,
            note: req.note,
            description: nil,
            attachments: req.proofAttachment.map { [$0] } ?? [],
            createdBy: req.createdByUserId.map {
              LedgerTransaction.ActorRef(id: $0, name: req.createdByName ?? "")
            },
            resolvedBy: req.resolvedByUserId.map {
              LedgerTransaction.ActorRef(id: $0, name: req.resolvedByName ?? "")
            },
            occurredAt: req.createdAt,
            resolvedAt: req.resolvedAt,
            cycleId: nil
          )
        )
      }

      let filtered = allItems.filter { item in
        switch filter {
        case .all: return true
        case .pending: return item.status == .pending
        case .confirmed: return item.status == .confirmed
        case .withProof: return !item.attachments.isEmpty
        }
      }

      return SettlementVaultPage(
        items: Array(filtered.prefix(limit)),
        summary: SettlementVaultSummary(
          pendingCount: pendingCount,
          confirmedCount: confirmedCount,
          confirmedTotalAmount: confirmedTotal,
          proofCount: proofCount
        ),
        nextCursor: nil
      )
    }

    public func listSettlementCycles(
      groupId: ExpenseGroup.ID
    ) async throws(AppError) -> SettlementCyclesOverview {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let cycles = settlementCyclesByGroup[groupId] ?? []
      let txs = transactionsByGroup[groupId] ?? []
      let countedOpen = txs.filter {
        $0.cycleId == nil
          && $0.deletedAt == nil
          && ($0.approval.status == .none || $0.approval.status == .approved)
      }
      let openExpenses = countedOpen.filter { $0.type == .expense }
      let totalExpense = openExpenses.reduce(Money.zero) { $0 + $1.amount }
      let startedAt = cycles.first?.closedAt ?? group.createdAt
      return SettlementCyclesOverview(
        cycles: cycles,
        currentPeriod: CurrentPeriodSummary(
          startedAt: startedAt,
          expenseCount: openExpenses.count,
          totalExpenseAmount: totalExpense,
          countedTransactionCount: countedOpen.count
        )
      )
    }

    public func closeSettlementCycle(
      groupId: ExpenseGroup.ID,
      title: String?,
      idempotencyKey _: IdempotencyKey
    ) async throws(AppError) -> SettlementCycle {
      try await simulateNetwork()
      guard let group = groupsById[groupId],
        let members = membersByGroup[groupId],
        let balances = balancesByGroup[groupId]
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var txs = transactionsByGroup[groupId] ?? []
      let countedOpenIndices = txs.indices.filter {
        txs[$0].cycleId == nil
          && txs[$0].deletedAt == nil
          && (txs[$0].approval.status == .none || txs[$0].approval.status == .approved)
      }
      guard !countedOpenIndices.isEmpty else {
        throw .cycleEmpty
      }
      let existing = settlementCyclesByGroup[groupId] ?? []
      let nextNumber = (existing.first?.cycleNumber ?? 0) + 1
      let cycleId = SettlementCycle.ID(UUID().uuidString.lowercased())
      let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
      let resolvedTitle =
        (trimmedTitle?.isEmpty == false) ? (trimmedTitle ?? "") : "Đợt \(nextNumber)"

      var expenseCount = 0
      var expenseTotal = Money.zero
      for idx in countedOpenIndices {
        txs[idx].cycleId = cycleId
        if txs[idx].type == .expense {
          expenseCount += 1
          expenseTotal = expenseTotal + txs[idx].amount
        }
      }
      transactionsByGroup[groupId] = txs

      let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
      let cycle = SettlementCycle(
        id: cycleId,
        cycleNumber: nextNumber,
        title: resolvedTitle,
        startedAt: existing.first?.closedAt ?? group.createdAt,
        closedAt: "2026-11-26T00:00:00.000Z",
        closedBy: TripScenario.actorMinh,
        expenseCount: expenseCount,
        totalExpenseAmount: expenseTotal,
        snapshot: SettlementCycle.Snapshot(
          balances: balances.balances.compactMap { b in
            guard let m = memberById[b.memberId], m.kind == .person else { return nil }
            return SettlementCycle.BalanceSnapshot(
              memberId: m.id,
              name: m.name,
              shape: m.shape,
              color: m.color,
              balance: b.balance
            )
          },
          transfers: balances.transfers.compactMap { t in
            guard let from = memberById[t.fromMemberId], let to = memberById[t.toMemberId] else {
              return nil
            }
            return SettlementCycle.TransferSnapshot(
              fromMemberId: t.fromMemberId,
              fromName: from.name,
              toMemberId: t.toMemberId,
              toName: to.name,
              amount: t.amount
            )
          },
          fundBalance: balances.fund?.cash
        )
      )
      var updated = existing
      updated.insert(cycle, at: 0)
      settlementCyclesByGroup[groupId] = updated
      return cycle
    }

    public func reopenSettlementCycle(
      groupId: ExpenseGroup.ID,
      cycleId: SettlementCycle.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role == .owner else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var cycles = settlementCyclesByGroup[groupId] ?? []
      guard let latest = cycles.first else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard latest.id == cycleId else {
        throw .cycleNotLatest
      }
      cycles.removeFirst()
      settlementCyclesByGroup[groupId] = cycles
      if var txs = transactionsByGroup[groupId] {
        for idx in txs.indices where txs[idx].cycleId == cycleId {
          txs[idx].cycleId = nil
        }
        transactionsByGroup[groupId] = txs
      }
    }

    public func guestLinkStatus(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      return guestLinksByGroup[groupId]?.link ?? GuestLink(active: false)
    }

    public func createOrRotateGuestLink(
      groupId: ExpenseGroup.ID,
      rotate: Bool
    ) async throws(AppError) -> GuestLink {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      if let existing = guestLinksByGroup[groupId], existing.link.active, !rotate {
        return existing.link
      }
      let token =
        rotate
        ? "rotatedGuestShareToken1234567890abcdef_\(UUID().uuidString.prefix(8))"
        : "sampleGuestShareToken1234567890abcdefghijk"
      let link = GuestLink(
        active: true,
        url: "http://localhost:3000/share/\(token)",
        createdAt: "2026-11-26T00:00:00.000Z"
      )
      guestLinksByGroup[groupId] = (token: token, link: link)
      return link
    }

    public func revokeGuestLink(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      let revoked = GuestLink(active: false, url: nil, createdAt: nil)
      guestLinksByGroup.removeValue(forKey: groupId)
      return revoked
    }

    public func fetchGuestGroup(
      token: String,
      cycleId: TransactionCycleFilter?,
      cursor _: String?,
      limit: Int
    ) async throws(AppError) -> GuestGroupSnapshot {
      try await simulateNetwork()
      guard
        let entry = guestLinksByGroup.first(where: {
          $0.value.token == token && $0.value.link.active
        }),
        let group = groupsById[entry.key],
        let members = membersByGroup[entry.key],
        let balances = balancesByGroup[entry.key]
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let cyclesOverview = try await listSettlementCycles(groupId: group.id)
      let resolvedSelected: TransactionCycleFilter = {
        if let cycleId { return cycleId }
        if cyclesOverview.currentPeriod.expenseCount == 0, let latest = cyclesOverview.cycles.first
        {
          return .cycle(latest.id)
        }
        return .current
      }()
      let breakdownFocus: BreakdownCycleSelection = {
        if let cycleId {
          switch cycleId {
          case .current: return .current
          case .cycle(let id): return .cycle(id)
          }
        }
        return .auto
      }()
      let breakdownResult = try await fetchBreakdowns(groupId: group.id, cycleId: breakdownFocus)
      let allTxs = (transactionsByGroup[group.id] ?? []).filter { tx in
        guard tx.deletedAt == nil,
          tx.approval.status == .none || tx.approval.status == .approved
        else { return false }
        switch resolvedSelected {
        case .current: return tx.cycleId == nil
        case .cycle(let id): return tx.cycleId == id
        }
      }
      let guestTxs = Array(allTxs.prefix(limit)).map { tx in
        GuestTransaction(
          id: tx.id,
          type: tx.type,
          description: tx.description,
          amount: tx.amount,
          currency: tx.currency,
          occurredAt: tx.occurredAt,
          category: tx.category,
          categoryId: tx.categoryId,
          payers: tx.payers,
          shares: tx.shares,
          split: tx.split,
          paymentChannel: tx.paymentChannel,
          paymentNote: tx.paymentNote,
          cycleId: tx.cycleId,
          attachments: tx.attachments
        )
      }
      return GuestGroupSnapshot(
        group: GuestGroupInfo(
          id: group.id,
          name: group.name,
          currency: group.currency,
          minimized: group.minimizeDebts,
          archivedAt: group.archivedAt.map {
            Date.ISO8601FormatStyle(includingFractionalSeconds: true).format($0)
          }
        ),
        members: members.map {
          GuestMember(
            id: $0.id,
            name: $0.name,
            kind: $0.kind,
            active: $0.active,
            shape: $0.shape,
            color: $0.color
          )
        },
        cycles: cyclesOverview.cycles,
        selectedCycleId: resolvedSelected,
        currentPeriod: cyclesOverview.currentPeriod,
        balances: balances.balances,
        transfers: balances.transfers.map {
          GuestTransfer(
            fromMemberId: $0.fromMemberId,
            toMemberId: $0.toMemberId,
            amount: $0.amount,
            purpose: $0.purpose ?? "SP",
            paymentMethods: $0.paymentMethods
          )
        },
        fund: balances.fund,
        resolvedFocus: breakdownResult.resolvedFocus,
        breakdowns: breakdownResult.breakdowns,
        transactions: Page(items: guestTxs, nextCursor: nil)
      )
    }

    public func fetchGuestAttachmentData(
      token: String,
      attachmentId: Attachment.ID
    ) async throws(AppError) -> Data {
      try await simulateNetwork()
      guard
        let entry = guestLinksByGroup.first(where: {
          $0.value.token == token && $0.value.link.active
        })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let txs = transactionsByGroup[entry.key] ?? []
      let isCountedExpenseAttachment = txs.contains { tx in
        tx.deletedAt == nil
          && (tx.type == .expense || tx.type == .income)
          && tx.approval.status != .rejected
          && tx.attachments.contains(where: { $0.id == attachmentId })
      }
      guard isCountedExpenseAttachment else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return try await attachmentContent(groupId: entry.key, attachmentId: attachmentId)
    }
  }
#endif
