import DesignSystem
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
  private let remindersRepository: (any RemindersRepository)?
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<BalancesViewData> = .loading
  private(set) var hasCurrentPaymentDetails = false
  public private(set) var refreshError: AppError?
  public private(set) var isNotFound = false
  public private(set) var isResolvingSettlement = false
  public private(set) var settlementError: AppError?
  public private(set) var settlementNotice: SettlementNotice?
  public private(set) var isSendingReminder = false
  public private(set) var reminderNotice: String?

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    settlementRequests: (any SettlementRequestsRepository)? = nil,
    remindersRepository: (any RemindersRepository)? = nil,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.settlementRequests = settlementRequests
    self.remindersRepository = remindersRepository
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

  public func sendReminder(fromMember: Member, toMember: Member) async {
    guard hasCurrentPaymentDetails, let remindersRepository, !isSendingReminder else { return }
    isSendingReminder = true
    reminderNotice = nil
    defer { isSendingReminder = false }
    do throws(AppError) {
      _ = try await remindersRepository.sendReminder(
        groupId: groupId,
        fromMemberId: fromMember.id,
        toMemberId: toMember.id
      )
      reminderNotice = L10n.t("reminders.remindedOne", ["name": fromMember.name])
    } catch {
      if case .reminderTooSoon(let nextAt) = error {
        let timeStr = formatReminderNextAt(nextAt)
        reminderNotice = L10n.t("reminders.tooSoon", ["name": fromMember.name, "time": timeStr])
      } else if case .api("REMINDER_TOO_SOON", _) = error {
        reminderNotice = L10n.t("reminders.tooSoon", ["name": fromMember.name, "time": ""])
      } else if error == .unauthorized {
        onUnauthorized()
      } else {
        reminderNotice = L10n.tr("common.saveError")
      }
    }
  }

  public func sendAllReminders() async {
    guard hasCurrentPaymentDetails, let remindersRepository, !isSendingReminder else { return }
    isSendingReminder = true
    reminderNotice = nil
    defer { isSendingReminder = false }
    do throws(AppError) {
      let result = try await remindersRepository.sendAllReminders(groupId: groupId)
      reminderNotice = L10n.t("reminders.remindedMany", ["count": String(result.reminded.count)])
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else {
        reminderNotice = L10n.tr("common.saveError")
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

public func canRemindTransfer(
  transfer: SuggestedTransfer,
  from: Member,
  to: Member,
  myMemberId: Member.ID?,
  role: Role,
  verified: Bool
) -> Bool {
  guard verified else { return false }
  guard transfer.pendingSettlement == nil else { return false }
  guard from.kind == .person && from.claimed && to.kind == .person else { return false }
  guard from.id != myMemberId else { return false }
  return role != .viewer || myMemberId == to.id
}

func formatReminderNextAt(_ nextAtIso: String, now: Date = Date()) -> String {
  let iso = ISO8601DateFormatter()
  iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  var target = iso.date(from: nextAtIso)
  if target == nil {
    iso.formatOptions = [.withInternetDateTime]
    target = iso.date(from: nextAtIso)
  }
  guard let target else { return nextAtIso }

  var cal = Calendar(identifier: .gregorian)
  if let tz = TimeZone(identifier: "Asia/Ho_Chi_Minh") {
    cal.timeZone = tz
  }
  let targetComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: target)
  let nowComponents = cal.dateComponents([.year, .month, .day], from: now)

  let hour = String(format: "%02d", targetComponents.hour ?? 0)
  let minute = String(format: "%02d", targetComponents.minute ?? 0)
  let timeStr = "\(hour):\(minute)"

  if targetComponents.year == nowComponents.year,
    targetComponents.month == nowComponents.month,
    targetComponents.day == nowComponents.day
  {
    return timeStr
  } else {
    let day = String(format: "%02d", targetComponents.day ?? 0)
    let month = String(format: "%02d", targetComponents.month ?? 0)
    return "\(timeStr) ngày \(day)/\(month)"
  }
}
