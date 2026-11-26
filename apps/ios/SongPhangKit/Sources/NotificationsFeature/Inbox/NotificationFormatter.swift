import DesignSystem
public import Domain
import Foundation

public enum NotificationFormatter {
  public static func formatText(_ notification: AppNotification) -> String {
    let group = notification.groupName
    switch notification.payload {
    case .expenseAdded(let actor, _, _, let desc, let share):
      return L10n.t(
        "notifications.expenseAdded",
        [
          "actor": actor,
          "description": desc,
          "share": MoneyFormat.full(share),
        ])

    case .expenseChanged(let actor, _, _, let desc, let action):
      if action == "deleted" {
        return L10n.t(
          "notifications.expenseDeleted",
          [
            "actor": actor,
            "description": desc,
          ])
      } else {
        return L10n.t(
          "notifications.expenseEdited",
          [
            "actor": actor,
            "description": desc,
          ])
      }

    case .commentAdded(let actor, _, _, let desc):
      return L10n.t(
        "notifications.commentAdded",
        [
          "actor": actor,
          "description": desc,
        ])

    case .disputeOpened(let actor, _, _, let desc, _):
      return L10n.t(
        "notifications.disputeOpened",
        [
          "actor": actor,
          "description": desc,
        ])

    case .disputeResolved(let actor, _, _, let desc):
      return L10n.t(
        "notifications.disputeResolved",
        [
          "actor": actor,
          "description": desc,
        ])

    case .settlementRequested(let actor, _, let amount):
      return L10n.t(
        "notifications.settlementRequested",
        [
          "actor": actor,
          "amount": MoneyFormat.full(amount),
        ])

    case .settlementConfirmed(let actor, _, let amount):
      return L10n.t(
        "notifications.settlementConfirmed",
        [
          "actor": actor,
          "amount": MoneyFormat.full(amount),
        ])

    case .settlementRejected(let actor, _, let amount):
      return L10n.t(
        "notifications.settlementRejected",
        [
          "actor": actor,
          "amount": MoneyFormat.full(amount),
        ])

    case .debtReminder(_, _, let toName, let amount):
      return L10n.t(
        "notifications.debtReminder",
        [
          "to": toName,
          "amount": MoneyFormat.full(amount),
          "group": group,
        ])

    case .approvalRequested(let actor, _, _, let desc, let amount):
      return L10n.t(
        "notifications.approvalRequested",
        [
          "actor": actor,
          "description": desc,
          "amount": MoneyFormat.full(amount),
        ])

    case .approvalDecided(let actor, _, _, let desc, let decision):
      if decision == "approved" {
        return L10n.t(
          "notifications.approvalApproved",
          [
            "actor": actor,
            "description": desc,
          ])
      } else {
        return L10n.t(
          "notifications.approvalRejected",
          [
            "actor": actor,
            "description": desc,
          ])
      }

    case .budgetState(_, _, let state):
      if state == "over" {
        return L10n.t("notifications.budgetOver", ["group": group])
      } else {
        return L10n.t("notifications.budgetNear", ["group": group])
      }

    case .recurringPosted(let groupName, _, let desc, let amount, let share):
      let resolvedGroup = groupName.isEmpty ? group : groupName
      if let share {
        return
          "Khoản định kỳ \(desc) · \(MoneyFormat.full(amount)) (phần bạn \(MoneyFormat.full(share)))"
      } else {
        return
          "Khoản định kỳ \(desc) · \(MoneyFormat.full(amount)) đã được ghi vào \(resolvedGroup)"
      }

    case .recurringDue(let groupName, _, let desc, _):
      let resolvedGroup = groupName.isEmpty ? group : groupName
      return "\(L10n.t("recurring.overviewDueTemplate", ["description": desc])) (\(resolvedGroup))"

    case .unknown:
      return L10n.t("notifications.fallback", ["group": group])
    }
  }

  public static func formatDateTime(_ isoString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var date = formatter.date(from: isoString)
    if date == nil {
      formatter.formatOptions = [.withInternetDateTime]
      date = formatter.date(from: isoString)
    }
    guard let date else { return isoString }

    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

    if let day = components.day, day >= 1 {
      let printFormatter = DateFormatter()
      printFormatter.locale = Locale(identifier: "vi_VN")
      printFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
      printFormatter.dateFormat = "HH:mm dd/MM"
      return printFormatter.string(from: date)
    } else if let hour = components.hour, hour >= 1 {
      return "\(hour) giờ trước"
    } else if let minute = components.minute, minute >= 1 {
      return "\(minute) phút trước"
    } else {
      return "vừa xong"
    }
  }
}
