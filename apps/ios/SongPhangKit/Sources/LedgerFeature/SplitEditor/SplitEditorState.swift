import DesignSystem
public import Domain
import Foundation

public enum SplitMethod: String, Sendable, CaseIterable, Hashable {
  case equal
  case exact
  case shares
  case percent

  public var modeLabel: String {
    switch self {
    case .equal: return L10n.tr("split.modeEqual")
    case .exact: return L10n.tr("split.modeExact")
    case .shares: return L10n.tr("split.modeShares")
    case .percent: return L10n.tr("split.modePercent")
    }
  }

  public var methodName: String {
    switch self {
    case .equal: return L10n.tr("split.methodEqual")
    case .exact: return L10n.tr("split.methodExact")
    case .shares: return L10n.tr("split.methodShares")
    case .percent: return L10n.tr("split.methodPercent")
    }
  }
}

public struct SplitStatusInfo: Sendable, Equatable {
  public let text: String
  public let matched: Bool

  public init(text: String, matched: Bool) {
    self.text = text
    self.matched = matched
  }
}

public struct SplitEditorState: Sendable, Equatable {
  public var method: SplitMethod
  public var ids: [Member.ID]
  public var values: [Member.ID: String]
  public var spread: Bool

  public init(members: [Member], initial: SplitSpec? = nil) {
    switch initial {
    case .equal(let memberIds):
      self.method = .equal
      self.ids = memberIds
      self.values = [:]
      self.spread = false
    case .exact(let memberIds, let entries, let remainder):
      self.method = .exact
      self.ids = memberIds
      var map: [Member.ID: String] = [:]
      for entry in entries {
        map[entry.memberId] = MoneyFormat.amount(entry.amount)
      }
      self.values = map
      self.spread = (remainder == .equalAmongAll)
    case .shares(let entries):
      self.method = .shares
      self.ids = entries.map(\.memberId)
      var map: [Member.ID: String] = [:]
      for entry in entries {
        map[entry.memberId] = entry.weight
      }
      self.values = map
      self.spread = false
    case .percent(let entries):
      self.method = .percent
      self.ids = entries.map(\.memberId)
      var map: [Member.ID: String] = [:]
      for entry in entries {
        map[entry.memberId] = entry.percent
      }
      self.values = map
      self.spread = false
    case nil:
      self.method = .equal
      self.ids = members.map(\.id)
      self.values = [:]
      self.spread = false
    }
  }

  public func selectedMembers(from members: [Member]) -> [Member] {
    members.filter { ids.contains($0.id) }
  }

  public func blankCount(from members: [Member]) -> Int {
    selectedMembers(from: members).filter { (values[$0.id] ?? "").isEmpty }.count
  }

  public func restAmount(from members: [Member], totalAmount: Money) -> Money {
    let selected = selectedMembers(from: members)
    let enteredSum = selected.reduce(Money.zero) { acc, member in
      acc + (MoneyFormat.parseInput(values[member.id] ?? "") ?? .zero)
    }
    return totalAmount - enteredSum
  }

  public func resolvedSplit(from members: [Member], totalAmount: Money) -> SplitSpec? {
    let selected = selectedMembers(from: members)
    guard !selected.isEmpty else { return nil }

    switch method {
    case .equal:
      return .equal(members: selected.map(\.id))

    case .exact:
      let blanks = blankCount(from: members)
      let rest = restAmount(from: members, totalAmount: totalAmount)
      guard !rest.isNegative, blanks > 0 || spread || rest.isZero else {
        return nil
      }
      var entries: [SplitSpec.ExactEntry] = []
      for member in selected {
        if let text = values[member.id], !text.isEmpty,
          let amt = MoneyFormat.parseInput(text)
        {
          entries.append(SplitSpec.ExactEntry(memberId: member.id, amount: amt))
        }
      }
      let remainderMode: ExactRemainderMode =
        blanks > 0
        ? .equalAmongBlank
        : (spread ? .equalAmongAll : .none)
      return .exact(
        members: selected.map(\.id),
        entries: entries,
        remainder: remainderMode
      )

    case .shares:
      let hasPositive = selected.contains { member in
        let raw = values[member.id] ?? member.defaultWeight
        return raw.contains(where: { $0 >= "1" && $0 <= "9" })
      }
      guard hasPositive else { return nil }
      let entries = selected.map { member in
        let raw = values[member.id] ?? member.defaultWeight
        return SplitSpec.ShareWeightEntry(
          memberId: member.id,
          weight: raw.isEmpty ? "0" : raw
        )
      }
      return .shares(entries: entries)

    case .percent:
      let sum = sumHundredths(from: members)
      guard sum == 10_000 else { return nil }
      let entries = selected.map { member in
        SplitSpec.PercentEntry(
          memberId: member.id,
          percent: values[member.id] ?? "0"
        )
      }
      return .percent(entries: entries)
    }
  }

  public func status(from members: [Member], totalAmount: Money) -> SplitStatusInfo {
    let split = resolvedSplit(from: members, totalAmount: totalAmount)
    let matched = (split != nil)

    if method == .percent {
      let sum = sumHundredths(from: members)
      if sum == 10_000 {
        return SplitStatusInfo(text: L10n.tr("split.percentMatch"), matched: true)
      }
      let diff = abs(10_000 - sum)
      let key = sum < 10_000 ? "split.percentShort" : "split.percentOver"
      return SplitStatusInfo(
        text: L10n.t(key, ["percent": Self.formatHundredths(diff)]),
        matched: false
      )
    }

    let rest = restAmount(from: members, totalAmount: totalAmount)
    let blanks = blankCount(from: members)
    if method == .exact && rest.isNegative {
      return SplitStatusInfo(
        text: L10n.t("split.over", ["amount": MoneyFormat.full(rest.magnitude)]),
        matched: false
      )
    }
    if method == .exact && blanks > 0 {
      return SplitStatusInfo(
        text: L10n.t(
          "split.blankShare",
          [
            "amount": MoneyFormat.full(rest),
            "count": String(blanks),
          ]
        ),
        matched: matched
      )
    }
    if !matched {
      let shortAmount = rest.isPositive ? rest : .zero
      return SplitStatusInfo(
        text: L10n.t("split.short", ["amount": MoneyFormat.full(shortAmount)]),
        matched: false
      )
    }
    return SplitStatusInfo(
      text: L10n.t("split.match", ["amount": MoneyFormat.full(totalAmount)]),
      matched: true
    )
  }

  public mutating func changeMode(_ next: SplitMethod, members: [Member]) {
    method = next
    spread = false
    if next == .shares {
      var map: [Member.ID: String] = [:]
      for member in selectedMembers(from: members) {
        map[member.id] = member.defaultWeight
      }
      values = map
    } else {
      values = [:]
    }
  }

  public mutating func setValue(_ value: String, for memberId: Member.ID) {
    values[memberId] = value
  }

  public mutating func toggle(_ memberId: Member.ID, members: [Member]) {
    if ids.contains(memberId) {
      ids.removeAll { $0 == memberId }
    } else {
      ids = members.filter { ids.contains($0.id) || $0.id == memberId }.map(\.id)
    }
    values.removeValue(forKey: memberId)
  }

  private func sumHundredths(from members: [Member]) -> Int {
    selectedMembers(from: members).reduce(0) { acc, member in
      acc + (Self.parseHundredths(values[member.id] ?? "") ?? 0)
    }
  }

  private static func parseHundredths(_ raw: String) -> Int? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count <= 2 else { return nil }
    let wholePart = String(parts[0])
    guard !wholePart.isEmpty, wholePart.count <= 3,
      wholePart.allSatisfy({ $0.isWholeNumber && $0.isASCII })
    else { return nil }
    let fracPart = parts.count == 2 ? String(parts[1]) : ""
    guard fracPart.count <= 2,
      fracPart.allSatisfy({ $0.isWholeNumber && $0.isASCII })
    else { return nil }
    let paddedFrac: String
    switch fracPart.count {
    case 0: paddedFrac = "00"
    case 1: paddedFrac = fracPart + "0"
    default: paddedFrac = fracPart
    }
    return Int(wholePart + paddedFrac)
  }

  private static func formatHundredths(_ value: Int) -> String {
    let raw = String(abs(value))
    let padded: String
    switch raw.count {
    case 1: padded = "00" + raw
    case 2: padded = "0" + raw
    default: padded = raw
    }
    let whole = String(padded.dropLast(2))
    let frac = String(padded.suffix(2))
    if frac == "00" {
      return whole
    }
    if frac.hasSuffix("0") {
      return "\(whole).\(frac.dropLast())"
    }
    return "\(whole).\(frac)"
  }
}
