public import Domain
public import Observation

@Observable
public final class GroupListModel {
  public enum Tab: String, CaseIterable, Sendable {
    case active
    case archived
  }

  public private(set) var groups: Loadable<[ExpenseGroup]> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var actionError: AppError?
  public private(set) var isRefreshing = false
  public private(set) var isPerformingAction = false
  public var selectedTab: Tab = .active

  public let repository: any GroupsRepository

  public init(repository: any GroupsRepository) {
    self.repository = repository
  }

  public var activeGroups: [ExpenseGroup] {
    groups.value?.filter { !$0.isArchived } ?? []
  }

  public var archivedGroups: [ExpenseGroup] {
    groups.value?.filter { $0.isArchived } ?? []
  }

  public var displayedGroups: [ExpenseGroup] {
    switch selectedTab {
    case .active: return activeGroups
    case .archived: return archivedGroups
    }
  }

  public func archive(groupId: ExpenseGroup.ID) async -> Bool {
    guard !isPerformingAction else { return false }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await repository.archive(groupId: groupId)
      await load()
      return true
    } catch {
      actionError = error
      return false
    }
  }

  public func unarchive(groupId: ExpenseGroup.ID) async -> Bool {
    guard !isPerformingAction else { return false }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await repository.unarchive(groupId: groupId)
      await load()
      return true
    } catch {
      actionError = error
      return false
    }
  }

  public func load() async {
    if let lastKnown = await repository.lastKnownGroups() {
      groups = .loaded(lastKnown)
    } else if case .failed = groups {
      groups = .loading
    }
    isRefreshing = true
    defer { isRefreshing = false }
    do throws(AppError) {
      let fetched = try await repository.groups()
      groups = .loaded(fetched)
      refreshError = nil
      if actionError == .offline {
        actionError = nil
      }
    } catch {
      if case .loaded = groups {
        refreshError = error
      } else {
        groups = .failed(error)
      }
    }
  }
}
