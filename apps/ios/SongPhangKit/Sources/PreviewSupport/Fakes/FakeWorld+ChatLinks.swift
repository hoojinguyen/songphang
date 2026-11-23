#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public func listChatIdentities() -> [ChatIdentity] {
      chatIdentities
    }

    public func unlinkChatIdentity(platform: ChatPlatform) {
      chatIdentities.removeAll { $0.platform == platform }
    }

    public func startTelegramPairing() -> StartedTelegramPairing {
      let id = TelegramPairing.ID(UUID().uuidString.lowercased())
      let pairing = TelegramPairing(
        id: id,
        status: .pendingTelegram,
        botUsername: "SongPhangBot",
        stagedPlatformUserId: nil,
        stagedPlatformName: nil,
        expiresAt: "2026-11-23T12:00:00.000Z"
      )
      pairingsById[id] = pairing
      return StartedTelegramPairing(
        pairing: pairing,
        startCommand: "/start fake_token",
        deepLinkUrl: "https://t.me/SongPhangBot?start=fake_token"
      )
    }

    public func fetchTelegramPairing(id: TelegramPairing.ID) -> TelegramPairing {
      pairingsById[id]
        ?? TelegramPairing(
          id: id,
          status: .telegramConfirmed,
          botUsername: "SongPhangBot",
          stagedPlatformUserId: "999999",
          stagedPlatformName: "@minh_demo",
          expiresAt: "2026-11-23T12:00:00.000Z"
        )
    }

    public func confirmTelegramPairing(id: TelegramPairing.ID) {
      if let existing = pairingsById[id] {
        pairingsById[id] = TelegramPairing(
          id: existing.id,
          status: .completed,
          botUsername: existing.botUsername,
          stagedPlatformUserId: existing.stagedPlatformUserId,
          stagedPlatformName: existing.stagedPlatformName,
          expiresAt: existing.expiresAt
        )
      }
      if !chatIdentities.contains(where: { $0.platform == .telegram }) {
        chatIdentities.append(
          ChatIdentity(platform: .telegram, linkedAt: "2026-11-23T10:00:00.000Z")
        )
      }
    }

    public func cancelTelegramPairing(id: TelegramPairing.ID) {
      if let existing = pairingsById[id] {
        pairingsById[id] = TelegramPairing(
          id: existing.id,
          status: .cancelled,
          botUsername: existing.botUsername,
          stagedPlatformUserId: existing.stagedPlatformUserId,
          stagedPlatformName: existing.stagedPlatformName,
          expiresAt: existing.expiresAt
        )
      }
    }

    public func listGroupChatLinks(groupId: ExpenseGroup.ID) -> GroupChatLinks {
      GroupChatLinks(
        botUsername: "SongPhangBot",
        chatLinks: groupChatLinksByGroup[groupId] ?? []
      )
    }

    public func createGroupChatLinkCode(groupId: ExpenseGroup.ID) -> GroupChatLinkCode {
      GroupChatLinkCode(
        command: "/link 123456",
        botUsername: "SongPhangBot",
        expiresAt: "2026-11-23T12:00:00.000Z"
      )
    }

    public func unlinkGroupChat(groupId: ExpenseGroup.ID, chatLinkId: ChatLink.ID) {
      groupChatLinksByGroup[groupId]?.removeAll { $0.id == chatLinkId }
    }
  }
#endif
