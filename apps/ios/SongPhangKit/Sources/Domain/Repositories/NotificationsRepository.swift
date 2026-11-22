import Foundation

public protocol NotificationsRepository: Sendable {
  func list(cursor: String?, limit: Int) async throws(AppError) -> (
    notifications: [AppNotification], nextCursor: String?
  )
  func unreadCount() async throws(AppError) -> Int
  func markRead(ids: [AppNotification.ID]) async throws(AppError)
  func markAllRead() async throws(AppError)
  func settings() async throws(AppError) -> NotificationSettings
  func updateSettings(emailImmediate: Bool?, emailDigest: Bool?) async throws(AppError)
    -> NotificationSettings
}
