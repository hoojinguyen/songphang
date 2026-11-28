public import SwiftUI

#if DEBUG
  import os
#endif

public enum Motion {
  #if DEBUG
    private static let logger = Logger(subsystem: "vn.songphang.app", category: "Motion")
  #endif

  // ~220 ms critically damped spring so chip/segment selection feels immediate without wobble.
  public static let quick: Animation = .spring(duration: 0.22, bounce: 0.0)

  // Slight overshoot reserved for positive completion and shape reactions (~300 ms).
  public static let bounce: Animation = .spring(duration: 0.30, bounce: 0.26)

  // Smooth spring without overshoot for sheets, scroll-to-anchor and expanding sections.
  public static let smooth: Animation = .spring(duration: 0.28, bounce: 0.0)

  private static let reducedFade: Animation = .easeOut(duration: 0.12)

  public static func isReduced(_ environmentReduceMotion: Bool) -> Bool {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--reduce-motion") {
        return true
      }
    #endif
    return environmentReduceMotion
  }

  public static func animation(
    _ token: Animation,
    reduceMotion: Bool,
    allowOpacityFade: Bool = false
  ) -> Animation? {
    let reduced = isReduced(reduceMotion)
    #if DEBUG
      logger.notice(
        "Motion.animation reduceMotion=\(reduced, privacy: .public) allowOpacityFade=\(allowOpacityFade, privacy: .public)"
      )
    #endif
    if reduced {
      return allowOpacityFade ? reducedFade : nil
    }
    return token
  }

  @discardableResult
  public static func withAnimation<Result>(
    _ token: Animation = Motion.quick,
    reduceMotion: Bool,
    allowOpacityFade: Bool = false,
    _ body: () throws -> Result
  ) rethrows -> Result {
    try SwiftUI.withAnimation(
      animation(token, reduceMotion: reduceMotion, allowOpacityFade: allowOpacityFade),
      body
    )
  }
}

private struct SPMotionModifier<V: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let token: Animation
  let value: V
  let allowOpacityFade: Bool

  func body(content: Content) -> some View {
    content.animation(
      Motion.animation(token, reduceMotion: reduceMotion, allowOpacityFade: allowOpacityFade),
      value: value
    )
  }
}

extension View {
  public func spAnimation<V: Equatable>(
    _ token: Animation = Motion.quick,
    value: V,
    allowOpacityFade: Bool = false
  ) -> some View {
    modifier(SPMotionModifier(token: token, value: value, allowOpacityFade: allowOpacityFade))
  }
}
