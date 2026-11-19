public import Domain

// Temporary explicitly-gated repositories for Task 5B.1 only.
// Each repository is replaced as Tasks 5B.2, 5B.3, and 5B.4 connect live resources.

public struct GatedAuthRepository: AuthRepository {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func currentUser() async throws(AppError) -> User? {
    nil
  }

  public func signIn(email: String, password: String) async throws(AppError) -> User {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func signInWithGoogle() async throws(AppError) -> User {
    throw .api(code: "STAGE_5C1_PENDING", status: 501)
  }

  public func signInWithApple() async throws(AppError) -> User {
    throw .api(code: "STAGE_5C2_PENDING", status: 501)
  }

  public func register(email: String, name: String, password: String) async throws(AppError) {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func requestPasswordReset(email: String) async throws(AppError) {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func resendVerification() async throws(AppError) {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func changePassword(
    currentPassword: String,
    newPassword: String,
    revokeOtherSessions: Bool
  ) async throws(AppError) {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func deleteAccount(email: String) async throws(AppError) {
    throw .api(code: "STAGE_5B2_PENDING", status: 501)
  }

  public func serverFeatures() async throws(AppError) -> ServerFeatures {
    try await environment.fetchServerFeatures()
  }

  public func signOut() async throws(AppError) {
    await environment.tokenStore.clear()
  }
}

public struct GatedGroupsRepository: GroupsRepository {
  public init() {}
  public func lastKnownGroups() async -> [ExpenseGroup]? { nil }
  public func groups() async throws(AppError) -> [ExpenseGroup] {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func lastKnownGroup(id: ExpenseGroup.ID) async -> ExpenseGroup? { nil }
  public func group(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func create(
    name: String,
    memberNames: [String],
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func update(
    id: ExpenseGroup.ID,
    input: UpdateGroupInput
  ) async throws(AppError) -> ExpenseGroup {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func delete(id: ExpenseGroup.ID, confirmName: String) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
}

public struct GatedMembersRepository: MembersRepository {
  public init() {}
  public func lastKnownMembers(groupId: ExpenseGroup.ID) async -> [Member]? { nil }
  public func members(groupId: ExpenseGroup.ID) async throws(AppError) -> [Member] {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func lastKnownGroupUsers(groupId: ExpenseGroup.ID) async -> [GroupUser]? { nil }
  public func groupUsers(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupUser] {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func create(
    groupId: ExpenseGroup.ID,
    name: String,
    key: IdempotencyKey
  ) async throws(AppError) -> Member {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func update(
    groupId: ExpenseGroup.ID,
    memberId: Member.ID,
    input: UpdateMemberInput
  ) async throws(AppError) -> Member {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func delete(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func chooseMyMember(
    groupId: ExpenseGroup.ID,
    memberId: Member.ID
  ) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func updateUserRole(
    groupId: ExpenseGroup.ID,
    userId: User.ID,
    role: Role
  ) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func removeUser(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func transferOwnership(
    groupId: ExpenseGroup.ID,
    userId: User.ID
  ) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func leaveGroup(groupId: ExpenseGroup.ID) async throws(AppError) {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
}

public struct GatedInvitesRepository: InvitesRepository {
  public init() {}
  public func lastKnownInvite(groupId: ExpenseGroup.ID) async -> Invite? { nil }
  public func invite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func setActive(groupId: ExpenseGroup.ID, active: Bool) async throws(AppError) -> Invite {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func rotate(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func preview(token: String) async throws(AppError) -> InvitePreview {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
  public func join(
    token: String,
    choice: JoinChoice,
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup.ID {
    throw .api(code: "STAGE_5B3_PENDING", status: 501)
  }
}

public struct GatedTransactionsRepository: TransactionsRepository {
  public init() {}
  public func lastKnownFirstPage(
    groupId: ExpenseGroup.ID
  ) async -> Page<LedgerTransaction>? { nil }
  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<LedgerTransaction> {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func transaction(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func preview(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft
  ) async throws(AppError) -> SharePreview {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func create(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft,
    key: IdempotencyKey
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func update(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    draft: TransactionDraft,
    version: Int
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func delete(groupId: ExpenseGroup.ID, id: LedgerTransaction.ID) async throws(AppError) {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func restore(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedBalancesRepository: BalancesRepository {
  public init() {}
  public func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances? { nil }
  public func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedActivityRepository: ActivityRepository {
  public init() {}
  public func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<ActivityItem>? { nil }
  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<ActivityItem> {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedQuickEntryRepository: QuickEntryRepository {
  public init() {}
  public func parse(
    groupId: ExpenseGroup.ID,
    text: String
  ) async throws(AppError) -> QuickEntryReading {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedGroupEventsRepository: GroupEventsRepository {
  public init() {}
  public func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
    AsyncStream { $0.finish() }
  }
}
