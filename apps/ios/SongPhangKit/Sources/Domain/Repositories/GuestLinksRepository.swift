public import Foundation

public protocol GuestLinksRepository: Sendable {
  func status(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink
  func createOrRotate(groupId: ExpenseGroup.ID, rotate: Bool) async throws(AppError) -> GuestLink
  func revoke(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink
  func fetchGuestGroup(
    token: String,
    cycleId: TransactionCycleFilter?,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> GuestGroupSnapshot
  func fetchGuestAttachmentData(
    token: String,
    attachmentId: Attachment.ID
  ) async throws(AppError) -> Data
}

extension GuestLinksRepository {
  public func fetchGuestGroup(
    token: String,
    cycleId: TransactionCycleFilter? = nil,
    cursor: String? = nil
  ) async throws(AppError) -> GuestGroupSnapshot {
    try await fetchGuestGroup(token: token, cycleId: cycleId, cursor: cursor, limit: 50)
  }
}
