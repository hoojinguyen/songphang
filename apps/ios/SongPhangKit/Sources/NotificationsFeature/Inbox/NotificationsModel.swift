public import Domain
import Foundation
public import Observation

@Observable
public final class NotificationsModel {
  public struct ScreenData: Sendable, Equatable {
    public var notifications: [AppNotification]
    public var unreadCount: Int
    public var nextCursor: String?

    public init(notifications: [AppNotification], unreadCount: Int, nextCursor: String?) {
      self.notifications = notifications
      self.unreadCount = unreadCount
      self.nextCursor = nextCursor
    }
  }

  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var isFetchingNextPage = false
  public private(set) var nextPageError: AppError?
  public private(set) var isMarkingAll = false
  public private(set) var markError: AppError?

  private let repository: any NotificationsRepository
  private let onUnauthorized: () -> Void

  public init(
    repository: any NotificationsRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.repository = repository
    self.onUnauthorized = onUnauthorized
  }

  public var hasUnread: Bool {
    guard case .loaded(let data) = state else { return false }
    return data.unreadCount > 0 || data.notifications.contains(where: { !$0.read })
  }

  public func load() async {
    state = .loading
    markError = nil
    nextPageError = nil
    do {
      async let countFetch = repository.unreadCount()
      async let listFetch = repository.list(cursor: nil, limit: 30)
      let (count, list) = try await (countFetch, listFetch)
      state = .loaded(
        ScreenData(
          notifications: list.notifications,
          unreadCount: count,
          nextCursor: list.nextCursor
        )
      )
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      state = .failed(error)
    } catch {
      state = .failed(.unexpected)
    }
  }

  public func fetchNextPage() async {
    guard case .loaded(var data) = state, let cursor = data.nextCursor, !isFetchingNextPage else {
      return
    }
    isFetchingNextPage = true
    nextPageError = nil
    defer { isFetchingNextPage = false }

    do throws(AppError) {
      let page = try await repository.list(cursor: cursor, limit: 30)
      data.notifications.append(contentsOf: page.notifications)
      data.nextCursor = page.nextCursor
      nextPageError = nil
      state = .loaded(data)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else {
        nextPageError = error
      }
    }
  }

  public func markOneRead(_ notification: AppNotification) {
    guard !notification.read else { return }
    guard case .loaded(var data) = state else { return }

    if let idx = data.notifications.firstIndex(where: { $0.id == notification.id }) {
      data.notifications[idx].read = true
      data.unreadCount = max(0, data.unreadCount - 1)
      state = .loaded(data)
    }

    Task {
      do throws(AppError) {
        try await repository.markRead(ids: [notification.id])
      } catch {
        if error == .unauthorized {
          onUnauthorized()
        }
      }
    }
  }

  public func markAllRead() async {
    guard case .loaded(var data) = state, !isMarkingAll else { return }
    isMarkingAll = true
    defer { isMarkingAll = false }

    let previousNotifications = data.notifications
    let previousUnreadCount = data.unreadCount

    for i in data.notifications.indices {
      data.notifications[i].read = true
    }
    data.unreadCount = 0
    state = .loaded(data)

    do throws(AppError) {
      try await repository.markAllRead()
      markError = nil
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      markError = error
      if case .loaded(var current) = state {
        for (idx, prev) in previousNotifications.enumerated() {
          if idx < current.notifications.count && current.notifications[idx].id == prev.id {
            current.notifications[idx].read = prev.read
          }
        }
        current.unreadCount = previousUnreadCount
        state = .loaded(current)
      }
    }
  }
}
