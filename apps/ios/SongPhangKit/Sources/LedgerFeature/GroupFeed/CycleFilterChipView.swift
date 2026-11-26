import DesignSystem
import Domain
import SwiftUI

struct CycleFilterChipView: View {
  private let overview: SettlementCyclesOverview
  private let selectedCycle: TransactionCycleFilter?
  private let onSelectCycle: (TransactionCycleFilter?) -> Void

  init(
    overview: SettlementCyclesOverview,
    selectedCycle: TransactionCycleFilter?,
    onSelectCycle: @escaping (TransactionCycleFilter?) -> Void
  ) {
    self.overview = overview
    self.selectedCycle = selectedCycle
    self.onSelectCycle = onSelectCycle
  }

  var body: some View {
    if !overview.cycles.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Menu {
            Button {
              onSelectCycle(.current)
            } label: {
              Label(
                "\(L10n.tr("cycles.currentPeriod")) (\(overview.currentPeriod.countedTransactionCount))",
                systemImage: selectedCycle == .current ? "checkmark" : ""
              )
            }

            Button {
              onSelectCycle(nil)
            } label: {
              Label(
                L10n.tr("cycles.allPeriods"),
                systemImage: selectedCycle == nil ? "checkmark" : ""
              )
            }

            Divider()

            ForEach(overview.cycles) { cycle in
              Button {
                onSelectCycle(.cycle(cycle.id))
              } label: {
                let isSelected = selectedCycle == .cycle(cycle.id)
                Label(
                  cycle.title,
                  systemImage: isSelected ? "checkmark" : ""
                )
              }
            }
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "calendar")
                .font(.system(size: 12, weight: .semibold))
              Text(currentLabel)
                .font(Typography.captionBold)
              Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Tokens.surface, in: Capsule())
          }

          Spacer(minLength: 0)
        }

        if case .cycle(let activeId) = selectedCycle,
          let activeCycle = overview.cycles.first(where: { $0.id == activeId })
        {
          HStack(spacing: 8) {
            Text(L10n.t("cycles.viewingBanner", ["title": activeCycle.title]))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.onAccent)
            Spacer(minLength: 4)
            Button(L10n.tr("cycles.backToCurrent")) {
              onSelectCycle(.current)
            }
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.onAccent)
            .underline()
            .buttonStyle(.plain)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
      }
    }
  }

  private var currentLabel: String {
    switch selectedCycle {
    case .current:
      return
        "\(L10n.tr("cycles.currentPeriod")) (\(overview.currentPeriod.countedTransactionCount))"
    case .cycle(let id):
      return overview.cycles.first(where: { $0.id == id })?.title
        ?? L10n.tr("cycles.currentPeriod")
    case nil:
      return L10n.tr("cycles.allPeriods")
    }
  }
}
