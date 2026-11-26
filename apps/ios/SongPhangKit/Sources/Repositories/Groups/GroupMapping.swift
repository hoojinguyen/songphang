import Domain
import Foundation
import GeneratedAPI

enum GroupMapping {
  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapSummary(_ dto: Components.Schemas.GroupSummaryDto) -> ExpenseGroup {
    ExpenseGroup(
      id: ExpenseGroup.ID(dto.id),
      name: dto.name,
      currency: dto.currency.rawValue,
      memberCount: dto.memberCount,
      previewMembers: dto.previewMembers.map { preview in
        ExpenseGroup.PreviewMember(
          id: Member.ID(preview.id),
          name: preview.name,
          shape: MemberShape(code: preview.shape.rawValue),
          color: MemberColor(code: preview.color.rawValue)
        )
      },
      myBalance: Money(Int64(dto.myBalance)),
      myIndividualBalance: dto.myIndividualBalance.map { Money(Int64($0)) },
      householdName: dto.householdName,
      role: dto.role.map { Role(code: $0.rawValue) } ?? .editor,
      archivedAt: dto.archivedAt,
      pendingActionCount: dto.pendingActionCount ?? 0
    )
  }

  private struct ReminderIntervalEnvelope: Decodable {
    struct Group: Decodable {
      let reminderIntervalDays: Int?
    }
    let group: Group
  }

  static func extractReminderIntervalDays(from data: Data?) -> Int? {
    guard let data,
      let decoded = try? JSONDecoder().decode(ReminderIntervalEnvelope.self, from: data)
    else {
      return nil
    }
    return decoded.group.reminderIntervalDays
  }

  static func mapDetail(
    _ dto: Components.Schemas.GroupDto,
    reminderIntervalDays: Int? = nil
  ) -> ExpenseGroup {
    ExpenseGroup(
      id: ExpenseGroup.ID(dto.id),
      name: dto.name,
      currency: dto.currency.rawValue,
      memberCount: 0,
      previewMembers: [],
      myBalance: .zero,
      minimizeDebts: dto.minimizeDebts,
      defaultRole: Role(code: dto.defaultRole.rawValue),
      role: Role(code: dto.role.rawValue),
      myMemberId: dto.myMemberId.map(Member.ID.init),
      muted: dto.muted,
      reminderIntervalDays: reminderIntervalDays,
      approvalThreshold: dto.approvalThreshold.map { Money(Int64($0)) },
      ownerName: dto.ownerName,
      createdAt: formatISO(dto.createdAt),
      archivedAt: dto.archivedAt,
      pendingActionCount: 0
    )
  }

  // MARK: - Resilient snapshot & unknown-enum decoders

  struct RawPreviewMember: Codable, Sendable {
    let id: String
    let name: String
    let shape: String
    let color: String
  }

  struct RawGroupSummary: Codable, Sendable {
    let id: String
    let name: String
    let currency: String
    let memberCount: Int
    let previewMembers: [RawPreviewMember]
    let myBalance: Int64
    let myIndividualBalance: Int64?
    let householdName: String?
    let role: String?
    let archivedAt: String?
    let pendingActionCount: Int?

    func toDomain() -> ExpenseGroup {
      ExpenseGroup(
        id: ExpenseGroup.ID(id),
        name: name,
        currency: currency,
        memberCount: memberCount,
        previewMembers: previewMembers.map { p in
          ExpenseGroup.PreviewMember(
            id: Member.ID(p.id),
            name: p.name,
            shape: MemberShape(code: p.shape),
            color: MemberColor(code: p.color)
          )
        },
        myBalance: Money(myBalance),
        myIndividualBalance: myIndividualBalance.map(Money.init),
        householdName: householdName,
        role: role.map { Role(code: $0) } ?? .editor,
        archivedAt: archivedAt.flatMap(ISO8601Support.parse),
        pendingActionCount: pendingActionCount ?? 0
      )
    }
  }

  struct RawGroupsResponse: Codable, Sendable {
    let groups: [RawGroupSummary]
  }

  struct RawGroupDetail: Codable, Sendable {
    let id: String
    let name: String
    let currency: String
    let minimizeDebts: Bool
    let defaultRole: String
    let role: String
    let myMemberId: String?
    let muted: Bool?
    let reminderIntervalDays: Int?
    let approvalThreshold: Int64?
    let ownerName: String?
    let createdAt: String
    let archivedAt: String?

    func toDomain() -> ExpenseGroup {
      ExpenseGroup(
        id: ExpenseGroup.ID(id),
        name: name,
        currency: currency,
        memberCount: 0,
        previewMembers: [],
        myBalance: .zero,
        minimizeDebts: minimizeDebts,
        defaultRole: Role(code: defaultRole),
        role: Role(code: role),
        myMemberId: myMemberId.map(Member.ID.init),
        muted: muted ?? false,
        reminderIntervalDays: reminderIntervalDays,
        approvalThreshold: approvalThreshold.map(Money.init),
        ownerName: ownerName ?? "",
        createdAt: createdAt,
        archivedAt: archivedAt.flatMap(ISO8601Support.parse),
        pendingActionCount: 0
      )
    }
  }

  struct RawGroupResponse: Codable, Sendable {
    let group: RawGroupDetail
  }

  static func decodeResilientGroups(from data: Data) throws -> [ExpenseGroup] {
    try JSONDecoder().decode(RawGroupsResponse.self, from: data).groups.map { $0.toDomain() }
  }

  static func encodeGroupsSnapshot(_ groups: [ExpenseGroup]) -> Data? {
    let payload = RawGroupsResponse(
      groups: groups.map { g in
        RawGroupSummary(
          id: g.id.rawValue,
          name: g.name,
          currency: g.currency,
          memberCount: g.memberCount,
          previewMembers: g.previewMembers.map { p in
            RawPreviewMember(
              id: p.id.rawValue,
              name: p.name,
              shape: p.shape.code,
              color: p.color.code
            )
          },
          myBalance: g.myBalance.amount,
          myIndividualBalance: g.myIndividualBalance?.amount,
          householdName: g.householdName,
          role: g.role.code,
          archivedAt: g.archivedAt.map { formatISO($0) },
          pendingActionCount: g.pendingActionCount
        )
      }
    )
    return try? JSONEncoder().encode(payload)
  }

  static func decodeResilientGroup(from data: Data) throws -> ExpenseGroup {
    try JSONDecoder().decode(RawGroupResponse.self, from: data).group.toDomain()
  }

  static func encodeGroupSnapshot(_ group: ExpenseGroup) -> Data? {
    let payload = RawGroupResponse(
      group: RawGroupDetail(
        id: group.id.rawValue,
        name: group.name,
        currency: group.currency,
        minimizeDebts: group.minimizeDebts,
        defaultRole: group.defaultRole.code,
        role: group.role.code,
        myMemberId: group.myMemberId?.rawValue,
        muted: group.muted,
        reminderIntervalDays: group.reminderIntervalDays,
        approvalThreshold: group.approvalThreshold?.amount,
        ownerName: group.ownerName,
        createdAt: group.createdAt,
        archivedAt: group.archivedAt.map { formatISO($0) }
      )
    )
    return try? JSONEncoder().encode(payload)
  }
}
