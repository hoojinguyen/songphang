public protocol TransactionsRepository: Sendable {
  func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<LedgerTransaction>?
  func page(
    groupId: ExpenseGroup.ID,
    filter: TransactionFilter?,
    cursor: String?
  ) async throws(AppError) -> Page<LedgerTransaction>
  func transaction(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction
  func preview(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft
  ) async throws(AppError) -> SharePreview
  func previewItems(
    groupId: ExpenseGroup.ID,
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra],
    targetTotal: Money?
  ) async throws(AppError) -> ItemsPreview
  func create(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft,
    key: IdempotencyKey
  ) async throws(AppError) -> LedgerTransaction
  func update(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    draft: TransactionDraft,
    version: Int
  ) async throws(AppError) -> LedgerTransaction
  func delete(groupId: ExpenseGroup.ID, id: LedgerTransaction.ID) async throws(AppError)
  func restore(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction
}

extension TransactionsRepository {
  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<LedgerTransaction> {
    try await page(groupId: groupId, filter: nil, cursor: cursor)
  }

  public func previewItems(
    groupId: ExpenseGroup.ID,
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra]
  ) async throws(AppError) -> ItemsPreview {
    try await previewItems(groupId: groupId, items: items, extras: extras, targetTotal: nil)
  }
}
