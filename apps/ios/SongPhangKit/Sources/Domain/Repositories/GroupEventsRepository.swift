public protocol GroupEventsRepository: Sendable {
  func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent>
}
