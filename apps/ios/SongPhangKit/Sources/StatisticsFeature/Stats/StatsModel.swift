public import Domain
public import Foundation
public import Observation

@Observable
public final class StatsModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var categories: [GroupCategory]
    public var budget: GroupBudget?
    public var stats: GroupStats
    public var periodRange: DateRange
  }

  public struct DateRange: Sendable, Equatable {
    public let from: String?
    public let to: String?

    public init(from: String? = nil, to: String? = nil) {
      self.from = from
      self.to = to
    }
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isRefreshingPeriod = false
  public private(set) var isExportingCSV = false
  public private(set) var exportError: AppError?

  public var period: StatsPeriod = .all
  public var customFromDate: Date
  public var customToDate: Date

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let categoriesRepository: any CategoriesRepository
  private let budgetRepository: any BudgetRepository
  private let statisticsRepository: any StatisticsRepository
  private let onUnauthorized: () -> Void

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    categoriesRepository: any CategoriesRepository,
    budgetRepository: any BudgetRepository,
    statisticsRepository: any StatisticsRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.categoriesRepository = categoriesRepository
    self.budgetRepository = budgetRepository
    self.statisticsRepository = statisticsRepository
    self.onUnauthorized = onUnauthorized
    let monthBounds = StatsDateHelper.currentMonthDates()
    self.customFromDate = monthBounds.start
    self.customToDate = monthBounds.end
  }

  public var isOffline: Bool {
    if refreshError == .offline { return true }
    if case .failed(.offline) = state { return true }
    return false
  }

  public func load() async {
    if case .failed = state {
      state = .loading
    }
    let range = activeRange()
    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedCategories = categoriesRepository.list(groupId: groupId)
      async let fetchedBudget = budgetRepository.budget(groupId: groupId)
      async let fetchedStats = statisticsRepository.stats(
        groupId: groupId,
        from: range.from,
        to: range.to
      )
      let (g, m, c, b, s) = try await (
        fetchedGroup,
        fetchedMembers,
        fetchedCategories,
        fetchedBudget,
        fetchedStats
      )
      state = .loaded(
        ScreenData(
          group: g,
          members: m,
          categories: c,
          budget: b,
          stats: s,
          periodRange: range
        )
      )
      refreshError = nil
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      if case .loaded = state {
        refreshError = error
      } else {
        state = .failed(error)
      }
    } catch {
      if case .loaded = state {
        refreshError = .unexpected
      } else {
        state = .failed(.unexpected)
      }
    }
  }

  public func selectPeriod(_ next: StatsPeriod) async {
    period = next
    await refreshStatsOnly()
  }

  public func applyCustomDates() async {
    guard period == .custom else { return }
    if customToDate < customFromDate {
      customToDate = customFromDate
    }
    await refreshStatsOnly()
  }

  public func filterForCategory(_ entry: CategoryStat, range: DateRange) -> TransactionFilter {
    if let cat = entry.category {
      return TransactionFilter(
        category: cat,
        spendingOnly: true,
        from: range.from,
        to: range.to
      )
    }
    if let categoryId = entry.categoryId {
      return TransactionFilter(
        categoryId: categoryId,
        spendingOnly: true,
        from: range.from,
        to: range.to
      )
    }
    return TransactionFilter(
      uncategorized: true,
      spendingOnly: true,
      from: range.from,
      to: range.to
    )
  }

  public func filterForMember(_ entry: MemberStat, range: DateRange) -> TransactionFilter {
    TransactionFilter(
      memberId: entry.memberId,
      spendingOnly: true,
      from: range.from,
      to: range.to
    )
  }

  public func filterForBucket(
    _ entry: TimeBucketStat,
    bucketType: StatsBucket,
    range: DateRange
  ) -> TransactionFilter {
    let clamped = StatsDateHelper.clampedBucketRange(
      start: entry.start,
      bucket: bucketType,
      periodRange: range
    )
    return TransactionFilter(
      spendingOnly: true,
      from: clamped.from,
      to: clamped.to
    )
  }

  public func exportCSVFile() async -> URL? {
    guard !isExportingCSV else { return nil }
    isExportingCSV = true
    exportError = nil
    defer { isExportingCSV = false }
    do {
      let data = try await statisticsRepository.exportCSV(groupId: groupId)
      let fileName = "songphang-\(groupId.rawValue)-\(UUID().uuidString.prefix(8)).csv"
      let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try await Task.detached(priority: .userInitiated) {
        try data.write(
          to: fileURL,
          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
      }.value
      return fileURL
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return nil
      }
      exportError = error
      return nil
    } catch {
      exportError = .unexpected
      return nil
    }
  }

  private func refreshStatsOnly() async {
    guard case .loaded(var current) = state else {
      await load()
      return
    }
    isRefreshingPeriod = true
    defer { isRefreshingPeriod = false }
    let range = activeRange()
    do throws(AppError) {
      let nextStats = try await statisticsRepository.stats(
        groupId: groupId,
        from: range.from,
        to: range.to
      )
      current.stats = nextStats
      current.periodRange = range
      state = .loaded(current)
      refreshError = nil
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      refreshError = error
    }
  }

  private func activeRange() -> DateRange {
    switch period {
    case .all:
      return DateRange()
    case .thisMonth:
      let bounds = StatsDateHelper.currentMonthRange()
      return DateRange(from: bounds.from, to: bounds.to)
    case .lastMonth:
      let bounds = StatsDateHelper.previousMonthRange()
      return DateRange(from: bounds.from, to: bounds.to)
    case .custom:
      let from = StatsDateHelper.formatCalendarDate(customFromDate)
      let to = StatsDateHelper.formatCalendarDate(customToDate)
      guard StatsDateHelper.isWithinFiveYears(from: from, to: to) else {
        return DateRange()
      }
      return DateRange(from: from, to: to)
    }
  }
}

enum StatsDateHelper {
  private static var gregorian: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    return cal
  }

  static func formatCalendarDate(_ date: Date) -> String {
    let comps = gregorian.dateComponents([.year, .month, .day], from: date)
    let y = comps.year ?? 2026
    let m = comps.month ?? 1
    let d = comps.day ?? 1
    return String(format: "%04d-%02d-%02d", y, m, d)
  }

  static func currentMonthDates(now: Date = Date()) -> (start: Date, end: Date) {
    let cal = gregorian
    let comps = cal.dateComponents([.year, .month], from: now)
    let start = cal.date(from: comps) ?? now
    let range = cal.range(of: .day, in: .month, for: start)
    let lastDay = range?.upperBound.advanced(by: -1) ?? 28
    var endComps = comps
    endComps.day = lastDay
    let end = cal.date(from: endComps) ?? now
    return (start, end)
  }

  static func currentMonthRange(now: Date = Date()) -> (from: String, to: String) {
    let dates = currentMonthDates(now: now)
    return (formatCalendarDate(dates.start), formatCalendarDate(dates.end))
  }

  static func previousMonthRange(now: Date = Date()) -> (from: String, to: String) {
    let cal = gregorian
    let currentStart = currentMonthDates(now: now).start
    let prevDate = cal.date(byAdding: .month, value: -1, to: currentStart) ?? now
    let prevDates = currentMonthDates(now: prevDate)
    return (formatCalendarDate(prevDates.start), formatCalendarDate(prevDates.end))
  }

  static func isWithinFiveYears(from: String, to: String) -> Bool {
    guard from <= to,
      let fromDate = parseYYYYMMDD(from),
      let toDate = parseYYYYMMDD(to),
      let limitDate = gregorian.date(byAdding: .year, value: 5, to: fromDate)
    else {
      return false
    }
    return toDate <= limitDate
  }

  static func formatBucketLabel(start: String, bucket: StatsBucket) -> String {
    let parts = start.split(separator: "-")
    guard parts.count == 3 else { return start }
    let year = parts[0]
    let month = parts[1]
    let day = parts[2]
    if bucket == .month {
      return "\(month)/\(year)"
    }
    return "\(day)/\(month)"
  }

  static func clampedBucketRange(
    start: String,
    bucket: StatsBucket,
    periodRange: StatsModel.DateRange
  ) -> (from: String, to: String) {
    let rawEnd: String
    switch bucket {
    case .week:
      if let date = parseYYYYMMDD(start),
        let plusSix = gregorian.date(byAdding: .day, value: 6, to: date)
      {
        rawEnd = formatCalendarDate(plusSix)
      } else {
        rawEnd = start
      }
    case .month:
      let parts = start.split(separator: "-")
      if parts.count == 3,
        let y = Int(parts[0]),
        let m = Int(parts[1]),
        let first = gregorian.date(from: DateComponents(year: y, month: m, day: 1)),
        let days = gregorian.range(of: .day, in: .month, for: first)?.count
      {
        rawEnd = String(format: "%04d-%02d-%02d", y, m, days)
      } else {
        rawEnd = start
      }
    case .day, .unknown:
      rawEnd = start
    }

    let from =
      if let pFrom = periodRange.from, pFrom > start {
        pFrom
      } else {
        start
      }
    let to =
      if let pTo = periodRange.to, pTo < rawEnd {
        pTo
      } else {
        rawEnd
      }
    return to < from ? (from, from) : (from, to)
  }

  private static func parseYYYYMMDD(_ value: String) -> Date? {
    let parts = value.split(separator: "-")
    guard parts.count == 3,
      let y = Int(parts[0]),
      let m = Int(parts[1]),
      let d = Int(parts[2])
    else { return nil }
    return gregorian.date(from: DateComponents(year: y, month: m, day: d))
  }
}
