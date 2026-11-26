public protocol BalancesRepository: Sendable {
  func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances?
  func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances
  func breakdowns(
    groupId: ExpenseGroup.ID,
    cycleId: BreakdownCycleSelection
  ) async throws(AppError) -> MemberBreakdownsResult
  func settlementVault(
    groupId: ExpenseGroup.ID,
    filter: SettlementVaultFilter,
    cycleId: TransactionCycleFilter?,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> SettlementVaultPage
}

extension BalancesRepository {
  public func breakdowns(groupId: ExpenseGroup.ID) async throws(AppError) -> MemberBreakdownsResult
  {
    try await breakdowns(groupId: groupId, cycleId: .auto)
  }

  public func settlementVault(
    groupId: ExpenseGroup.ID,
    filter: SettlementVaultFilter = .all,
    cycleId: TransactionCycleFilter? = nil,
    cursor: String? = nil
  ) async throws(AppError) -> SettlementVaultPage {
    try await settlementVault(
      groupId: groupId,
      filter: filter,
      cycleId: cycleId,
      cursor: cursor,
      limit: 50
    )
  }
}
