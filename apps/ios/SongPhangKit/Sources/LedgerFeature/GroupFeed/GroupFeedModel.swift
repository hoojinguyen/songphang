public import Domain
import Foundation
public import Observation

@Observable
public final class GroupFeedModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var balances: GroupBalances
    public var categories: [GroupCategory]
    public var budget: GroupBudget?
    public var transactions: [LedgerTransaction]
    public var nextCursor: String?
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isLoadingMore = false
  public private(set) var loadMoreError: AppError?
  public private(set) var isFiltering = false
  public private(set) var filter: TransactionFilter
  public var searchText: String
  public var hasNewItemsPill = false
  public var isScrolledAwayFromBottom = false
  public var lastDeletedTransactionId: LedgerTransaction.ID?
  public var toastMessage: String?

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let categoriesRepository: any CategoriesRepository
  private let budgetRepository: any BudgetRepository
  private let transactionsRepository: any TransactionsRepository
  private let eventsRepository: any GroupEventsRepository
  private var searchTask: Task<Void, Never>?
  private var loadMoreTask: Task<Void, Never>?
  private var listGeneration: UInt64 = 0

  @discardableResult
  private func invalidatePagination() -> UInt64 {
    listGeneration &+= 1
    loadMoreTask?.cancel()
    loadMoreTask = nil
    isLoadingMore = false
    loadMoreError = nil
    isFiltering = false
    return listGeneration
  }

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    categoriesRepository: any CategoriesRepository,
    budgetRepository: any BudgetRepository,
    transactionsRepository: any TransactionsRepository,
    eventsRepository: any GroupEventsRepository,
    initialFilter: TransactionFilter? = nil,
    initialHasNewItemsPill: Bool = false,
    initialDeletedTransactionId: LedgerTransaction.ID? = nil
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.categoriesRepository = categoriesRepository
    self.budgetRepository = budgetRepository
    self.transactionsRepository = transactionsRepository
    self.eventsRepository = eventsRepository
    let resolvedFilter = initialFilter ?? TransactionFilter()
    self.filter = resolvedFilter
    self.searchText = resolvedFilter.query ?? ""
    self.hasNewItemsPill = initialHasNewItemsPill
    self.lastDeletedTransactionId = initialDeletedTransactionId
  }

  public func undoDelete(restoredMessage: String, errorMessage: String) async {
    guard let id = lastDeletedTransactionId else { return }
    lastDeletedTransactionId = nil
    do throws(AppError) {
      _ = try await transactionsRepository.restore(groupId: groupId, id: id)
      toastMessage = restoredMessage
      await load()
    } catch {
      toastMessage = errorMessage
    }
  }

  public var isOffline: Bool {
    if refreshError == .offline { return true }
    if case .failed(.offline) = state { return true }
    return false
  }

  public func load() async {
    async let cachedGroup = groupsRepository.lastKnownGroup(id: groupId)
    async let cachedMembers = membersRepository.lastKnownMembers(groupId: groupId)
    async let cachedBalances = balancesRepository.lastKnownBalances(groupId: groupId)
    async let cachedCategories = categoriesRepository.lastKnownCategories(groupId: groupId)
    async let cachedBudget = budgetRepository.lastKnownBudget(groupId: groupId)
    async let cachedPage = transactionsRepository.lastKnownFirstPage(groupId: groupId)

    if filter.isEmpty,
      let g = await cachedGroup,
      let m = await cachedMembers,
      let b = await cachedBalances,
      let p = await cachedPage
    {
      let c = await cachedCategories ?? []
      let bud = await cachedBudget
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
          categories: c,
          budget: bud,
          transactions: p.items,
          nextCursor: p.nextCursor
        )
      )
    } else if case .failed = state {
      state = .loading
    }

    let generation = invalidatePagination()
    let requestedFilter = filter

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)
      async let fetchedCategories = categoriesRepository.list(groupId: groupId)
      async let fetchedBudget = budgetRepository.budget(groupId: groupId)
      async let fetchedPage = transactionsRepository.page(
        groupId: groupId,
        filter: requestedFilter,
        cursor: nil
      )

      let g = try await fetchedGroup
      let m = try await fetchedMembers
      let b = try await fetchedBalances
      let c = try await fetchedCategories
      let bud = try await fetchedBudget
      let p = try await fetchedPage
      guard listGeneration == generation, filter == requestedFilter else {
        return
      }
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
          categories: c,
          budget: bud,
          transactions: p.items,
          nextCursor: p.nextCursor
        )
      )
      refreshError = nil
    } catch let error as AppError {
      guard listGeneration == generation else { return }
      if case .loaded = state {
        refreshError = error
      } else {
        state = .failed(error)
      }
    } catch {
      guard listGeneration == generation else { return }
      if case .loaded = state {
        refreshError = .unexpected
      } else {
        state = .failed(.unexpected)
      }
    }
  }

  public func updateSearchText(_ next: String) {
    let clamped = String(next.prefix(100))
    if searchText != clamped {
      searchText = clamped
    }
    let trimmed = clamped.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalized: String? = trimmed.isEmpty ? nil : trimmed
    searchTask?.cancel()
    if normalized == filter.query { return }
    searchTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      filter.query = normalized
      invalidatePagination()
      await reloadTransactionsOnly()
    }
  }

  public func applyFilter(_ next: TransactionFilter) async {
    searchTask?.cancel()
    filter = next
    searchText = next.query ?? ""
    invalidatePagination()
    await reloadTransactionsOnly()
  }

  public func clearFilter() async {
    await applyFilter(TransactionFilter())
  }

  private func reloadTransactionsOnly() async {
    guard case .loaded = state else {
      await load()
      return
    }
    let generation = invalidatePagination()
    let requestedFilter = filter
    isFiltering = true
    defer {
      if listGeneration == generation {
        isFiltering = false
      }
    }
    do throws(AppError) {
      let page = try await transactionsRepository.page(
        groupId: groupId,
        filter: requestedFilter,
        cursor: nil
      )
      guard listGeneration == generation,
        filter == requestedFilter,
        case .loaded(var latest) = state
      else { return }
      latest.transactions = page.items
      latest.nextCursor = page.nextCursor
      state = .loaded(latest)
      refreshError = nil
    } catch {
      if listGeneration == generation {
        refreshError = error
      }
    }
  }

  public func loadNextPageIfNeeded() async {
    guard case .loaded(let current) = state,
      let cursor = current.nextCursor,
      !isLoadingMore,
      !isFiltering
    else { return }
    let generation = listGeneration
    let requestedFilter = filter
    isLoadingMore = true
    loadMoreError = nil

    let task = Task {
      defer {
        if listGeneration == generation {
          loadMoreTask = nil
          isLoadingMore = false
        }
      }
      do throws(AppError) {
        let nextPage = try await transactionsRepository.page(
          groupId: groupId,
          filter: requestedFilter,
          cursor: cursor
        )
        guard !Task.isCancelled,
          listGeneration == generation,
          filter == requestedFilter,
          case .loaded(var latest) = state,
          latest.nextCursor == cursor
        else { return }
        latest.transactions.append(contentsOf: nextPage.items)
        latest.nextCursor = nextPage.nextCursor
        state = .loaded(latest)
      } catch {
        guard !Task.isCancelled, listGeneration == generation else { return }
        loadMoreError = error
      }
    }
    loadMoreTask = task
    await task.value
  }

  public func listenForEvents(onRemoved: @escaping () -> Void) async {
    let stream = eventsRepository.events(groupId: groupId)
    for await event in stream {
      switch event {
      case .removed:
        onRemoved()
        return
      case .reconnected:
        await load()
      case .changed(let resources):
        await refetch(resources: resources)
      }
    }
  }

  private func refetch(resources: [String]) async {
    guard case .loaded(let initial) = state else { return }
    let previousNewestId = initial.transactions.first?.id
    let refetchGeneration = listGeneration
    let refetchFilter = filter
    var pageGeneration: UInt64?
    var pageFilter: TransactionFilter?

    do throws(AppError) {
      let fetchedGroup =
        resources.contains("group") ? try await groupsRepository.group(id: groupId) : nil
      let fetchedMembers =
        resources.contains("members") ? try await membersRepository.members(groupId: groupId) : nil
      let fetchedBalances =
        resources.contains("balances")
        ? try await balancesRepository.balances(groupId: groupId) : nil
      let fetchedCategories =
        resources.contains("categories")
        ? try await categoriesRepository.list(groupId: groupId) : nil
      let fetchedBudget =
        (resources.contains("budget") || resources.contains("transactions"))
        ? try await budgetRepository.budget(groupId: groupId) : nil

      var fetchedPage: Page<LedgerTransaction>?
      if resources.contains("transactions") {
        let gen = invalidatePagination()
        let reqFilter = filter
        pageGeneration = gen
        pageFilter = reqFilter
        fetchedPage = try await transactionsRepository.page(
          groupId: groupId,
          filter: reqFilter,
          cursor: nil
        )
      }

      let expectedGeneration = pageGeneration ?? refetchGeneration
      let expectedFilter = pageFilter ?? refetchFilter
      guard listGeneration == expectedGeneration,
        filter == expectedFilter,
        case .loaded(var current) = state
      else { return }

      if let fetchedGroup { current.group = fetchedGroup }
      if let fetchedMembers { current.members = fetchedMembers }
      if let fetchedBalances { current.balances = fetchedBalances }
      if let fetchedCategories { current.categories = fetchedCategories }
      if let fetchedBudget { current.budget = fetchedBudget }
      if let fetchedPage {
        current.transactions = fetchedPage.items
        current.nextCursor = fetchedPage.nextCursor
      }
      state = .loaded(current)
      refreshError = nil
      if let newNewestId = current.transactions.first?.id,
        newNewestId != previousNewestId,
        isScrolledAwayFromBottom
      {
        hasNewItemsPill = true
      }
    } catch {
      let expectedGeneration = pageGeneration ?? refetchGeneration
      guard listGeneration == expectedGeneration else { return }
      refreshError = error
    }
  }
}
