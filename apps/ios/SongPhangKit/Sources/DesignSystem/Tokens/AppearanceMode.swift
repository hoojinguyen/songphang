public import SwiftUI

public enum AppearanceMode: String, CaseIterable, Sendable, Identifiable {
  case system
  case light
  case dark

  public static let storageKey = "appearanceMode"

  public var id: String { rawValue }

  public var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }

  public var labelKey: String {
    switch self {
    case .system: return "appearance.system"
    case .light: return "appearance.light"
    case .dark: return "appearance.dark"
    }
  }
}
