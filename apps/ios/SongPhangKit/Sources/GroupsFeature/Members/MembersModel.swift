public import Domain
import Foundation
public import Observation

@Observable
public final class MembersModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var users: [GroupUser]
    public var balances: GroupBalances
    public var invite: Invite?
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var actionError: AppError?
  public private(set) var isPerformingAction = false
  public var expandedMemberId: Member.ID?
  public var isAddMemberOpen = false

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let invitesRepository: any InvitesRepository

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    invitesRepository: any InvitesRepository
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.invitesRepository = invitesRepository
  }

  public func load() async {
    async let cachedGroup = groupsRepository.lastKnownGroup(id: groupId)
    async let cachedMembers = membersRepository.lastKnownMembers(groupId: groupId)
    async let cachedUsers = membersRepository.lastKnownGroupUsers(groupId: groupId)
    async let cachedBalances = balancesRepository.lastKnownBalances(groupId: groupId)
    async let cachedInvite = invitesRepository.lastKnownInvite(groupId: groupId)

    if let g = await cachedGroup,
      let m = await cachedMembers,
      let u = await cachedUsers,
      let b = await cachedBalances
    {
      state = .loaded(
        ScreenData(group: g, members: m, users: u, balances: b, invite: await cachedInvite)
      )
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedUsers = membersRepository.groupUsers(groupId: groupId)
      async let fetchedBalances: Result<GroupBalances, AppError> = {
        do throws(AppError) {
          return .success(try await balancesRepository.balances(groupId: groupId))
        } catch {
          return .failure(error)
        }
      }()
      async let fetchedInvite = invitesRepository.invite(groupId: groupId)

      let g = try await fetchedGroup
      let m = try await fetchedMembers
      let u = try await fetchedUsers
      let b: GroupBalances
      switch await fetchedBalances {
      case .success(let fetched):
        b = fetched
      case .failure(let error):
        if case .api("STAGE_5B4_PENDING", 501) = error {
          b = GroupBalances(balances: [], transfers: [])
        } else {
          throw error
        }
      }
      let inv = try? await fetchedInvite
      state = .loaded(ScreenData(group: g, members: m, users: u, balances: b, invite: inv))
      refreshError = nil
    } catch let error as AppError {
      if case .loaded = state {
        refreshError = error
      } else {
        state = .failed(error)
      }
    } catch {
      if case .loaded = state {
        refreshError = .unexpected
      } else {
        state = .failed(.unexpected)
      }
    }
  }

  public func addMember(name: String) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await membersRepository.create(
        groupId: groupId,
        name: name,
        key: IdempotencyKey()
      )
      isAddMemberOpen = false
      await load()
    } catch {
      actionError = error
    }
  }

  public func renameMember(memberId: Member.ID, newName: String) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await membersRepository.update(
        groupId: groupId,
        memberId: memberId,
        input: UpdateMemberInput(name: newName)
      )
      await load()
    } catch {
      actionError = error
    }
  }

  public func setMemberActive(memberId: Member.ID, active: Bool) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await membersRepository.update(
        groupId: groupId,
        memberId: memberId,
        input: UpdateMemberInput(active: active)
      )
      await load()
    } catch {
      actionError = error
    }
  }

  public func deleteMember(memberId: Member.ID) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.delete(groupId: groupId, memberId: memberId)
      if expandedMemberId == memberId {
        expandedMemberId = nil
      }
      await load()
    } catch {
      actionError = error
    }
  }

  public func chooseMyMember(memberId: Member.ID) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.chooseMyMember(groupId: groupId, memberId: memberId)
      await load()
    } catch {
      actionError = error
    }
  }

  public func updateUserRole(userId: User.ID, role: Role) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.updateUserRole(groupId: groupId, userId: userId, role: role)
      await load()
    } catch {
      actionError = error
    }
  }

  public func removeUser(userId: User.ID) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.removeUser(groupId: groupId, userId: userId)
      await load()
    } catch {
      actionError = error
    }
  }

  public func leaveGroup(onLeft: () -> Void) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.leaveGroup(groupId: groupId)
      onLeft()
    } catch {
      actionError = error
    }
  }
}
