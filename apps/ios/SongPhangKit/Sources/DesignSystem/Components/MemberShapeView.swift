public import Domain
import Foundation
public import SwiftUI

public struct MemberShapeView: View {
  private let shape: MemberShape
  private let color: MemberColor
  private let name: String
  private let size: CGFloat
  private let isClaimed: Bool

  public init(
    shape: MemberShape,
    color: MemberColor,
    name: String,
    size: CGFloat,
    isClaimed: Bool = true
  ) {
    self.shape = shape
    self.color = color
    self.name = name
    self.size = size
    self.isClaimed = isClaimed
  }

  public init(
    shape: MemberShape,
    color: MemberColor,
    initial: String,
    size: CGFloat,
    isClaimed: Bool = true
  ) {
    self.shape = shape
    self.color = color
    self.name = initial
    self.size = size
    self.isClaimed = isClaimed
  }

  public init(member: Member, size: CGFloat) {
    self.shape = member.shape
    self.color = member.color
    self.name = member.name
    self.size = size
    self.isClaimed = member.claimed
  }

  public var body: some View {
    ZStack {
      drawnShape
        .fill(Tokens.color(for: color).opacity(isClaimed ? 1.0 : 0.45))
        .overlay {
          if !isClaimed {
            drawnShape.stroke(
              Tokens.dashed,
              style: StrokeStyle(
                lineWidth: max(1.5, size * 0.055),
                dash: [max(3, size * 0.11), max(2.5, size * 0.08)]
              )
            )
          }
        }
        .frame(width: size * scaleFactor, height: size * scaleFactor)
        .rotationEffect(.degrees(rotationDegrees))

      if let firstLetter = initialLetter {
        Text(firstLetter)
          .font(.system(size: initialFontSize, weight: .black))
          .foregroundStyle(Tokens.onAccent)
          .accessibilityHidden(true)
      }
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name)
  }

  private var initialFontSize: CGFloat {
    if size < 32 {
      return max(9, size * 0.42)
    }
    return size * 0.36
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

#if DEBUG
  #Preview("Claimed vs Unclaimed Shapes") {
    HStack(spacing: 16) {
      MemberShapeView(shape: .circle, color: .mint, name: "Minh", size: 52, isClaimed: true)
      MemberShapeView(shape: .diamond, color: .sky, name: "Lan", size: 52, isClaimed: false)
      MemberShapeView(shape: .squircle, color: .coral, name: "Hùng", size: 28, isClaimed: true)
      MemberShapeView(shape: .leaf, color: .lilac, name: "Thu", size: 24, isClaimed: false)
    }
    .padding(20)
    .background(Tokens.bg)
  }
#endif
