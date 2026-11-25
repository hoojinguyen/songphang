public import Domain
import Foundation
public import SwiftUI

public struct MemberShapeView: View {
  private let shape: MemberShape
  private let color: MemberColor
  private let name: String
  private let size: CGFloat
  private let showInitial: Bool

  public init(
    shape: MemberShape,
    color: MemberColor,
    name: String,
    size: CGFloat,
    showInitial: Bool = true
  ) {
    self.shape = shape
    self.color = color
    self.name = name
    self.size = size
    self.showInitial = showInitial
  }

  public init(
    shape: MemberShape,
    color: MemberColor,
    initial: String,
    size: CGFloat
  ) {
    self.shape = shape
    self.color = color
    self.name = initial
    self.size = size
    self.showInitial = true
  }

  public var body: some View {
    ZStack {
      drawnShape
        .fill(Tokens.color(for: color))
        .frame(width: size * scaleFactor, height: size * scaleFactor)
        .rotationEffect(.degrees(rotationDegrees))

      if showInitial && size >= 44, let firstLetter = initialLetter {
        Text(firstLetter)
          .font(.system(size: size * 0.36, weight: .black))
          .foregroundStyle(Tokens.onAccent)
          .accessibilityHidden(true)
      }
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name)
  }

  private var initialLetter: String? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let first = trimmed.first else { return nil }
    return String(first).uppercased(with: Locale(identifier: "vi"))
  }

  private var scaleFactor: CGFloat {
    switch shape {
    case .circle, .unknown:
      return 1.0
    case .diamond:
      return 0.72
    case .squircle:
      return 1.0
    case .leaf:
      return 0.86
    }
  }

  private var rotationDegrees: Double {
    switch shape {
    case .diamond:
      return 45
    case .circle, .squircle, .leaf, .unknown:
      return 0
    }
  }

  private var drawnShape: AnyShape {
    switch shape {
    case .circle:
      return AnyShape(Circle())
    case .unknown(let raw):
      return raw == "fund" ? AnyShape(Capsule()) : AnyShape(Circle())
    case .diamond:
      return AnyShape(RoundedRectangle(cornerRadius: size * scaleFactor * 0.24, style: .continuous))
    case .squircle:
      return AnyShape(RoundedRectangle(cornerRadius: size * scaleFactor * 0.38, style: .continuous))
    case .leaf:
      let side = size * scaleFactor
      return AnyShape(
        UnevenRoundedRectangle(
          topLeadingRadius: side * 0.50,
          bottomLeadingRadius: side * 0.10,
          bottomTrailingRadius: side * 0.50,
          topTrailingRadius: side * 0.10,
          style: .continuous
        )
      )
    }
  }
}
