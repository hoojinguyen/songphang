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

  public func loadInitial() async {
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
    do throws(AppError) {
      if availableGroups.isEmpty {
        if let groupsRepository {
          if let fetchedGroups = try? await groupsRepository.list(status: nil),
            !fetchedGroups.isEmpty
          {
            availableGroups = fetchedGroups.map { ($0.id, $0.name) }
          } else if let cachedGroups = await groupsRepository.lastKnownGroups(),
            !cachedGroups.isEmpty
          {
            availableGroups = cachedGroups.map { ($0.id, $0.name) }
          }
        }
        if availableGroups.isEmpty, let cached = await repository.lastKnownOverview() {
          availableGroups = cached.groupBalances.map { ($0.groupId, $0.groupName) }
        }
      }
      let page = try await repository.transactions(
        cursor: nil,
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
      items = page.items
      nextCursor = page.nextCursor
    } catch {
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
