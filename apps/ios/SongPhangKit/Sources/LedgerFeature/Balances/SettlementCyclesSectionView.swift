import DesignSystem
import Domain
import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

struct SettlementCyclesSectionView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let overview: SettlementCyclesOverview?
  private let isOwner: Bool
  private let isArchived: Bool
  private let isOffline: Bool
  private let isReopening: Bool
  private let errorMessage: String?
  private let onViewCycleExpenses: ((SettlementCycle.ID) -> Void)?
  private let onReopenLatest: ((SettlementCycle.ID) -> Void)?

  @State private var expandedCycleId: SettlementCycle.ID?
  @State private var isDefaultLatestCollapsed = false
  @State private var cyclePendingReopen: SettlementCycle?

  init(
    overview: SettlementCyclesOverview?,
    isOwner: Bool,
    isArchived: Bool,
    isOffline: Bool,
    isReopening: Bool = false,
    errorMessage: String? = nil,
    onViewCycleExpenses: ((SettlementCycle.ID) -> Void)? = nil,
    onReopenLatest: ((SettlementCycle.ID) -> Void)? = nil
  ) {
    self.overview = overview
    self.isOwner = isOwner
    self.isArchived = isArchived
    self.isOffline = isOffline
    self.isReopening = isReopening
    self.errorMessage = errorMessage
    self.onViewCycleExpenses = onViewCycleExpenses
    self.onReopenLatest = onReopenLatest
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let errorMessage {
        Text(errorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
      }

      if let current = overview?.currentPeriod {
        SPCard(padding: 16) {
          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("cycles.currentPeriod"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
            HStack {
              Text("\(LedgerDateLabels.dayLabel(for: current.startedAt)) – \(current.expenseCount)")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
              Spacer()
              MoneyText(
                current.totalExpenseAmount,
                style: .full,
                font: Typography.subheadlineBold,
                color: Tokens.ink
              )
            }
          }
        }
      }

      let cycles = overview?.cycles ?? []
      if cycles.isEmpty {
        SPCard {
          Text(L10n.tr("cycles.emptyPeriodError"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        }
      } else {
        ForEach(Array(cycles.enumerated()), id: \.element.id) { index, cycle in
          cycleCard(cycle, isLatest: index == 0)
        }
      }
    }
    .confirmationDialog(
      L10n.tr("cycles.reopenAction"),
      isPresented: Binding(
        get: { cyclePendingReopen != nil },
        set: { if !$0 { cyclePendingReopen = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let target = cyclePendingReopen {
        Button(L10n.tr("cycles.reopenAction"), role: .destructive) {
          onReopenLatest?(target.id)
          cyclePendingReopen = nil
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        cyclePendingReopen = nil
      }
    } message: {
      Text(L10n.tr("cycles.reopenConfirmBody"))
    }
  }

  private func cycleCard(_ cycle: SettlementCycle, isLatest: Bool) -> some View {
    let isExpanded =
      expandedCycleId == cycle.id
      || (expandedCycleId == nil && isLatest && !isDefaultLatestCollapsed)
    return SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 12) {
        Button {
          Motion.withAnimation(Motion.smooth, reduceMotion: reduceMotion) {
            if isLatest {
              if isExpanded {
                expandedCycleId = nil
                isDefaultLatestCollapsed = true
              } else {
                expandedCycleId = cycle.id
                isDefaultLatestCollapsed = false
              }
            } else {
              expandedCycleId = (expandedCycleId == cycle.id) ? nil : cycle.id
            }
          }
        } label: {
          HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
              Text(cycle.title)
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
              Text(
                "\(LedgerDateLabels.dayLabel(for: cycle.startedAt)) – \(LedgerDateLabels.dayLabel(for: cycle.closedAt))"
              )
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
              MoneyText(
                cycle.totalExpenseAmount,
                style: .full,
                font: Typography.subheadlineBold,
                color: Tokens.ink
              )
              Text("\(cycle.expenseCount)")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
          }
        }
        .buttonStyle(.plain)

        if isExpanded {
          Divider().overlay(Tokens.borderSubtle)

          Text(L10n.tr("cycles.frozenSnapshotLabel"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          if !cycle.snapshot.transfers.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
              ForEach(cycle.snapshot.transfers) { transfer in
                HStack {
                  Text("\(transfer.fromName) → \(transfer.toName)")
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

          VStack(alignment: .leading, spacing: 6) {
            ForEach(cycle.snapshot.balances) { item in
              HStack(spacing: 8) {
                MemberShapeView(
                  shape: item.shape,
                  color: item.color,
                  name: item.name,
                  size: 20,
                  showInitial: false
                )
                Text(item.name)
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.ink)
                Spacer()
                MoneyText(
                  item.balance,
                  style: .signed,
                  font: Typography.captionBold,
                  color: item.balance.isPositive
                    ? Tokens.credit
                    : (item.balance.isNegative ? Tokens.debt : Tokens.muted)
                )
              }
            }
          }

          if let onViewCycleExpenses {
            SPButton(
              L10n.tr("cycles.viewExpensesAction"),
              variant: .surface,
              isFullWidth: true
            ) {
              onViewCycleExpenses(cycle.id)
            }
          }

          if isLatest && isOwner && !isArchived && !isOffline, onReopenLatest != nil {
            SPButton(
              L10n.tr("cycles.reopenAction"),
              variant: .surface,
              isFullWidth: true,
              isDisabled: isReopening,
              isPending: isReopening
            ) {
              cyclePendingReopen = cycle
            }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Cycles Loaded") {
    ScrollView {
      SettlementCyclesSectionView(
        overview: SettlementCyclesOverview(
          cycles: [PreviewSamples.sampleCycle],
          currentPeriod: CurrentPeriodSummary(
            startedAt: "2026-11-16T15:00:00.000Z",
            expenseCount: 1,
            totalExpenseAmount: Money(99_999),
            countedTransactionCount: 1
          )
        ),
        isOwner: true,
        isArchived: false,
        isOffline: false
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }

  #Preview("Cycles Empty") {
    ScrollView {
      SettlementCyclesSectionView(
        overview: SettlementCyclesOverview(
          cycles: [],
          currentPeriod: CurrentPeriodSummary(
            startedAt: "2026-11-10T00:00:00.000Z",
            expenseCount: 0,
            totalExpenseAmount: .zero,
            countedTransactionCount: 0
          )
        ),
        isOwner: true,
        isArchived: false,
        isOffline: false
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }
#endif
