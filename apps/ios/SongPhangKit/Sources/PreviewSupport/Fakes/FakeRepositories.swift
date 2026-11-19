#if DEBUG
  public import Domain

  public nonisolated struct FakeAuthRepository: AuthRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownUser() async -> User? {
      await world.lastKnownUser()
    }

    public func currentUser() async throws(AppError) -> User? {
      try await world.getCurrentUser()
    }

    public func signIn(email: String, password: String) async throws(AppError) -> User {
      try await world.signIn(email: email, password: password)
    }

    public func signInWithGoogle() async throws(AppError) -> User {
      try await world.signInWithProvider()
    }

    public func signInWithApple() async throws(AppError) -> User {
      try await world.signInWithProvider()
    }

    public func register(email: String, name: String, password: String) async throws(AppError) {
      try await world.register(email: email, name: name, password: password)
    }

    public func requestPasswordReset(email: String) async throws(AppError) {
      try await world.requestPasswordReset(email: email)
    }

    public func resendVerification() async throws(AppError) {
      try await world.resendVerification()
    }

    public func changePassword(
      currentPassword: String,
      newPassword: String,
      revokeOtherSessions: Bool
    ) async throws(AppError) {
      try await world.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        revokeOtherSessions: revokeOtherSessions
      )
    }

    public func deleteAccount(email: String) async throws(AppError) {
      try await world.deleteAccount(email: email)
    }

    public func sessions() async throws(AppError) -> [UserSession] {
      try await world.listSessions()
    }

    public func revokeSession(id: UserSession.ID) async throws(AppError) {
      try await world.revokeSession(id: id)
    }

    public func serverFeatures() async throws(AppError) -> ServerFeatures {
      try await world.simulateNetwork()
      return ServerFeatures(google: true, apple: true, devLogin: false)
    }

    public func signOut() async throws(AppError) {
      try await world.signOut()
    }
  }

  public nonisolated struct FakeGroupsRepository: GroupsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownGroups() async -> [ExpenseGroup]? {
      await world.lastKnownGroups()
    }

    public func groups() async throws(AppError) -> [ExpenseGroup] {
      try await world.fetchGroups()
    }

    public func lastKnownGroup(id: ExpenseGroup.ID) async -> ExpenseGroup? {
      await world.lastKnownGroup(id: id)
    }

    public func group(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
      try await world.fetchGroup(id: id)
    }

    public func create(
      name: String,
      memberNames: [String],
      key: IdempotencyKey
    ) async throws(AppError) -> ExpenseGroup {
      try await world.createGroup(name: name, memberNames: memberNames, key: key)
    }

    public func update(
      id: ExpenseGroup.ID,
      input: UpdateGroupInput
    ) async throws(AppError) -> ExpenseGroup {
      try await world.updateGroup(id: id, input: input)
    }

    public func delete(id: ExpenseGroup.ID, confirmName: String) async throws(AppError) {
      try await world.deleteGroup(id: id, confirmName: confirmName)
    }
  }

  public nonisolated struct FakeMembersRepository: MembersRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownMembers(groupId: ExpenseGroup.ID) async -> [Member]? {
      await world.lastKnownMembers(groupId: groupId)
    }

    public func members(groupId: ExpenseGroup.ID) async throws(AppError) -> [Member] {
      try await world.fetchMembers(groupId: groupId)
    }

    public func lastKnownGroupUsers(groupId: ExpenseGroup.ID) async -> [GroupUser]? {
      await world.lastKnownGroupUsers(groupId: groupId)
    }

    public func groupUsers(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupUser] {
      try await world.fetchGroupUsers(groupId: groupId)
    }

    public func create(
      groupId: ExpenseGroup.ID,
      name: String,
      key: IdempotencyKey
    ) async throws(AppError) -> Member {
      try await world.createMember(groupId: groupId, name: name, key: key)
    }

    public func update(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID,
      input: UpdateMemberInput
    ) async throws(AppError) -> Member {
      try await world.updateMember(groupId: groupId, memberId: memberId, input: input)
    }

    public func delete(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError) {
      try await world.deleteMember(groupId: groupId, memberId: memberId)
    }

    public func chooseMyMember(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID
    ) async throws(AppError) {
      try await world.chooseMyMember(groupId: groupId, memberId: memberId)
    }

    public func updateUserRole(
      groupId: ExpenseGroup.ID,
      userId: User.ID,
      role: Role
    ) async throws(AppError) {
      try await world.updateUserRole(groupId: groupId, userId: userId, role: role)
    }

    public func removeUser(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError) {
      try await world.removeUser(groupId: groupId, userId: userId)
    }

    public func transferOwnership(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError)
    {
      try await world.transferOwnership(groupId: groupId, userId: userId)
    }

    public func leaveGroup(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await world.leaveGroup(groupId: groupId)
    }
  }

  public nonisolated struct FakeInvitesRepository: InvitesRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownInvite(groupId: ExpenseGroup.ID) async -> Invite? {
      await world.lastKnownInvite(groupId: groupId)
    }

    public func invite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
      try await world.fetchInvite(groupId: groupId)
    }

    public func setActive(groupId: ExpenseGroup.ID, active: Bool) async throws(AppError) -> Invite {
      try await world.setInviteActive(groupId: groupId, active: active)
    }

    public func rotate(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
      try await world.rotateInvite(groupId: groupId)
    }

    public func preview(token: String) async throws(AppError) -> InvitePreview {
      try await world.previewInvite(token: token)
    }

    public func join(
      token: String,
      choice: JoinChoice,
      key: IdempotencyKey
    ) async throws(AppError) -> ExpenseGroup.ID {
      try await world.joinInvite(token: token, choice: choice, key: key)
    }
  }

  public nonisolated struct FakeTransactionsRepository: TransactionsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownFirstPage(
      groupId: ExpenseGroup.ID
    ) async -> Page<LedgerTransaction>? {
      await world.lastKnownTransactionsFirstPage(groupId: groupId)
    }

    public func page(
      groupId: ExpenseGroup.ID,
      cursor: String?
    ) async throws(AppError) -> Page<LedgerTransaction> {
      try await world.fetchTransactionsPage(groupId: groupId, cursor: cursor)
    }

    public func transaction(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await world.fetchTransaction(groupId: groupId, id: id)
    }

    public func preview(
      groupId: ExpenseGroup.ID,
      draft: TransactionDraft
    ) async throws(AppError) -> SharePreview {
      try await world.previewTransaction(groupId: groupId, draft: draft)
    }

    public func create(
      groupId: ExpenseGroup.ID,
      draft: TransactionDraft,
      key: IdempotencyKey
    ) async throws(AppError) -> LedgerTransaction {
      try await world.createTransaction(groupId: groupId, draft: draft, key: key)
    }

    public func update(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      draft: TransactionDraft,
      version: Int
    ) async throws(AppError) -> LedgerTransaction {
      try await world.updateTransaction(
        groupId: groupId,
        id: id,
        draft: draft,
        version: version
      )
    }

    public func delete(groupId: ExpenseGroup.ID, id: LedgerTransaction.ID) async throws(AppError) {
      try await world.deleteTransaction(groupId: groupId, id: id)
    }

    public func restore(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await world.restoreTransaction(groupId: groupId, id: id)
    }
  }

  public nonisolated struct FakeBalancesRepository: BalancesRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances? {
      await world.lastKnownBalances(groupId: groupId)
    }

    public func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances {
      try await world.fetchBalances(groupId: groupId)
    }
  }

  public nonisolated struct FakeActivityRepository: ActivityRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<ActivityItem>? {
      await world.lastKnownActivityFirstPage(groupId: groupId)
    }

    public func page(
      groupId: ExpenseGroup.ID,
      cursor: String?
    ) async throws(AppError) -> Page<ActivityItem> {
      try await world.fetchActivityPage(groupId: groupId, cursor: cursor)
    }
  }

  public nonisolated struct FakeQuickEntryRepository: QuickEntryRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func parse(
      groupId: ExpenseGroup.ID,
      text: String
    ) async throws(AppError) -> QuickEntryReading {
      try await world.parseSentence(groupId: groupId, text: text)
    }
  }

  public nonisolated struct FakeGroupEventsRepository: GroupEventsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
      world.eventStream(for: groupId)
    }
  }
#endif
