public protocol HouseholdsRepository: Sendable {
  func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [Household]
  func create(
    groupId: ExpenseGroup.ID,
    input: CreateHouseholdInput,
    key: IdempotencyKey
  ) async throws(AppError) -> Household
  func update(
    groupId: ExpenseGroup.ID,
    id: Household.ID,
    input: UpdateHouseholdInput
  ) async throws(AppError) -> Household
  func delete(groupId: ExpenseGroup.ID, id: Household.ID) async throws(AppError)
}
