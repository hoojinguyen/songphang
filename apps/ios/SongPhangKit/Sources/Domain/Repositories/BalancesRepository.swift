public protocol BalancesRepository: Sendable {
  func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances?
  func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances
}
