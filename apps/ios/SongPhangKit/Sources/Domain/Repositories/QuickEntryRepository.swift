public protocol QuickEntryRepository: Sendable {
  func parse(
    groupId: ExpenseGroup.ID,
    text: String
  ) async throws(AppError) -> QuickEntryReading
}
