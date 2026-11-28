import CoreText
import Foundation
public import SwiftUI
import UIKit
import os

public enum Typography {
  private static let logger = Logger(subsystem: "vn.songphang.app", category: "Typography")
  private static var didAttemptRegistration = false
  private static let hasCustomFonts: Bool = {
    registerFontsIfAvailable()
    return UIFont(name: "BeVietnamPro-Regular", size: 17) != nil
  }()

  public static func registerFontsIfAvailable() {
    guard !didAttemptRegistration else { return }
    didAttemptRegistration = true

    let rootURLs = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
    let subURLs = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
    let fontURLs = Array(Set(rootURLs + subURLs))
      .sorted { $0.lastPathComponent < $1.lastPathComponent }

    if fontURLs.isEmpty {
      logger.debug("No bundled .ttf fonts found; using Dynamic Type system fonts.")
      return
    }

    for fontURL in fontURLs {
      var error: Unmanaged<CFError>?
      let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
      if !registered, let cfError = error?.takeRetainedValue() {
        let nsError = (cfError as any Error) as NSError
        // Ignore already-registered error when SwiftUI previews invoke startup twice.
        if nsError.code != CTFontManagerError.alreadyRegistered.rawValue {
          logger.error(
            "Failed to register font \(fontURL.lastPathComponent, privacy: .public): \(nsError.localizedDescription, privacy: .public)"
          )
        }
      }
    }

    configureNavigationBarAppearance()
  }

  private static func configureNavigationBarAppearance() {
    let navAppearance = UINavigationBar.appearance()
    if let inlineFont = UIFont(name: "BeVietnamPro-ExtraBold", size: 17) {
      let scaledInline = UIFontMetrics(forTextStyle: .headline).scaledFont(for: inlineFont)
      navAppearance.titleTextAttributes = [.font: scaledInline]
    }
    if let largeFont = UIFont(name: "BeVietnamPro-Black", size: 34) {
      let scaledLarge = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeFont)
      navAppearance.largeTitleTextAttributes = [.font: scaledLarge]
    }
  }

  public static let displayNumber: Font = customOrSystem(
    "BeVietnamPro-Black",
    size: 44,
    relativeTo: .largeTitle,
    fallback: .system(.largeTitle, design: .default, weight: .black)
  )
  .leading(.tight)

  public static let heroNumber: Font = customOrSystem(
    "BeVietnamPro-Black",
    size: 40,
    relativeTo: .largeTitle,
    fallback: .system(.largeTitle, design: .default, weight: .black)
  )
  .leading(.tight)

  public static let pageTitle: Font = customOrSystem(
    "BeVietnamPro-Black",
    size: 34,
    relativeTo: .largeTitle,
    fallback: .system(.largeTitle, design: .default, weight: .black)
  )

  public static let sectionTitle: Font = customOrSystem(
    "BeVietnamPro-Black",
    size: 20,
    relativeTo: .title3,
    fallback: .system(.title3, design: .default, weight: .black)
  )

  public static let screenHeaderTitle: Font = customOrSystem(
    "BeVietnamPro-ExtraBold",
    size: 17,
    relativeTo: .headline,
    fallback: .system(.headline, design: .default, weight: .heavy)
  )

  public static let bodyBold: Font = customOrSystem(
    "BeVietnamPro-Bold",
    size: 17,
    relativeTo: .body,
    fallback: .system(.body, design: .default, weight: .bold)
  )

  public static let body: Font = customOrSystem(
    "BeVietnamPro-Medium",
    size: 17,
    relativeTo: .body,
    fallback: .system(.body, design: .default, weight: .medium)
  )

  public static let subheadlineBold: Font = customOrSystem(
    "BeVietnamPro-Bold",
    size: 15,
    relativeTo: .subheadline,
    fallback: .system(.subheadline, design: .default, weight: .bold)
  )

  public static let subheadline: Font = customOrSystem(
    "BeVietnamPro-Medium",
    size: 15,
    relativeTo: .subheadline,
    fallback: .system(.subheadline, design: .default, weight: .medium)
  )

  public static let captionBold: Font = customOrSystem(
    "BeVietnamPro-SemiBold",
    size: 13,
    relativeTo: .footnote,
    fallback: .system(.footnote, design: .default, weight: .semibold)
  )

  public static let caption: Font = customOrSystem(
    "BeVietnamPro-Medium",
    size: 12,
    relativeTo: .caption,
    fallback: .system(.caption, design: .default, weight: .medium)
  )

  public static let microBold: Font = customOrSystem(
    "BeVietnamPro-Bold",
    size: 11,
    relativeTo: .caption2,
    fallback: .system(.caption2, design: .default, weight: .bold)
  )

  public static let micro: Font = customOrSystem(
    "BeVietnamPro-SemiBold",
    size: 11,
    relativeTo: .caption2,
    fallback: .system(.caption2, design: .default, weight: .semibold)
  )

  private static func customOrSystem(
    _ postScriptName: String,
    size: CGFloat,
    relativeTo textStyle: Font.TextStyle,
    fallback: Font
  ) -> Font {
    if hasCustomFonts, UIFont(name: postScriptName, size: size) != nil {
      return .custom(postScriptName, size: size, relativeTo: textStyle)
    }
    return fallback
  }
}

private struct SPScaledIconModifier: ViewModifier {
  @ScaledMetric private var scaledSize: CGFloat
  private let weight: Font.Weight

  init(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) {
    self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    self.weight = weight
  }

  func body(content: Content) -> some View {
    content.font(.system(size: scaledSize, weight: weight))
  }
}

extension View {
  public func spIconFont(
    size: CGFloat,
    weight: Font.Weight = .semibold,
    relativeTo textStyle: Font.TextStyle = .body
  ) -> some View {
    modifier(SPScaledIconModifier(size: size, weight: weight, relativeTo: textStyle))
  }
}
