import DesignSystem
import Domain
import SwiftUI

struct BudgetSettingsCard: View {
  let budget: GroupBudget?
  let isDisabled: Bool
  let isPending: Bool
  let errorMessage: String?
  let onSave: (BudgetPeriod, Money) -> Void
  let onRemove: () -> Void

  @State private var period: BudgetPeriod = .month
  @State private var amountText: String = ""
  @State private var hasDraftEdit = false

  var body: some View {
    let activePeriod = hasDraftEdit ? period : (budget?.period ?? .month)
    let activeAmountText =
      hasDraftEdit ? amountText : (budget.map { MoneyFormat.amount($0.amount) } ?? "")
    let parsed = MoneyFormat.parseInput(activeAmountText)
    let isValid = parsed.map { $0.amount >= 1 && $0.amount <= 999_999_999_999 } ?? false
    let isUnchanged = budget != nil && activePeriod == budget?.period && parsed == budget?.amount

    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.tr("budget.title"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      SPSegmentedControl(
        label: L10n.tr("budget.title"),
        options: [
          SPSegmentedControl.Option(
            value: BudgetPeriod.month.rawValue, label: L10n.tr("budget.periodMonth")),
          SPSegmentedControl.Option(
            value: BudgetPeriod.total.rawValue, label: L10n.tr("budget.periodTotal")),
        ],
        value: activePeriod.rawValue,
        isDisabled: isDisabled || isPending
      ) { next in
        if let nextPeriod = BudgetPeriod(rawValue: next) {
          period = nextPeriod
          if !hasDraftEdit {
            amountText = activeAmountText
            hasDraftEdit = true
          }
        }
      }

      SPTextField(
        label: L10n.tr("budget.amountLabel"),
        text: Binding(
          get: { activeAmountText },
          set: { next in
            let digits = next.filter { $0.isWholeNumber && $0.isASCII }
            if digits.isEmpty {
              amountText = ""
            } else if let amount = MoneyFormat.parseInput(digits) {
              amountText = MoneyFormat.amount(amount)
            }
            if !hasDraftEdit {
              period = activePeriod
              hasDraftEdit = true
            }
          }
        )
      )
      .keyboardType(.numberPad)

      if let errorMessage {
        Text(errorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }

      HStack(spacing: 10) {
        SPButton(
          L10n.tr("budget.save"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: isDisabled || isPending || !isValid || isUnchanged,
          isPending: isPending
        ) {
          if let parsed {
            onSave(activePeriod, parsed)
          }
        }

        if budget != nil {
          SPButton(
            L10n.tr("budget.remove"),
            variant: .surface,
            isFullWidth: true,
            isDisabled: isDisabled || isPending
          ) {
            onRemove()
          }
        }
      }
    }
    .onChange(of: budget) { _, _ in
      hasDraftEdit = false
      amountText = ""
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}
