import Domain
import Foundation
public import SwiftUI

public struct ShapeLoader: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let itemSize: CGFloat

  private static let brandItems: [(shape: MemberShape, color: Color)] = [
    (.circle, Tokens.mint),
    (.diamond, Tokens.sky),
    (.squircle, Tokens.coral),
    (.leaf, Tokens.lilac),
  ]

  public init(itemSize: CGFloat = 18) {
    self.itemSize = itemSize
  }

  public var body: some View {
    Group {
      if Motion.isReduced(reduceMotion) {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
          let wave = 0.5 * (1.0 + sin(context.date.timeIntervalSinceReferenceDate * 2.4))
          let alpha = 0.45 + 0.45 * wave
          HStack(spacing: itemSize * 0.55) {
            ForEach(0..<Self.brandItems.count, id: \.self) { index in
              brandGlyph(index: index)
                .opacity(alpha)
            }
          }
        }
      } else {
        PhaseAnimator([0, 1, 2, 3]) { activeIndex in
          HStack(spacing: itemSize * 0.55) {
            ForEach(0..<Self.brandItems.count, id: \.self) { index in
              brandGlyph(index: index)
                .offset(y: activeIndex == index ? -itemSize * 0.45 : 0)
                .scaleEffect(activeIndex == index ? 1.08 : 0.96)
            }
          }
        } animation: { _ in
          Motion.animation(Motion.bounce, reduceMotion: false)
        }
      }
    }
    .padding(.vertical, 8)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.tr("ios.common.loading"))
  }

  @ViewBuilder
  private func brandGlyph(index: Int) -> some View {
    let spec = Self.brandItems[index]
    switch spec.shape {
    case .circle, .unknown:
      Circle()
        .fill(spec.color)
        .frame(width: itemSize, height: itemSize)
    case .diamond:
      RoundedRectangle(cornerRadius: itemSize * 0.24, style: .continuous)
        .fill(spec.color)
        .frame(width: itemSize * 0.78, height: itemSize * 0.78)
        .rotationEffect(.degrees(45))
        .frame(width: itemSize, height: itemSize)
    case .squircle:
      RoundedRectangle(cornerRadius: itemSize * 0.38, style: .continuous)
        .fill(spec.color)
        .frame(width: itemSize, height: itemSize)
    case .leaf:
      UnevenRoundedRectangle(
        topLeadingRadius: itemSize * 0.50,
        bottomLeadingRadius: itemSize * 0.12,
        bottomTrailingRadius: itemSize * 0.50,
        topTrailingRadius: itemSize * 0.12,
        style: .continuous
      )
      .fill(spec.color)
      .frame(width: itemSize * 0.9, height: itemSize * 0.9)
      .frame(width: itemSize, height: itemSize)
    }
  }
}

#if DEBUG
  #Preview("ShapeLoader") {
    VStack(spacing: 24) {
      ShapeLoader()
      ShapeLoader(itemSize: 26)
    }
    .padding(24)
    .background(Tokens.bg)
  }
#endif
