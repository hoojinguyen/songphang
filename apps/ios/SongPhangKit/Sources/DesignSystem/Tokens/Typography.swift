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

    guard !fontURLs.isEmpty else {
      logger.debug("No bundled .ttf fonts found; using Dynamic Type system fonts.")
      return
    }

    for fontURL in fontURLs {
      var error: Unmanaged<CFError>?
      let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
      if !registered, let cfError = error?.takeRetainedValue() {
        let nsError = (cfError as any Error) as NSError
        // Ignore already-registered error when SwiftUI previews or tests invoke startup twice.
        if nsError.code != CTFontManagerError.alreadyRegistered.rawValue {
          logger.error(
            "Failed to register font \(fontURL.lastPathComponent, privacy: .public): \(nsError.localizedDescription, privacy: .public)"
          )
        }
      }
    }
  }

  public static let heroNumber: Font = customOrSystem(
    "BeVietnamPro-Black",
    size: 40,
    relativeTo: .largeTitle,
    fallback: .system(size: 40, weight: .black, design: .default)
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
