public import Domain
public import SwiftUI

public struct TransactionExtrasCardView: View {
  private let totalAmount: Money
  private let extras: [SplitSpec.ItemsExtra]
  private let allocation: ExtrasAllocation?
  private let defaultAllocation: ExtrasAllocation
  private let showCardChrome: Bool

  public init(
    totalAmount: Money,
    extras: [SplitSpec.ItemsExtra],
    allocation: ExtrasAllocation?,
    defaultAllocation: ExtrasAllocation = .equal,
    showCardChrome: Bool = true
  ) {
    self.totalAmount = totalAmount
    self.extras = extras
    self.allocation = allocation
    self.defaultAllocation = defaultAllocation
    self.showCardChrome = showCardChrome
  }

  private var netExtrasAmount: Int64 {
    extras.reduce(Int64(0)) { sum, extra in
      let signed = extra.kind == .discount ? -extra.amount.amount : extra.amount.amount
      return sum + signed
    }
  }

  private var goodsSubtotal: Money {
    Money(totalAmount.amount - netExtrasAmount)
  }

  private var allocationText: String {
    switch allocation ?? defaultAllocation {
    case .proportional:
      return L10n.tr("extras.allocProportionalLabel")
    case .equal, .unknown:
      return L10n.tr("extras.allocEqualLabel")
    }
  }

  public var body: some View {
    if showCardChrome {
      SPCard(padding: 16) {
        content
      }
    } else {
      content
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(L10n.tr("extras.goodsSubtotal"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer()
        MoneyText(
          goodsSubtotal,
          style: .full,
          font: Typography.captionBold,
          color: Tokens.ink
        )
      }

      ForEach(Array(extras.enumerated()), id: \.offset) { _, extra in
        let baseTitle = extra.label.isEmpty ? extra.kind.localizedTitle : extra.label
        let title =
          extra.ratePercent.map { "\(baseTitle) (\($0)%)" } ?? baseTitle
        let displayedAmount =
          extra.kind == .discount
          ? Money(-extra.amount.amount)
          : extra.amount
        HStack {
          Text(title)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
          Spacer()
          MoneyText(
            displayedAmount,
            style: .signed,
            font: Typography.captionBold,
            color: extra.kind == .discount ? Tokens.credit : Tokens.ink
          )
        }
      }

      Divider().overlay(Tokens.borderSubtle)

      HStack {
        Text(allocationText)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer()
        Text(L10n.tr("extras.totalPayment"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
        MoneyText(
          totalAmount,
          style: .full,
          font: Typography.subheadlineBold,
          color: Tokens.ink
        )
      }
    }
  }
}
