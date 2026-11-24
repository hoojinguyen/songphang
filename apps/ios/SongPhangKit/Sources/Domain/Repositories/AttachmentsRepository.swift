public import Foundation

public protocol AttachmentsRepository: Sendable {
  func upload(
    groupId: ExpenseGroup.ID,
    data: Data,
    filename: String,
    contentType: String
  ) async throws(AppError) -> Attachment

  func content(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID
  ) async throws(AppError) -> Data

  func delete(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID
  ) async throws(AppError)
}
