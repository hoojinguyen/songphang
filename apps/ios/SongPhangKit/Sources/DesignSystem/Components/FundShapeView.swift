public import SwiftUI

public struct FundShapeView: View {
  private let name: String
  private let size: CGFloat

  public init(name: String, size: CGFloat) {
    self.name = name
    self.size = size
  }

  public var body: some View {
    Capsule()
      .fill(Tokens.accent)
      .frame(width: (size * 1.6).rounded(), height: size)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(name)
  }
}
