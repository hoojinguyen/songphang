public protocol ReceiptScansRepository: Sendable {
  func start(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID,
    key: IdempotencyKey
  ) async throws(AppError) -> ReceiptScan

  func scan(
    groupId: ExpenseGroup.ID,
    id: ReceiptScan.ID
  ) async throws(AppError) -> ReceiptScan
}
