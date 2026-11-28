import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

struct CloseCycleSheetView: View {
  private let currentPeriod: CurrentPeriodSummary
  private let nextCycleNumber: Int
  private let isClosing: Bool
  private let errorMessage: String?
  private let onConfirm: (String) async -> Void
  private let onDismiss: () -> Void

  @State private var title: String

  init(
    currentPeriod: CurrentPeriodSummary,
    nextCycleNumber: Int,
    isClosing: Bool = false,
    errorMessage: String? = nil,
    onConfirm: @escaping (String) async -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.currentPeriod = currentPeriod
    self.nextCycleNumber = nextCycleNumber
    self.isClosing = isClosing
    self.errorMessage = errorMessage
    self.onConfirm = onConfirm
    self.onDismiss = onDismiss
    self._title = State(
      initialValue: L10n.t("cycles.defaultTitle", ["number": String(nextCycleNumber)])
    )
  }

  private var defaultTitle: String {
    L10n.t("cycles.defaultTitle", ["number": String(nextCycleNumber)])
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("cycles.titleLabel"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
            TextField(
              defaultTitle,
              text: $title
            )
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onChange(of: title) { _, newValue in
              if newValue.utf16.count > 80 {
                var clamped = newValue
                while clamped.utf16.count > 80, !clamped.isEmpty {
                  clamped.removeLast()
                }
                title = clamped
              }
            }
          }

          SPCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
              Text(L10n.tr("cycles.currentPeriod"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
              HStack {
                Text(LedgerDateLabels.dayLabel(for: currentPeriod.startedAt))
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
                Spacer()
                MoneyText(
                  currentPeriod.totalExpenseAmount,
                  style: .full,
                  font: Typography.bodyBold,
                  color: Tokens.ink
                )
              }
            }
          }

          SPCard(tone: .accent, padding: 16) {
            Text(L10n.tr("cycles.carryOverNote"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.onAccent)
          }

          if let errorMessage {
            Text(errorMessage)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.debt)
          }

          if currentPeriod.countedTransactionCount == 0 {
            Text(L10n.tr("cycles.emptyPeriodError"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
          }

          SPButton(
            L10n.tr("cycles.closeAction"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: currentPeriod.countedTransactionCount == 0
              || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isPending: isClosing
          ) {
            Task { await onConfirm(title) }
          }
        }
        .padding(20)
        .spFittedSheetContent()
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("cycles.closeTitle"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          SheetCancelButton(action: onDismiss)
            .disabled(isClosing)
        }
      }
    }
    .spSheet(.fitted, embedsNavigationStack: true)
    .discardGuard(isDirty: title != defaultTitle && !isClosing, onDiscard: onDismiss)
  }
}

#if DEBUG
  #Preview("Close Cycle") {
    CloseCycleSheetView(
      currentPeriod: CurrentPeriodSummary(
        startedAt: "2026-11-10T00:00:00.000Z",
        expenseCount: 3,
        totalExpenseAmount: Money(1_599_999),
        countedTransactionCount: 3
      ),
      nextCycleNumber: 1,
      onConfirm: { _ in },
      onDismiss: {}
    )
  }
#endif
