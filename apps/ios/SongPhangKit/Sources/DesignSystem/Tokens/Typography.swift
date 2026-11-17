public import SwiftUI

public enum Typography {
  public static func registerFontsIfAvailable() {
    // Be Vietnam Pro files in apps/web are WOFF2 web fonts; iOS uses system Dynamic Type fonts.
  }

  public static let heroNumber: Font = .system(
    size: 40, weight: .black, design: .default
  ).leading(.tight)
  public static let pageTitle: Font = .system(.largeTitle, design: .default, weight: .black)
  public static let sectionTitle: Font = .system(.title3, design: .default, weight: .black)
  public static let screenHeaderTitle: Font = .system(.headline, design: .default, weight: .heavy)
  public static let bodyBold: Font = .system(.body, design: .default, weight: .bold)
  public static let body: Font = .system(.body, design: .default, weight: .medium)
  public static let subheadlineBold: Font = .system(.subheadline, design: .default, weight: .bold)
  public static let subheadline: Font = .system(.subheadline, design: .default, weight: .medium)
  public static let captionBold: Font = .system(.footnote, design: .default, weight: .semibold)
  public static let caption: Font = .system(.caption, design: .default, weight: .medium)
}
