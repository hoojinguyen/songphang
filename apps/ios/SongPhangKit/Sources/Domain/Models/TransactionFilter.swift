import Foundation

public struct TransactionFilter: Sendable, Hashable {
  public var query: String?
  public var memberId: Member.ID?
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var uncategorized: Bool
  public var spendingOnly: Bool
  public var type: TransactionType?
  public var from: String?
  public var to: String?

  public init(
    query: String? = nil,
    memberId: Member.ID? = nil,
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    uncategorized: Bool = false,
    spendingOnly: Bool = false,
    type: TransactionType? = nil,
    from: String? = nil,
    to: String? = nil
  ) {
    let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.query = (trimmedQuery?.isEmpty == false) ? trimmedQuery : nil
    self.memberId = memberId

    if let categoryId {
      self.category = nil
      self.categoryId = categoryId
      self.uncategorized = false
    } else if let category {
      self.category = category
      self.categoryId = nil
      self.uncategorized = false
    } else {
      self.category = nil
      self.categoryId = nil
      self.uncategorized = uncategorized
    }

    self.type = type
    self.spendingOnly = (type == .transfer) ? false : spendingOnly
    let trimmedFrom = from?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTo = to?.trimmingCharacters(in: .whitespacesAndNewlines)
    let candidateFrom = (trimmedFrom?.isEmpty == false) ? trimmedFrom : nil
    let candidateTo = (trimmedTo?.isEmpty == false) ? trimmedTo : nil

    var validFrom: String?
    var validTo: String?
    if let candidateFrom, let candidateTo {
      if Self.parseCalendarDateParts(candidateFrom) != nil,
        Self.parseCalendarDateParts(candidateTo) != nil,
        Self.isWithinFiveYears(from: candidateFrom, to: candidateTo)
      {
        validFrom = candidateFrom
        validTo = candidateTo
      }
    } else if let candidateFrom {
      if Self.parseCalendarDateParts(candidateFrom) != nil {
        validFrom = candidateFrom
      }
    } else if let candidateTo {
      if Self.parseCalendarDateParts(candidateTo) != nil {
        validTo = candidateTo
      }
    }
    self.from = validFrom
    self.to = validTo
  }

  private static func parseCalendarDateParts(_ value: String) -> (year: Int, month: Int, day: Int)?
  {
    let parts = value.split(separator: "-")
    guard parts.count == 3,
      parts[0].count == 4,
      parts[1].count == 2,
      parts[2].count == 2,
      let y = Int(parts[0]),
      let m = Int(parts[1]),
      let d = Int(parts[2]),
      y >= 2000, y <= 2100,
      m >= 1, m <= 12,
      d >= 1, d <= 31
    else { return nil }
    var calendar = Calendar(identifier: .gregorian)
    if let tz = TimeZone(identifier: "Asia/Ho_Chi_Minh") {
      calendar.timeZone = tz
    }
    let comps = DateComponents(year: y, month: m, day: d)
    guard let date = calendar.date(from: comps) else { return nil }
    let backComps = calendar.dateComponents([.year, .month, .day], from: date)
    guard backComps.year == y, backComps.month == m, backComps.day == d else { return nil }
    return (year: y, month: m, day: d)
  }

  private static func isWithinFiveYears(from: String, to: String) -> Bool {
    guard let start = parseCalendarDateParts(from),
      parseCalendarDateParts(to) != nil
    else { return false }
    if from > to { return false }
    let maxYear = start.year + 5
    let limit = String(format: "%04d-%02d-%02d", maxYear, start.month, start.day)
    return to <= limit
  }

  public var isEmpty: Bool {
    query == nil && !hasModalFilters
  }

  public var hasModalFilters: Bool {
    memberId != nil
      || category != nil
      || categoryId != nil
      || uncategorized
      || spendingOnly
      || type != nil
      || from != nil
      || to != nil
  }
}
