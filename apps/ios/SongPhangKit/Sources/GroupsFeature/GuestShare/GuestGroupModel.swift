import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class GuestGroupModel {
  public let token: String
  private let guestLinksRepository: any GuestLinksRepository

  public private(set) var state: Loadable<GuestGroupSnapshot> = .loading
  public private(set) var selectedCycleId: TransactionCycleFilter?
  public private(set) var isSwitchingCycle = false
  public private(set) var isLoadingMore = false
  public private(set) var isNotFound = false
  public private(set) var refreshError: AppError?

  public init(
    token: String,
    guestLinksRepository: any GuestLinksRepository
  ) {
    self.token = token
    self.guestLinksRepository = guestLinksRepository
  }

  public func load() async {
    isNotFound = false
    if case .failed = state {
      state = .loading
    }
    do throws(AppError) {
      let snapshot = try await guestLinksRepository.fetchGuestGroup(
        token: token,
        cycleId: selectedCycleId,
        cursor: nil
      )
      selectedCycleId = snapshot.selectedCycleId
      state = .loaded(snapshot)
      refreshError = nil
    } catch {
      if case .api(_, 404) = error {
        isNotFound = true
        state = .failed(error)
      } else if case .loaded = state {
        refreshError = error
      } else {
        state = .failed(error)
      }
    }
  }

  public func selectCycle(_ cycle: TransactionCycleFilter) async {
    guard !isSwitchingCycle else { return }
    selectedCycleId = cycle
    isSwitchingCycle = true
    defer { isSwitchingCycle = false }
    do throws(AppError) {
      let snapshot = try await guestLinksRepository.fetchGuestGroup(
        token: token,
        cycleId: cycle,
        cursor: nil
      )
      selectedCycleId = snapshot.selectedCycleId
      state = .loaded(snapshot)
      refreshError = nil
    } catch {
      if case .api(_, 404) = error {
        isNotFound = true
        state = .failed(error)
      } else {
        refreshError = error
      }
    }
  }

  public func loadMoreIfNeeded() async {
    guard !isLoadingMore,
      case .loaded(let current) = state,
      let cursor = current.transactions.nextCursor
    else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do throws(AppError) {
      let next = try await guestLinksRepository.fetchGuestGroup(
        token: token,
        cycleId: selectedCycleId,
        cursor: cursor
      )
      guard case .loaded(let latest) = state else { return }
      let mergedPage = Page(
        items: latest.transactions.items + next.transactions.items,
        nextCursor: next.transactions.nextCursor
      )
      state = .loaded(
        GuestGroupSnapshot(
          group: next.group,
          members: next.members,
          cycles: next.cycles,
          selectedCycleId: next.selectedCycleId,
          currentPeriod: next.currentPeriod,
          balances: next.balances,
          transfers: next.transfers,
          fund: next.fund,
          resolvedFocus: next.resolvedFocus,
          breakdowns: next.breakdowns,
          transactions: mergedPage
        )
      )
    } catch {
      refreshError = error
    }
  }

  public func loadAttachment(id: Attachment.ID) async throws -> Data {
    try await guestLinksRepository.fetchGuestAttachmentData(token: token, attachmentId: id)
  }
}
