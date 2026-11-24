public import Domain
public import SwiftUI
import UIKit

public enum Tokens {
  // Background and surfaces
  public static let bg = dynamicColor(lightHex: 0xF6F2FB, darkHex: 0x111016)
  public static let surface = dynamicColor(lightHex: 0xFFFFFF, darkHex: 0x1B1924)
  public static let surfaceElevated = dynamicColor(lightHex: 0xFFFFFF, darkHex: 0x242130)
  public static let sunken = dynamicColor(lightHex: 0xE9E4F3, darkHex: 0x262333)
  public static let borderSubtle = dynamicColor(lightHex: 0xE3DDF0, darkHex: 0x343045)

  // Ink and text
  public static let ink = dynamicColor(lightHex: 0x1C1B22, darkHex: 0xF5F3FA)
  public static let inkRaised = dynamicColor(lightHex: 0x34323D, darkHex: 0xE2DEF0)
  public static let muted = dynamicColor(lightHex: 0x5A5766, darkHex: 0xA8A3BA)
  public static let placeholder = dynamicColor(lightHex: 0x6F6B7E, darkHex: 0x8E88A3)
  public static let onInk = dynamicColor(lightHex: 0xFFFFFF, darkHex: 0x14131A)
  public static let onInkMuted = dynamicColor(lightHex: 0xC9C5D6, darkHex: 0x514D63)
  public static let dashed = dynamicColor(lightHex: 0xB9B3CC, darkHex: 0x4B4660)

  // Accents and semantic statuses
  public static let accent = dynamicColor(lightHex: 0xFFD84D, darkHex: 0xF5C93B)
  public static let onAccent = dynamicColor(lightHex: 0x1C1B22, darkHex: 0x1C1B22)
  public static let credit = dynamicColor(lightHex: 0x0E7A4B, darkHex: 0x5FE0A2)
  public static let creditSoft = dynamicColor(lightHex: 0xDFF7EA, darkHex: 0x153326)
  public static let debt = dynamicColor(lightHex: 0xC73826, darkHex: 0xFF8A7A)
  public static let debtSoft = dynamicColor(lightHex: 0xFFD9D1, darkHex: 0x3B1E1B)
  public static let warning = dynamicColor(lightHex: 0x9A6300, darkHex: 0xFFD84D)
  public static let warningSoft = dynamicColor(lightHex: 0xFFF3C4, darkHex: 0x352B14)

  // Member colors
  public static let mint = dynamicColor(lightHex: 0x9EEBC0, darkHex: 0x6BD9A2)
  public static let sky = dynamicColor(lightHex: 0x9CCBFF, darkHex: 0x70B4FF)
  public static let coral = dynamicColor(lightHex: 0xFF8A73, darkHex: 0xFF7F66)
  public static let lilac = dynamicColor(lightHex: 0xD3B8FF, darkHex: 0xBC9AFF)
  public static let sun = accent

  // Phrase highlights
  public static let phraseAmount = dynamicColor(lightHex: 0xFFE99A, darkHex: 0x4A3D14)
  public static let phrasePayer = dynamicColor(lightHex: 0xCFE3FF, darkHex: 0x1B3252)
  public static let phraseSplit = dynamicColor(lightHex: 0xCFF5DF, darkHex: 0x153D2A)
  public static let phraseRest = dynamicColor(lightHex: 0xE7D9FF, darkHex: 0x33214D)

  // Radii and spacing
  public static let radiusCard: CGFloat = 32
  public static let radiusPill: CGFloat = 9999
  public static let controlMediumHeight: CGFloat = 48
  public static let controlLargeHeight: CGFloat = 64

  public static func color(for memberColor: MemberColor) -> Color {
    switch memberColor {
    case .mint: return mint
    case .sky: return sky
    case .coral: return coral
    case .lilac: return lilac
    case .unknown(let raw): return raw == "sun" ? sun : mint
    }
  }

  public static let allNamedColors: [(name: String, hex: String, color: Color)] = [
    ("bg", "#F6F2FB / #111016", bg),
    ("surface", "#FFFFFF / #1B1924", surface),
    ("surface-elevated", "#FFFFFF / #242130", surfaceElevated),
    ("sunken", "#E9E4F3 / #262333", sunken),
    ("border-subtle", "#E3DDF0 / #343045", borderSubtle),
    ("ink", "#1C1B22 / #F5F3FA", ink),
    ("ink-raised", "#34323D / #E2DEF0", inkRaised),
    ("muted", "#5A5766 / #A8A3BA", muted),
    ("placeholder", "#6F6B7E / #8E88A3", placeholder),
    ("on-ink", "#FFFFFF / #14131A", onInk),
    ("on-ink-muted", "#C9C5D6 / #514D63", onInkMuted),
    ("dashed", "#B9B3CC / #4B4660", dashed),
    ("accent", "#FFD84D / #F5C93B", accent),
    ("on-accent", "#1C1B22 / #1C1B22", onAccent),
    ("credit", "#0E7A4B / #5FE0A2", credit),
    ("credit-soft", "#DFF7EA / #153326", creditSoft),
    ("debt", "#C73826 / #FF8A7A", debt),
    ("debt-soft", "#FFD9D1 / #3B1E1B", debtSoft),
    ("warning", "#9A6300 / #FFD84D", warning),
    ("warning-soft", "#FFF3C4 / #352B14", warningSoft),
    ("mint", "#9EEBC0 / #6BD9A2", mint),
    ("sky", "#9CCBFF / #70B4FF", sky),
    ("coral", "#FF8A73 / #FF7F66", coral),
    ("lilac", "#D3B8FF / #BC9AFF", lilac),
    ("sun", "#FFD84D / #F5C93B", sun),
    ("phrase-amount", "#FFE99A / #4A3D14", phraseAmount),
    ("phrase-payer", "#CFE3FF / #1B3252", phrasePayer),
    ("phrase-split", "#CFF5DF / #153D2A", phraseSplit),
    ("phrase-rest", "#E7D9FF / #33214D", phraseRest),
  ]

  private static func dynamicColor(lightHex: UInt32, darkHex: UInt32) -> Color {
    Color(
      uiColor: UIColor { traitCollection in
        let hex = traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex
        return UIColor(
          red: CGFloat((hex >> 16) & 0xFF) / 255.0,
          green: CGFloat((hex >> 8) & 0xFF) / 255.0,
          blue: CGFloat(hex & 0xFF) / 255.0,
          alpha: 1.0
        )
      }
    )
  }
}
