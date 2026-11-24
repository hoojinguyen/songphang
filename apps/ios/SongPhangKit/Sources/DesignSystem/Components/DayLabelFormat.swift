import Domain
public import Foundation

public enum DayLabelFormat {
  public static func dayLabel(for isoString: String, now: Date = Date()) -> String {
    guard let date = ISO8601Support.parse(isoString) else {
      return String(isoString.prefix(10))
    }

    let calendar = Calendar(identifier: .gregorian)
    let todayStart = calendar.startOfDay(for: now)
    let dateStart = calendar.startOfDay(for: date)

    if dateStart == todayStart {
      return L10n.tr("feed.today")
    }
    if let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart),
      dateStart == yesterdayStart
    {
      return L10n.tr("feed.yesterday")
    }

    let components = calendar.dateComponents([.day, .month, .year], from: date)
    let day = String(format: "%02d", components.day ?? 1)
    let month = String(format: "%02d", components.month ?? 1)
    let year = components.year ?? 2026
    return "\(day)/\(month)/\(year)"
  }

  public static func timeLabel(for isoString: String) -> String {
    guard let date = ISO8601Support.parse(isoString) else {
      return ""
    }
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.hour, .minute], from: date)
    return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
  }
}
