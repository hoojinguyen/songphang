public enum FundHolderUpdate: Sendable, Hashable {
  case unchanged
  case set(Member.ID)
  case clear
}

public protocol FundRepository: Sendable {
  func create(
    groupId: ExpenseGroup.ID,
    name: String?,
    holderMemberId: Member.ID?,
    key: IdempotencyKey
  ) async throws(AppError) -> Member
  func update(
    groupId: ExpenseGroup.ID,
    name: String?,
    holder: FundHolderUpdate,
    active: Bool?
  ) async throws(AppError) -> Member
  func delete(groupId: ExpenseGroup.ID) async throws(AppError)
}
