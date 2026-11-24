public import Domain
public import Observation

@Observable
public final class OverviewModel {
  public private(set) var overview: Loadable<OverviewSummary> = .loading
  public private(set) var recentTransactions: [PersonalTransaction] = []
  public private(set) var isRefreshing = false
  public private(set) var refreshError: AppError?

  private let repository: any OverviewRepository

  public init(repository: any OverviewRepository) {
    self.repository = repository
  }

  public func load() async {
    if let lastKnown = await repository.lastKnownOverview() {
      overview = .loaded(lastKnown)
    } else if case .failed = overview {
      overview = .loading
    }
    isRefreshing = true
    defer { isRefreshing = false }
    do {
      async let fetchedTask = repository.overview()
      async let txPageTask = repository.transactions(
        cursor: nil,
        limit: 5,
        type: nil,
        groupId: nil,
        query: nil
      )
      let fetched = try await fetchedTask
      let txPage = try await txPageTask
      overview = .loaded(fetched)
      refreshError = nil
      recentTransactions = txPage.items
    } catch let appError as AppError {
      if case .loaded = overview {
        refreshError = appError
      } else {
        overview = .failed(appError)
      }
    } catch {
      let appError = AppError.unexpected
      if case .loaded = overview {
        refreshError = appError
      } else {
        overview = .failed(appError)
      }
    }
  }
}
