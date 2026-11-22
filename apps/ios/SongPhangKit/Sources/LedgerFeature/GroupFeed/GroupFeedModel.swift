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
  private let transactionsRepository: any TransactionsRepository
  private let eventsRepository: any GroupEventsRepository
  private var searchTask: Task<Void, Never>?

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    categoriesRepository: any CategoriesRepository,
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
    async let cachedPage = transactionsRepository.lastKnownFirstPage(groupId: groupId)

    if filter.isEmpty,
      let g = await cachedGroup,
      let m = await cachedMembers,
      let b = await cachedBalances,
      let p = await cachedPage
    {
      let c = await cachedCategories ?? []
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
          categories: c,
          transactions: p.items,
          nextCursor: p.nextCursor
        )
      )
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)
      async let fetchedCategories = categoriesRepository.list(groupId: groupId)
      async let fetchedPage = transactionsRepository.page(
        groupId: groupId,
        filter: filter,
        cursor: nil
      )

      let g = try await fetchedGroup
      let m = try await fetchedMembers
      let b = try await fetchedBalances
      let c = try await fetchedCategories
      let p = try await fetchedPage
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
          categories: c,
          transactions: p.items,
          nextCursor: p.nextCursor
        )
      )
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
      await reloadTransactionsOnly()
    }
  }

  public func applyFilter(_ next: TransactionFilter) async {
    searchTask?.cancel()
    filter = next
    searchText = next.query ?? ""
    await reloadTransactionsOnly()
  }

  public func clearFilter() async {
    await applyFilter(TransactionFilter())
  }

  private func reloadTransactionsOnly() async {
    guard case .loaded(var current) = state else {
      await load()
      return
    }
    isFiltering = true
    defer { isFiltering = false }
    do throws(AppError) {
      let page = try await transactionsRepository.page(
        groupId: groupId,
        filter: filter,
        cursor: nil
      )
      current.transactions = page.items
      current.nextCursor = page.nextCursor
      state = .loaded(current)
      refreshError = nil
    } catch {
      refreshError = error
    }
  }

  public func loadNextPageIfNeeded() async {
    guard case .loaded(var current) = state,
      let cursor = current.nextCursor,
      !isLoadingMore
    else { return }
    isLoadingMore = true
    loadMoreError = nil
    defer { isLoadingMore = false }
    do throws(AppError) {
      let nextPage = try await transactionsRepository.page(
        groupId: groupId,
        filter: filter,
        cursor: cursor
      )
      current.transactions.append(contentsOf: nextPage.items)
      current.nextCursor = nextPage.nextCursor
      state = .loaded(current)
    } catch {
      loadMoreError = error
    }
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
    guard case .loaded(var current) = state else { return }
    let previousNewestId = current.transactions.first?.id

    do throws(AppError) {
      if resources.contains("group") {
        current.group = try await groupsRepository.group(id: groupId)
      }
      if resources.contains("members") {
        current.members = try await membersRepository.members(groupId: groupId)
      }
      if resources.contains("balances") {
        current.balances = try await balancesRepository.balances(groupId: groupId)
      }
      if resources.contains("categories") {
        current.categories = try await categoriesRepository.list(groupId: groupId)
      }
      if resources.contains("transactions") {
        let page = try await transactionsRepository.page(
          groupId: groupId,
          filter: filter,
          cursor: nil
        )
        current.transactions = page.items
        current.nextCursor = page.nextCursor
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
      refreshError = error
    }
  }
}
