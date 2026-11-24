public import Domain
public import Observation

@Observable
public final class PersonalLedgerModel {
  public private(set) var items: [PersonalTransaction] = []
  public private(set) var nextCursor: String?
  public private(set) var isLoading = false
  public private(set) var isLoadingMore = false
  public private(set) var error: AppError?

  public var query: String = ""
  public var selectedGroupId: ExpenseGroup.ID?
  public var selectedType: TransactionType?

  private let repository: any OverviewRepository

  public init(repository: any OverviewRepository) {
    self.repository = repository
  }

  public var hasMore: Bool {
    nextCursor != nil
  }

  public func loadInitial() async {
    isLoading = true
    error = nil
    defer { isLoading = false }
    do throws(AppError) {
      let page = try await repository.transactions(
        cursor: nil,
        limit: 20,
        type: selectedType,
        groupId: selectedGroupId,
        query: query.isEmpty ? nil : query
      )
      items = page.items
      nextCursor = page.nextCursor
    } catch {
      self.error = error
    }
  }

  public func loadMore() async {
    guard !isLoadingMore, let cursor = nextCursor else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do throws(AppError) {
      let page = try await repository.transactions(
        cursor: cursor,
        limit: 20,
        type: selectedType,
        groupId: selectedGroupId,
        query: query.isEmpty ? nil : query
      )
      items.append(contentsOf: page.items)
      nextCursor = page.nextCursor
    } catch {
      self.error = error
    }
  }

  public func updateFilters(
    query: String? = nil,
    groupId: ExpenseGroup.ID?? = nil,
    type: TransactionType?? = nil
  ) async {
    if let query {
      self.query = query
    }
    if let groupId {
      self.selectedGroupId = groupId
    }
    if let type {
      self.selectedType = type
    }
    await loadInitial()
  }
}
