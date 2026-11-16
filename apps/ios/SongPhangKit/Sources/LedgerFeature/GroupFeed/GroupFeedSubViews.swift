import DesignSystem
import Domain
import SwiftUI

struct FeedBalanceBlockView: View {
  let balance: Money
  let onOpenBalances: () -> Void

  var body: some View {
    let caption =
      balance.isPositive
      ? L10n.tr("feed.owedToYou")
      : balance.isNegative
        ? L10n.tr("feed.youOwe")
        : L10n.tr("feed.settled")

    let actionLabel =
      balance.isPositive
      ? L10n.tr("feed.collect")
      : balance.isNegative
        ? L10n.tr("feed.pay")
        : L10n.tr("feed.view")

    Button(action: onOpenBalances) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(caption)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
          MoneyText(
            balance.magnitude,
            style: .full,
            font: Typography.heroNumber,
            color: Tokens.ink
          )
        }
        Spacer(minLength: 8)
        Text(actionLabel)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.surface)
          .padding(.horizontal, 20)
          .frame(minHeight: 48)
          .background(Tokens.ink)
          .clipShape(Capsule())
      }
      .padding(.leading, 20)
      .padding(.trailing, 18)
      .padding(.top, 14)
      .padding(.bottom, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.accent)
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct FeedTransactionRowView: View {
  let transaction: LedgerTransaction
  let members: [Member]
  let myMemberId: Member.ID?
  let canEdit: Bool
  let onTap: () -> Void

  var body: some View {
    Group {
      if canEdit {
        Button(action: onTap) {
          rowContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.t("feed.editRow", ["description": transaction.description]))
      } else {
        rowContent
      }
    }
  }

  @ViewBuilder
  private var rowContent: some View {
    if transaction.type == .expense {
      expenseBubble
    } else {
      ledgerPill
    }
  }

  private var expenseBubble: some View {
    let payer = members.first(where: { $0.id == transaction.payers.first?.memberId })
    let isMine = payer?.id == myMemberId && myMemberId != nil
    let myShare = transaction.shares.first(where: { $0.memberId == myMemberId })

    return HStack(alignment: .bottom, spacing: 8) {
      if isMine {
        Spacer(minLength: 48)
      } else if let payer {
        MemberShapeView(
          shape: payer.shape,
          color: payer.color,
          name: payer.name,
          size: 36
        )
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(
          isMine
            ? L10n.tr("feed.youPaid")
            : L10n.t("feed.memberPaid", ["name": payer?.name ?? ""])
        )
        .font(Typography.captionBold)
        .foregroundStyle(isMine ? Tokens.onInkMuted : Tokens.muted)

        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text(transaction.description)
            .font(Typography.bodyBold)
            .foregroundStyle(isMine ? Tokens.surface : Tokens.ink)
          Spacer(minLength: 4)
          MoneyText(
            transaction.amount,
            style: .amountOnly,
            font: Typography.sectionTitle,
            color: isMine ? Tokens.surface : Tokens.ink
          )
        }

        if transaction.version > 1 {
          Text(L10n.tr("feed.edited"))
            .font(Typography.captionBold)
            .foregroundStyle(isMine ? Tokens.onInkMuted : Tokens.muted)
        }

        if isMine {
          HStack(spacing: 4) {
            ForEach(Array(transaction.shares.prefix(4))) { share in
              let member = members.first(where: { $0.id == share.memberId })
              HStack(spacing: 4) {
                if let member {
                  MemberShapeView(
                    shape: member.shape,
                    color: member.color,
                    name: member.name,
                    size: 14,
                    showInitial: false
                  )
                }
                Text(MoneyFormat.compact(share.amount))
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.surface)
              }
              .padding(.horizontal, 9)
              .padding(.vertical, 5)
              .background(Tokens.inkRaised)
              .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            if transaction.shares.count > 4 {
              Text(L10n.t("feed.moreShares", ["count": String(transaction.shares.count - 4)]))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.surface)
                .padding(.horizontal, 6)
            }
          }
          .padding(.top, 4)
        } else {
          let shareLine =
            if let myShare {
              L10n.t(
                "feed.equalSplitMine",
                [
                  "count": String(transaction.shares.count),
                  "amount": MoneyFormat.amount(myShare.amount),
                ]
              )
            } else {
              L10n.t(
                "feed.equalSplitNotMine",
                [
                  "count": String(transaction.shares.count)
                ]
              )
            }
          Text(shareLine)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
            .padding(.top, 2)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .padding(.bottom, 14)
      .background(isMine ? Tokens.ink : Tokens.surface)
      .clipShape(
        UnevenRoundedRectangle(
          topLeadingRadius: 26,
          bottomLeadingRadius: isMine ? 26 : 8,
          bottomTrailingRadius: isMine ? 8 : 26,
          topTrailingRadius: 26,
          style: .continuous
        )
      )

      if !isMine {
        Spacer(minLength: 48)
      }
    }
  }

  private var ledgerPill: some View {
    let from = members.first(where: { $0.id == transaction.payers.first?.memberId })
    let to = members.first(where: { $0.id == transaction.shares.first?.memberId })
    let amountStr = MoneyFormat.full(transaction.amount)
    let text: String
    if let from {
      if transaction.type == .income {
        let key = from.id == myMemberId ? "feed.incomeYou" : "feed.income"
        text = L10n.t(
          key,
          [
            "name": from.name,
            "description": transaction.description,
            "amount": amountStr,
          ]
        )
      } else if let to {
        if from.id == myMemberId {
          text = L10n.t("feed.transferFromYou", ["name": to.name, "amount": amountStr])
        } else if to.id == myMemberId {
          text = L10n.t("feed.transferToYou", ["name": from.name, "amount": amountStr])
        } else {
          text = L10n.t(
            "feed.transferOther", ["from": from.name, "to": to.name, "amount": amountStr])
        }
      } else {
        text = transaction.description
      }
    } else {
      text = transaction.description
    }

    return HStack(spacing: 8) {
      if let from {
        MemberShapeView(
          shape: from.shape,
          color: from.color,
          name: from.name,
          size: 18,
          showInitial: false
        )
      }
      Text(text)
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
      if transaction.version > 1 {
        Text(L10n.tr("feed.edited"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
    }
    .padding(.vertical, 6)
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .background(Tokens.sunken)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .frame(maxWidth: .infinity)
  }
}

struct FeedEmptyStreamView: View {
  let members: [Member]
  let canInvite: Bool
  let onSelectSample: (String) -> Void
  let onOpenMembers: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Spacer(minLength: 20)

      HStack(spacing: 4) {
        ForEach(Array(members.prefix(4))) { member in
          MemberShapeView(
            shape: member.shape,
            color: member.color,
            name: member.name,
            size: 76
          )
        }
      }

      Text(L10n.tr("feed.emptyTitle"))
        .font(Typography.pageTitle)
        .foregroundStyle(Tokens.ink)
        .multilineTextAlignment(.center)

      Text(L10n.tr("feed.emptyHint"))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.muted)
        .multilineTextAlignment(.center)

      if canInvite {
        ForEach(L10n.feedSamples, id: \.self) { sample in
          Button {
            onSelectSample(sample)
          } label: {
            Text(sample)
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 18)
              .padding(.vertical, 14)
              .background(Tokens.surface)
              .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          }
          .buttonStyle(.plain)
        }

        Button(action: onOpenMembers) {
          Text(L10n.tr("feed.inviteLink"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
      }

      Spacer(minLength: 20)
    }
    .frame(maxWidth: .infinity)
  }
}

struct FeedEntryBarView: View {
  let isOffline: Bool
  let isReadOnly: Bool
  let onOpenManualForm: () -> Void
  let onOpenQuickEntry: () -> Void

  var body: some View {
    if isOffline {
      Text(L10n.tr("offline.entry"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.muted)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(Tokens.sunken)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    } else if isReadOnly {
      Text(L10n.tr("members.roleViewer"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.muted)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(Tokens.sunken)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    } else {
      HStack(spacing: 12) {
        Button(action: onOpenManualForm) {
          VStack(spacing: 2) {
            Image(systemName: "plus")
              .font(.system(size: 20, weight: .bold))
            Text(L10n.tr("feed.manualEntry"))
              .font(Typography.captionBold)
          }
          .foregroundStyle(Tokens.ink)
          .frame(width: 84, height: 64)
          .background(Tokens.accent)
          .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)

        Button(action: onOpenQuickEntry) {
          HStack {
            Text(L10n.tr("feed.entryPlaceholder"))
              .font(Typography.body)
              .foregroundStyle(Tokens.muted)
            Spacer()
          }
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 64)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
