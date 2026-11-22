public protocol CategoriesRepository: Sendable {
  func lastKnownCategories(groupId: ExpenseGroup.ID) async -> [GroupCategory]?
  func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupCategory]
  func create(
    groupId: ExpenseGroup.ID,
    name: String,
    color: MemberColor,
    key: IdempotencyKey
  ) async throws(AppError) -> GroupCategory
  func update(
    groupId: ExpenseGroup.ID,
    categoryId: GroupCategory.ID,
    name: String?,
    color: MemberColor?
  ) async throws(AppError) -> GroupCategory
  func archive(
    groupId: ExpenseGroup.ID,
    categoryId: GroupCategory.ID
  ) async throws(AppError)
}

extension CategoriesRepository {
  public func lastKnownCategories(groupId: ExpenseGroup.ID) async -> [GroupCategory]? {
    nil
  }
}
