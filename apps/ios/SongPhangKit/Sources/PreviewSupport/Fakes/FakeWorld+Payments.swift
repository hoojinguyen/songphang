#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public nonisolated static let sampleMinhPaymentMethods: [PaymentMethod] = [
      .bank(
        BankPayment(
          bin: "970436",
          name: "Vietcombank",
          accountNumber: "0123456789",
          accountName: "NGUYEN VAN MINH",
          qrPayload:
            "00020101021238570010A00000072701270006970436011001234567890208QRIBFTTA530370454062100005802VN62180814SP DALAT 3N2D6304ABCD",
          accountQrPayload:
            "00020101021138570010A00000072701270006970436011001234567890208QRIBFTTA53037045802VN63041234"
        )
      ),
      .momo(phone: "0901234567"),
    ]

    public nonisolated static let sampleThuPaymentMethods: [PaymentMethod] = [
      .bank(
        BankPayment(
          bin: "970407",
          name: "Techcombank",
          accountNumber: "9876543210",
          accountName: "TRAN THI THU"
        )
      )
    ]

    public nonisolated static let samplePendingSettlementRequest = SettlementRequest(
      id: "01a1e4bd-ce20-7000-8000-000000000p01",
      fromMemberId: TripScenario.thuId,
      toMemberId: TripScenario.minhId,
      amount: Money(210_000),
      status: .pending,
      channel: .bank,
      note: "CK Vietcombank",
      createdByUserId: TripScenario.lanUserId,
      createdByName: "Thu",
      createdAt: "2026-11-22T10:00:00.000Z"
    )

    internal nonisolated static func applySamplePaymentMethods(to members: [Member]) -> [Member] {
      members.map { member in
        var updated = member
        if member.id == TripScenario.minhId || member.isMe {
          updated.paymentMethods = sampleMinhPaymentMethods
        } else if member.id == TripScenario.thuId {
          updated.paymentMethods = sampleThuPaymentMethods
        }
        return updated
      }
    }

    internal nonisolated static func applySamplePaymentMethods(to bal: GroupBalances)
      -> GroupBalances
    {
      let updatedTransfers = bal.transfers.map { transfer in
        let methods: [PaymentMethod] =
          transfer.toMemberId == TripScenario.thuId
          ? sampleThuPaymentMethods
          : sampleMinhPaymentMethods
        return SuggestedTransfer(
          fromMemberId: transfer.fromMemberId,
          toMemberId: transfer.toMemberId,
          fromHousehold: transfer.fromHousehold,
          toHousehold: transfer.toHousehold,
          amount: transfer.amount,
          paymentMethods: methods,
          purpose: transfer.purpose ?? "SP DALAT 3N2D",
          pendingSettlement: transfer.pendingSettlement
        )
      }
      return GroupBalances(
        currency: bal.currency,
        minimized: bal.minimized,
        balances: bal.balances,
        transfers: updatedTransfers,
        fund: bal.fund
      )
    }

    internal nonisolated static func applySamplePendingSettlement(to bal: GroupBalances)
      -> GroupBalances
    {
      let updatedTransfers = bal.transfers.map { transfer in
        guard transfer.fromMemberId == TripScenario.thuId,
          transfer.toMemberId == TripScenario.minhId
        else {
          return transfer
        }
        return SuggestedTransfer(
          fromMemberId: transfer.fromMemberId,
          toMemberId: transfer.toMemberId,
          fromHousehold: transfer.fromHousehold,
          toHousehold: transfer.toHousehold,
          amount: transfer.amount,
          paymentMethods: transfer.paymentMethods,
          purpose: transfer.purpose,
          pendingSettlement: PendingSettlement(
            id: samplePendingSettlementRequest.id,
            amount: Money(210_000),
            createdByMe: false,
            channel: .bank,
            note: "CK Vietcombank"
          )
        )
      }
      return GroupBalances(
        currency: bal.currency,
        minimized: bal.minimized,
        balances: bal.balances,
        transfers: updatedTransfers,
        fund: bal.fund
      )
    }

    public func seedSamplePaymentDetails(groupId: ExpenseGroup.ID = TripScenario.groupId) {
      let targetGroupId = groupsById[groupId] != nil ? groupId : (groupOrder.first ?? groupId)
      if let members = membersByGroup[targetGroupId] {
        membersByGroup[targetGroupId] = Self.applySamplePaymentMethods(to: members)
      }
      if let bal = balancesByGroup[targetGroupId] {
        balancesByGroup[targetGroupId] = Self.applySamplePaymentMethods(to: bal)
      }
    }

    public func seedSamplePendingSettlementRequest(groupId: ExpenseGroup.ID = TripScenario.groupId)
    {
      let targetGroupId = groupsById[groupId] != nil ? groupId : (groupOrder.first ?? groupId)
      var list = settlementRequestsByGroup[targetGroupId] ?? []
      if !list.contains(where: { $0.id == Self.samplePendingSettlementRequest.id }) {
        list.insert(Self.samplePendingSettlementRequest, at: 0)
        settlementRequestsByGroup[targetGroupId] = list
      }
      if let bal = balancesByGroup[targetGroupId] {
        balancesByGroup[targetGroupId] = Self.applySamplePendingSettlement(to: bal)
      }
    }

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
      channel: PaymentChannel?,
      note: String?,
      proofAttachmentId: Attachment.ID?,
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
      let proofAttachment = proofAttachmentId.flatMap { attachmentsByGroup[groupId]?[$0] }
      if proofAttachmentId != nil && proofAttachment == nil {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      seenIdempotencyKeys.insert(key)
      let reqId = UUID().uuidString
      let req = SettlementRequest(
        id: reqId,
        fromMemberId: transfer.fromMemberId,
        toMemberId: transfer.toMemberId,
        amount: transfer.amount,
        status: .pending,
        channel: channel,
        note: note,
        proofAttachment: proofAttachment,
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
                createdByMe: true,
                channel: channel,
                note: note,
                proofAttachmentId: proofAttachmentId
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
          attachments: current.proofAttachment.map { [$0] } ?? [],
          paymentChannel: current.channel,
          paymentNote: current.note
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
        channel: current.channel,
        note: current.note,
        proofAttachment: current.proofAttachment,
        transactionId: assignedTxId,
        createdByUserId: current.createdByUserId,
        createdByName: current.createdByName,
        resolvedByUserId: currentUser?.id,
        resolvedByName: currentUser?.name,
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
