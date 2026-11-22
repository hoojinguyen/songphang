#if DEBUG
  public import Domain
  import Foundation

  public nonisolated enum ScenarioPreset: String, Sendable, CaseIterable, Hashable {
    case empty = "empty"
    case tripStep0 = "trip (step 0)"
    case tripStep4 = "trip (step 4)"
    case large = "large"
  }

  public nonisolated struct FakeBehavior: Sendable, Equatable {
    public var latency: Duration
    public var failure: AppError?
    public var hasSnapshot: Bool
    public var role: Role

    public init(
      latency: Duration = .zero,
      failure: AppError? = nil,
      hasSnapshot: Bool = true,
      role: Role = .owner
    ) {
      self.latency = latency
      self.failure = failure
      self.hasSnapshot = hasSnapshot
      self.role = role
    }
  }

  public actor FakeWorld {
    public private(set) var preset: ScenarioPreset
    public private(set) var behavior: FakeBehavior
    public private(set) var currentUser: User?
    private var activeSessions: [UserSession] = [
      UserSession(
        id: UserSession.ID("00000000-0000-7000-8000-000000000501"),
        client: .ios,
        deviceName: "iPhone 17 Pro",
        createdAt: "2026-11-16T08:00:00.000Z",
        lastSeenAt: "2026-11-16T15:00:00.000Z",
        current: true
      ),
      UserSession(
        id: UserSession.ID("00000000-0000-7000-8000-000000000502"),
        client: .web,
        deviceName: nil,
        createdAt: "2026-11-15T10:00:00.000Z",
        lastSeenAt: "2026-11-16T14:30:00.000Z",
        current: false
      ),
    ]

    internal var groupsById: [ExpenseGroup.ID: ExpenseGroup] = [:]
    private var groupOrder: [ExpenseGroup.ID] = []
    internal var membersByGroup: [ExpenseGroup.ID: [Member]] = [:]
    private var usersByGroup: [ExpenseGroup.ID: [GroupUser]] = [:]
    private var invitesByGroup: [ExpenseGroup.ID: Invite] = [:]
    internal var transactionsByGroup: [ExpenseGroup.ID: [LedgerTransaction]] = [:]
    internal var balancesByGroup: [ExpenseGroup.ID: GroupBalances] = [:]
    internal var activityByGroup: [ExpenseGroup.ID: [ActivityItem]] = [:]
    internal var categoriesByGroup: [ExpenseGroup.ID: [GroupCategory]] = [:]
    internal var settlementRequestsByGroup: [ExpenseGroup.ID: [SettlementRequest]] = [:]
    internal var seenIdempotencyKeys: Set<IdempotencyKey> = []
    internal var deletedTransactionsByGroup:
      [ExpenseGroup.ID: [LedgerTransaction.ID: LedgerTransaction]] = [:]
    internal var deletedPrevBalancesByGroup:
      [ExpenseGroup.ID: [LedgerTransaction.ID: GroupBalances]] = [:]
    private var eventContinuations: [UUID: AsyncStream<GroupEvent>.Continuation] = [:]

    private struct PresetState: Sendable {
      var user: User?
      var groupsById: [ExpenseGroup.ID: ExpenseGroup] = [:]
      var groupOrder: [ExpenseGroup.ID] = []
      var membersByGroup: [ExpenseGroup.ID: [Member]] = [:]
      var usersByGroup: [ExpenseGroup.ID: [GroupUser]] = [:]
      var invitesByGroup: [ExpenseGroup.ID: Invite] = [:]
      var transactionsByGroup: [ExpenseGroup.ID: [LedgerTransaction]] = [:]
      var balancesByGroup: [ExpenseGroup.ID: GroupBalances] = [:]
      var activityByGroup: [ExpenseGroup.ID: [ActivityItem]] = [:]
      var categoriesByGroup: [ExpenseGroup.ID: [GroupCategory]] = [:]
    }

    public init(
      preset: ScenarioPreset = .tripStep4,
      behavior: FakeBehavior = FakeBehavior(),
      signedIn: Bool = true
    ) {
      self.preset = preset
      self.behavior = behavior
      let initial = Self.makePresetState(preset, role: behavior.role, signedIn: signedIn)
      self.currentUser = initial.user
      self.groupsById = initial.groupsById
      self.groupOrder = initial.groupOrder
      self.membersByGroup = initial.membersByGroup
      self.usersByGroup = initial.usersByGroup
      self.invitesByGroup = initial.invitesByGroup
      self.transactionsByGroup = initial.transactionsByGroup
      self.balancesByGroup = initial.balancesByGroup
      self.activityByGroup = initial.activityByGroup
      self.categoriesByGroup = initial.categoriesByGroup
    }

    public func setBehavior(_ newBehavior: FakeBehavior) {
      self.behavior = newBehavior
      for groupId in groupOrder {
        if var group = groupsById[groupId] {
          group.role = newBehavior.role
          groupsById[groupId] = group
        }
        if var users = usersByGroup[groupId] {
          for idx in users.indices where users[idx].isMe {
            users[idx].role = newBehavior.role
          }
          usersByGroup[groupId] = users
        }
      }
    }

    public func applyScenario(_ newPreset: ScenarioPreset, signedIn: Bool = true) {
      self.preset = newPreset
      let next = Self.makePresetState(newPreset, role: behavior.role, signedIn: signedIn)
      self.currentUser = next.user
      self.groupsById = next.groupsById
      self.groupOrder = next.groupOrder
      self.membersByGroup = next.membersByGroup
      self.usersByGroup = next.usersByGroup
      self.invitesByGroup = next.invitesByGroup
      self.transactionsByGroup = next.transactionsByGroup
      self.balancesByGroup = next.balancesByGroup
      self.activityByGroup = next.activityByGroup
      self.categoriesByGroup = next.categoriesByGroup
      self.seenIdempotencyKeys.removeAll()
      self.deletedTransactionsByGroup.removeAll()
      self.deletedPrevBalancesByGroup.removeAll()
    }

    public func setCurrentUser(_ user: User?) {
      self.currentUser = user
    }

    private nonisolated static func makePresetState(
      _ preset: ScenarioPreset,
      role: Role,
      signedIn: Bool
    ) -> PresetState {
      var state = PresetState()
      switch preset {
      case .empty:
        state.user = signedIn ? EmptyScenario.user : nil
      case .tripStep0:
        state.user = signedIn ? TripScenario.user : nil
        let group = TripScenario.group(forStep: 0, role: role)
        let id = group.id
        state.groupsById[id] = group
        state.groupOrder = [id]
        state.membersByGroup[id] = TripScenario.members
        state.usersByGroup[id] = TripScenario.groupUsers
        state.invitesByGroup[id] = TripScenario.invite
        state.transactionsByGroup[id] = TripScenario.transactions(forStep: 0)
        state.balancesByGroup[id] = TripScenario.balances(forStep: 0)
        state.activityByGroup[id] = [TripScenario.activityItems.last].compactMap { $0 }
      case .tripStep4:
        state.user = signedIn ? TripScenario.user : nil
        let group = TripScenario.group(forStep: 4, role: role)
        let id = group.id
        state.groupsById[id] = group
        state.groupOrder = [id]
        state.membersByGroup[id] = TripScenario.members
        state.usersByGroup[id] = TripScenario.groupUsers
        state.invitesByGroup[id] = TripScenario.invite
        state.transactionsByGroup[id] = TripScenario.transactions(forStep: 4)
        state.balancesByGroup[id] = TripScenario.balances(forStep: 4)
        state.activityByGroup[id] = TripScenario.activityItems
        state.categoriesByGroup[id] = FakeWorld.defaultTripCategories
      case .large:
        state.user = signedIn ? TripScenario.user : nil
        var group = LargeScenario.group
        group.role = role
        let id = group.id
        state.groupsById[id] = group
        state.groupOrder = [id]
        state.membersByGroup[id] = LargeScenario.members
        state.usersByGroup[id] = TripScenario.groupUsers
        state.invitesByGroup[id] = TripScenario.invite
        state.transactionsByGroup[id] = LargeScenario.transactions
        state.balancesByGroup[id] = LargeScenario.balances
        state.activityByGroup[id] = TripScenario.activityItems
      }
      return state
    }

    public func simulateNetwork() async throws(AppError) {
      if behavior.latency > .zero {
        try? await Task.sleep(for: behavior.latency)
      }
      if let failure = behavior.failure {
        if failure == .unauthorized {
          currentUser = nil
        }
        throw failure
      }
    }

    // MARK: - Events

    public nonisolated func eventStream(for _: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
      AsyncStream { continuation in
        let id = UUID()
        Task {
          await self.registerContinuation(continuation, id: id)
        }
        continuation.onTermination = { _ in
          Task {
            await self.unregisterContinuation(id: id)
          }
        }
      }
    }

    private func registerContinuation(
      _ continuation: AsyncStream<GroupEvent>.Continuation,
      id: UUID
    ) {
      eventContinuations[id] = continuation
    }

    private func unregisterContinuation(id: UUID) {
      eventContinuations.removeValue(forKey: id)
    }

    public func clearActivity(groupId: ExpenseGroup.ID) {
      activityByGroup[groupId] = []
    }

    public func emitEvent(_ event: GroupEvent) {
      if case .removed = event {
        let groupId = TripScenario.groupId
        groupsById.removeValue(forKey: groupId)
        groupOrder.removeAll { $0 == groupId }
      }
      if case .changed = event {
        // When the debug panel emits a changed event on trip, append a scripted transaction if not present so "new item" can be observed.
        let groupId = TripScenario.groupId
        if var list = transactionsByGroup[groupId] {
          let extraId = LedgerTransaction.ID("event-tx-coffee")
          if !list.contains(where: { $0.id == extraId }) {
            let newTx = LedgerTransaction(
              id: extraId,
              type: .expense,
              description: "cà phê",
              amount: Money(180_000),
              currency: "VND",
              occurredAt: "2026-11-16T15:00:00.000Z",
              category: .food,
              payers: [MemberAmount(memberId: TripScenario.minhId, amount: Money(180_000))],
              split: .equal(members: [
                TripScenario.minhId, TripScenario.lanId, TripScenario.hungId, TripScenario.thuId,
              ]),
              shares: [
                MemberAmount(memberId: TripScenario.minhId, amount: Money(45_000)),
                MemberAmount(memberId: TripScenario.lanId, amount: Money(45_000)),
                MemberAmount(memberId: TripScenario.hungId, amount: Money(45_000)),
                MemberAmount(memberId: TripScenario.thuId, amount: Money(45_000)),
              ],
              version: 1,
              updatedBy: TripScenario.actorMinh,
              createdBy: TripScenario.actorMinh
            )
            list.insert(newTx, at: 0)
            transactionsByGroup[groupId] = list
          }
        }
      }
      for continuation in eventContinuations.values {
        continuation.yield(event)
      }
    }

    // MARK: - Auth

    public func lastKnownUser() -> User? {
      behavior.hasSnapshot ? currentUser : nil
    }

    public func getCurrentUser() async throws(AppError) -> User? {
      try await simulateNetwork()
      return currentUser
    }

    public func listSessions() async throws(AppError) -> [UserSession] {
      try await simulateNetwork()
      guard currentUser != nil else { throw .unauthorized }
      return activeSessions
    }

    public func revokeSession(id: UserSession.ID) async throws(AppError) {
      try await simulateNetwork()
      guard currentUser != nil else { throw .unauthorized }
      if let idx = activeSessions.firstIndex(where: { $0.id == id }) {
        let wasCurrent = activeSessions[idx].current
        activeSessions.remove(at: idx)
        if wasCurrent {
          currentUser = nil
        }
      } else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
    }

    public func signIn(email: String, password: String) async throws(AppError) -> User {
      try await simulateNetwork()
      if password == "wrong" {
        throw .api(code: "INVALID_CREDENTIALS", status: 401)
      }
      let user = User(
        id: TripScenario.userId,
        email: email.isEmpty ? TripScenario.user.email : email.lowercased(),
        name: TripScenario.user.name,
        avatarUrl: nil,
        emailVerified: true,
        hasPassword: true
      )
      currentUser = user
      return user
    }

    public func signInWithProvider() async throws(AppError) -> User {
      try await simulateNetwork()
      let user = TripScenario.user
      currentUser = user
      return user
    }

    public func register(email: String, name: String, password: String) async throws(AppError) {
      try await simulateNetwork()
      if password.count < 10 {
        throw .api(code: "WEAK_PASSWORD", status: 400)
      }
      _ = (email, name)
    }

    public func requestPasswordReset(email _: String) async throws(AppError) {
      try await simulateNetwork()
    }

    public func resendVerification() async throws(AppError) {
      try await simulateNetwork()
    }

    public func changePassword(
      currentPassword: String,
      newPassword: String,
      revokeOtherSessions _: Bool
    ) async throws(AppError) {
      try await simulateNetwork()
      if currentPassword == "wrong" {
        throw .api(code: "INVALID_CREDENTIALS", status: 401)
      }
      if newPassword.count < 10 {
        throw .api(code: "WEAK_PASSWORD", status: 400)
      }
      if var user = currentUser {
        user.hasPassword = true
        currentUser = user
      }
    }

    public func deleteAccount(email: String) async throws(AppError) {
      try await simulateNetwork()
      guard let user = currentUser, email.lowercased() == user.email.lowercased() else {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      currentUser = nil
    }

    public func signOut() async throws(AppError) {
      try await simulateNetwork()
      currentUser = nil
    }

    public func registerDevice(
      token: String,
      environment _: PushRegistrationEnvironment
    ) async throws(AppError) -> String {
      try await simulateNetwork()
      _ = token
      return "01930000-0000-7000-8000-0000000000d1"
    }

    public func removeDevice(id _: String) async throws(AppError) {
      try await simulateNetwork()
    }

    public func updateHidePushContent(_ hideContent: Bool) async throws(AppError) -> Bool {
      try await simulateNetwork()
      if var user = currentUser {
        user.hidePushContent = hideContent
        currentUser = user
      }
      return hideContent
    }

    // MARK: - Groups

    public func lastKnownGroups() -> [ExpenseGroup]? {
      guard behavior.hasSnapshot else { return nil }
      return groupOrder.compactMap { groupsById[$0] }
    }

    public func fetchGroups() async throws(AppError) -> [ExpenseGroup] {
      try await simulateNetwork()
      return groupOrder.compactMap { groupsById[$0] }
    }

    public func lastKnownGroup(id: ExpenseGroup.ID) -> ExpenseGroup? {
      guard behavior.hasSnapshot else { return nil }
      return groupsById[id]
    }

    public func fetchGroup(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      guard let group = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return group
    }

    public func createGroup(
      name: String,
      memberNames: [String],
      key: IdempotencyKey
    ) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      if seenIdempotencyKeys.contains(key), let firstId = groupOrder.first,
        let existing = groupsById[firstId]
      {
        return existing
      }
      seenIdempotencyKeys.insert(key)

      let creatorName = currentUser?.name ?? "Minh"
      let allNames = [creatorName] + memberNames
      let shapes: [MemberShape] = [.circle, .diamond, .squircle, .leaf]
      let colors: [MemberColor] = [.mint, .sky, .coral, .lilac]

      let newGroupId =
        groupOrder.isEmpty ? TripScenario.groupId : ExpenseGroup.ID("group-\(UUID().uuidString)")
      var createdMembers: [Member] = []
      var shapeIndex = 0
      var colorIndex = 0
      for (idx, memberName) in allNames.enumerated() {
        let memberId: Member.ID
        if newGroupId == TripScenario.groupId && idx < TripScenario.members.count {
          memberId = TripScenario.members[idx].id
        } else {
          memberId = Member.ID("member-\(idx)-\(UUID().uuidString)")
        }
        let shape = shapes[shapeIndex]
        let color = colors[colorIndex]
        shapeIndex += 1
        if shapeIndex == shapes.count { shapeIndex = 0 }
        colorIndex += 1
        if colorIndex == colors.count { colorIndex = 0 }
        createdMembers.append(
          Member(
            id: memberId,
            name: memberName,
            active: true,
            defaultWeight: "1.00",
            position: idx,
            shape: shape,
            color: color,
            isMe: idx == 0,
            claimed: idx == 0
          )
        )
      }

      let preview = Array(createdMembers.prefix(4)).map {
        ExpenseGroup.PreviewMember(id: $0.id, name: $0.name, shape: $0.shape, color: $0.color)
      }
      let myMemberId = createdMembers.first?.id
      let group = ExpenseGroup(
        id: newGroupId,
        name: name,
        currency: "VND",
        memberCount: createdMembers.count,
        previewMembers: preview,
        myBalance: .zero,
        minimizeDebts: true,
        defaultRole: .editor,
        role: .owner,
        myMemberId: myMemberId
      )

      groupsById[newGroupId] = group
      groupOrder.insert(newGroupId, at: 0)
      membersByGroup[newGroupId] = createdMembers
      usersByGroup[newGroupId] = [
        GroupUser(
          userId: currentUser?.id ?? TripScenario.userId,
          name: creatorName,
          role: .owner,
          memberId: myMemberId,
          isMe: true
        )
      ]
      invitesByGroup[newGroupId] = TripScenario.invite
      transactionsByGroup[newGroupId] = []
      balancesByGroup[newGroupId] = GroupBalances(
        currency: "VND",
        minimized: true,
        balances: createdMembers.map { Balance(memberId: $0.id, balance: .zero) },
        transfers: []
      )
      activityByGroup[newGroupId] = [
        ActivityItem(
          id: ActivityItem.ID("act-\(UUID().uuidString)"),
          actor: TripScenario.activityActorMinh,
          action: "create",
          entityType: .group,
          entityId: newGroupId.rawValue,
          summary: name,
          after: ActivityItem.SnapshotValues(memberCount: createdMembers.count),
          createdAt: "2026-11-16T14:23:26.244Z",
          canRestore: false
        )
      ]
      return group
    }

    public func updateGroup(
      id: ExpenseGroup.ID,
      input: UpdateGroupInput
    ) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      guard var group = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let name = input.name {
        group.name = name
      }
      if let minimizeDebts = input.minimizeDebts {
        group.minimizeDebts = minimizeDebts
        if var bal = balancesByGroup[id] {
          bal = GroupBalances(
            currency: bal.currency,
            minimized: minimizeDebts,
            balances: bal.balances,
            transfers: bal.transfers
          )
          balancesByGroup[id] = bal
        }
      }
      if let defaultRole = input.defaultRole {
        group.defaultRole = defaultRole
      }
      groupsById[id] = group
      return group
    }

    public func deleteGroup(id: ExpenseGroup.ID, confirmName: String) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.name == confirmName else {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      groupsById.removeValue(forKey: id)
      groupOrder.removeAll { $0 == id }
      membersByGroup.removeValue(forKey: id)
      usersByGroup.removeValue(forKey: id)
      invitesByGroup.removeValue(forKey: id)
      transactionsByGroup.removeValue(forKey: id)
      balancesByGroup.removeValue(forKey: id)
      activityByGroup.removeValue(forKey: id)
    }

    // MARK: - Members

    public func lastKnownMembers(groupId: ExpenseGroup.ID) -> [Member]? {
      guard behavior.hasSnapshot else { return nil }
      return membersByGroup[groupId]
    }

    public func fetchMembers(groupId: ExpenseGroup.ID) async throws(AppError) -> [Member] {
      try await simulateNetwork()
      guard let members = membersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return members
    }

    public func lastKnownGroupUsers(groupId: ExpenseGroup.ID) -> [GroupUser]? {
      guard behavior.hasSnapshot else { return nil }
      return usersByGroup[groupId]
    }

    public func fetchGroupUsers(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupUser] {
      try await simulateNetwork()
      guard let users = usersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return users
    }

    public func createMember(
      groupId: ExpenseGroup.ID,
      name: String,
      key: IdempotencyKey
    ) async throws(AppError) -> Member {
      try await simulateNetwork()
      guard var members = membersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if seenIdempotencyKeys.contains(key), let last = members.last {
        return last
      }
      seenIdempotencyKeys.insert(key)

      let shapes: [MemberShape] = [.circle, .diamond, .squircle, .leaf]
      let colors: [MemberColor] = [.mint, .sky, .coral, .lilac]
      let pos = members.count
      var shapeIndex = 0
      var colorIndex = 0
      for _ in 0..<pos {
        shapeIndex += 1
        if shapeIndex == shapes.count { shapeIndex = 0 }
        colorIndex += 1
        if colorIndex == colors.count { colorIndex = 0 }
      }
      let member = Member(
        id: Member.ID("member-\(pos)-\(UUID().uuidString)"),
        name: name,
        active: true,
        defaultWeight: "1.00",
        position: pos,
        shape: shapes[shapeIndex],
        color: colors[colorIndex],
        isMe: false,
        claimed: false
      )
      members.append(member)
      membersByGroup[groupId] = members
      syncGroupSummary(groupId: groupId)
      if var bal = balancesByGroup[groupId] {
        var list = bal.balances
        list.append(Balance(memberId: member.id, balance: .zero))
        bal = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: list,
          transfers: bal.transfers
        )
        balancesByGroup[groupId] = bal
      }
      return member
    }

    public func updateMember(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID,
      input: UpdateMemberInput
    ) async throws(AppError) -> Member {
      try await simulateNetwork()
      guard var members = membersByGroup[groupId],
        let idx = members.firstIndex(where: { $0.id == memberId })
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let name = input.name {
        members[idx].name = name
      }
      if let weight = input.defaultWeight {
        members[idx].defaultWeight = weight
      }
      if let active = input.active {
        members[idx].active = active
      }
      membersByGroup[groupId] = members
      syncGroupSummary(groupId: groupId)
      return members[idx]
    }

    public func deleteMember(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError) {
      try await simulateNetwork()
      guard var members = membersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let txs = transactionsByGroup[groupId] ?? []
      let hasTx = txs.contains { tx in
        tx.payers.contains(where: { $0.memberId == memberId })
          || tx.shares.contains(where: { $0.memberId == memberId })
      }
      if hasTx {
        throw .api(code: "MEMBER_HAS_TRANSACTIONS", status: 409)
      }
      members.removeAll { $0.id == memberId }
      membersByGroup[groupId] = members
      syncGroupSummary(groupId: groupId)
    }

    public func chooseMyMember(
      groupId: ExpenseGroup.ID,
      memberId: Member.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard var members = membersByGroup[groupId],
        var group = groupsById[groupId]
      else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      for idx in members.indices {
        if members[idx].id == memberId {
          members[idx].isMe = true
          members[idx].claimed = true
        } else if members[idx].isMe {
          members[idx].isMe = false
          members[idx].claimed = false
        }
      }
      group.myMemberId = memberId
      membersByGroup[groupId] = members
      groupsById[groupId] = group
    }

    public func updateUserRole(
      groupId: ExpenseGroup.ID,
      userId: User.ID,
      role: Role
    ) async throws(AppError) {
      try await simulateNetwork()
      guard var users = usersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let idx = users.firstIndex(where: { $0.userId == userId }) {
        users[idx].role = role
      }
      usersByGroup[groupId] = users
    }

    public func removeUser(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError) {
      try await simulateNetwork()
      guard var users = usersByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      users.removeAll { $0.userId == userId }
      usersByGroup[groupId] = users
    }

    public func transferOwnership(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError)
    {
      try await simulateNetwork()
      guard var users = usersByGroup[groupId], var group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      for idx in users.indices {
        if users[idx].userId == userId {
          users[idx].role = .owner
        } else if users[idx].isMe {
          users[idx].role = .editor
        }
      }
      group.role = .editor
      behavior.role = .editor
      usersByGroup[groupId] = users
      groupsById[groupId] = group
    }

    public func leaveGroup(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await simulateNetwork()
      groupsById.removeValue(forKey: groupId)
      groupOrder.removeAll { $0 == groupId }
    }

    internal func syncGroupSummary(groupId: ExpenseGroup.ID) {
      guard var group = groupsById[groupId], let members = membersByGroup[groupId] else { return }
      let activeMembers = members.filter(\.active)
      group.memberCount = activeMembers.count
      group.previewMembers = Array(activeMembers.prefix(4)).map {
        ExpenseGroup.PreviewMember(id: $0.id, name: $0.name, shape: $0.shape, color: $0.color)
      }
      if let myMemberId = group.myMemberId,
        let bal = balancesByGroup[groupId]?.balances.first(where: { $0.memberId == myMemberId })
      {
        group.myBalance = bal.balance
      }
      groupsById[groupId] = group
    }

    // MARK: - Invites

    public func lastKnownInvite(groupId: ExpenseGroup.ID) -> Invite? {
      guard behavior.hasSnapshot else { return nil }
      return invitesByGroup[groupId]
    }

    public func fetchInvite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
      try await simulateNetwork()
      guard let invite = invitesByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return invite
    }

    public func setInviteActive(
      groupId: ExpenseGroup.ID,
      active: Bool
    ) async throws(AppError) -> Invite {
      try await simulateNetwork()
      guard var invite = invitesByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      invite.active = active
      invitesByGroup[groupId] = invite
      return invite
    }

    public func rotateInvite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
      try await simulateNetwork()
      guard var invite = invitesByGroup[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let newToken = "rot-\(UUID().uuidString.prefix(12))"
      invite.token = newToken
      invite.active = true
      invite.url = "http://localhost:3000/join/\(newToken)"
      invitesByGroup[groupId] = invite
      return invite
    }

    public func previewInvite(token: String) async throws(AppError) -> InvitePreview {
      try await simulateNetwork()
      let currentInvite = invitesByGroup[TripScenario.groupId] ?? TripScenario.invite
      guard token == TripScenario.invite.token || token == currentInvite.token,
        currentInvite.active
      else {
        throw .api(code: "INVITE_INVALID", status: 404)
      }
      return TripScenario.invitePreview
    }

    public func joinInvite(
      token: String,
      choice: JoinChoice,
      key: IdempotencyKey
    ) async throws(AppError) -> ExpenseGroup.ID {
      try await simulateNetwork()
      let currentInvite = invitesByGroup[TripScenario.groupId] ?? TripScenario.invite
      guard token == TripScenario.invite.token || token == currentInvite.token,
        currentInvite.active
      else {
        throw .api(code: "INVITE_INVALID", status: 404)
      }
      seenIdempotencyKeys.insert(key)
      let groupId = TripScenario.groupId
      if groupsById[groupId] == nil {
        let group = TripScenario.group(forStep: 4, role: behavior.role)
        groupsById[groupId] = group
        groupOrder.insert(groupId, at: 0)
        membersByGroup[groupId] = TripScenario.members
        usersByGroup[groupId] = TripScenario.groupUsers
        invitesByGroup[groupId] = currentInvite
        transactionsByGroup[groupId] = TripScenario.transactions(forStep: 4)
        balancesByGroup[groupId] = TripScenario.balances(forStep: 4)
        activityByGroup[groupId] = TripScenario.activityItems
      }
      if case .newMember(let name) = choice {
        _ = try await createMember(groupId: groupId, name: name, key: IdempotencyKey())
      }
      return groupId
    }
  }
#endif
