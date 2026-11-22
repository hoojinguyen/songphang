public import Domain
import Foundation
public import Observation

public struct BalancesViewData: Sendable, Equatable {
  public var group: ExpenseGroup
  public var members: [Member]
  public var balances: GroupBalances
  public var transactions: [LedgerTransaction]
  public var pendingRequests: [SettlementRequest]

  public init(
    group: ExpenseGroup,
    members: [Member],
    balances: GroupBalances,
    transactions: [LedgerTransaction],
    pendingRequests: [SettlementRequest] = []
  ) {
    self.group = group
    self.members = members
    self.balances = balances
    self.transactions = transactions
    self.pendingRequests = pendingRequests
  }
}

@Observable
public final class BalancesModel {
  public enum SettlementNotice: Sendable, Equatable {
    case confirmed(amount: Money, fromName: String)
    case rejected
    case alreadyResolved
  }

  public let groupId: ExpenseGroup.ID
  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  private let settlementRequests: (any SettlementRequestsRepository)?
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<BalancesViewData> = .loading
  private(set) var hasCurrentPaymentDetails = false
  public private(set) var refreshError: AppError?
  public private(set) var isNotFound = false
  public private(set) var isResolvingSettlement = false
  public private(set) var settlementError: AppError?
  public private(set) var settlementNotice: SettlementNotice?

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    settlementRequests: (any SettlementRequestsRepository)? = nil,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.settlementRequests = settlementRequests
    self.onUnauthorized = onUnauthorized
  }

  public func load() async {
    isNotFound = false
    hasCurrentPaymentDetails = false
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
      async let fetchedPending = fetchPendingRequests()

      let (group, members, balances, firstPage, pendingRequests) = try await (
        fetchedGroup, fetchedMembers, fetchedBalances, fetchedPage, fetchedPending
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
          transactions: allTransactions,
          pendingRequests: pendingRequests
        )
      )
      refreshError = nil
      hasCurrentPaymentDetails = true
    } catch let error as AppError {
      handleError(error)
    } catch {
      handleError(.unexpected)
    }
  }

  func resolveSettlement(
    requestId: String,
    amount: Money,
    fromName: String,
    decision: SettlementDecision
  ) async {
    guard hasCurrentPaymentDetails, let settlementRequests, !isResolvingSettlement else { return }
    isResolvingSettlement = true
    settlementError = nil
    settlementNotice = nil
    defer { isResolvingSettlement = false }
    do {
      try await settlementRequests.resolve(
        groupId: groupId, requestId: requestId, decision: decision
      )
      switch decision {
      case .confirm:
        settlementNotice = .confirmed(amount: amount, fromName: fromName)
      case .reject:
        settlementNotice = .rejected
      case .cancel:
        break
      }
      await load()
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else if error == .conflict || isConflictAPIError(error) {
        settlementNotice = .alreadyResolved
        await load()
      } else {
        settlementError = error
      }
    }
  }

  private func fetchPendingRequests() async throws(AppError) -> [SettlementRequest] {
    guard let settlementRequests else { return [] }
    return try await settlementRequests.list(groupId: groupId, status: .pending)
  }

  private func isConflictAPIError(_ error: AppError) -> Bool {
    if case .api(_, 409) = error { return true }
    return false
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
