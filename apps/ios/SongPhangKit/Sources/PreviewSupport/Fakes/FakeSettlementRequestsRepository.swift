#if DEBUG
  public import Domain

  public nonisolated struct FakeSettlementRequestsRepository: SettlementRequestsRepository {
    private let world: FakeWorld

    public init(world: FakeWorld) {
      self.world = world
    }

    public func list(
      groupId: ExpenseGroup.ID,
      status: SettlementRequestStatus?
    ) async throws(AppError) -> [SettlementRequest] {
      try await world.listSettlementRequests(groupId: groupId, status: status)
    }

    public func request(
      groupId: ExpenseGroup.ID,
      transfer: SuggestedTransfer,
      channel: PaymentChannel?,
      note: String?,
      proofAttachmentId: Attachment.ID?,
      idempotencyKey: String
    ) async throws(AppError) {
      try await world.createSettlementRequest(
        groupId: groupId,
        transfer: transfer,
        channel: channel,
        note: note,
        proofAttachmentId: proofAttachmentId,
        idempotencyKey: idempotencyKey
      )
    }

    public func resolve(
      groupId: ExpenseGroup.ID,
      requestId: String,
      decision: SettlementDecision
    ) async throws(AppError) {
      try await world.resolveSettlementRequest(
        groupId: groupId, requestId: requestId, decision: decision)
    }
  }
#endif
