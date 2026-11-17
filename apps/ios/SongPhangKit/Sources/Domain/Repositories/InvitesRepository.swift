public protocol InvitesRepository: Sendable {
  func lastKnownInvite(groupId: ExpenseGroup.ID) async -> Invite?
  func invite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite
  func setActive(groupId: ExpenseGroup.ID, active: Bool) async throws(AppError) -> Invite
  func rotate(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite
  func preview(token: String) async throws(AppError) -> InvitePreview
  func join(
    token: String,
    choice: JoinChoice,
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup.ID
}
