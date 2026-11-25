public protocol OverviewRepository: Sendable {
  func lastKnownOverview() async -> OverviewSummary?
  func overview() async throws(AppError) -> OverviewSummary
  func transactions(
    cursor: String?,
    limit: Int,
    type: TransactionType?,
    groupId: ExpenseGroup.ID?,
    query: String?
  ) async throws(AppError) -> PersonalTransactionsPage
}
