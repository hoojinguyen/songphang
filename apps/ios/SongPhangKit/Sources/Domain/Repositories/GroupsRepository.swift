public struct UpdateGroupInput: Sendable, Hashable {
  public var name: String?
  public var minimizeDebts: Bool?
  public var defaultRole: Role?

  public init(name: String? = nil, minimizeDebts: Bool? = nil, defaultRole: Role? = nil) {
    self.name = name
    self.minimizeDebts = minimizeDebts
    self.defaultRole = defaultRole
  }
}

public protocol GroupsRepository: Sendable {
  func lastKnownGroups() async -> [ExpenseGroup]?
  func groups() async throws(AppError) -> [ExpenseGroup]
  func lastKnownGroup(id: ExpenseGroup.ID) async -> ExpenseGroup?
  func group(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup
  func create(
    name: String,
    memberNames: [String],
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup
  func update(
    id: ExpenseGroup.ID,
    input: UpdateGroupInput
  ) async throws(AppError) -> ExpenseGroup
  func delete(id: ExpenseGroup.ID, confirmName: String) async throws(AppError)
}
