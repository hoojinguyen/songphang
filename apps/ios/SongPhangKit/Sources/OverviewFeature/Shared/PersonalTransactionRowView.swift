import DesignSystem
import Domain
import SwiftUI

struct PersonalTransactionRowView: View {
  let transaction: PersonalTransaction
  var verticalPadding: CGFloat = 14
  var cornerRadius: CGFloat = 22
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(transaction.groupName)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
              .lineLimit(1)
            Text("• \(DayLabelFormat.dayLabel(for: transaction.occurredAt))")
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
              .lineLimit(1)
          }

          Text(transaction.description)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .lineLimit(1)
        }

        Spacer(minLength: 8)

        VStack(alignment: .trailing, spacing: 2) {
          MoneyText(
            transaction.myDelta,
            style: transaction.myDelta.isZero ? .amountOnly : .signed,
            font: Typography.subheadlineBold,
            color: transaction.myDelta.isPositive
              ? Tokens.credit
              : (transaction.myDelta.isNegative ? Tokens.debt : Tokens.muted)
          )
          .monospacedDigit()
          .lineLimit(1)

          MoneyText(
            transaction.amount,
            style: .amountOnly,
            font: Typography.caption,
            color: Tokens.muted
          )
          .monospacedDigit()
          .lineLimit(1)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, verticalPadding)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
