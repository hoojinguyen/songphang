import Foundation

public enum ChatPlatform: String, Sendable, Hashable, Codable {
  case telegram
}

public struct ChatIdentity: Sendable, Hashable {
  public let platform: ChatPlatform
  public let linkedAt: String

  public init(platform: ChatPlatform, linkedAt: String) {
    self.platform = platform
    self.linkedAt = linkedAt
  }
}

public struct ChatLink: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let platform: ChatPlatform
  public let chatId: String
  public let linkedAt: String

  public init(id: ID, platform: ChatPlatform, chatId: String, linkedAt: String) {
    self.id = id
    self.platform = platform
    self.chatId = chatId
    self.linkedAt = linkedAt
  }
}

public struct GroupChatLinks: Sendable, Hashable {
  public let botUsername: String?
  public let chatLinks: [ChatLink]

  public init(botUsername: String?, chatLinks: [ChatLink]) {
    self.botUsername = botUsername
    self.chatLinks = chatLinks
  }
}

public struct GroupChatLinkCode: Sendable, Hashable {
  public let command: String
  public let botUsername: String?
  public let expiresAt: String

  public init(command: String, botUsername: String?, expiresAt: String) {
    self.command = command
    self.botUsername = botUsername
    self.expiresAt = expiresAt
  }
}

public enum TelegramPairingStatus: String, Sendable, Hashable {
  case pendingTelegram = "pending_telegram"
  case telegramConfirmed = "telegram_confirmed"
  case completed
  case cancelled
  case expired
}

public struct TelegramPairing: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let status: TelegramPairingStatus
  public let botUsername: String?
  public let stagedPlatformUserId: String?
  public let stagedPlatformName: String?
  public let expiresAt: String

  public init(
    id: ID,
    status: TelegramPairingStatus,
    botUsername: String?,
    stagedPlatformUserId: String?,
    stagedPlatformName: String?,
    expiresAt: String
  ) {
    self.id = id
    self.status = status
    self.botUsername = botUsername
    self.stagedPlatformUserId = stagedPlatformUserId
    self.stagedPlatformName = stagedPlatformName
    self.expiresAt = expiresAt
  }
}

public struct StartedTelegramPairing: Sendable, Hashable {
  public let pairing: TelegramPairing
  public let startCommand: String
  public let deepLinkUrl: String?

  public init(pairing: TelegramPairing, startCommand: String, deepLinkUrl: String?) {
    self.pairing = pairing
    self.startCommand = startCommand
    self.deepLinkUrl = deepLinkUrl
  }
}
