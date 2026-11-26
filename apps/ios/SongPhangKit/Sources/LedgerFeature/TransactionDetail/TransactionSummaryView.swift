import DesignSystem
import Domain
import SwiftUI

struct TransactionSummaryView: View {
  let transaction: LedgerTransaction
  let members: [Member]
  let categories: [GroupCategory]
  var loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)? = nil

  private func memberName(for id: Member.ID) -> String {
    members.first(where: { $0.id == id })?.name ?? ""
  }

  private var payerNames: String {
    if transaction.payers.count > 1 {
      return transaction.payers.map {
        "\(memberName(for: $0.memberId)) \(MoneyFormat.compact($0.amount))"
      }.joined(separator: " · ")
    }
    guard let first = transaction.payers.first else { return "" }
    return memberName(for: first.memberId)
  }

  private var formattedDateTime: String {
    let day = LedgerDateLabels.dayLabel(for: transaction.occurredAt)
    let time = LedgerDateLabels.timeLabel(for: transaction.occurredAt)
    return time.isEmpty ? day : "\(day) · \(time)"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if transaction.deletedAt != nil {
        Text(L10n.tr("expenseForm.deletedNotice"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      }

      HStack {
        Text(formattedDateTime)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        Spacer()

        if transaction.version > 1 {
          Text(L10n.tr("feed.edited"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }
      }

      Text(transaction.description)
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(MoneyFormat.amount(transaction.amount))
          .font(.system(size: 44, weight: .black))
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 10)
          .padding(.vertical, 2)
          .background(
            Tokens.phraseAmount,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
          )

        Text(L10n.tr("common.currency"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.muted)
      }

      VStack(alignment: .leading, spacing: 8) {
        let payerChipText: String = {
          if transaction.type == .income {
            return "\(L10n.tr("expenseForm.typeIncome")): \(payerNames)"
          } else if transaction.type == .transfer {
            let from = transaction.payers.first.map { memberName(for: $0.memberId) } ?? ""
            let to = transaction.shares.first.map { memberName(for: $0.memberId) } ?? ""
            return "\(from) → \(to)"
          } else {
            return L10n.t("compose.payer", ["name": payerNames])
          }
        }()

        Text(payerChipText)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            Tokens.phrasePayer,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )

        if transaction.type == .transfer,
          transaction.paymentChannel != nil || (transaction.paymentNote?.isEmpty == false)
        {
          HStack(spacing: 8) {
            if let channel = transaction.paymentChannel {
              PaymentChannelBadge(channel)
            }
            if let note = transaction.paymentNote, !note.isEmpty {
              Text("“\(note)”")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
          }
        }

        if transaction.type != .transfer, !transaction.shares.isEmpty {
          let splitText: String = {
            switch transaction.split {
            case .exact(_, let entries, _, _, _):
              let parts = entries.map { entry in
                "\(memberName(for: entry.memberId)) \(MoneyFormat.compact(entry.amount))"
              }.joined(separator: " · ")
              return L10n.t("compose.exact", ["parts": parts])
            case .items:
              return L10n.tr("split.methodItems")
            case .shares:
              return L10n.tr("split.methodShares")
            case .percent:
              return L10n.tr("split.methodPercent")
            case .equal:
              let isEqual = transaction.shares.allSatisfy {
                $0.amount == transaction.shares.first?.amount
              }
              return L10n.t(
                isEqual ? "compose.equal" : "compose.equalUneven",
                [
                  "count": String(transaction.shares.count),
                  "amount": MoneyFormat.amount(transaction.shares.first?.amount ?? .zero),
                ]
              )
            }
          }()

          Text(splitText)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              Tokens.phraseSplit,
              in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
      }

      if let catDisplay = CategoryDisplay.label(
        category: transaction.category,
        categoryId: transaction.categoryId,
        categories: categories,
        includeArchivedTag: true
      ) {
        HStack(spacing: 6) {
          if let dotColor = catDisplay.color {
            Circle()
              .fill(dotColor)
              .frame(width: 10, height: 10)
          }
          Text(catDisplay.name)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      if case .items(let items, let extras, let allocation) = transaction.split {
        VStack(spacing: 8) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            HStack {
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
              Spacer()
              MoneyText(item.amount, style: .full, font: Typography.captionBold, color: Tokens.ink)
            }
            .padding(.vertical, 4)
          }

          if !extras.isEmpty {
            Divider().overlay(Tokens.borderSubtle)
            TransactionExtrasCardView(
              totalAmount: transaction.amount,
              extras: extras,
              allocation: allocation,
              defaultAllocation: .proportional,
              showCardChrome: false
            )
          }
        }
        .padding(14)
        .background(Tokens.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      } else if !transaction.split.extras.isEmpty {
        TransactionExtrasCardView(
          totalAmount: transaction.amount,
          extras: transaction.split.extras,
          allocation: transaction.split.extrasAllocation
        )
      }

      if transaction.type != .transfer, !transaction.shares.isEmpty {
        let items: [ShareShapeItem] = transaction.shares.compactMap { s in
          guard let m = members.first(where: { $0.id == s.memberId }) else { return nil }
          return ShareShapeItem(member: m, amount: s.amount)
        }
        if !items.isEmpty {
          ShareShapesView(shares: items)
        }
      }

      if transaction.deletedAt == nil, !transaction.attachments.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(transaction.attachments) { att in
              RemoteAttachmentThumbnail(attachmentId: att.id, size: 84, cornerRadius: 18) { id in
                if let loadAttachment {
                  return try await loadAttachment(id)
                }
                return Data()
              }
            }
          }
        }
      }
    }
    .padding(20)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
  }
}
