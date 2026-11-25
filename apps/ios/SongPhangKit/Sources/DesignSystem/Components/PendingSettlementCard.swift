public import Domain
public import Foundation
public import SwiftUI

public struct PendingSettlementCard: View {
  private let amount: Money
  private let fromName: String
  private let toName: String
  private let channel: PaymentChannel?
  private let note: String?
  private let proofAttachmentId: Attachment.ID?
  private let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
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
    channel: PaymentChannel? = nil,
    note: String? = nil,
    proofAttachmentId: Attachment.ID? = nil,
    loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)? = nil,
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
    self.channel = channel
    self.note = note
    self.proofAttachmentId = proofAttachmentId
    self.loadAttachment = loadAttachment
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
      HStack(alignment: .top, spacing: 10) {
        VStack(alignment: .leading, spacing: 6) {
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

          if channel != nil || (note?.isEmpty == false) {
            HStack(spacing: 6) {
              if let channel {
                PaymentChannelBadge(channel)
              }
              if let note, !note.isEmpty {
                Text("“\(note)”")
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
                  .lineLimit(2)
              }
            }
          }
        }

        Spacer(minLength: 4)

        if let proofAttachmentId, let loadAttachment {
          RemoteAttachmentThumbnail(
            attachmentId: proofAttachmentId,
            size: 38,
            cornerRadius: 10,
            loadContent: loadAttachment
          )
          .accessibilityLabel(L10n.tr("settlementProof.viewProof"))
        } else if proofAttachmentId != nil {
          ProofBadgeView(attachmentId: nil)
        }
      }

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
