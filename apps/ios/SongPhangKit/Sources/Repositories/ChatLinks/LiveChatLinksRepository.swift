public import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveChatLinksRepository: ChatLinksRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func myIdentities() async throws(AppError) -> [ChatIdentity] {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities(
          .init())
      switch output {
      case .ok(let ok):
        let body = try ok.body.json
        return body.chatIdentities.map { Self.mapIdentity($0) }
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func unlinkMyIdentity(platform: ChatPlatform) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities_sol__lcub_platform_rcub_(
          .init(path: .init(platform: Self.mapPlatform(platform)))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func startTelegramPairing() async throws(AppError) -> StartedTelegramPairing {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities_sol_telegram_sol_pairings(.init())
      switch output {
      case .created(let created):
        let body = try created.body.json
        return StartedTelegramPairing(
          pairing: Self.mapPairing(body.pairing),
          startCommand: body.startCommand,
          deepLinkUrl: body.deepLinkUrl
        )
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func telegramPairing(id: TelegramPairing.ID) async throws(AppError) -> TelegramPairing {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities_sol_telegram_sol_pairings_sol__lcub_pairingId_rcub_(
          .init(path: .init(pairingId: id.rawValue))
        )
      switch output {
      case .ok(let ok):
        return Self.mapPairing(try ok.body.json.pairing)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func confirmTelegramPairing(id: TelegramPairing.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities_sol_telegram_sol_pairings_sol__lcub_pairingId_rcub__sol_confirm(
          .init(path: .init(pairingId: id.rawValue))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func cancelTelegramPairing(id: TelegramPairing.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_me_sol_chat_hyphen_identities_sol_telegram_sol_pairings_sol__lcub_pairingId_rcub__sol_cancel(
          .init(path: .init(pairingId: id.rawValue))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func groupChatLinks(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupChatLinks {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_chat_hyphen_links(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        let body = try ok.body.json
        return GroupChatLinks(
          botUsername: body.botUsername,
          chatLinks: body.chatLinks.map { Self.mapChatLink($0) }
        )
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func createGroupChatLinkCode(groupId: ExpenseGroup.ID) async throws(AppError)
    -> GroupChatLinkCode
  {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_chat_hyphen_links_sol_code(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        let body = try ok.body.json
        return GroupChatLinkCode(
          command: body.command,
          botUsername: body.botUsername,
          expiresAt: Self.formatISO(body.expiresAt)
        )
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func unlinkGroupChat(
    groupId: ExpenseGroup.ID,
    chatLinkId: ChatLink.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_chat_hyphen_links_sol__lcub_chatLinkId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, chatLinkId: chatLinkId.rawValue))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  private static func formatISO(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  private static func mapPlatform(_ platform: ChatPlatform) -> Components.Schemas.ChatPlatform {
    switch platform {
    case .telegram: .telegram
    }
  }

  private static func mapDomainPlatform(_ platform: Components.Schemas.ChatPlatform) -> ChatPlatform
  {
    switch platform {
    case .telegram: .telegram
    }
  }

  private static func mapIdentity(_ dto: Components.Schemas.ChatIdentityDto) -> ChatIdentity {
    ChatIdentity(
      platform: mapDomainPlatform(dto.platform),
      linkedAt: formatISO(dto.linkedAt)
    )
  }

  private static func mapChatLink(_ dto: Components.Schemas.ChatLinkDto) -> ChatLink {
    ChatLink(
      id: ChatLink.ID(dto.id),
      platform: mapDomainPlatform(dto.platform),
      chatId: dto.chatId,
      linkedAt: formatISO(dto.linkedAt)
    )
  }

  private static func mapPairing(_ dto: Components.Schemas.TelegramPairingDto) -> TelegramPairing {
    let status: TelegramPairingStatus =
      switch dto.status {
      case .pending_telegram: .pendingTelegram
      case .telegram_confirmed: .telegramConfirmed
      case .completed: .completed
      case .cancelled: .cancelled
      case .expired: .expired
      }
    return TelegramPairing(
      id: TelegramPairing.ID(dto.id),
      status: status,
      botUsername: dto.botUsername,
      stagedPlatformUserId: dto.stagedPlatformUserId,
      stagedPlatformName: dto.stagedPlatformName,
      expiresAt: formatISO(dto.expiresAt)
    )
  }
}
