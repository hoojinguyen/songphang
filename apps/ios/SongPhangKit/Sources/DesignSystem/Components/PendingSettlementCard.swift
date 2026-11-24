public import Domain
public import SwiftUI

public struct PendingSettlementCard: View {
  private let amount: Money
  private let fromName: String
  private let toName: String
  private let canResolve: Bool
  private let canCancel: Bool
  private let isDisabled: Bool
  private let isPending: Bool
  private let onConfirm: () -> Void
  private let onReject: () -> Void
  private let onCancel: () -> Void

  public init(
    amount: Money,
    fromName: String,
    toName: String,
    canResolve: Bool,
    canCancel: Bool,
    isDisabled: Bool,
    isPending: Bool,
    onConfirm: @escaping () -> Void,
    onReject: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.amount = amount
    self.fromName = fromName
    self.toName = toName
    self.canResolve = canResolve
    self.canCancel = canCancel
    self.isDisabled = isDisabled
    self.isPending = isPending
    self.onConfirm = onConfirm
    self.onReject = onReject
    self.onCancel = onCancel
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(
        canResolve
          ? L10n.t(
            "pay.pendingConfirmText",
            ["from": fromName, "amount": MoneyFormat.full(amount)]
          )
          : L10n.t("pay.pendingWaiting", ["to": toName])
      )
      .font(Typography.subheadlineBold)
      .foregroundStyle(Tokens.ink)

      if canResolve || canCancel {
        ViewThatFits {
          HStack(spacing: 8) {
            actionButtons(fullWidth: false)
          }
          VStack(spacing: 8) {
            actionButtons(fullWidth: true)
          }
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }

  @ViewBuilder
  private func actionButtons(fullWidth: Bool) -> some View {
    if canResolve {
      SPButton(
        L10n.tr("balances.received"),
        variant: .accent,
        isFullWidth: fullWidth,
        isDisabled: isDisabled,
        isPending: isPending,
        action: onConfirm
      )
      SPButton(
        L10n.tr("pay.rejectReceived"),
        variant: .surface,
        isFullWidth: fullWidth,
        isDisabled: isDisabled,
        isPending: isPending,
        action: onReject
      )
    }
    if canCancel {
      SPButton(
        L10n.tr("pay.cancelReport"),
        variant: .surface,
        isFullWidth: fullWidth || !canResolve,
        isDisabled: isDisabled,
        isPending: isPending,
        action: onCancel
      )
    }
  }
}
