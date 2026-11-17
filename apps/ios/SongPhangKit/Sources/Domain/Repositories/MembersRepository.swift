public struct UpdateMemberInput: Sendable, Hashable {
  public var name: String?
  public var defaultWeight: String?
  public var active: Bool?

  public init(name: String? = nil, defaultWeight: String? = nil, active: Bool? = nil) {
    self.name = name
    self.defaultWeight = defaultWeight
    self.active = active
  }
}

public protocol MembersRepository: Sendable {
  func lastKnownMembers(groupId: ExpenseGroup.ID) async -> [Member]?
  func members(groupId: ExpenseGroup.ID) async throws(AppError) -> [Member]
  func lastKnownGroupUsers(groupId: ExpenseGroup.ID) async -> [GroupUser]?
  func groupUsers(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupUser]
  func create(
    groupId: ExpenseGroup.ID,
    name: String,
    key: IdempotencyKey
  ) async throws(AppError) -> Member
  func update(
    groupId: ExpenseGroup.ID,
    memberId: Member.ID,
    input: UpdateMemberInput
  ) async throws(AppError) -> Member
  func delete(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError)
  func chooseMyMember(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError)
  func updateUserRole(
    groupId: ExpenseGroup.ID,
    userId: User.ID,
    role: Role
  ) async throws(AppError)
  func removeUser(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError)
  func transferOwnership(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError)
  func leaveGroup(groupId: ExpenseGroup.ID) async throws(AppError)
}
