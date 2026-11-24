public protocol BudgetRepository: Sendable {
  func lastKnownBudget(groupId: ExpenseGroup.ID) async -> GroupBudget?
  func budget(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBudget?
  func setBudget(
    groupId: ExpenseGroup.ID,
    period: BudgetPeriod,
    amount: Money
  ) async throws(AppError) -> GroupBudget
  func deleteBudget(groupId: ExpenseGroup.ID) async throws(AppError)
}
