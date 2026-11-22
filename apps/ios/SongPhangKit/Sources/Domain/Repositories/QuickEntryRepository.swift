public protocol QuickEntryRepository: Sendable {
  func parse(
    groupId: ExpenseGroup.ID,
    text: String,
    ai: Bool
  ) async throws(AppError) -> QuickEntryReading
}

extension QuickEntryRepository {
  public func parse(
    groupId: ExpenseGroup.ID,
    text: String
  ) async throws(AppError) -> QuickEntryReading {
    try await parse(groupId: groupId, text: text, ai: false)
  }
}
