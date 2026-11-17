import Foundation

public enum L10n {
  public static func tr(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: "Localizable")
  }

  public static func t(_ key: String, _ replacements: [String: String]) -> String {
    var result = tr(key)
    for (placeholder, value) in replacements {
      result = result.replacingOccurrences(of: "{\(placeholder)}", with: value)
    }
    return result
  }

  public static var feedSamples: [String] {
    [
      tr("feed.samples.0"),
      tr("feed.samples.1"),
      tr("feed.samples.2"),
    ]
  }
}
