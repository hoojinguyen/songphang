import Foundation

public protocol ChatLinksRepository: Sendable {
  func myIdentities() async throws(AppError) -> [ChatIdentity]
  func unlinkMyIdentity(platform: ChatPlatform) async throws(AppError)
  func startTelegramPairing() async throws(AppError) -> StartedTelegramPairing
  func telegramPairing(id: TelegramPairing.ID) async throws(AppError) -> TelegramPairing
  func confirmTelegramPairing(id: TelegramPairing.ID) async throws(AppError)
  func cancelTelegramPairing(id: TelegramPairing.ID) async throws(AppError)
  func groupChatLinks(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupChatLinks
  func createGroupChatLinkCode(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupChatLinkCode
  func unlinkGroupChat(groupId: ExpenseGroup.ID, chatLinkId: ChatLink.ID) async throws(AppError)
}
