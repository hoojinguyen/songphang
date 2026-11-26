import DesignSystem
import Domain
import SwiftUI

struct GuestBreakdownSheet: View {
  let breakdown: MemberDebtBreakdown
  let focusLabel: String
  let transfers: [GuestTransfer]
  let members: [GuestMember]
  let onDismiss: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          SPCard(padding: 16) {
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(breakdown.memberName)
                  .font(Typography.bodyBold)
                  .foregroundStyle(Tokens.ink)
                Text(focusLabel)
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
              Spacer()
              MoneyText(
                breakdown.netBalance,
                style: .signed,
                font: Typography.sectionTitle,
                color: breakdown.netBalance.isPositive
                  ? Tokens.credit
                  : (breakdown.netBalance.isNegative ? Tokens.debt : Tokens.ink)
              )
            }
          }

          SPCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
              summaryRow(L10n.tr("breakdown.carryOver"), breakdown.carryOverBalance)
              summaryRow(L10n.tr("breakdown.periodExpenses"), breakdown.focusExpenseDelta)
              summaryRow(L10n.tr("breakdown.periodTransfers"), breakdown.focusTransferDelta)
              if !breakdown.postCycleDelta.isZero {
                summaryRow(L10n.tr("breakdown.postCycleDelta"), breakdown.postCycleDelta)
              }
              Divider().overlay(Tokens.borderSubtle)
              summaryRow(L10n.tr("breakdown.currentBalance"), breakdown.netBalance)
            }
          }

          if !transfers.isEmpty {
            SPCard(padding: 16) {
              VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tr("breakdown.transferAllocation"))
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
                ForEach(transfers) { transfer in
                  let toName = members.first(where: { $0.id == transfer.toMemberId })?.name ?? ""
                  HStack {
                    Text("\(breakdown.memberName) → \(toName)")
                      .font(Typography.captionBold)
                      .foregroundStyle(Tokens.ink)
                    Spacer()
                    MoneyText(
                      transfer.amount,
                      style: .full,
                      font: Typography.captionBold,
                      color: Tokens.ink
                    )
                  }
                }
              }
            }
          }

          ForEach(breakdown.lines) { line in
            SPCard(padding: 14) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(line.description)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(Tokens.ink)
                  Text("\(DayLabelFormat.dayLabel(for: line.occurredAt)) · \(line.payerSummary)")
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.muted)
                }
                Spacer()
                MoneyText(
                  line.delta,
                  style: .signed,
                  font: Typography.subheadlineBold,
                  color: line.delta.isPositive
                    ? Tokens.credit
                    : (line.delta.isNegative ? Tokens.debt : Tokens.ink)
                )
              }
            }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("breakdown.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.tr("split.done"), action: onDismiss)
        }
      }
    }
  }

  private func summaryRow(_ label: String, _ money: Money) -> some View {
    HStack {
      Text(label)
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
      Spacer()
      MoneyText(
        money,
        style: .signed,
        font: Typography.captionBold,
        color: money.isPositive ? Tokens.credit : (money.isNegative ? Tokens.debt : Tokens.ink)
      )
    }
  }
}
