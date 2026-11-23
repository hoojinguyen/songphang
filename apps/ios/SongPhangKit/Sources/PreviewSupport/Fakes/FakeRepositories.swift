#if DEBUG
  public import Domain
  public import Foundation

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
      return ServerFeatures(
        google: true,
        apple: true,
        devLogin: false,
        receiptReading: true,
        sentenceAi: true
      )
    }

    public func sessionGeneration() async -> UInt64 {
      0
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

    public func setMuted(id: ExpenseGroup.ID, muted: Bool) async throws(AppError) -> Bool {
      await world.setGroupMuted(id: id, muted: muted)
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

    public func replacePaymentMethods(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID,
      methods: [PaymentMethod]
    ) async throws(AppError) {
      try await world.replacePaymentMethods(groupId: groupId, memberId: memberId, methods: methods)
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
      filter: TransactionFilter?,
      cursor: String?
    ) async throws(AppError) -> Page<LedgerTransaction> {
      try await world.fetchTransactionsPage(groupId: groupId, filter: filter, cursor: cursor)
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

    public func previewItems(
      groupId: ExpenseGroup.ID,
      items: [SplitSpec.ItemEntry],
      extras: [SplitSpec.ItemsExtra],
      targetTotal: Money?
    ) async throws(AppError) -> ItemsPreview {
      try await world.previewItems(
        groupId: groupId,
        items: items,
        extras: extras,
        targetTotal: targetTotal
      )
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

    public func comments(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      cursor: String?,
      limit: Int
    ) async throws(AppError) -> (comments: [Comment], nextCursor: String?) {
      try await world.fetchComments(groupId: groupId, id: id, cursor: cursor, limit: limit)
    }

    public func addComment(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      body: String,
      key: IdempotencyKey
    ) async throws(AppError) -> Comment {
      try await world.addComment(groupId: groupId, id: id, body: body, key: key)
    }

    public func deleteComment(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      commentId: Comment.ID
    ) async throws(AppError) {
      try await world.deleteComment(groupId: groupId, id: id, commentId: commentId)
    }

    public func openDispute(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      reason: String
    ) async throws(AppError) -> LedgerTransaction.TransactionDispute {
      try await world.openDispute(groupId: groupId, id: id, reason: reason)
    }

    public func resolveDispute(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) {
      try await world.resolveDispute(groupId: groupId, id: id)
    }

    public func approve(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID
    ) async throws(AppError) -> LedgerTransaction {
      try await world.approveTransaction(groupId: groupId, id: id)
    }

    public func reject(
      groupId: ExpenseGroup.ID,
      id: LedgerTransaction.ID,
      note: String?
    ) async throws(AppError) -> LedgerTransaction {
      try await world.rejectTransaction(groupId: groupId, id: id, note: note)
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
      text: String,
      ai: Bool
    ) async throws(AppError) -> QuickEntryReading {
      try await world.parseSentence(groupId: groupId, text: text, ai: ai)
    }
  }

  public nonisolated struct FakeGroupEventsRepository: GroupEventsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
      world.eventStream(for: groupId)
    }
  }

  public nonisolated struct FakeDevicesRepository: DevicesRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func registerDevice(
      token: String,
      environment: PushRegistrationEnvironment
    ) async throws(AppError) -> String {
      try await world.registerDevice(token: token, environment: environment)
    }

    public func removeDevice(id: String) async throws(AppError) {
      try await world.removeDevice(id: id)
    }

    public func updateHidePushContent(_ hideContent: Bool) async throws(AppError) -> Bool {
      try await world.updateHidePushContent(hideContent)
    }
  }

  public nonisolated struct FakeCategoriesRepository: CategoriesRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownCategories(groupId: ExpenseGroup.ID) async -> [GroupCategory]? {
      await world.lastKnownCategories(groupId: groupId)
    }

    public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupCategory] {
      try await world.listCategories(groupId: groupId)
    }

    public func create(
      groupId: ExpenseGroup.ID,
      name: String,
      color: MemberColor,
      key: IdempotencyKey
    ) async throws(AppError) -> GroupCategory {
      try await world.createCategory(groupId: groupId, name: name, color: color, key: key)
    }

    public func update(
      groupId: ExpenseGroup.ID,
      categoryId: GroupCategory.ID,
      name: String?,
      color: MemberColor?
    ) async throws(AppError) -> GroupCategory {
      try await world.updateCategory(
        groupId: groupId,
        categoryId: categoryId,
        name: name,
        color: color
      )
    }

    public func archive(
      groupId: ExpenseGroup.ID,
      categoryId: GroupCategory.ID
    ) async throws(AppError) {
      try await world.archiveCategory(groupId: groupId, categoryId: categoryId)
    }
  }

  public nonisolated struct FakeStatisticsRepository: StatisticsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func stats(
      groupId: ExpenseGroup.ID,
      from: String?,
      to: String?
    ) async throws(AppError) -> GroupStats {
      try await world.fetchStats(groupId: groupId, from: from, to: to)
    }

    public func exportCSV(groupId: ExpenseGroup.ID) async throws(AppError) -> Data {
      try await world.exportCSV(groupId: groupId)
    }
  }

  public nonisolated struct FakeFundRepository: FundRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func create(
      groupId: ExpenseGroup.ID,
      name: String?,
      holderMemberId: Member.ID?,
      key: IdempotencyKey
    ) async throws(AppError) -> Member {
      try await world.createFund(
        groupId: groupId,
        name: name,
        holderMemberId: holderMemberId,
        key: key
      )
    }

    public func update(
      groupId: ExpenseGroup.ID,
      name: String?,
      holder: FundHolderUpdate,
      active: Bool?
    ) async throws(AppError) -> Member {
      try await world.updateFund(groupId: groupId, name: name, holder: holder, active: active)
    }

    public func delete(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await world.deleteFund(groupId: groupId)
    }
  }

  public nonisolated struct FakeBudgetRepository: BudgetRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func lastKnownBudget(groupId: ExpenseGroup.ID) async -> GroupBudget? {
      await world.lastKnownBudget(groupId: groupId)
    }

    public func budget(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBudget? {
      try await world.fetchBudget(groupId: groupId)
    }

    public func setBudget(
      groupId: ExpenseGroup.ID,
      period: BudgetPeriod,
      amount: Money
    ) async throws(AppError) -> GroupBudget {
      try await world.setBudget(groupId: groupId, period: period, amount: amount)
    }

    public func deleteBudget(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await world.deleteBudget(groupId: groupId)
    }
  }

  public nonisolated struct FakeAttachmentsRepository: AttachmentsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func upload(
      groupId: ExpenseGroup.ID,
      data: Data,
      filename: String,
      contentType: String
    ) async throws(AppError) -> Attachment {
      try await world.uploadAttachment(
        groupId: groupId,
        data: data,
        filename: filename,
        contentType: contentType
      )
    }

    public func content(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID
    ) async throws(AppError) -> Data {
      try await world.attachmentContent(groupId: groupId, attachmentId: attachmentId)
    }

    public func delete(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID
    ) async throws(AppError) {
      try await world.deleteAttachment(groupId: groupId, attachmentId: attachmentId)
    }
  }

  public nonisolated struct FakeReceiptScansRepository: ReceiptScansRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func start(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID,
      key: IdempotencyKey
    ) async throws(AppError) -> ReceiptScan {
      try await world.startReceiptScan(groupId: groupId, attachmentId: attachmentId, key: key)
    }

    public func scan(
      groupId: ExpenseGroup.ID,
      id: ReceiptScan.ID
    ) async throws(AppError) -> ReceiptScan {
      try await world.receiptScan(groupId: groupId, id: id)
    }
  }

  public nonisolated struct FakeNotificationsRepository: NotificationsRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func list(cursor: String?, limit: Int) async throws(AppError) -> (
      notifications: [AppNotification], nextCursor: String?
    ) {
      await world.listNotifications(cursor: cursor, limit: limit)
    }

    public func unreadCount() async throws(AppError) -> Int {
      await world.unreadNotificationCount()
    }

    public func markRead(ids: [AppNotification.ID]) async throws(AppError) {
      await world.markNotificationsRead(ids: ids)
    }

    public func markAllRead() async throws(AppError) {
      await world.markAllNotificationsRead()
    }

    public func settings() async throws(AppError) -> NotificationSettings {
      await world.getNotificationSettings()
    }

    public func updateSettings(emailImmediate: Bool?, emailDigest: Bool?) async throws(AppError)
      -> NotificationSettings
    {
      await world.updateNotificationSettings(
        emailImmediate: emailImmediate, emailDigest: emailDigest)
    }
  }

  public nonisolated struct FakeRemindersRepository: RemindersRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func sendReminder(
      groupId: ExpenseGroup.ID,
      fromMemberId: Member.ID,
      toMemberId: Member.ID
    ) async throws(AppError) -> SendReminderResult {
      await world.sendReminder(groupId: groupId, fromMemberId: fromMemberId, toMemberId: toMemberId)
    }

    public func sendAllReminders(groupId: ExpenseGroup.ID) async throws(AppError)
      -> SendReminderResult
    {
      await world.sendAllReminders(groupId: groupId)
    }
  }

  public nonisolated struct FakeChatLinksRepository: ChatLinksRepository {
    private let world: FakeWorld
    public init(world: FakeWorld) { self.world = world }

    public func myIdentities() async throws(AppError) -> [ChatIdentity] {
      await world.listChatIdentities()
    }

    public func unlinkMyIdentity(platform: ChatPlatform) async throws(AppError) {
      await world.unlinkChatIdentity(platform: platform)
    }

    public func startTelegramPairing() async throws(AppError) -> StartedTelegramPairing {
      await world.startTelegramPairing()
    }

    public func telegramPairing(id: TelegramPairing.ID) async throws(AppError) -> TelegramPairing {
      await world.fetchTelegramPairing(id: id)
    }

    public func confirmTelegramPairing(id: TelegramPairing.ID) async throws(AppError) {
      await world.confirmTelegramPairing(id: id)
    }

    public func cancelTelegramPairing(id: TelegramPairing.ID) async throws(AppError) {
      await world.cancelTelegramPairing(id: id)
    }

    public func groupChatLinks(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupChatLinks {
      await world.listGroupChatLinks(groupId: groupId)
    }

    public func createGroupChatLinkCode(groupId: ExpenseGroup.ID) async throws(AppError)
      -> GroupChatLinkCode
    {
      await world.createGroupChatLinkCode(groupId: groupId)
    }

    public func unlinkGroupChat(
      groupId: ExpenseGroup.ID,
      chatLinkId: ChatLink.ID
    ) async throws(AppError) {
      await world.unlinkGroupChat(groupId: groupId, chatLinkId: chatLinkId)
    }
  }
#endif
