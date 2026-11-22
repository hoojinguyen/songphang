import DesignSystem
public import Domain
import Foundation

public struct ActivityChangeChip: Sendable, Hashable, Identifiable {
  public var id: String { field }
  public let field: String
  public let before: String
  public let after: String
}

public struct ActivityTextPart: Sendable, Hashable, Identifiable {
  public let id: Int
  public let text: String
  public let bold: Bool
}

public struct ActivityDescription: Sendable, Hashable {
  public let parts: [ActivityTextPart]
  public let chips: [ActivityChangeChip]
}

public enum ActivitySentenceFormatter {
  public static func describe(
    entry: ActivityItem,
    members: [Member]
  ) -> ActivityDescription {
    let after = entry.after
    let before = entry.before
    let actorName = entry.actor?.name ?? L10n.tr("activity.someone")

    func memberName(_ id: Member.ID?) -> String {
      guard let id else { return L10n.tr("activity.someone") }
      return members.first(where: { $0.id == id })?.name ?? L10n.tr("activity.someone")
    }

    let amountValue: String = {
      if let amt = after?.amount ?? before?.amount {
        return MoneyFormat.full(amt)
      }
      return L10n.tr("common.pendingValue")
    }()

    let countValue: String = {
      if let mc = after?.memberCount {
        return String(mc)
      }
      return L10n.tr("common.pendingValue")
    }()

    var values: [String: String] = [
      "actor": actorName,
      "summary": entry.summary,
      "amount": amountValue,
      "count": countValue,
      "member": after?.name ?? entry.summary,
      "name": after?.name ?? L10n.tr("common.pendingValue"),
      "role": after?.role == .viewer
        ? L10n.tr("members.roleViewer")
        : L10n.tr("members.roleEditor"),
      "from": memberName(after?.payers?.first?.memberId),
      "to": memberName(after?.shares?.first?.memberId),
    ]

    var templates: [String] = []
    switch entry.entityType {
    case .transaction:
      switch entry.action {
      case "create":
        switch after?.transactionType {
        case .transfer:
          templates = [L10n.tr("activity.transfer")]
        case .income:
          templates = [L10n.tr("activity.income")]
        default:
          templates = [L10n.tr("activity.expense")]
        }
      case "update":
        templates = [L10n.tr("activity.edit")]
      case "delete":
        templates = [L10n.tr("activity.delete")]
      default:
        templates = [L10n.tr("activity.restore")]
      }

    case .group:
      if entry.action == "create" {
        templates = [L10n.tr("activity.groupCreate")]
      } else {
        if after?.name != nil {
          templates.append(L10n.tr("activity.groupName"))
        }
        if let minimize = after?.minimizeDebts {
          templates.append(
            minimize ? L10n.tr("activity.minimizeOn") : L10n.tr("activity.minimizeOff")
          )
        }
        if let defaultRole = after?.defaultRole {
          values["role"] =
            defaultRole == .viewer
            ? L10n.tr("members.roleViewer")
            : L10n.tr("members.roleEditor")
          templates.append(L10n.tr("activity.defaultRole"))
        }
        if let inviteActive = after?.inviteActive {
          templates.append(
            inviteActive ? L10n.tr("activity.inviteOn") : L10n.tr("activity.inviteOff")
          )
        }
        if after?.inviteRotated == true {
          templates.append(L10n.tr("activity.inviteRotate"))
        }
      }

    case .member:
      switch entry.action {
      case "create":
        templates = [L10n.tr("activity.memberAdd")]
      case "delete":
        templates = [L10n.tr("activity.memberDelete")]
      default:
        if let active = after?.active {
          templates = [
            active ? L10n.tr("activity.memberActive") : L10n.tr("activity.memberInactive")
          ]
        } else if after?.name != nil {
          templates = [L10n.tr("activity.memberName")]
        } else {
          templates = [L10n.tr("activity.memberWeight")]
        }
      }

    case .groupUser, .unknown:
      switch entry.action {
      case "join":
        templates = [L10n.tr("activity.join")]
      case "leave":
        templates = [L10n.tr("activity.leave")]
      case "remove":
        templates = [L10n.tr("activity.remove")]
      case "role_change":
        templates = [L10n.tr("activity.role")]
      case "transfer_ownership":
        templates = [L10n.tr("activity.ownership")]
      default:
        templates = [L10n.tr("activity.choose")]
      }
    }

    let joinedTemplate = templates.joined(separator: " · ")
    return ActivityDescription(
      parts: buildParts(template: joinedTemplate, values: values),
      chips: buildChips(entry: entry, members: members)
    )
  }

  private static func buildParts(
    template: String,
    values: [String: String]
  ) -> [ActivityTextPart] {
    var result: [ActivityTextPart] = []
    var currentIndex = template.startIndex
    var nextId = 0

    while currentIndex < template.endIndex {
      if let openBrace = template[currentIndex...].firstIndex(of: "{"),
        let closeBrace = template[openBrace...].firstIndex(of: "}")
      {
        if openBrace > currentIndex {
          let prefix = String(template[currentIndex..<openBrace])
          result.append(ActivityTextPart(id: nextId, text: prefix, bold: false))
          nextId += 1
        }
        let keyStart = template.index(after: openBrace)
        let key = String(template[keyStart..<closeBrace])
        let replacement = values[key] ?? ""
        result.append(ActivityTextPart(id: nextId, text: replacement, bold: true))
        nextId += 1
        currentIndex = template.index(after: closeBrace)
      } else {
        let remainder = String(template[currentIndex..<template.endIndex])
        result.append(ActivityTextPart(id: nextId, text: remainder, bold: false))
        break
      }
    }
    return result
  }

  private static func buildChips(
    entry: ActivityItem,
    members: [Member]
  ) -> [ActivityChangeChip] {
    guard entry.action == "update",
      let before = entry.before,
      let after = entry.after
    else {
      return []
    }

    func memberName(_ id: Member.ID) -> String {
      members.first(where: { $0.id == id })?.name ?? L10n.tr("activity.someone")
    }

    func formatMemberAmounts(_ list: [MemberAmount]) -> String {
      list.map { "\(memberName($0.memberId)) \(MoneyFormat.amount($0.amount))" }
        .joined(separator: " · ")
    }

    func formatSplit(_ split: SplitSpec) -> String {
      switch split {
      case .equal(let ids):
        return ids.map(memberName).joined(separator: " · ")
      case .exact(_, let entries, _):
        return entries.map { "\(memberName($0.memberId)) \(MoneyFormat.amount($0.amount))" }
          .joined(separator: " · ")
      case .shares(let entries):
        return entries.map { "\(memberName($0.memberId)) \($0.weight)" }
          .joined(separator: " · ")
      case .percent(let entries):
        return entries.map { "\(memberName($0.memberId)) \($0.percent)" }
          .joined(separator: " · ")
      case .items(let items, _):
        return items.map(\.name).joined(separator: " · ")
      }
    }

    func formatCategory(_ category: TransactionCategory) -> String {
      switch category {
      case .food: return L10n.tr("expenseForm.categories.food")
      case .transport: return L10n.tr("expenseForm.categories.transport")
      case .lodging: return L10n.tr("expenseForm.categories.lodging")
      case .shopping: return L10n.tr("expenseForm.categories.shopping")
      case .entertainment, .bills, .other, .unknown:
        return L10n.tr("expenseForm.categories.other")
      }
    }

    var chips: [ActivityChangeChip] = []

    if let beforeAmount = before.amount, let afterAmount = after.amount,
      beforeAmount != afterAmount
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.amount"),
          before: MoneyFormat.amount(beforeAmount),
          after: MoneyFormat.amount(afterAmount)
        )
      )
    }

    if let beforeDesc = before.description, let afterDesc = after.description,
      beforeDesc != afterDesc
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.description"),
          before: beforeDesc,
          after: afterDesc
        )
      )
    }

    if let beforeDate = before.occurredAt, let afterDate = after.occurredAt,
      beforeDate != afterDate
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.date"),
          before: beforeDate,
          after: afterDate
        )
      )
    }

    if let beforeCat = before.category, let afterCat = after.category,
      beforeCat != afterCat
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.category"),
          before: formatCategory(beforeCat),
          after: formatCategory(afterCat)
        )
      )
    }

    if let beforePayers = before.payers, let afterPayers = after.payers,
      beforePayers != afterPayers
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.payers"),
          before: formatMemberAmounts(beforePayers),
          after: formatMemberAmounts(afterPayers)
        )
      )
    }

    if let beforeShares = before.shares, let afterShares = after.shares,
      beforeShares != afterShares
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.split"),
          before: formatMemberAmounts(beforeShares),
          after: formatMemberAmounts(afterShares)
        )
      )
    } else if after.shares == nil,
      let beforeSplit = before.split, let afterSplit = after.split,
      beforeSplit != afterSplit
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.split"),
          before: formatSplit(beforeSplit),
          after: formatSplit(afterSplit)
        )
      )
    }

    if let beforeName = before.name, let afterName = after.name,
      beforeName != afterName
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("activity.description"),
          before: beforeName,
          after: afterName
        )
      )
    }

    if let beforeWeight = before.defaultWeight, let afterWeight = after.defaultWeight,
      beforeWeight != afterWeight
    {
      chips.append(
        ActivityChangeChip(
          field: L10n.tr("split.modeShares"),
          before: beforeWeight,
          after: afterWeight
        )
      )
    }

    return chips
  }
}
