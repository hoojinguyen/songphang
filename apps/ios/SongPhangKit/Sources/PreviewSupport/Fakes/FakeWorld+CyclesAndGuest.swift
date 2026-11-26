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
      let cycleById = Dictionary(uniqueKeysWithValues: cycles.map { ($0.id, $0) })
      let txs = (transactionsByGroup[groupId] ?? []).filter {
        $0.deletedAt == nil && ($0.approval.status == .none || $0.approval.status == .approved)
      }
      let openHasExpense = txs.contains {
        $0.cycleId == nil && ($0.type == .expense || $0.type == .income)
      }

      enum FocusMode {
        case all
        case current
        case latestWithPostTransfers(cycleId: SettlementCycle.ID, cycleNumber: Int)
        case cycle(cycleId: SettlementCycle.ID, cycleNumber: Int)
      }

      let focus: MemberBreakdownsResolvedFocus
      let focusMode: FocusMode
      switch cycleId {
      case .auto:
        if cycles.isEmpty {
          focus = MemberBreakdownsResolvedFocus(kind: .all, cycleId: nil, label: "Đợt hiện tại")
          focusMode = .all
        } else if openHasExpense {
          focus = MemberBreakdownsResolvedFocus(
            kind: .current,
            cycleId: nil,
            label: "Đợt hiện tại"
          )
          focusMode = .current
        } else if let latest = cycles.first {
          focus = MemberBreakdownsResolvedFocus(
            kind: .cycle,
            cycleId: latest.id,
            label: latest.title
          )
          focusMode = .latestWithPostTransfers(
            cycleId: latest.id,
            cycleNumber: latest.cycleNumber
          )
        } else {
          focus = MemberBreakdownsResolvedFocus(kind: .all, cycleId: nil, label: "Đợt hiện tại")
          focusMode = .all
        }
      case .current:
        focus = MemberBreakdownsResolvedFocus(
          kind: cycles.isEmpty ? .all : .current,
          cycleId: nil,
          label: "Đợt hiện tại"
        )
        focusMode = .current
      case .cycle(let targetId):
        guard let target = cycleById[targetId] else {
          throw .api(code: "NOT_FOUND", status: 404)
        }
        focus = MemberBreakdownsResolvedFocus(
          kind: .cycle,
          cycleId: target.id,
          label: target.title
        )
        focusMode = .cycle(cycleId: target.id, cycleNumber: target.cycleNumber)
      }

      let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
      let breakdowns: [MemberDebtBreakdown] = members.filter { $0.kind == .person }.map { member in
        var carryOverBalance = Money.zero
        var focusExpenseDelta = Money.zero
        var focusTransferDelta = Money.zero
        var postCycleDelta = Money.zero
        var computedNet = Money.zero
        var lines: [MemberBreakdownLine] = []

        for tx in txs {
          let paid = tx.payers.first(where: { $0.memberId == member.id })?.amount ?? .zero
          let share = tx.shares.first(where: { $0.memberId == member.id })?.amount ?? .zero
          let signedDelta =
            tx.type == .income
            ? Money(share.amount - paid.amount) : Money(paid.amount - share.amount)
          computedNet = computedNet + signedDelta

          let txCycleNumber = tx.cycleId.flatMap { cycleById[$0]?.cycleNumber }
          enum Bucket { case carry, focus, post }
          let bucket: Bucket
          var isPostCloseoutTransfer = false

          switch focusMode {
          case .all:
            bucket = .focus
          case .current:
            bucket = (tx.cycleId == nil) ? .focus : .carry
          case .latestWithPostTransfers(let targetCycleId, let targetCycleNumber):
            if tx.cycleId == targetCycleId {
              bucket = .focus
            } else if tx.cycleId == nil && tx.type == .transfer {
              bucket = .focus
              isPostCloseoutTransfer = true
            } else if let txCycleNumber, txCycleNumber < targetCycleNumber {
              bucket = .carry
            } else {
              bucket = .post
            }
          case .cycle(let targetCycleId, let targetCycleNumber):
            if tx.cycleId == targetCycleId {
              bucket = .focus
            } else if let txCycleNumber, txCycleNumber < targetCycleNumber {
              bucket = .carry
            } else {
              bucket = .post
            }
          }

          switch bucket {
          case .carry:
            carryOverBalance = carryOverBalance + signedDelta
          case .post:
            postCycleDelta = postCycleDelta + signedDelta
          case .focus:
            if tx.type == .transfer {
              focusTransferDelta = focusTransferDelta + signedDelta
            } else {
              focusExpenseDelta = focusExpenseDelta + signedDelta
            }
            if !signedDelta.isZero {
              let payerSummary = buildBreakdownPayerSummary(
                type: tx.type,
                payers: tx.payers,
                shares: tx.shares,
                memberById: memberById
              )
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
                  isPostCloseoutTransfer: isPostCloseoutTransfer
                )
              )
            }
          }
        }

        let serverNet =
          balances.balances.first(where: { $0.memberId == member.id })?.balance ?? computedNet
        return MemberDebtBreakdown(
          memberId: member.id,
          memberName: member.name,
          shape: member.shape,
          color: member.color,
          carryOverBalance: carryOverBalance,
          focusExpenseDelta: focusExpenseDelta,
          focusTransferDelta: focusTransferDelta,
          postCycleDelta: postCycleDelta,
          netBalance: serverNet,
          lines: lines
        )
      }

      return MemberBreakdownsResult(
        hasClosedCycles: !cycles.isEmpty,
        resolvedFocus: focus,
        breakdowns: breakdowns
      )
    }

    private func buildBreakdownPayerSummary(
      type: TransactionType,
      payers: [MemberAmount],
      shares: [MemberAmount],
      memberById: [Member.ID: Member]
    ) -> String {
      if type == .transfer {
        let fromName = payers.first.flatMap { memberById[$0.memberId]?.name } ?? ""
        let toName = shares.first.flatMap { memberById[$0.memberId]?.name } ?? ""
        return "\(fromName) chuyển \(toName)".trimmingCharacters(in: .whitespaces)
      }
      let names = payers.compactMap { memberById[$0.memberId]?.name }
      if names.isEmpty { return "" }
      if names.count == 1 { return "\(names[0]) trả" }
      if names.count == 2 { return "\(names[0]), \(names[1]) trả" }
      return "\(names[0]) +\(names.count - 1) trả"
    }

    public func fetchSettlementVault(
      groupId: ExpenseGroup.ID,
      filter: SettlementVaultFilter,
      cycleId: TransactionCycleFilter?,
      cursor: String?,
      limit: Int
    ) async throws(AppError) -> SettlementVaultPage {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let cycles = settlementCyclesByGroup[groupId] ?? []
      let latestClosedAt = cycles.first?.closedAt
      let targetCycle: SettlementCycle? = {
        guard case .cycle(let id) = cycleId else { return nil }
        return cycles.first(where: { $0.id == id })
      }()
      let matchesRequestCycle: (SettlementRequest) -> Bool = { req in
        guard let cycleId else { return true }
        switch cycleId {
        case .current:
          return req.status == .pending
            || latestClosedAt == nil
            || req.createdAt >= latestClosedAt!
        case .cycle:
          guard let targetCycle else { return false }
          return req.status != .pending
            && req.createdAt >= targetCycle.startedAt
            && req.createdAt <= targetCycle.closedAt
        }
      }
      let transfers = (transactionsByGroup[groupId] ?? []).filter {
        $0.type == .transfer && $0.deletedAt == nil
      }
      let requests = (settlementRequestsByGroup[groupId] ?? []).filter(matchesRequestCycle)

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

      let startIndex = cursor.flatMap(Int.init) ?? 0
      let pageItems = Array(filtered.dropFirst(startIndex).prefix(limit))
      let nextOffset = startIndex + pageItems.count
      return SettlementVaultPage(
        items: pageItems,
        summary: SettlementVaultSummary(
          pendingCount: pendingCount,
          confirmedCount: confirmedCount,
          confirmedTotalAmount: confirmedTotal,
          proofCount: proofCount
        ),
        nextCursor: nextOffset < filtered.count ? String(nextOffset) : nil
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
      cursor: String?,
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
      let startIndex = cursor.flatMap(Int.init) ?? 0
      let pageTxs = Array(allTxs.dropFirst(startIndex).prefix(limit))
      let guestTxs = pageTxs.map { tx in
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
          attachments: tx.type == .transfer ? [] : tx.attachments
        )
      }
      let nextOffset = startIndex + guestTxs.count
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
        transactions: Page(
          items: guestTxs,
          nextCursor: nextOffset < allTxs.count ? String(nextOffset) : nil
        )
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
          && (tx.approval.status == .none || tx.approval.status == .approved)
          && tx.attachments.contains(where: { $0.id == attachmentId })
      }
      guard isCountedExpenseAttachment else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return try await attachmentContent(groupId: entry.key, attachmentId: attachmentId)
    }
  }
#endif
