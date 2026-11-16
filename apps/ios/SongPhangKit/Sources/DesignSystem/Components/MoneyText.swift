public import Domain
public import SwiftUI

public struct MoneyText: View {
  public enum Style: Sendable {
    case full
    case amountOnly
    case signed
    case compact
  }

  private let money: Money
  private let style: Style
  private let font: Font
  private let color: Color

  public init(
    _ money: Money,
    style: Style = .full,
    font: Font = Typography.bodyBold,
    color: Color = Tokens.ink
  ) {
    self.money = money
    self.style = style
    self.font = font
    self.color = color
  }

  public var body: some View {
    Text(formattedText)
      .font(font)
      .foregroundStyle(color)
      .monospacedDigit()
  }

  private var formattedText: String {
    switch style {
    case .full:
      return MoneyFormat.full(money)
    case .amountOnly:
      return MoneyFormat.amount(money)
    case .signed:
      return MoneyFormat.signedAmount(money)
    case .compact:
      return MoneyFormat.compact(money)
    }
  }
}
