import DesignSystem
public import Domain
import Foundation
public import Observation

public enum BalancesSubTab: String, Sendable, CaseIterable, Hashable {
  case toPay
  case vault
  case cycles
}

public struct BalancesViewData: Sendable, Equatable {
  public var group: ExpenseGroup
  public var members: [Member]
  public var balances: GroupBalances
  public var transactions: [LedgerTransaction]
  public var pendingRequests: [SettlementRequest]
  public var cyclesOverview: SettlementCyclesOverview?
  public var vault: SettlementVaultPage?
  public var breakdowns: MemberBreakdownsResult?

  public init(
    group: ExpenseGroup,
    members: [Member],
    balances: GroupBalances,
    transactions: [LedgerTransaction],
    pendingRequests: [SettlementRequest] = [],
    cyclesOverview: SettlementCyclesOverview? = nil,
    vault: SettlementVaultPage? = nil,
    breakdowns: MemberBreakdownsResult? = nil
  ) {
    self.group = group
    self.members = members
    self.balances = balances
    self.transactions = transactions
    self.pendingRequests = pendingRequests
    self.cyclesOverview = cyclesOverview
    self.vault = vault
    self.breakdowns = breakdowns
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
  private let settlementCyclesRepository: (any SettlementCyclesRepository)?
  private let eventsRepository: (any GroupEventsRepository)?
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<BalancesViewData> = .loading
  public var selectedSubTab: BalancesSubTab = .toPay
  public private(set) var vaultFilter: SettlementVaultFilter = .all
  public private(set) var isLoadingVault = false
  public private(set) var isLoadingMoreVault = false
  public private(set) var vaultError: String?
  public private(set) var isClosingCycle = false
  public private(set) var isReopeningCycle = false
  public var cycleErrorMessage: String?
  private(set) var hasCurrentPaymentDetails = false
  public private(set) var refreshError: AppError?
  public private(set) var isNotFound = false
  public private(set) var isResolvingSettlement = false
  public private(set) var settlementError: AppError?
  public private(set) var pendingLoadError: String?
  public private(set) var settlementNotice: SettlementNotice?
  public private(set) var isSendingReminder = false
  public private(set) var reminderNotice: String?
  public private(set) var allSettledCelebrationTick = 0
  private var shouldCheckCelebrationAfterNextLoad = false

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    settlementRequests: (any SettlementRequestsRepository)? = nil,
    remindersRepository: (any RemindersRepository)? = nil,
    settlementCyclesRepository: (any SettlementCyclesRepository)? = nil,
    eventsRepository: (any GroupEventsRepository)? = nil,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.settlementRequests = settlementRequests
    self.remindersRepository = remindersRepository
    self.settlementCyclesRepository = settlementCyclesRepository
    self.eventsRepository = eventsRepository
    self.onUnauthorized = onUnauthorized
  }

  public func markOwnActionPendingCelebration() {
    if let current = state.value, !current.balances.transfers.isEmpty {
      shouldCheckCelebrationAfterNextLoad = true
    }
  }

  #if DEBUG
    public func triggerAllSettledCelebrationForExercise() {
      allSettledCelebrationTick &+= 1
    }
  #endif

  public func load() async {
    isNotFound = false
    hasCurrentPaymentDetails = false
    let existingCycles = state.value?.cyclesOverview
    let existingVault = state.value?.vault
    let existingBreakdowns = state.value?.breakdowns
    let existingPending = state.value?.pendingRequests ?? []
    vaultError = nil
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
          transactions: cachedPage.items,
          cyclesOverview: existingCycles,
          vault: existingVault,
          breakdowns: existingBreakdowns
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
      async let fetchedPending = fetchPendingRequestsResult(fallback: existingPending)
      async let fetchedCycles = fetchOptional(fallback: existingCycles) {
        try await fetchCyclesOverview()
      }
      async let fetchedVault = fetchOptional(fallback: existingVault) {
        try await fetchVaultPage(filter: vaultFilter, cursor: nil)
      }
      async let fetchedBreakdowns = fetchOptional(fallback: existingBreakdowns) {
        try await fetchBreakdowns()
      }

      let (
        group,
        members,
        balances,
        firstPage,
        pendingResult,
        cyclesOverview,
        vault,
        breakdowns
      ) = try await (
        fetchedGroup,
        fetchedMembers,
        fetchedBalances,
        fetchedPage,
        fetchedPending,
        fetchedCycles,
        fetchedVault,
        fetchedBreakdowns
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
          pendingRequests: pendingResult.requests,
          cyclesOverview: cyclesOverview,
          vault: vault,
          breakdowns: breakdowns
        )
      )
      if shouldCheckCelebrationAfterNextLoad {
        shouldCheckCelebrationAfterNextLoad = false
        if !allTransactions.isEmpty && balances.transfers.isEmpty {
          allSettledCelebrationTick &+= 1
        }
      }
      refreshError = nil
      hasCurrentPaymentDetails = (pendingResult.error == nil)
      pendingLoadError = pendingResult.error != nil ? L10n.tr("common.loadError") : nil
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
        markOwnActionPendingCelebration()
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

  public func selectVaultFilter(_ next: SettlementVaultFilter) async {
    vaultFilter = next
    vaultError = nil
    guard case .loaded = state else { return }
    isLoadingVault = true
    defer { isLoadingVault = false }
    do throws(AppError) {
      let page = try await balancesRepository.settlementVault(
        groupId: groupId,
        filter: next,
        cycleId: nil,
        cursor: nil
      )
      guard vaultFilter == next, case .loaded(var latest) = state else { return }
      latest.vault = page
      state = .loaded(latest)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else if vaultFilter == next {
        vaultError = L10n.tr("common.loadError")
      }
    }
  }

  public func loadMoreVaultIfNeeded() async {
    guard !isLoadingMoreVault,
      case .loaded(let current) = state,
      let existing = current.vault,
      let cursor = existing.nextCursor
    else { return }
    let activeFilter = vaultFilter
    isLoadingMoreVault = true
    defer { isLoadingMoreVault = false }
    do throws(AppError) {
      let nextPage = try await balancesRepository.settlementVault(
        groupId: groupId,
        filter: activeFilter,
        cycleId: nil,
        cursor: cursor
      )
      guard vaultFilter == activeFilter, case .loaded(var latest) = state else { return }
      let combinedItems = (latest.vault?.items ?? []) + nextPage.items
      latest.vault = SettlementVaultPage(
        items: combinedItems,
        summary: nextPage.summary,
        nextCursor: nextPage.nextCursor
      )
      state = .loaded(latest)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      }
    }
  }

  public func closeCycle(title: String?) async -> Bool {
    guard let settlementCyclesRepository, !isClosingCycle else { return false }
    isClosingCycle = true
    cycleErrorMessage = nil
    defer { isClosingCycle = false }
    let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalized = (trimmed?.isEmpty == false) ? trimmed : nil
    do throws(AppError) {
      _ = try await settlementCyclesRepository.close(
        groupId: groupId,
        title: normalized,
        idempotencyKey: IdempotencyKey()
      )
      await load()
      return true
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else if error == .cycleEmpty {
        cycleErrorMessage = L10n.tr("cycles.emptyPeriodError")
      } else if case .api(_, 403) = error {
        cycleErrorMessage = L10n.tr("common.forbidden")
      } else {
        cycleErrorMessage = L10n.tr("common.saveError")
      }
      return false
    }
  }

  public func reopenLatestCycle(_ cycleId: SettlementCycle.ID) async {
    guard let settlementCyclesRepository, !isReopeningCycle else { return }
    isReopeningCycle = true
    cycleErrorMessage = nil
    defer { isReopeningCycle = false }
    do throws(AppError) {
      try await settlementCyclesRepository.reopen(groupId: groupId, cycleId: cycleId)
      await load()
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else if case .api(_, 403) = error {
        cycleErrorMessage = L10n.tr("common.forbidden")
      } else {
        cycleErrorMessage = L10n.tr("common.saveError")
      }
    }
  }

  public func listenForEvents(onRemoved: @escaping () -> Void) async {
    guard let eventsRepository else { return }
    for await event in eventsRepository.events(groupId: groupId) {
      switch event {
      case .removed:
        onRemoved()
        return
      case .reconnected:
        await load()
      case .changed(let resources):
        let interesting = [
          "balances", "transactions", "settlementRequests", "settlementCycles", "members", "group",
        ]
        if resources.contains(where: { interesting.contains($0) }) {
          await load()
        }
      }
    }
  }

  private func fetchPendingRequestsResult(
    fallback: [SettlementRequest]
  ) async throws(AppError) -> (requests: [SettlementRequest], error: AppError?) {
    do {
      return (try await fetchPendingRequests(), nil)
    } catch {
      if error == .unauthorized { throw error }
      return (fallback, error)
    }
  }

  private func fetchOptional<T: Sendable>(
    fallback: T,
    _ work: () async throws -> T
  ) async throws(AppError) -> T {
    do {
      return try await work()
    } catch let error as AppError {
      if error == .unauthorized { throw error }
      return fallback
    } catch {
      return fallback
    }
  }

  private func fetchPendingRequests() async throws(AppError) -> [SettlementRequest] {
    guard let settlementRequests else { return [] }
    return try await settlementRequests.list(groupId: groupId, status: .pending)
  }

  private func fetchCyclesOverview() async throws(AppError) -> SettlementCyclesOverview? {
    guard let settlementCyclesRepository else { return nil }
    return try await settlementCyclesRepository.list(groupId: groupId)
  }

  private func fetchVaultPage(
    filter: SettlementVaultFilter,
    cursor: String?
  ) async throws(AppError) -> SettlementVaultPage? {
    try await balancesRepository.settlementVault(
      groupId: groupId,
      filter: filter,
      cycleId: nil,
      cursor: cursor
    )
  }

  private func fetchBreakdowns() async throws(AppError) -> MemberBreakdownsResult? {
    try await balancesRepository.breakdowns(groupId: groupId)
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
  if let myMemberId, transfer.fromHousehold?.memberIds.contains(myMemberId) == true {
    return false
  }
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
    return L10n.t(
      "ios.balances.cooldownDate",
      ["time": timeStr, "day": day, "month": month]
    )
  }
}
