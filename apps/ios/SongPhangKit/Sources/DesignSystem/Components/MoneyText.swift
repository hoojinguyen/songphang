public import Domain
public import SwiftUI

public struct MoneyText: View {
  public enum Style: Sendable {
    case hero
    case full
    case amountOnly
    case signed
    case compact
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  // Track direction via integer Money comparison so we never convert Money to Double.
  @State private var countsDown = false

  private let money: Money
  private let style: Style
  private let font: Font
  private let color: Color
  private let showsPositiveSign: Bool

  public init(
    _ money: Money,
    style: Style = .full,
    font: Font = Typography.bodyBold,
    color: Color = Tokens.ink,
    showsPositiveSign: Bool = false
  ) {
    self.money = money
    self.style = style
    self.font = font
    self.color = color
    self.showsPositiveSign = showsPositiveSign
  }

  public var body: some View {
    if style == .hero {
      let reduced = Motion.isReduced(reduceMotion)
      baseText
        .contentTransition(reduced ? .identity : .numericText(countsDown: countsDown))
        .spAnimation(Motion.smooth, value: money)
        .onChange(of: money) { oldValue, newValue in
          countsDown = newValue < oldValue
        }
    } else {
      baseText
    }
  }

  private var baseText: some View {
    Text(formattedText)
      .font(font)
      .foregroundStyle(color)
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.5)
  }

  private var formattedText: String {
    switch style {
    case .hero, .full:
      return MoneyFormat.full(money, showsPositiveSign: showsPositiveSign)
    case .amountOnly:
      return MoneyFormat.amount(money)
    case .signed:
      return MoneyFormat.signedAmount(money)
    case .compact:
      return MoneyFormat.compact(money)
    }
  }
}
