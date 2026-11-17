public protocol TransactionsRepository: Sendable {
  func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<LedgerTransaction>?
  func page(
    groupId: ExpenseGroup.ID,
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
