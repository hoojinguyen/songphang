import DesignSystem
public import Domain
import Foundation
public import Observation

@Observable
public final class GuestLinkSheetModel {
  public let groupId: ExpenseGroup.ID
  private let guestLinksRepository: any GuestLinksRepository
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<GuestLink> = .loading
  public private(set) var isPerformingAction = false
  public private(set) var actionError: String?

  public init(
    groupId: ExpenseGroup.ID,
    guestLinksRepository: any GuestLinksRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.guestLinksRepository = guestLinksRepository
    self.onUnauthorized = onUnauthorized
  }

  public func load() async {
    actionError = nil
    if case .failed = state {
      state = .loading
    }
    do throws(AppError) {
      let link = try await guestLinksRepository.status(groupId: groupId)
      state = .loaded(link)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else if case .loaded = state {
        actionError = L10n.tr("common.loadError")
      } else {
        state = .failed(error)
      }
    }
  }

  public func enableOrRotate(rotate: Bool) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      let link = try await guestLinksRepository.createOrRotate(groupId: groupId, rotate: rotate)
      state = .loaded(link)
    } catch {
      handleActionError(error)
    }
  }

  public func revoke() async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }
    do throws(AppError) {
      let link = try await guestLinksRepository.revoke(groupId: groupId)
      state = .loaded(link)
    } catch {
      handleActionError(error)
    }
  }

  private func handleActionError(_ error: AppError) {
    if error == .unauthorized {
      onUnauthorized()
    } else if case .api(_, 403) = error {
      actionError = L10n.tr("common.forbidden")
    } else {
      actionError = L10n.tr("common.saveError")
    }
  }
}
