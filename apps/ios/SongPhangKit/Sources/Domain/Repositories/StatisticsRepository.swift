public import Foundation

public protocol StatisticsRepository: Sendable {
  func stats(
    groupId: ExpenseGroup.ID,
    from: String?,
    to: String?
  ) async throws(AppError) -> GroupStats
  func exportCSV(groupId: ExpenseGroup.ID) async throws(AppError) -> Data
}
