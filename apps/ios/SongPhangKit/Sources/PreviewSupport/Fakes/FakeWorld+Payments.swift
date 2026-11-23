#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public func replacePaymentMethods(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID,
      methods: [PaymentMethod]
    ) async throws(AppError) {
      try await simulateNetwork()
      guard var members = membersByGroup[groupId],
        let idx = members.firstIndex(where: { $0.id == memberId })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      members[idx].paymentMethods = methods
      membersByGroup[groupId] = members
    }

    public func listSettlementRequests(
      groupId: ExpenseGroup.ID,
      status: SettlementRequestStatus?
    ) async throws(AppError) -> [SettlementRequest] {
      try await simulateNetwork()
      let all = settlementRequestsByGroup[groupId] ?? []
      guard let status else { return all }
      return all.filter { $0.status == status }
    }

    public func createSettlementRequest(
      groupId: ExpenseGroup.ID,
      transfer: SuggestedTransfer,
      idempotencyKey: String
    ) async throws(AppError) {
      try await simulateNetwork()
      let key = IdempotencyKey(rawValue: idempotencyKey)
      if seenIdempotencyKeys.contains(key) {
        return
      }
      var list = settlementRequestsByGroup[groupId] ?? []
      if list.contains(where: {
        $0.status == .pending
          && $0.fromMemberId == transfer.fromMemberId
          && $0.toMemberId == transfer.toMemberId
      }) {
        throw .api(code: "REQUEST_ALREADY_PENDING", status: 409)
      }
      seenIdempotencyKeys.insert(key)
      let reqId = UUID().uuidString
      let req = SettlementRequest(
        id: reqId,
        fromMemberId: transfer.fromMemberId,
        toMemberId: transfer.toMemberId,
        amount: transfer.amount,
        status: .pending,
        createdByUserId: currentUser?.id,
        createdByName: currentUser?.name,
        createdAt: "2026-11-22T10:00:00.000Z"
      )
      list.insert(req, at: 0)
      settlementRequestsByGroup[groupId] = list

      if let bal = balancesByGroup[groupId] {
        let updatedTransfers = bal.transfers.map { candidate in
          if candidate.fromMemberId == transfer.fromMemberId
            && candidate.toMemberId == transfer.toMemberId
          {
            return SuggestedTransfer(
              fromMemberId: candidate.fromMemberId,
              toMemberId: candidate.toMemberId,
              amount: candidate.amount,
              paymentMethods: candidate.paymentMethods,
              purpose: candidate.purpose,
              pendingSettlement: PendingSettlement(
                id: reqId,
                amount: transfer.amount,
                createdByMe: true
              )
            )
          }
          return candidate
        }
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: bal.balances,
          transfers: updatedTransfers,
          fund: bal.fund
        )
      }
    }

    public func resolveSettlementRequest(
      groupId: ExpenseGroup.ID,
      requestId: String,
      decision: SettlementDecision
    ) async throws(AppError) {
      try await simulateNetwork()
      var list = settlementRequestsByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == requestId }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let current = list[idx]
      guard current.status == .pending else {
        throw .api(code: "REQUEST_NOT_PENDING", status: 409)
      }
      let nextStatus: SettlementRequestStatus =
        switch decision {
        case .confirm: .confirmed
        case .reject: .rejected
        case .cancel: .cancelled
        }
      let newTxId = "tx-settle-\(UUID().uuidString)"
      var assignedTxId: LedgerTransaction.ID? = current.transactionId
      if decision == .confirm {
        let txId = LedgerTransaction.ID(newTxId)
        assignedTxId = txId
        let tx = LedgerTransaction(
          id: txId,
          type: .transfer,
          description: "Thanh toán",
          amount: current.amount,
          currency: "VND",
          occurredAt: "2026-11-22T10:05:00.000Z",
          category: nil,
          categoryId: nil,
          payers: [MemberAmount(memberId: current.fromMemberId, amount: current.amount)],
          split: .exact(
            members: [current.toMemberId],
            entries: [SplitSpec.ExactEntry(memberId: current.toMemberId, amount: current.amount)],
            remainder: .none
          ),
          shares: [MemberAmount(memberId: current.toMemberId, amount: current.amount)],
          version: 1,
          updatedBy: TripScenario.actorMinh,
          createdBy: TripScenario.actorMinh,
          attachments: []
        )
        var txList = transactionsByGroup[groupId] ?? []
        txList.insert(tx, at: 0)
        transactionsByGroup[groupId] = txList
        var actList = activityByGroup[groupId] ?? []
        actList.insert(
          ActivityItem(
            id: ActivityItem.ID("act-settle-\(UUID().uuidString)"),
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
            createdAt: tx.occurredAt,
            canRestore: false
          ),
          at: 0
        )
        activityByGroup[groupId] = actList
      }
      list[idx] = SettlementRequest(
        id: current.id,
        fromMemberId: current.fromMemberId,
        toMemberId: current.toMemberId,
        amount: current.amount,
        status: nextStatus,
        transactionId: assignedTxId,
        createdByUserId: current.createdByUserId,
        createdByName: current.createdByName,
        createdAt: current.createdAt,
        resolvedAt: "2026-11-22T10:05:00.000Z"
      )
      settlementRequestsByGroup[groupId] = list

      if let bal = balancesByGroup[groupId] {
        let updatedTransfers: [SuggestedTransfer]
        let updatedBalances: [Balance]
        switch decision {
        case .confirm:
          updatedTransfers = bal.transfers.filter { candidate in
            candidate.pendingSettlement?.id != current.id
          }
          updatedBalances = bal.balances.map { item in
            if item.memberId == current.fromMemberId {
              return Balance(memberId: item.memberId, balance: item.balance + current.amount)
            } else if item.memberId == current.toMemberId {
              return Balance(memberId: item.memberId, balance: item.balance - current.amount)
            }
            return item
          }
        case .reject, .cancel:
          updatedBalances = bal.balances
          updatedTransfers = bal.transfers.map { candidate in
            if candidate.pendingSettlement?.id == current.id {
              return SuggestedTransfer(
                fromMemberId: candidate.fromMemberId,
                toMemberId: candidate.toMemberId,
                amount: candidate.amount,
                paymentMethods: candidate.paymentMethods,
                purpose: candidate.purpose,
                pendingSettlement: nil
              )
            }
            return candidate
          }
        }
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: updatedBalances,
          transfers: updatedTransfers,
          fund: bal.fund
        )
      }
    }
  }
#endif
