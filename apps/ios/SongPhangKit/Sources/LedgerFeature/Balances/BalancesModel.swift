public import Domain
import Foundation
public import Observation

public struct BalancesViewData: Sendable, Equatable {
  public var group: ExpenseGroup
  public var members: [Member]
  public var balances: GroupBalances
  public var transactions: [LedgerTransaction]

  public init(
    group: ExpenseGroup,
    members: [Member],
    balances: GroupBalances,
    transactions: [LedgerTransaction]
  ) {
    self.group = group
    self.members = members
    self.balances = balances
    self.transactions = transactions
  }
}

@Observable
public final class BalancesModel {
  public let groupId: ExpenseGroup.ID
  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<BalancesViewData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isNotFound = false

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.onUnauthorized = onUnauthorized
  }

  public func load() async {
    isNotFound = false
    if let cachedGroup = await groupsRepository.lastKnownGroup(id: groupId),
      let cachedMembers = await membersRepository.lastKnownMembers(groupId: groupId),
      let cachedBalances = await balancesRepository.lastKnownBalances(groupId: groupId),
      let cachedPage = await transactionsRepository.lastKnownFirstPage(groupId: groupId)
    {
      state = .loaded(
        BalancesViewData(
          group: cachedGroup,
          members: cachedMembers,
          balances: cachedBalances,
          transactions: cachedPage.items
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

      let (group, members, balances, firstPage) = try await (
        fetchedGroup, fetchedMembers, fetchedBalances, fetchedPage
      )
      var allTransactions = firstPage.items
      var nextCursor = firstPage.nextCursor
      if balances.transfers.isEmpty {
        while let cursor = nextCursor {
          let nextPage = try await transactionsRepository.page(groupId: groupId, cursor: cursor)
          allTransactions.append(contentsOf: nextPage.items)
          nextCursor = nextPage.nextCursor
        }
      }
      state = .loaded(
        BalancesViewData(
          group: group,
          members: members,
          balances: balances,
          transactions: allTransactions
        )
      )
      refreshError = nil
    } catch let error as AppError {
      handleError(error)
    } catch {
      handleError(.unexpected)
    }
  }

  private func handleError(_ error: AppError) {
    if error == .unauthorized {
      onUnauthorized()
      return
    }
    if case .api(_, 404) = error {
      isNotFound = true
      state = .failed(error)
      return
    }
    if case .loaded = state {
      refreshError = error
    } else {
      state = .failed(error)
    }
  }
}
