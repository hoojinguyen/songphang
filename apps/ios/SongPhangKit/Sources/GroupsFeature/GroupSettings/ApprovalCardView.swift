import DesignSystem
import Domain
import SwiftUI

struct ApprovalCardView: View {
  private enum PendingAction: Equatable {
    case save(Money)
    case disable
  }

  let group: ExpenseGroup
  let isDisabled: Bool
  let isPending: Bool
  let onSave: (Money?) -> Void

  @State private var isEnabled: Bool
  @State private var amountText: String
  @State private var hasDraftEdit = false
  @State private var pendingAction: PendingAction?

  init(
    group: ExpenseGroup,
    isDisabled: Bool,
    isPending: Bool,
    onSave: @escaping (Money?) -> Void
  ) {
    self.group = group
    self.isDisabled = isDisabled
    self.isPending = isPending
    self.onSave = onSave
    self._isEnabled = State(initialValue: group.approvalThreshold != nil)
    self._amountText = State(
      initialValue: group.approvalThreshold.map { MoneyFormat.amount($0) } ?? ""
    )
  }

  var body: some View {
    let parsed = MoneyFormat.parseInput(amountText)
    let isValid = parsed.map { $0.amount >= 1 && $0.amount <= 999_999_999_999 } ?? false
    let isUnchanged =
      group.approvalThreshold != nil && parsed == group.approvalThreshold

    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(L10n.tr("approval.settingsTitle"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        Spacer()

        Toggle(
          L10n.tr("approval.settingsTitle"),
          isOn: Binding(
            get: { isEnabled },
            set: { next in
              isEnabled = next
              if !next {
                if group.approvalThreshold != nil {
                  pendingAction = .disable
                  hasDraftEdit = false
                  onSave(nil)
                } else {
                  amountText = ""
                  hasDraftEdit = false
                }
              } else {
                hasDraftEdit = true
              }
            }
          )
        )
        .labelsHidden()
        .tint(Tokens.accent)
        .disabled(isDisabled || isPending)
      }

      if isEnabled {
        SPTextField(
          label: L10n.tr("approval.thresholdLabel"),
          text: Binding(
            get: { amountText },
            set: { next in
              let digits = next.filter { $0.isWholeNumber && $0.isASCII }
              if digits.isEmpty {
                amountText = ""
              } else if let amount = MoneyFormat.parseInput(digits) {
                amountText = MoneyFormat.amount(amount)
              }
              hasDraftEdit = true
            }
          )
        )
        .keyboardType(.numberPad)
        .disabled(isDisabled || isPending)

        Text(L10n.tr("approval.settingsHint"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        SPButton(
          L10n.tr("fund.saveButton"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: isDisabled || isPending || !isValid || isUnchanged,
          isPending: isPending
        ) {
          if let parsed {
            pendingAction = .save(parsed)
            onSave(parsed)
          }
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .onChange(of: group.approvalThreshold) { _, newThreshold in
      let matchesPendingAndCurrentDraft: Bool = {
        switch pendingAction {
        case .save(let target):
          return newThreshold == target && MoneyFormat.parseInput(amountText) == target
        case .disable:
          return newThreshold == nil
        case nil:
          return false
        }
      }()
      if matchesPendingAndCurrentDraft || !hasDraftEdit {
        isEnabled = newThreshold != nil
        if let newThreshold {
          amountText = MoneyFormat.amount(newThreshold)
        } else {
          amountText = ""
        }
        hasDraftEdit = false
        pendingAction = nil
      } else if case .save(let target) = pendingAction, newThreshold == target {
        pendingAction = nil
      }
    }
    .onChange(of: isPending) { wasPending, nowPending in
      if wasPending && !nowPending {
        switch pendingAction {
        case .disable:
          isEnabled = group.approvalThreshold != nil
          if let threshold = group.approvalThreshold {
            amountText = MoneyFormat.amount(threshold)
          } else {
            amountText = ""
          }
        case .save(let target):
          if group.approvalThreshold == target, MoneyFormat.parseInput(amountText) == target {
            hasDraftEdit = false
          }
        case nil:
          break
        }
        pendingAction = nil
      }
    }
  }
}
