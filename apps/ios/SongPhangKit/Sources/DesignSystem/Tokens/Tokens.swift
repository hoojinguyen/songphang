public import Domain
public import SwiftUI

public enum Tokens {
  // Background and surfaces
  public static let bg = Color(red: 0xF6 / 255.0, green: 0xF2 / 255.0, blue: 0xFB / 255.0)
  public static let surface = Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
  public static let sunken = Color(red: 0xE9 / 255.0, green: 0xE4 / 255.0, blue: 0xF3 / 255.0)

  // Ink and text
  public static let ink = Color(red: 0x1C / 255.0, green: 0x1B / 255.0, blue: 0x22 / 255.0)
  public static let inkRaised = Color(red: 0x34 / 255.0, green: 0x32 / 255.0, blue: 0x3D / 255.0)
  public static let muted = Color(red: 0x5A / 255.0, green: 0x57 / 255.0, blue: 0x66 / 255.0)
  public static let onInkMuted = Color(red: 0xC9 / 255.0, green: 0xC5 / 255.0, blue: 0xD6 / 255.0)
  public static let dashed = Color(red: 0xB9 / 255.0, green: 0xB3 / 255.0, blue: 0xCC / 255.0)

  // Accents
  public static let accent = Color(red: 0xFF / 255.0, green: 0xD8 / 255.0, blue: 0x4D / 255.0)
  public static let debtSoft = Color(red: 0xFF / 255.0, green: 0xD9 / 255.0, blue: 0xD1 / 255.0)

  // Member colors
  public static let mint = Color(red: 0x9E / 255.0, green: 0xEB / 255.0, blue: 0xC0 / 255.0)
  public static let sky = Color(red: 0x9C / 255.0, green: 0xCB / 255.0, blue: 0xFF / 255.0)
  public static let coral = Color(red: 0xFF / 255.0, green: 0x8A / 255.0, blue: 0x73 / 255.0)
  public static let lilac = Color(red: 0xD3 / 255.0, green: 0xB8 / 255.0, blue: 0xFF / 255.0)

  // Phrase highlights
  public static let phraseAmount = Color(red: 0xFF / 255.0, green: 0xE9 / 255.0, blue: 0x9A / 255.0)
  public static let phrasePayer = Color(red: 0xCF / 255.0, green: 0xE3 / 255.0, blue: 0xFF / 255.0)
  public static let phraseSplit = Color(red: 0xCF / 255.0, green: 0xF5 / 255.0, blue: 0xDF / 255.0)
  public static let phraseRest = Color(red: 0xE7 / 255.0, green: 0xD9 / 255.0, blue: 0xFF / 255.0)

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
    case .unknown: return mint
    }
  }

  public static let allNamedColors: [(name: String, hex: String, color: Color)] = [
    ("bg", "#F6F2FB", bg),
    ("surface", "#FFFFFF", surface),
    ("sunken", "#E9E4F3", sunken),
    ("ink", "#1C1B22", ink),
    ("ink-raised", "#34323D", inkRaised),
    ("muted", "#5A5766", muted),
    ("on-ink-muted", "#C9C5D6", onInkMuted),
    ("dashed", "#B9B3CC", dashed),
    ("accent", "#FFD84D", accent),
    ("debt-soft", "#FFD9D1", debtSoft),
    ("mint", "#9EEBC0", mint),
    ("sky", "#9CCBFF", sky),
    ("coral", "#FF8A73", coral),
    ("lilac", "#D3B8FF", lilac),
    ("phrase-amount", "#FFE99A", phraseAmount),
    ("phrase-payer", "#CFE3FF", phrasePayer),
    ("phrase-split", "#CFF5DF", phraseSplit),
    ("phrase-rest", "#E7D9FF", phraseRest),
  ]
}
