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
      list[idx] = SettlementRequest(
        id: current.id,
        fromMemberId: current.fromMemberId,
        toMemberId: current.toMemberId,
        amount: current.amount,
        status: nextStatus,
        transactionId: current.transactionId,
        createdByUserId: current.createdByUserId,
        createdByName: current.createdByName,
        createdAt: current.createdAt,
        resolvedAt: "2026-11-22T10:05:00.000Z"
      )
      settlementRequestsByGroup[groupId] = list

      if let bal = balancesByGroup[groupId] {
        let updatedTransfers: [SuggestedTransfer]
        switch decision {
        case .confirm:
          updatedTransfers = bal.transfers.filter { candidate in
            !(candidate.fromMemberId == current.fromMemberId
              && candidate.toMemberId == current.toMemberId
              && (candidate.pendingSettlement?.id == current.id
                || candidate.pendingSettlement != nil))
          }
        case .reject, .cancel:
          updatedTransfers = bal.transfers.map { candidate in
            if candidate.fromMemberId == current.fromMemberId
              && candidate.toMemberId == current.toMemberId
              && (candidate.pendingSettlement?.id == current.id
                || candidate.pendingSettlement != nil)
            {
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
          balances: bal.balances,
          transfers: updatedTransfers,
          fund: bal.fund
        )
      }
    }
  }
#endif
