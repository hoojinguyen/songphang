import DesignSystem
import Domain
import Foundation

enum LedgerDateLabels {
  static func dayLabel(for isoString: String, now: Date = Date()) -> String {
    DayLabelFormat.dayLabel(for: isoString, now: now)
  }

  static func timeLabel(for isoString: String) -> String {
    DayLabelFormat.timeLabel(for: isoString)
  }
}
