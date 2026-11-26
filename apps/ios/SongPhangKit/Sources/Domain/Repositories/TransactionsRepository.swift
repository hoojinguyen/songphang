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
    extrasAllocation: ExtrasAllocation?,
    targetTotal: Money?
  ) async throws(AppError) -> ItemsPreview
  func previewExtras(
    groupId: ExpenseGroup.ID,
    input: PreviewExtrasInput
  ) async throws(AppError) -> PreviewExtrasResult
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
  func comments(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> (comments: [Comment], nextCursor: String?)
  func addComment(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    body: String,
    key: IdempotencyKey
  ) async throws(AppError) -> Comment
  func deleteComment(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    commentId: Comment.ID
  ) async throws(AppError)
  func openDispute(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    reason: String
  ) async throws(AppError) -> LedgerTransaction.TransactionDispute
  func resolveDispute(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError)
  func approve(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction
  func reject(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    note: String?
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
    extras: [SplitSpec.ItemsExtra],
    targetTotal: Money?
  ) async throws(AppError) -> ItemsPreview {
    try await previewItems(
      groupId: groupId,
      items: items,
      extras: extras,
      extrasAllocation: nil,
      targetTotal: targetTotal
    )
  }

  public func previewItems(
    groupId: ExpenseGroup.ID,
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra]
  ) async throws(AppError) -> ItemsPreview {
    try await previewItems(
      groupId: groupId,
      items: items,
      extras: extras,
      extrasAllocation: nil,
      targetTotal: nil
    )
  }
}
