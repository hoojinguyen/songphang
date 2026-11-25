public import Domain
public import Observation

@Observable
public final class PersonalLedgerModel {
  public private(set) var items: [PersonalTransaction] = []
  public private(set) var availableGroups: [(id: ExpenseGroup.ID, name: String)] = []
  public private(set) var nextCursor: String?
  public private(set) var isLoading = false
  public private(set) var isLoadingMore = false
  public private(set) var error: AppError?

  public var query: String = ""
  public var selectedGroupId: ExpenseGroup.ID?
  public var selectedType: TransactionType?

  private let repository: any OverviewRepository
  private let groupsRepository: (any GroupsRepository)?
  private var generation: UInt64 = 0
  private var hasLoadedGroups = false

  public init(
    repository: any OverviewRepository,
    groupsRepository: (any GroupsRepository)? = nil
  ) {
    self.repository = repository
    self.groupsRepository = groupsRepository
  }

  public var hasMore: Bool {
    nextCursor != nil
  }

  private func loadAvailableGroups() async -> (
    groups: [(id: ExpenseGroup.ID, name: String)], authoritative: Bool
  ) {
    if let groupsRepository {
      do {
        let fetchedGroups = try await groupsRepository.list(status: nil)
        return (fetchedGroups.map { ($0.id, $0.name) }, true)
      } catch {
        if let cachedGroups = await groupsRepository.lastKnownGroups(),
          !cachedGroups.isEmpty
        {
          return (cachedGroups.map { ($0.id, $0.name) }, false)
        }
      }
    }
    if let cached = await repository.lastKnownOverview() {
      return (cached.groupBalances.map { ($0.groupId, $0.groupName) }, false)
    }
    return ([], false)
  }

  private func fetchInitialPage(
    type: TransactionType?,
    groupId: ExpenseGroup.ID?,
    query: String?
  ) async -> Result<PersonalTransactionsPage, AppError> {
    do throws(AppError) {
      let page = try await repository.transactions(
        cursor: nil,
        limit: 20,
        type: type,
        groupId: groupId,
        query: query
      )
      return .success(page)
    } catch {
      return .failure(error)
    }
  }

  public func loadInitial(refreshGroups: Bool = false) async {
    generation &+= 1
    let currentGen = generation
    let targetGroupId = selectedGroupId
    let targetType = selectedType
    let targetQuery = query.isEmpty ? nil : query
    isLoading = true
    isLoadingMore = false
    error = nil
    nextCursor = nil
    defer {
      if currentGen == generation {
        isLoading = false
      }
    }
    let shouldFetchGroups = refreshGroups || (!hasLoadedGroups && availableGroups.isEmpty)
    async let fetchedPageResult = fetchInitialPage(
      type: targetType,
      groupId: targetGroupId,
      query: targetQuery
    )
    async let fetchedGroupsOutcome = shouldFetchGroups ? loadAvailableGroups() : nil

    let groupsOutcome = await fetchedGroupsOutcome
    if let groupsOutcome, currentGen == generation {
      if groupsOutcome.authoritative || availableGroups.isEmpty {
        availableGroups = groupsOutcome.groups
      }
      if groupsOutcome.authoritative {
        hasLoadedGroups = true
      }
    }

    switch await fetchedPageResult {
    case .success(let page):
      guard currentGen == generation,
        selectedGroupId == targetGroupId,
        selectedType == targetType,
        (query.isEmpty ? nil : query) == targetQuery
      else { return }
      items = page.items
      nextCursor = page.nextCursor
    case .failure(let error):
      guard currentGen == generation else { return }
      self.error = error
    }
  }

  public func loadMore() async {
    guard !isLoading, !isLoadingMore, let cursor = nextCursor else { return }
    let currentGen = generation
    let targetGroupId = selectedGroupId
    let targetType = selectedType
    let targetQuery = query.isEmpty ? nil : query
    isLoadingMore = true
    defer {
      if currentGen == generation {
        isLoadingMore = false
      }
    }
    do throws(AppError) {
      let page = try await repository.transactions(
        cursor: cursor,
        limit: 20,
        type: targetType,
        groupId: targetGroupId,
        query: targetQuery
      )
      guard currentGen == generation,
        selectedGroupId == targetGroupId,
        selectedType == targetType,
        (query.isEmpty ? nil : query) == targetQuery
      else { return }
      items.append(contentsOf: page.items)
      nextCursor = page.nextCursor
    } catch {
      guard currentGen == generation else { return }
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
