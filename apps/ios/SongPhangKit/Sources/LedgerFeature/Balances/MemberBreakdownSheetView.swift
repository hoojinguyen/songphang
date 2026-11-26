import DesignSystem
import Domain
import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

struct MemberBreakdownSheetView: View {
  private let breakdown: MemberDebtBreakdown
  private let householdBreakdown: HouseholdDebtBreakdown?
  private let focusLabel: String
  private let memberTransfers: [SuggestedTransfer]
  private let members: [Member]
  private let onDismiss: () -> Void

  init(
    breakdown: MemberDebtBreakdown,
    householdBreakdown: HouseholdDebtBreakdown? = nil,
    focusLabel: String,
    memberTransfers: [SuggestedTransfer] = [],
    members: [Member] = [],
    onDismiss: @escaping () -> Void
  ) {
    self.breakdown = breakdown
    self.householdBreakdown = householdBreakdown
    self.focusLabel = focusLabel
    self.memberTransfers = memberTransfers
    self.members = members
    self.onDismiss = onDismiss
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          headerCard
          if let householdBreakdown {
            householdSummaryCard(householdBreakdown)
          }
          reconciliationCard
          if !memberTransfers.isEmpty {
            allocationCard
          }
          linesCard
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

  private var headerCard: some View {
    SPCard(padding: 16) {
      HStack(spacing: 12) {
        MemberShapeView(
          shape: breakdown.shape,
          color: breakdown.color,
          name: breakdown.memberName,
          size: 48
        )
        VStack(alignment: .leading, spacing: 2) {
          Text(breakdown.memberName)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
          Text(focusLabel)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        Spacer(minLength: 8)
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
  }

  private var reconciliationCard: some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        summaryRow(label: L10n.tr("breakdown.carryOver"), money: breakdown.carryOverBalance)
        summaryRow(label: L10n.tr("breakdown.periodExpenses"), money: breakdown.focusExpenseDelta)
        summaryRow(label: L10n.tr("breakdown.periodTransfers"), money: breakdown.focusTransferDelta)
        if !breakdown.postCycleDelta.isZero {
          summaryRow(label: L10n.tr("breakdown.postCycleDelta"), money: breakdown.postCycleDelta)
        }
        Divider().overlay(Tokens.borderSubtle)
        HStack {
          Text(L10n.tr("breakdown.currentBalance"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Spacer()
          MoneyText(
            breakdown.netBalance,
            style: .signed,
            font: Typography.subheadlineBold,
            color: breakdown.netBalance.isPositive
              ? Tokens.credit
              : (breakdown.netBalance.isNegative ? Tokens.debt : Tokens.ink)
          )
        }
      }
    }
  }

  private func summaryRow(label: String, money: Money) -> some View {
    HStack {
      Text(label)
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
      Spacer()
      MoneyText(
        money,
        style: .signed,
        font: Typography.captionBold,
        color: money.isZero ? Tokens.muted : Tokens.ink
      )
    }
  }

  private func householdSummaryCard(_ hh: HouseholdDebtBreakdown) -> some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text(L10n.t("households.summaryTitleTemplate", ["name": hh.name]))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Spacer()
          MoneyText(
            hh.netBalance,
            style: .signed,
            font: Typography.subheadlineBold,
            color: hh.netBalance.isPositive
              ? Tokens.credit
              : (hh.netBalance.isNegative ? Tokens.debt : Tokens.ink)
          )
        }
        summaryRow(label: L10n.tr("breakdown.carryOver"), money: hh.carryOverBalance)
        summaryRow(label: L10n.tr("breakdown.periodExpenses"), money: hh.focusExpenseDelta)
        summaryRow(label: L10n.tr("breakdown.periodTransfers"), money: hh.focusTransferDelta)
        if !hh.postCycleDelta.isZero {
          summaryRow(label: L10n.tr("breakdown.postCycleDelta"), money: hh.postCycleDelta)
        }
      }
    }
  }

  private var allocationCard: some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("breakdown.transferAllocation"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
        ForEach(memberTransfers) { transfer in
          let fromName =
            members.first(where: { $0.id == transfer.fromMemberId })?.name ?? ""
          let toName =
            members.first(where: { $0.id == transfer.toMemberId })?.name ?? ""
          HStack {
            Text("\(fromName) → \(toName)")
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

  private var linesCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      if !breakdown.lines.isEmpty {
        ForEach(breakdown.lines) { line in
          SPCard(padding: 14) {
            HStack(alignment: .top, spacing: 10) {
              VStack(alignment: .leading, spacing: 3) {
                Text(line.description)
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
                  .lineLimit(2)
                Text("\(LedgerDateLabels.dayLabel(for: line.occurredAt)) · \(line.payerSummary)")
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
              Spacer(minLength: 8)
              VStack(alignment: .trailing, spacing: 3) {
                MoneyText(
                  line.delta,
                  style: .signed,
                  font: Typography.subheadlineBold,
                  color: line.delta.isPositive ? Tokens.credit : Tokens.debt
                )
                if !line.memberShare.isZero && line.memberShare != line.totalAmount {
                  Text(
                    "\(MoneyFormat.full(line.memberShare)) / \(MoneyFormat.full(line.totalAmount))"
                  )
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
                } else {
                  MoneyText(
                    line.totalAmount,
                    style: .full,
                    font: Typography.caption,
                    color: Tokens.muted
                  )
                }
              }
            }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Breakdown Loaded") {
    if let first = PreviewSamples.sampleBreakdowns.breakdowns.first {
      MemberBreakdownSheetView(
        breakdown: first,
        focusLabel: PreviewSamples.sampleBreakdowns.resolvedFocus.label,
        memberTransfers: [TripScenario.step4Balances.transfers[0]],
        members: TripScenario.members,
        onDismiss: {}
      )
    }
  }
#endif
