public enum SettlementDecision: Sendable {
  case confirm
  case reject
  case cancel
}

public protocol SettlementRequestsRepository: Sendable {
  func list(
    groupId: ExpenseGroup.ID,
    status: SettlementRequestStatus?
  ) async throws(AppError) -> [SettlementRequest]

  func request(
    groupId: ExpenseGroup.ID,
    transfer: SuggestedTransfer,
    channel: PaymentChannel?,
    note: String?,
    proofAttachmentId: Attachment.ID?,
    idempotencyKey: String
  ) async throws(AppError)

  func resolve(
    groupId: ExpenseGroup.ID,
    requestId: String,
    decision: SettlementDecision
  ) async throws(AppError)
}

extension SettlementRequestsRepository {
  public func request(
    groupId: ExpenseGroup.ID,
    transfer: SuggestedTransfer,
    idempotencyKey: String
  ) async throws(AppError) {
    try await request(
      groupId: groupId,
      transfer: transfer,
      channel: nil,
      note: nil,
      proofAttachmentId: nil,
      idempotencyKey: idempotencyKey
    )
  }
}
