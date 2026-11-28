import Foundation
public import SwiftUI

#if DEBUG
  import os
#endif

public enum FeedbackSettings {
  public static let soundEnabledKey = "feedbackSoundEnabled"
  public static let hapticsEnabledKey = "feedbackHapticsEnabled"

  public static var isSoundEnabled: Bool {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--sound-off") {
        return false
      }
    #endif
    return (UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool) ?? true
  }

  public static var isHapticsEnabled: Bool {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--haptics-off") {
        return false
      }
    #endif
    return (UserDefaults.standard.object(forKey: hapticsEnabledKey) as? Bool) ?? true
  }
}

public enum FeedbackKind: String, Sendable, CaseIterable {
  case selection
  case success
  case warning

  public var sensoryFeedback: SensoryFeedback {
    switch self {
    case .selection:
      return .selection
    case .success:
      return .success
    case .warning:
      return .warning
    }
  }
}

private struct SPFeedbackModifier<T: Equatable>: ViewModifier {
  #if DEBUG
    private static var logger: Logger {
      Logger(subsystem: "vn.songphang.app", category: "Feedback")
    }
  #endif

  @AppStorage(FeedbackSettings.hapticsEnabledKey) private var isHapticsEnabled = true
  let kind: FeedbackKind
  let trigger: T

  func body(content: Content) -> some View {
    content.sensoryFeedback(trigger: trigger) { _, _ in
      let enabled: Bool = {
        #if DEBUG
          if ProcessInfo.processInfo.arguments.contains("--haptics-off") {
            return false
          }
        #endif
        return isHapticsEnabled
      }()
      #if DEBUG
        Self.logger.notice(
          "spFeedback kind=\(kind.rawValue, privacy: .public) enabled=\(enabled, privacy: .public)"
        )
      #endif
      return enabled ? kind.sensoryFeedback : nil
    }
  }
}

extension View {
  public func spFeedback<T: Equatable>(_ kind: FeedbackKind, trigger: T) -> some View {
    modifier(SPFeedbackModifier(kind: kind, trigger: trigger))
  }
}
