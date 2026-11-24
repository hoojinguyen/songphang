import Domain
import Foundation
import GeneratedAPI

enum AuthMapping {
  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapUser(_ dto: Components.Schemas.UserDto) -> User {
    User(
      id: User.ID(dto.id),
      email: dto.email,
      name: dto.name,
      avatarUrl: dto.avatarUrl,
      emailVerified: dto.emailVerified,
      hasPassword: dto.hasPassword,
      hidePushContent: dto.hidePushContent ?? false
    )
  }

  static func mapSession(_ dto: Components.Schemas.SessionDto) -> UserSession {
    UserSession(
      id: UserSession.ID(dto.id),
      client: UserSession.Client(code: dto.client.rawValue),
      deviceName: dto.deviceName,
      createdAt: formatISO(dto.createdAt),
      lastSeenAt: formatISO(dto.lastSeenAt),
      current: dto.current
    )
  }

  /// Resilient fallback decoders preserve readable data and map unknown server
  /// enum values to `.unknown(raw)` while ignoring additive extra JSON fields.
  struct RawMeResponse: Codable, Sendable {
    struct RawUser: Codable, Sendable {
      let id: String
      let email: String
      let name: String
      let avatarUrl: String?
      let emailVerified: Bool
      let hasPassword: Bool
      let hidePushContent: Bool?
    }

    let user: RawUser

    func toDomain() -> User {
      User(
        id: User.ID(user.id),
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        emailVerified: user.emailVerified,
        hasPassword: user.hasPassword,
        hidePushContent: user.hidePushContent ?? false
      )
    }
  }

  struct RawSessionsResponse: Decodable, Sendable {
    struct RawSession: Decodable, Sendable {
      let id: String
      let client: String
      let deviceName: String?
      let createdAt: String
      let lastSeenAt: String
      let current: Bool
    }

    let sessions: [RawSession]

    func toDomain() -> [UserSession] {
      sessions.map { session in
        UserSession(
          id: UserSession.ID(session.id),
          client: UserSession.Client(code: session.client),
          deviceName: session.deviceName,
          createdAt: session.createdAt,
          lastSeenAt: session.lastSeenAt,
          current: session.current
        )
      }
    }
  }

  static func decodeCachedUser(from data: Data) throws -> (userId: String, value: User) {
    let decoder = JSONDecoder()
    let raw = try decoder.decode(RawMeResponse.self, from: data)
    return (userId: raw.user.id, value: raw.toDomain())
  }

  static func encodeCachedUser(_ user: User) -> Data? {
    let payload = RawMeResponse(
      user: RawMeResponse.RawUser(
        id: user.id.rawValue,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        emailVerified: user.emailVerified,
        hasPassword: user.hasPassword,
        hidePushContent: user.hidePushContent
      )
    )
    return try? JSONEncoder().encode(payload)
  }

  static func decodeResilientSessions(from data: Data) throws -> [UserSession] {
    let raw = try JSONDecoder().decode(RawSessionsResponse.self, from: data)
    return raw.toDomain()
  }
}
