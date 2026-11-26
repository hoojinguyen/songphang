import DesignSystem
import Domain
import SwiftUI

struct GuestTransactionDetailSheet: View {
  let transaction: GuestTransaction
  let members: [GuestMember]
  let loadAttachment: @Sendable (Attachment.ID) async throws -> Data
  let onDismiss: () -> Void

  private func memberName(for id: Member.ID) -> String {
    members.first(where: { $0.id == id })?.name ?? ""
  }

  private var categoryLabel: (name: String, color: Color?)? {
    if let category = transaction.category {
      return (CategoryDisplay.localizedName(for: category), nil)
    }
    if let name = transaction.categoryName, !name.isEmpty {
      let color = transaction.categoryColor.map { Tokens.color(for: $0) }
      return (name, color)
    }
    return nil
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          headerCard
          metadataBadges
          if let note = transaction.paymentNote, !note.isEmpty {
            SPCard(padding: 14) {
              Text(note)
                .font(Typography.subheadline)
                .foregroundStyle(Tokens.ink)
            }
          }
          if case .items(let items, let extras, let allocation) = transaction.split {
            itemsBreakdownCard(items: items, extras: extras, allocation: allocation)
          } else if !transaction.split.extras.isEmpty {
            TransactionExtrasCardView(
              totalAmount: transaction.amount,
              extras: transaction.split.extras,
              allocation: transaction.split.extrasAllocation
            )
          }
          if !transaction.payers.isEmpty || !transaction.shares.isEmpty {
            payersAndSharesCard
          }
          if !transaction.attachments.isEmpty {
            HStack(spacing: 12) {
              ForEach(transaction.attachments) { attachment in
                RemoteAttachmentThumbnail(
                  attachmentId: attachment.id,
                  size: 88,
                  cornerRadius: 16,
                  loadContent: loadAttachment
                )
              }
            }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
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
      VStack(alignment: .leading, spacing: 8) {
        Text(DayLabelFormat.dayLabel(for: transaction.occurredAt))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Text(transaction.description)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
        MoneyText(
          transaction.amount,
          style: .full,
          font: Typography.heroNumber,
          color: Tokens.ink
        )
      }
    }
  }

  @ViewBuilder
  private var metadataBadges: some View {
    let hasChannel = transaction.type == .transfer && transaction.paymentChannel != nil
    if categoryLabel != nil || hasChannel {
      HStack(spacing: 8) {
        if let cat = categoryLabel {
          HStack(spacing: 6) {
            if let dotColor = cat.color {
              Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
            }
            Text(cat.name)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        if hasChannel, let channel = transaction.paymentChannel {
          PaymentChannelBadge(channel)
        }
      }
    }
  }

  private func itemsBreakdownCard(
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra],
    allocation: ExtrasAllocation?
  ) -> some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("split.methodItems"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)

        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
              Text(item.name.isEmpty ? "—" : item.name)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
              if !item.memberIds.isEmpty {
                Text(item.memberIds.map { memberName(for: $0) }.joined(separator: ", "))
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
            }
            Spacer(minLength: 8)
            MoneyText(
              item.amount,
              style: .full,
              font: Typography.captionBold,
              color: Tokens.ink
            )
          }
          .padding(.vertical, 3)
        }

        if !extras.isEmpty {
          Divider().overlay(Tokens.borderSubtle)
          TransactionExtrasCardView(
            totalAmount: transaction.amount,
            extras: extras,
            allocation: allocation,
            showCardChrome: false
          )
        }
      }
    }
  }

  private var payersAndSharesCard: some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        ForEach(transaction.payers, id: \.memberId) { item in
          HStack {
            Text(L10n.t("compose.payer", ["name": memberName(for: item.memberId)]))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            Spacer()
            MoneyText(
              item.amount,
              style: .full,
              font: Typography.captionBold,
              color: Tokens.credit
            )
          }
        }
        if !transaction.shares.isEmpty {
          Divider().overlay(Tokens.borderSubtle)
          ForEach(transaction.shares, id: \.memberId) { item in
            HStack {
              Text(memberName(for: item.memberId))
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
              Spacer()
              MoneyText(
                item.amount,
                style: .full,
                font: Typography.captionBold,
                color: Tokens.ink
              )
            }
          }
        }
      }
    }
  }
}
