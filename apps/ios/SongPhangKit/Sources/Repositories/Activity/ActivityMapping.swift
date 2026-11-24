import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

enum ActivityMapping {
  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapItem(
    _ dto: Components.Schemas.ActivityResponse.activityPayloadPayload
  ) -> ActivityItem {
    ActivityItem(
      id: ActivityItem.ID(dto.id),
      actor: dto.actor.map {
        ActivityItem.Actor(
          userId: User.ID($0.userId),
          name: $0.name,
          memberId: $0.memberId.map(Member.ID.init)
        )
      },
      action: dto.action,
      entityType: ActivityItem.EntityType(code: dto.entityType.rawValue),
      entityId: dto.entityId,
      summary: dto.summary,
      before: dto.before.map { mapSnapshotValues($0.additionalProperties) },
      after: dto.after.map { mapSnapshotValues($0.additionalProperties) },
      createdAt: formatISO(dto.createdAt),
      canRestore: dto.canRestore
    )
  }

  private static func mapSnapshotValues(
    _ dict: [String: OpenAPIValueContainer]
  ) -> ActivityItem.SnapshotValues {
    var result = ActivityItem.SnapshotValues()
    if let s = dict["type"]?.value as? String {
      result.transactionType = TransactionType(code: s)
    }
    if let i = dict["amount"]?.value as? Int {
      result.amount = Money(Int64(i))
    }
    if let s = dict["description"]?.value as? String {
      result.description = s
    }
    if let s = dict["occurredAt"]?.value as? String {
      result.occurredAt = s
    }
    if let s = dict["category"]?.value as? String, !s.isEmpty {
      result.category = TransactionCategory(code: s)
    }
    if let s = dict["name"]?.value as? String {
      result.name = s
    }
    if let s = dict["defaultWeight"]?.value as? String {
      result.defaultWeight = s
    }
    if let b = dict["active"]?.value as? Bool {
      result.active = b
    }
    if let s = dict["role"]?.value as? String {
      result.role = Role(code: s)
    }
    if let s = dict["defaultRole"]?.value as? String {
      result.defaultRole = Role(code: s)
    }
    if let b = dict["minimizeDebts"]?.value as? Bool {
      result.minimizeDebts = b
    }
    if let b = dict["inviteActive"]?.value as? Bool {
      result.inviteActive = b
    }
    if let b = dict["inviteRotated"]?.value as? Bool {
      result.inviteRotated = b
    }
    if let i = dict["memberCount"]?.value as? Int {
      result.memberCount = i
    }
    if let rawPayers = dict["payers"]?.value as? [[String: Any]] {
      result.payers = mapRawMemberAmounts(rawPayers)
    }
    if let rawShares = dict["shares"]?.value as? [[String: Any]] {
      result.shares = mapRawMemberAmounts(rawShares)
    }
    return result
  }

  private static func mapRawMemberAmounts(_ items: [[String: Any]]) -> [MemberAmount] {
    items.compactMap { entry in
      guard let memberId = entry["memberId"] as? String,
        let amount = entry["amount"] as? Int
      else { return nil }
      return MemberAmount(memberId: Member.ID(memberId), amount: Money(Int64(amount)))
    }
  }

  // MARK: - Resilient snapshot & unknown-enum decoders

  struct RawActor: Codable, Sendable {
    let userId: String
    let name: String
    let memberId: String?
  }

  struct RawSnapshotValues: Codable, Sendable {
    let type: String?
    let amount: Int64?
    let description: String?
    let occurredAt: String?
    let category: String?
    let payers: [TransactionMapping.RawMemberAmount]?
    let shares: [TransactionMapping.RawMemberAmount]?
    let name: String?
    let defaultWeight: String?
    let active: Bool?
    let role: String?
    let defaultRole: String?
    let minimizeDebts: Bool?
    let inviteActive: Bool?
    let inviteRotated: Bool?
    let memberCount: Int?

    init(values: ActivityItem.SnapshotValues) {
      self.type = values.transactionType?.code
      self.amount = values.amount?.amount
      self.description = values.description
      self.occurredAt = values.occurredAt
      self.category = values.category?.code
      self.payers = values.payers?.map {
        TransactionMapping.RawMemberAmount(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
      }
      self.shares = values.shares?.map {
        TransactionMapping.RawMemberAmount(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
      }
      self.name = values.name
      self.defaultWeight = values.defaultWeight
      self.active = values.active
      self.role = values.role?.code
      self.defaultRole = values.defaultRole?.code
      self.minimizeDebts = values.minimizeDebts
      self.inviteActive = values.inviteActive
      self.inviteRotated = values.inviteRotated
      self.memberCount = values.memberCount
    }

    func toDomain() -> ActivityItem.SnapshotValues {
      ActivityItem.SnapshotValues(
        transactionType: type.map(TransactionType.init(code:)),
        amount: amount.map(Money.init),
        description: description,
        occurredAt: occurredAt,
        category: TransactionMapping.mapCategory(category),
        payers: payers?.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        },
        shares: shares?.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        },
        name: name,
        defaultWeight: defaultWeight,
        active: active,
        role: role.map(Role.init(code:)),
        defaultRole: defaultRole.map(Role.init(code:)),
        minimizeDebts: minimizeDebts,
        inviteActive: inviteActive,
        inviteRotated: inviteRotated,
        memberCount: memberCount
      )
    }
  }

  struct RawActivityItem: Codable, Sendable {
    let id: String
    let actor: RawActor?
    let action: String
    let entityType: String
    let entityId: String?
    let summary: String
    let before: RawSnapshotValues?
    let after: RawSnapshotValues?
    let createdAt: String
    let canRestore: Bool

    init(item: ActivityItem) {
      self.id = item.id.rawValue
      self.actor = item.actor.map {
        RawActor(userId: $0.userId.rawValue, name: $0.name, memberId: $0.memberId?.rawValue)
      }
      self.action = item.action
      self.entityType = {
        switch item.entityType {
        case .transaction: return "transaction"
        case .member: return "member"
        case .group: return "group"
        case .groupUser: return "group_user"
        case .unknown(let raw): return raw
        }
      }()
      self.entityId = item.entityId
      self.summary = item.summary
      self.before = item.before.map(RawSnapshotValues.init)
      self.after = item.after.map(RawSnapshotValues.init)
      self.createdAt = item.createdAt
      self.canRestore = item.canRestore
    }

    func toDomain() -> ActivityItem {
      ActivityItem(
        id: ActivityItem.ID(id),
        actor: actor.map {
          ActivityItem.Actor(
            userId: User.ID($0.userId),
            name: $0.name,
            memberId: $0.memberId.map(Member.ID.init)
          )
        },
        action: action,
        entityType: ActivityItem.EntityType(code: entityType),
        entityId: entityId,
        summary: summary,
        before: before?.toDomain(),
        after: after?.toDomain(),
        createdAt: createdAt,
        canRestore: canRestore
      )
    }
  }

  struct RawActivityPage: Codable, Sendable {
    let activity: [RawActivityItem]
    let nextCursor: String?
  }

  static func decodeResilientPage(from data: Data) throws -> Page<ActivityItem> {
    let raw = try JSONDecoder().decode(RawActivityPage.self, from: data)
    return Page(items: raw.activity.map { $0.toDomain() }, nextCursor: raw.nextCursor)
  }

  static func encodePageSnapshot(_ page: Page<ActivityItem>) -> Data? {
    let payload = RawActivityPage(
      activity: page.items.map(RawActivityItem.init),
      nextCursor: page.nextCursor
    )
    return try? JSONEncoder().encode(payload)
  }
}
