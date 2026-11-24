public import Domain
import Foundation
public import Observation

@Observable
public final class FundModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var balances: GroupBalances
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isPerformingAction = false
  public private(set) var actionError: AppError?

  public var nameDraft = ""
  public var holderDraftId: Member.ID?

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let fundRepository: any FundRepository
  private let onUnauthorized: () -> Void

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    fundRepository: any FundRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.fundRepository = fundRepository
    self.onUnauthorized = onUnauthorized
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

    if let g = await cachedGroup, let m = await cachedMembers, let b = await cachedBalances {
      syncDrafts(from: b.fund)
      state = .loaded(ScreenData(group: g, members: m, balances: b))
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)
      let (g, m, b) = try await (fetchedGroup, fetchedMembers, fetchedBalances)
      syncDrafts(from: b.fund)
      state = .loaded(ScreenData(group: g, members: m, balances: b))
      refreshError = nil
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
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

  public func saveSettings() async {
    guard case .loaded(let data) = state, let fund = data.balances.fund, !isPerformingAction else {
      return
    }
    let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let nameChange = trimmed != fund.name ? trimmed : nil
    let holderUpdate: FundHolderUpdate =
      if holderDraftId == fund.holderMemberId {
        .unchanged
      } else if let holderDraftId {
        .set(holderDraftId)
      } else {
        .clear
      }
    guard nameChange != nil || holderUpdate != .unchanged else { return }

    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await fundRepository.update(
        groupId: groupId,
        name: nameChange,
        holder: holderUpdate,
        active: nil
      )
      await load()
    } catch {
      handleActionError(error)
    }
  }

  public func toggleActive() async {
    guard case .loaded(let data) = state, let fund = data.balances.fund, !isPerformingAction else {
      return
    }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      _ = try await fundRepository.update(
        groupId: groupId,
        name: nil,
        holder: .unchanged,
        active: !fund.active
      )
      await load()
    } catch {
      handleActionError(error)
    }
  }

  public func deleteFund(onDeleted: @escaping () -> Void) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      try await fundRepository.delete(groupId: groupId)
      onDeleted()
    } catch {
      handleActionError(error)
    }
  }

  private func syncDrafts(from fund: FundSummary?) {
    guard let fund else { return }
    nameDraft = fund.name
    holderDraftId = fund.holderMemberId
  }

  private func handleActionError(_ error: AppError) {
    if error == .unauthorized {
      onUnauthorized()
      return
    }
    actionError = error
  }
}
