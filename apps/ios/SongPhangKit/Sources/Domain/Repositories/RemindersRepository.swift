import Foundation

public protocol RemindersRepository: Sendable {
  func sendReminder(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID
  ) async throws(AppError) -> SendReminderResult

  func sendAllReminders(groupId: ExpenseGroup.ID) async throws(AppError) -> SendReminderResult
}
