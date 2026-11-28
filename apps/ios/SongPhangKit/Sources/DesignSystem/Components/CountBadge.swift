public import SwiftUI

public struct CountBadge: View {
  private let count: Int
  private let isSelected: Bool

  public init(count: Int, isSelected: Bool = false) {
    self.count = count
    self.isSelected = isSelected
  }

  public var body: some View {
    if count > 0 {
      Text("\(count)")
        .font(Typography.microBold)
        .monospacedDigit()
        .foregroundStyle(isSelected ? Tokens.onAccent : Tokens.onInk)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(isSelected ? Tokens.accent : Tokens.ink, in: Capsule())
    }
  }
}

#if DEBUG
  #Preview("CountBadge States") {
    HStack(spacing: 12) {
      Text("Zero:")
      CountBadge(count: 0)
      Text("Three:")
      CountBadge(count: 3)
      Text("Selected:")
      CountBadge(count: 12, isSelected: true)
    }
    .padding(20)
    .background(Tokens.bg)
  }
#endif
