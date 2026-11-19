import Domain
import Foundation
import GeneratedAPI

enum InviteMapping {
  static func mapInvite(_ dto: Components.Schemas.InviteDto) -> Invite {
    Invite(token: dto.token, active: dto.active, url: dto.url)
  }

  static func mapPreview(_ dto: Components.Schemas.InvitePreviewResponse) -> InvitePreview {
    InvitePreview(
      groupId: ExpenseGroup.ID(dto.group.id),
      groupName: dto.group.name,
      ownerName: dto.ownerName,
      memberCount: dto.memberCount,
      transactionCount: dto.transactionCount,
      members: dto.members.map { m in
        InvitePreview.PreviewMember(
          id: Member.ID(m.id),
          name: m.name,
          shape: MemberShape(code: m.shape.rawValue),
          color: MemberColor(code: m.color.rawValue),
          claimed: m.claimed,
          balance: m.balance.map { Money(Int64($0)) }
        )
      },
      alreadyJoined: dto.alreadyJoined
    )
  }

  struct RawInvitePreview: Decodable, Sendable {
    struct RawGroup: Decodable, Sendable {
      let id: String
      let name: String
    }

    struct RawMember: Decodable, Sendable {
      let id: String
      let name: String
      let shape: String
      let color: String
      let claimed: Bool
      let balance: Int64?
    }

    let group: RawGroup
    let ownerName: String
    let memberCount: Int
    let transactionCount: Int
    let members: [RawMember]
    let alreadyJoined: Bool

    func toDomain() -> InvitePreview {
      InvitePreview(
        groupId: ExpenseGroup.ID(group.id),
        groupName: group.name,
        ownerName: ownerName,
        memberCount: memberCount,
        transactionCount: transactionCount,
        members: members.map { m in
          InvitePreview.PreviewMember(
            id: Member.ID(m.id),
            name: m.name,
            shape: MemberShape(code: m.shape),
            color: MemberColor(code: m.color),
            claimed: m.claimed,
            balance: m.balance.map { Money(Int64($0)) }
          )
        },
        alreadyJoined: alreadyJoined
      )
    }
  }

  static func decodeResilientPreview(from data: Data) throws -> InvitePreview {
    try JSONDecoder().decode(RawInvitePreview.self, from: data).toDomain()
  }
}
