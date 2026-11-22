public import Domain
import Foundation
public import Observation

@Observable
public final class GroupSettingsModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var invite: Invite
    public var users: [GroupUser]
    public var categories: [GroupCategory]
    public var budget: GroupBudget?
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var actionError: AppError?
  public private(set) var budgetError: AppError?
  public private(set) var isPerformingAction = false
  public private(set) var isSavingBudget = false
  public var nameDraft = ""

  private let groupsRepository: any GroupsRepository
  private let invitesRepository: any InvitesRepository
  private let membersRepository: any MembersRepository
  public let categoriesRepository: any CategoriesRepository
  private let budgetRepository: any BudgetRepository

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    invitesRepository: any InvitesRepository,
    membersRepository: any MembersRepository,
    categoriesRepository: any CategoriesRepository,
    budgetRepository: any BudgetRepository
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.invitesRepository = invitesRepository
    self.membersRepository = membersRepository
    self.categoriesRepository = categoriesRepository
    self.budgetRepository = budgetRepository
  }

  public func load() async {
    async let cachedGroup = groupsRepository.lastKnownGroup(id: groupId)
    async let cachedInvite = invitesRepository.lastKnownInvite(groupId: groupId)
    async let cachedUsers = membersRepository.lastKnownGroupUsers(groupId: groupId)
    async let cachedCategories = categoriesRepository.lastKnownCategories(groupId: groupId)
    async let cachedBudget = budgetRepository.lastKnownBudget(groupId: groupId)

    if let g = await cachedGroup, let inv = await cachedInvite, let u = await cachedUsers {
      let c = await cachedCategories ?? []
      let b = await cachedBudget
      if nameDraft.isEmpty { nameDraft = g.name }
      state = .loaded(ScreenData(group: g, invite: inv, users: u, categories: c, budget: b))
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedInvite = invitesRepository.invite(groupId: groupId)
      async let fetchedUsers = membersRepository.groupUsers(groupId: groupId)
      async let fetchedCategories = categoriesRepository.list(groupId: groupId)
      async let fetchedBudget = budgetRepository.budget(groupId: groupId)

      let g = try await fetchedGroup
      let inv = try await fetchedInvite
      let u = try await fetchedUsers
      let c = try await fetchedCategories
      let b = try await fetchedBudget
      nameDraft = g.name
      state = .loaded(ScreenData(group: g, invite: inv, users: u, categories: c, budget: b))
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

  public func saveName() async {
    let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await groupsRepository.update(
        id: groupId,
        input: UpdateGroupInput(name: trimmed)
      )
      await load()
    } catch {
      actionError = error
    }
  }

  public func setMinimizeDebts(_ minimize: Bool) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await groupsRepository.update(
        id: groupId,
        input: UpdateGroupInput(minimizeDebts: minimize)
      )
      await load()
    } catch {
      actionError = error
    }
  }

  public func setDefaultRole(_ role: Role) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await groupsRepository.update(
        id: groupId,
        input: UpdateGroupInput(defaultRole: role)
      )
      await load()
    } catch {
      actionError = error
    }
  }

  public func setInviteActive(_ active: Bool) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await invitesRepository.setActive(groupId: groupId, active: active)
      await load()
    } catch {
      actionError = error
    }
  }

  public func rotateInvite() async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await invitesRepository.rotate(groupId: groupId)
      await load()
    } catch {
      actionError = error
    }
  }

  public func transferOwnership(to userId: User.ID, onTransferred: () -> Void) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await membersRepository.transferOwnership(groupId: groupId, userId: userId)
      onTransferred()
    } catch {
      actionError = error
    }
  }

  public func deleteGroup(confirmName: String, onDeleted: () -> Void) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await groupsRepository.delete(id: groupId, confirmName: confirmName)
      onDeleted()
    } catch {
      actionError = error
    }
  }

  public func updateCategories(_ next: [GroupCategory]) {
    if case .loaded(var current) = state {
      current.categories = next
      state = .loaded(current)
    }
  }

  public func saveBudget(period: BudgetPeriod, amount: Money) async {
    guard !isSavingBudget else { return }
    isSavingBudget = true
    budgetError = nil
    defer { isSavingBudget = false }
    do throws(AppError) {
      let saved = try await budgetRepository.setBudget(
        groupId: groupId,
        period: period,
        amount: amount
      )
      if case .loaded(var current) = state {
        current.budget = saved
        state = .loaded(current)
      }
    } catch {
      budgetError = error
    }
  }

  public func removeBudget() async {
    guard !isSavingBudget else { return }
    isSavingBudget = true
    budgetError = nil
    defer { isSavingBudget = false }
    do throws(AppError) {
      try await budgetRepository.deleteBudget(groupId: groupId)
      if case .loaded(var current) = state {
        current.budget = nil
        state = .loaded(current)
      }
    } catch {
      budgetError = error
    }
  }
}
