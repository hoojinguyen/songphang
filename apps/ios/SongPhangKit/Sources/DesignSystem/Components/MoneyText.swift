public import Domain
public import SwiftUI

public struct MoneyText: View {
  public enum Role: Sendable {
    case hero
    case primary
    case secondary
  }

  public enum Style: Sendable {
    case hero
    case primary
    case secondary
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
    role: Role,
    font: Font? = nil,
    color: Color? = nil,
    showsPositiveSign: Bool = false
  ) {
    self.money = money
    switch role {
    case .hero:
      self.style = .hero
      self.font = font ?? Typography.heroNumber
      self.color = color ?? Tokens.ink
    case .primary:
      self.style = .primary
      self.font = font ?? Typography.bodyBold
      self.color = color ?? Tokens.ink
    case .secondary:
      self.style = .secondary
      self.font = font ?? Typography.captionBold
      self.color = color ?? Tokens.muted
    }
    self.showsPositiveSign = showsPositiveSign
  }

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
    case .hero, .primary, .full:
      return MoneyFormat.primary(money, showsPositiveSign: showsPositiveSign)
    case .secondary:
      return MoneyFormat.secondary(money, showsPositiveSign: showsPositiveSign)
    case .amountOnly:
      return MoneyFormat.amount(money)
    case .signed:
      return MoneyFormat.signedAmount(money)
    case .compact:
      return MoneyFormat.compact(money)
    }
  }
}

#if DEBUG
  #Preview("MoneyText Roles") {
    VStack(alignment: .leading, spacing: 12) {
      MoneyText(Money(500_000), role: .hero)
      HStack {
        MoneyText(Money(300_000), role: .primary)
        Spacer()
        MoneyText(Money(100_000), role: .secondary)
      }
    }
    .padding(20)
    .background(Tokens.bg)
  }
#endif
