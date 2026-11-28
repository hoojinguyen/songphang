import Foundation
public import SwiftUI

private struct SPSkeletonShimmerModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    if Motion.isReduced(reduceMotion) {
      content
    } else {
      TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
        let phase =
          context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
        let wave = 0.5 * (1.0 + sin(phase * 2.0 * .pi))
        content
          .opacity(0.58 + 0.34 * wave)
      }
    }
  }
}

extension View {
  public func spSkeletonShimmer() -> some View {
    modifier(SPSkeletonShimmerModifier())
  }
}

public struct SkeletonBar: View {
  private let width: CGFloat?
  private let height: CGFloat
  private let cornerRadius: CGFloat

  public init(width: CGFloat? = nil, height: CGFloat = 14, cornerRadius: CGFloat = 8) {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(Tokens.sunken)
      .frame(width: width, height: height)
      .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
  }
}

public struct BalanceCardSkeleton: View {
  public init() {}

  public var body: some View {
    AdaptiveStack(horizontalSpacing: 16, verticalSpacing: 12) {
      VStack(alignment: .leading, spacing: 10) {
        SkeletonBar(height: 14, cornerRadius: 7)
          .frame(maxWidth: 110, alignment: .leading)
        SkeletonBar(height: 36, cornerRadius: 12)
          .frame(maxWidth: 180, alignment: .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      SkeletonBar(width: 92, height: 48, cornerRadius: 24)
    }
    .padding(22)
    .frame(maxWidth: .infinity)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
    .spSkeletonShimmer()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.tr("ios.common.loading"))
  }
}

public struct LinkRowSkeleton: View {
  public init() {}

  public var body: some View {
    HStack(spacing: 12) {
      SkeletonBar(width: 132, height: 34, cornerRadius: 17)
      SkeletonBar(width: 118, height: 34, cornerRadius: 17)
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .spSkeletonShimmer()
    .accessibilityHidden(true)
  }
}

public struct SearchFieldSkeleton: View {
  public init() {}

  public var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Tokens.surface)
        .frame(height: 48)
        .overlay(alignment: .leading) {
          SkeletonBar(width: 120, height: 14, cornerRadius: 7)
            .padding(.leading, 16)
        }
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Tokens.surface)
        .frame(width: 68, height: 48)
    }
    .spSkeletonShimmer()
    .accessibilityHidden(true)
  }
}

public struct TransactionRowSkeleton: View {
  public init() {}

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Circle()
          .fill(Tokens.sunken)
          .frame(width: 28, height: 28)
        SkeletonBar(width: 96, height: 12, cornerRadius: 6)
        Spacer()
        SkeletonBar(width: 44, height: 12, cornerRadius: 6)
      }

      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 8) {
          SkeletonBar(width: 148, height: 18, cornerRadius: 8)
          SkeletonBar(width: 72, height: 20, cornerRadius: 10)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          SkeletonBar(width: 88, height: 18, cornerRadius: 8)
          SkeletonBar(width: 60, height: 12, cornerRadius: 6)
        }
      }

      HStack(spacing: 6) {
        ForEach(0..<3, id: \.self) { _ in
          Circle()
            .fill(Tokens.sunken)
            .frame(width: 20, height: 20)
        }
        Spacer()
        SkeletonBar(width: 64, height: 12, cornerRadius: 6)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .spSkeletonShimmer()
    .accessibilityHidden(true)
  }
}

public struct MemberRowSkeleton: View {
  public init() {}

  public var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Tokens.sunken)
        .frame(width: 52, height: 52)
      VStack(alignment: .leading, spacing: 6) {
        SkeletonBar(width: 108, height: 16, cornerRadius: 8)
        SkeletonBar(width: 140, height: 12, cornerRadius: 6)
      }
      Spacer(minLength: 8)
      SkeletonBar(width: 74, height: 28, cornerRadius: 14)
    }
    .padding(16)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .spSkeletonShimmer()
    .accessibilityHidden(true)
  }
}

#if DEBUG
  #Preview("SkeletonBlocks") {
    ScrollView {
      VStack(spacing: 14) {
        BalanceCardSkeleton()
        LinkRowSkeleton()
        SearchFieldSkeleton()
        TransactionRowSkeleton()
        MemberRowSkeleton()
      }
      .padding(20)
    }
    .background(Tokens.bg)
  }
#endif
