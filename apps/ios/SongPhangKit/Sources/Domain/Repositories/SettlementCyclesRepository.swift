public protocol SettlementCyclesRepository: Sendable {
  func list(groupId: ExpenseGroup.ID) async throws(AppError) -> SettlementCyclesOverview
  func close(
    groupId: ExpenseGroup.ID,
    title: String?,
    idempotencyKey: IdempotencyKey
  ) async throws(AppError) -> SettlementCycle
  func reopen(
    groupId: ExpenseGroup.ID,
    cycleId: SettlementCycle.ID
  ) async throws(AppError)
}
