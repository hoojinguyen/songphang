import Domain
import Foundation
import GeneratedAPI

enum NotificationsMapping {
  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  private struct RawPayload: Decodable {
    let kind: String?
    let actorName: String?
    let groupName: String?
    let description: String?
    let transactionId: String?
    let share: Int64?
    let action: String?
    let reason: String?
    let amount: Int64?
    let toName: String?
    let decision: String?
    let state: String?
  }

  static func mapNotification(_ dto: Components.Schemas.NotificationDto) -> AppNotification {
    let payloadData = try? JSONEncoder().encode(dto.payload)
    let raw = payloadData.flatMap { try? JSONDecoder().decode(RawPayload.self, from: $0) }

    let kind = raw?.kind ?? dto.kind
    let actor = raw?.actorName ?? ""
    let group = raw?.groupName ?? ""
    let desc = raw?.description ?? ""
    let txId = raw?.transactionId ?? ""
    let gId = ExpenseGroup.ID(dto.groupId)

    let payload: AppNotification.Payload
    let target: AppNotification.Target

    switch kind {
    case "expense_added":
      let share = Money(raw?.share ?? 0)
      payload = .expenseAdded(
        actorName: actor,
        groupName: group,
        transactionId: txId,
        description: desc,
        share: share
      )
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "expense_changed":
      let act = raw?.action ?? "edited"
      payload = .expenseChanged(
        actorName: actor,
        groupName: group,
        transactionId: txId,
        description: desc,
        action: act
      )
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "comment_added":
      payload = .commentAdded(
        actorName: actor, groupName: group, transactionId: txId, description: desc)
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "dispute_opened":
      payload = .disputeOpened(
        actorName: actor,
        groupName: group,
        transactionId: txId,
        description: desc,
        reason: raw?.reason ?? ""
      )
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "dispute_resolved":
      payload = .disputeResolved(
        actorName: actor, groupName: group, transactionId: txId, description: desc)
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "settlement_requested":
      let amount = Money(raw?.amount ?? 0)
      payload = .settlementRequested(actorName: actor, groupName: group, amount: amount)
      target = .balances(groupId: gId)

    case "settlement_confirmed":
      let amount = Money(raw?.amount ?? 0)
      payload = .settlementConfirmed(actorName: actor, groupName: group, amount: amount)
      target = .balances(groupId: gId)

    case "settlement_rejected":
      let amount = Money(raw?.amount ?? 0)
      payload = .settlementRejected(actorName: actor, groupName: group, amount: amount)
      target = .balances(groupId: gId)

    case "debt_reminder":
      let amount = Money(raw?.amount ?? 0)
      payload = .debtReminder(
        actorName: actor, groupName: group, toName: raw?.toName ?? "", amount: amount)
      target = .balances(groupId: gId)

    case "approval_requested":
      let amount = Money(raw?.amount ?? 0)
      payload = .approvalRequested(
        actorName: actor,
        groupName: group,
        transactionId: txId,
        description: desc,
        amount: amount
      )
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "approval_decided":
      let dec = raw?.decision ?? "approved"
      payload = .approvalDecided(
        actorName: actor,
        groupName: group,
        transactionId: txId,
        description: desc,
        decision: dec
      )
      target = txId.isEmpty ? .group(groupId: gId) : .transaction(groupId: gId, transactionId: txId)

    case "budget_state":
      let st = raw?.state ?? "near"
      payload = .budgetState(actorName: actor, groupName: group, state: st)
      target = .stats(groupId: gId)

    default:
      payload = .unknown(kind: kind, groupName: group.isEmpty ? nil : group)
      target = .group(groupId: gId)
    }

    return AppNotification(
      id: AppNotification.ID(dto.id),
      kind: kind,
      groupId: gId,
      groupName: group,
      read: dto.read,
      createdAt: formatISO(dto.createdAt),
      payload: payload,
      target: target
    )
  }

  static func mapSettings(_ dto: Components.Schemas.NotificationSettingsDto)
    -> NotificationSettings
  {
    NotificationSettings(
      emailImmediate: dto.emailImmediate,
      emailDigest: dto.emailDigest
    )
  }

  static func mapReminderResult(_ dto: Components.Schemas.SendReminderResponse)
    -> SendReminderResult
  {
    let reminded = dto.reminded.map {
      ReminderPair(
        fromMemberId: Member.ID($0.fromMemberId),
        toMemberId: Member.ID($0.toMemberId)
      )
    }
    let skipped = dto.skipped.map {
      SkippedReminder(
        fromMemberId: Member.ID($0.fromMemberId),
        toMemberId: Member.ID($0.toMemberId),
        reason: $0.reason.rawValue
      )
    }
    return SendReminderResult(reminded: reminded, skipped: skipped)
  }
}
