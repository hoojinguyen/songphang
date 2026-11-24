import DesignSystem
import Domain
import SwiftUI

struct StatsBarRowView: View {
  let label: String
  let amount: Money
  let maxAmount: Money
  let fillColor: Color
  let onTap: () -> Void

  var body: some View {
    let ratio = StatsBarMath.fraction(amount: amount, maxAmount: maxAmount)
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(label)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .multilineTextAlignment(.leading)
          Spacer(minLength: 8)
          MoneyText(
            amount,
            style: .full,
            font: Typography.subheadlineBold,
            color: Tokens.ink
          )
        }

        if amount.amount > 0 {
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Tokens.sunken)
                .frame(height: 12)
              if ratio > 0 {
                Capsule()
                  .fill(fillColor)
                  .frame(width: max(8, geo.size.width * ratio), height: 12)
              }
            }
          }
          .frame(height: 12)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
  }
}

struct MemberStatsRowView: View {
  let memberName: String
  let paid: Money
  let share: Money
  let maxAmount: Money
  let onTap: () -> Void

  var body: some View {
    let paidRatio = StatsBarMath.fraction(amount: paid, maxAmount: maxAmount)
    let shareRatio = StatsBarMath.fraction(amount: share, maxAmount: maxAmount)

    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 6) {
        Text(
          L10n.t(
            "stats.memberRow",
            [
              "name": memberName,
              "paid": MoneyFormat.full(paid),
              "share": MoneyFormat.full(share),
            ]
          )
        )
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
        .multilineTextAlignment(.leading)

        VStack(spacing: 4) {
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Tokens.sunken)
                .frame(height: 8)
              if paidRatio > 0 {
                Capsule()
                  .fill(Tokens.ink)
                  .frame(width: max(6, geo.size.width * paidRatio), height: 8)
              }
            }
          }
          .frame(height: 8)

          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Tokens.sunken)
                .frame(height: 8)
              if shareRatio > 0 {
                Capsule()
                  .fill(Tokens.mint)
                  .frame(width: max(6, geo.size.width * shareRatio), height: 8)
              }
            }
          }
          .frame(height: 8)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

private enum StatsBarMath {
  static func fraction(amount: Money, maxAmount: Money) -> CGFloat {
    guard maxAmount.amount > 0, amount.amount > 0 else { return 0 }
    if amount.amount >= maxAmount.amount { return 1 }
    let product = amount.amount.multipliedReportingOverflow(by: 1000)
    let permille: Int64
    if !product.overflow {
      permille = min(1000, product.partialValue / maxAmount.amount)
    } else {
      let step = max(1, maxAmount.amount / 1000)
      permille = min(1000, amount.amount / step)
    }
    return CGFloat(permille) / 1000
  }
}
