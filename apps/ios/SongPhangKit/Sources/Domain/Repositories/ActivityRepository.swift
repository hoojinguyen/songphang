public protocol ActivityRepository: Sendable {
  func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<ActivityItem>?
  func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<ActivityItem>
}
