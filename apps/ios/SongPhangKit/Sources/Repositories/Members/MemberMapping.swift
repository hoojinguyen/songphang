import Domain
import Foundation
import GeneratedAPI

enum MemberMapping {
  static func mapMember(_ dto: Components.Schemas.MemberDto) -> Member {
    Member(
      id: Member.ID(dto.id),
      name: dto.name,
      active: dto.active,
      defaultWeight: dto.defaultWeight,
      position: dto.position,
      shape: MemberShape(code: dto.shape.rawValue),
      color: MemberColor(code: dto.color.rawValue),
      isMe: dto.isMe,
      claimed: dto.claimed
    )
  }

  static func mapGroupUser(_ dto: Components.Schemas.GroupUserDto) -> GroupUser {
    GroupUser(
      userId: User.ID(dto.userId),
      name: dto.name,
      role: Role(code: dto.role.rawValue),
      memberId: dto.memberId.map(Member.ID.init),
      isMe: dto.isMe
    )
  }

  // MARK: - Resilient snapshot & unknown-enum decoders

  struct RawMember: Codable, Sendable {
    let id: String
    let name: String
    let active: Bool
    let defaultWeight: String
    let position: Int
    let shape: String
    let color: String
    let isMe: Bool
    let claimed: Bool

    func toDomain() -> Member {
      Member(
        id: Member.ID(id),
        name: name,
        active: active,
        defaultWeight: defaultWeight,
        position: position,
        shape: MemberShape(code: shape),
        color: MemberColor(code: color),
        isMe: isMe,
        claimed: claimed
      )
    }
  }

  struct RawMembersResponse: Codable, Sendable {
    let members: [RawMember]
  }

  struct RawMemberResponse: Codable, Sendable {
    let member: RawMember
  }

  struct RawGroupUser: Codable, Sendable {
    let userId: String
    let name: String
    let role: String
    let memberId: String?
    let isMe: Bool

    func toDomain() -> GroupUser {
      GroupUser(
        userId: User.ID(userId),
        name: name,
        role: Role(code: role),
        memberId: memberId.map(Member.ID.init),
        isMe: isMe
      )
    }
  }

  struct RawGroupUsersResponse: Codable, Sendable {
    let users: [RawGroupUser]
  }

  static func decodeResilientMembers(from data: Data) throws -> [Member] {
    try JSONDecoder().decode(RawMembersResponse.self, from: data).members.map { $0.toDomain() }
  }

  static func decodeResilientMember(from data: Data) throws -> Member {
    try JSONDecoder().decode(RawMemberResponse.self, from: data).member.toDomain()
  }

  static func encodeMembersSnapshot(_ members: [Member]) -> Data? {
    let payload = RawMembersResponse(
      members: members.map { m in
        RawMember(
          id: m.id.rawValue,
          name: m.name,
          active: m.active,
          defaultWeight: m.defaultWeight,
          position: m.position,
          shape: m.shape.code,
          color: m.color.code,
          isMe: m.isMe,
          claimed: m.claimed
        )
      }
    )
    return try? JSONEncoder().encode(payload)
  }

  static func decodeResilientGroupUsers(from data: Data) throws -> [GroupUser] {
    try JSONDecoder().decode(RawGroupUsersResponse.self, from: data).users.map { $0.toDomain() }
  }

  static func encodeGroupUsersSnapshot(_ users: [GroupUser]) -> Data? {
    let payload = RawGroupUsersResponse(
      users: users.map { u in
        RawGroupUser(
          userId: u.userId.rawValue,
          name: u.name,
          role: u.role.code,
          memberId: u.memberId?.rawValue,
          isMe: u.isMe
        )
      }
    )
    return try? JSONEncoder().encode(payload)
  }
}
