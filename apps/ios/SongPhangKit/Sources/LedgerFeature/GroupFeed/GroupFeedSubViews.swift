import DesignSystem
import Domain
import SwiftUI

struct FeedBalanceBlockView: View {
  let balance: Money
  let onOpenBalances: () -> Void
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    let layout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
      : AnyLayout(HStackLayout(spacing: 12))
    Button(action: onOpenBalances) {
      layout {
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
  let categories: [GroupCategory]
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

  private var payerNames: String {
    transaction.payers
      .map { entry in
        entry.memberId == myMemberId
          ? L10n.tr("common.you")
          : members.first(where: { $0.id == entry.memberId })?.name ?? ""
      }
      .joined(separator: ", ")
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
          transaction.payers.count > 1
            ? L10n.t("feed.memberPaid", ["name": payerNames])
            : isMine
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

        if let catDisplay = CategoryDisplay.label(
          category: transaction.category,
          categoryId: transaction.categoryId,
          categories: categories,
          includeArchivedTag: true
        ) {
          HStack(spacing: 5) {
            if let dotColor = catDisplay.color {
              Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            }
            Text(catDisplay.name)
              .font(Typography.captionBold)
              .foregroundStyle(isMine ? Tokens.onInkMuted : Tokens.muted)
          }
        }

        if transaction.attachmentCount > 0 {
          HStack(spacing: 4) {
            Image(systemName: "photo")
              .font(.system(size: 11, weight: .semibold))
            if transaction.attachmentCount > 1 {
              Text(String(transaction.attachmentCount))
                .font(Typography.captionBold)
            }
          }
          .foregroundStyle(isMine ? Tokens.onInkMuted : Tokens.muted)
          .accessibilityLabel(L10n.tr("attachments.hasPhotos"))
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
          .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
          .padding(.top, 4)
        } else {
          let methodLabel: String = {
            switch transaction.split {
            case .exact: return L10n.tr("feed.splitExact")
            case .shares: return L10n.tr("feed.splitShares")
            case .items: return L10n.tr("split.methodItems")
            case .percent: return L10n.tr("feed.splitPercent")
            case .equal: return ""
            }
          }()
          let shareLine: String = {
            let isEqual = if case .equal = transaction.split { true } else { false }
            if let myShare {
              return L10n.t(
                isEqual ? "feed.equalSplitMine" : "feed.splitMine",
                [
                  "method": methodLabel,
                  "count": String(transaction.shares.count),
                  "amount": MoneyFormat.amount(myShare.amount),
                ]
              )
            }
            return L10n.t(
              isEqual ? "feed.equalSplitNotMine" : "feed.splitNotMine",
              [
                "method": methodLabel,
                "count": String(transaction.shares.count),
              ]
            )
          }()
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

struct FeedSearchBarView: View {
  @Binding var text: String
  let hasModalFilters: Bool
  let onSearchChange: (String) -> Void
  let onOpenFilters: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      TextField(L10n.tr("filter.searchPlaceholder"), text: $text)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .background(Tokens.surface, in: Capsule())
        .accessibilityLabel(L10n.tr("filter.searchPlaceholder"))
        .onChange(of: text) { _, next in
          onSearchChange(next)
        }

      Button(action: onOpenFilters) {
        Text(L10n.tr("filter.button"))
          .font(Typography.captionBold)
          .foregroundStyle(hasModalFilters ? Tokens.surface : Tokens.ink)
          .padding(.horizontal, 16)
          .frame(minHeight: 44)
          .background(hasModalFilters ? Tokens.ink : Tokens.surface, in: Capsule())
      }
      .buttonStyle(.plain)
    }
  }
}

struct FeedFilterChipsView: View {
  let filter: TransactionFilter
  let members: [Member]
  let categories: [GroupCategory]
  let onChange: (TransactionFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    let chips = buildChips()
    if !chips.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(chips, id: \.key) { chip in
            Button(action: chip.remove) {
              HStack(spacing: 6) {
                Text(chip.label)
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.surface)
                Image(systemName: "xmark")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(Tokens.surface)
              }
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(Tokens.ink, in: Capsule())
            }
            .buttonStyle(.plain)
          }

          Button(action: onClear) {
            Text(L10n.tr("filter.clear"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(Tokens.surface, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private struct ChipItem {
    let key: String
    let label: String
    let remove: () -> Void
  }

  private func buildChips() -> [ChipItem] {
    var items: [ChipItem] = []
    if let q = filter.query {
      items.append(
        ChipItem(key: "q", label: "“\(q)”") {
          var next = filter
          next.query = nil
          onChange(next)
        }
      )
    }
    if let memberId = filter.memberId {
      let name = members.first(where: { $0.id == memberId })?.name ?? memberId.rawValue
      items.append(
        ChipItem(key: "member", label: "\(L10n.tr("filter.member")): \(name)") {
          var next = filter
          next.memberId = nil
          onChange(next)
        }
      )
    }
    if let category = filter.category {
      items.append(
        ChipItem(
          key: "category",
          label: "\(L10n.tr("filter.category")): \(CategoryDisplay.localizedName(for: category))"
        ) {
          var next = filter
          next.category = nil
          onChange(next)
        }
      )
    }
    if let categoryId = filter.categoryId {
      let name = categories.first(where: { $0.id == categoryId })?.name ?? categoryId.rawValue
      items.append(
        ChipItem(key: "categoryId", label: "\(L10n.tr("filter.category")): \(name)") {
          var next = filter
          next.categoryId = nil
          onChange(next)
        }
      )
    }
    if filter.uncategorized {
      items.append(
        ChipItem(
          key: "uncategorized",
          label: "\(L10n.tr("filter.category")): \(L10n.tr("stats.uncategorised"))"
        ) {
          var next = filter
          next.uncategorized = false
          onChange(next)
        }
      )
    }
    if let type = filter.type {
      let label: String =
        switch type {
        case .expense: L10n.tr("expenseForm.typeExpense")
        case .transfer: L10n.tr("expenseForm.typeTransfer")
        case .income: L10n.tr("expenseForm.typeIncome")
        case .unknown: type.code
        }
      items.append(
        ChipItem(key: "type", label: "\(L10n.tr("filter.type")): \(label)") {
          var next = filter
          next.type = nil
          onChange(next)
        }
      )
    }
    if filter.spendingOnly {
      let label =
        "\(L10n.tr("filter.type")): \(L10n.tr("expenseForm.typeExpense")) / \(L10n.tr("expenseForm.typeIncome"))"
      items.append(
        ChipItem(key: "spendingOnly", label: label) {
          var next = filter
          next.spendingOnly = false
          onChange(next)
        }
      )
    }
    if filter.from != nil || filter.to != nil {
      let dateText =
        if let from = filter.from, let to = filter.to {
          "\(from) → \(to)"
        } else {
          filter.from ?? filter.to ?? ""
        }
      items.append(
        ChipItem(key: "date", label: dateText) {
          var next = filter
          next.from = nil
          next.to = nil
          onChange(next)
        }
      )
    }
    return items
  }
}

struct FeedNoMatchView: View {
  let onClear: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Spacer(minLength: 24)
      Text(L10n.tr("filter.noResult"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.muted)
      SPButton(L10n.tr("filter.clear"), variant: .surface, action: onClear)
      Spacer(minLength: 24)
    }
    .frame(maxWidth: .infinity)
  }
}

struct FeedEntryBarView: View {
  let isOffline: Bool
  let isReadOnly: Bool
  var onOpenReceiptCapture: (() -> Void)? = nil
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

        if let onOpenReceiptCapture {
          Button(action: onOpenReceiptCapture) {
            Image(systemName: "camera.fill")
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(Tokens.ink)
              .frame(width: 64, height: 64)
              .background(Tokens.surface)
              .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("receipts.cameraLabel"))
        }

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
