public import Foundation

public enum ISO8601Support: Sendable {
  public static func parse(_ string: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: string) {
      return date
    }
    let standard = ISO8601DateFormatter()
    return standard.date(from: string)
  }

  public static func format(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}
