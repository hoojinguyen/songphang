public import Domain
import Foundation
public import Observation

@Observable
public final class GroupFeedModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var balances: GroupBalances
    public var transactions: [LedgerTransaction]
    public var nextCursor: String?
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isLoadingMore = false
  public private(set) var loadMoreError: AppError?
  public var hasNewItemsPill = false
  public var isScrolledAwayFromBottom = false

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  private let eventsRepository: any GroupEventsRepository

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    eventsRepository: any GroupEventsRepository,
    initialHasNewItemsPill: Bool = false
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.eventsRepository = eventsRepository
    self.hasNewItemsPill = initialHasNewItemsPill
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
    async let cachedPage = transactionsRepository.lastKnownFirstPage(groupId: groupId)

    if let g = await cachedGroup,
      let m = await cachedMembers,
      let b = await cachedBalances,
      let p = await cachedPage
    {
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
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
      async let fetchedPage = transactionsRepository.page(groupId: groupId, cursor: nil)

      let g = try await fetchedGroup
      let m = try await fetchedMembers
      let b = try await fetchedBalances
      let p = try await fetchedPage
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          balances: b,
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

  public func loadNextPageIfNeeded() async {
    guard case .loaded(var current) = state,
      let cursor = current.nextCursor,
      !isLoadingMore
    else { return }
    isLoadingMore = true
    loadMoreError = nil
    defer { isLoadingMore = false }
    do throws(AppError) {
      let nextPage = try await transactionsRepository.page(groupId: groupId, cursor: cursor)
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
      if resources.contains("transactions") {
        let page = try await transactionsRepository.page(groupId: groupId, cursor: nil)
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
