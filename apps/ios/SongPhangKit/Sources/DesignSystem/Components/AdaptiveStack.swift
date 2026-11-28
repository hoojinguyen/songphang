public import SwiftUI

public struct AdaptiveStack<Content: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private let horizontalAlignment: VerticalAlignment
  private let verticalAlignment: HorizontalAlignment
  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let content: Content

  public init(
    horizontalAlignment: VerticalAlignment = .center,
    verticalAlignment: HorizontalAlignment = .leading,
    horizontalSpacing: CGFloat = 12,
    verticalSpacing: CGFloat = 8,
    @ViewBuilder content: () -> Content
  ) {
    self.horizontalAlignment = horizontalAlignment
    self.verticalAlignment = verticalAlignment
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.content = content()
  }

  public var body: some View {
    let layout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: verticalAlignment, spacing: verticalSpacing))
      : AnyLayout(HStackLayout(alignment: horizontalAlignment, spacing: horizontalSpacing))
    layout {
      content
    }
  }
}

#if DEBUG
  import Domain

  #Preview("AdaptiveStack Default") {
    SPCard {
      AdaptiveStack {
        Text("Bạn được nhận")
          .font(Typography.bodyBold)
        Spacer(minLength: 8)
        MoneyText(Money(500_001), style: .full, font: Typography.sectionTitle, color: Tokens.credit)
      }
    }
    .padding(20)
    .background(Tokens.bg)
  }

  #Preview("AdaptiveStack Largest Accessibility") {
    SPCard {
      AdaptiveStack {
        Text("Bạn được nhận")
          .font(Typography.bodyBold)
        Spacer(minLength: 8)
        MoneyText(Money(500_001), style: .full, font: Typography.sectionTitle, color: Tokens.credit)
      }
    }
    .padding(20)
    .background(Tokens.bg)
    .environment(\.dynamicTypeSize, .accessibility5)
  }
#endif
