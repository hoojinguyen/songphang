public import Domain
public import Observation

@Observable
public final class GroupListModel {
  public private(set) var groups: Loadable<[ExpenseGroup]> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isRefreshing = false

  private let repository: any GroupsRepository

  public init(repository: any GroupsRepository) {
    self.repository = repository
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
    } catch {
      if case .loaded = groups {
        refreshError = error
      } else {
        groups = .failed(error)
      }
    }
  }
}
