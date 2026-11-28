import DesignSystem
import Domain
import SwiftUI

struct UnparsedBannerView: View {
  let reading: QuickEntryReading
  let activeCount: Int
  let onDismiss: () -> Void

  private var relevantIssues: [QuickEntryReading.Issue] {
    reading.issues.filter { issue in
      switch issue.code {
      case .amountMissing, .sumMismatch, .memberUnknown, .fundCannotShare, .countMismatch,
        .textNotUnderstood:
        return true
      case .descriptionMissing, .memberAmbiguous, .unknown:
        return false
      }
    }
  }

  var body: some View {
    if !relevantIssues.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(L10n.tr("unparsed.title"))
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)
          Spacer()
          Button(action: onDismiss) {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .bold))
              .foregroundStyle(Tokens.ink)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("common.cancel"))
        }

        HighlightedSentenceView(text: reading.text, spans: reading.spans)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            Tokens.surface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
          )

        ForEach(Array(relevantIssues.enumerated()), id: \.offset) { _, issue in
          if let line = issueLine(for: issue) {
            Text(line)
              .font(Typography.subheadline)
              .foregroundStyle(Tokens.ink)
          }
        }
      }
      .padding(16)
      .background(
        Tokens.phraseAmount,
        in: RoundedRectangle(cornerRadius: 30, style: .continuous)
      )
    }
  }

  private func issueLine(for issue: QuickEntryReading.Issue) -> String? {
    let word = sliceText(reading.text, start: issue.start, end: issue.end)
    switch issue.code {
    case .amountMissing:
      return L10n.tr("unparsed.amountMissing")
    case .sumMismatch:
      let actual = issue.actual ?? .zero
      let expected = issue.expected ?? .zero
      let rest = expected - actual
      let key = actual < expected ? "unparsed.sumShort" : "unparsed.sumOver"
      return L10n.t(
        key,
        [
          "actual": MoneyFormat.full(actual),
          "rest": MoneyFormat.full(rest),
          "total": MoneyFormat.full(expected),
        ]
      )
    case .memberUnknown:
      return L10n.t("unparsed.memberUnknown", ["word": word])
    case .fundCannotShare:
      return L10n.tr("unparsed.fundCannotShare")
    case .countMismatch:
      return L10n.t("unparsed.countTooLarge", ["total": String(activeCount)])
    case .textNotUnderstood:
      return L10n.t("unparsed.notUnderstood", ["fragment": word])
    case .descriptionMissing, .memberAmbiguous, .unknown:
      return nil
    }
  }

  private func sliceText(_ text: String, start: Int, end: Int) -> String {
    let chars = Array(text)
    guard start >= 0, end <= chars.count, start < end else { return "" }
    return String(chars[start..<end])
  }
}

struct ConflictNoticeView: View {
  let current: LedgerTransaction
  let onReload: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(
        L10n.t(
          "expenseForm.conflict",
          [
            "name": current.updatedBy?.name ?? L10n.tr("expenseForm.someone")
          ]
        )
      )
      .font(Typography.bodyBold)
      .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("expenseForm.reloadCurrent"),
        variant: .primary,
        action: onReload
      )
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Tokens.phraseAmount,
      in: RoundedRectangle(cornerRadius: 26, style: .continuous)
    )
  }
}

struct TypeSwitchView: View {
  let value: TransactionType
  let onChange: (TransactionType) -> Void

  private let options: [(TransactionType, String)] = [
    (.expense, "expenseForm.typeExpense"),
    (.transfer, "expenseForm.typeTransfer"),
    (.income, "expenseForm.typeIncome"),
  ]

  var body: some View {
    HStack(spacing: 4) {
      ForEach(Array(options.enumerated()), id: \.offset) { _, pair in
        let isSelected = (value == pair.0)
        Button {
          onChange(pair.0)
        } label: {
          Text(L10n.tr(pair.1))
            .font(Typography.captionBold)
            .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .frame(minWidth: 44, minHeight: 44)
            .background(
              isSelected ? Tokens.ink : Color.clear,
              in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .fixedSize(horizontal: true, vertical: false)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .accessibilityLabel(L10n.tr("expenseForm.typeLabel"))
  }
}

struct AmountFieldView: View {
  let value: String
  let onChange: (String) -> Void
  let onAddThousands: () -> Void
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 8) {
      TextField(
        "0",
        text: Binding(
          get: { value },
          set: { onChange($0) }
        )
      )
      .keyboardType(.numberPad)
      .focused($isFocused)
      .multilineTextAlignment(.center)
      .minimumScaleFactor(0.5)
      .font(.system(size: 46, weight: .black))
      .monospacedDigit()
      .lineLimit(1)
      .foregroundStyle(Tokens.ink)
      .accessibilityLabel(L10n.tr("expenseForm.amountLabel"))

      Text(L10n.tr("common.currency"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.muted)

      Button(action: onAddThousands) {
        Text(L10n.tr("expenseForm.addThousands"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .frame(minWidth: 44, minHeight: 44)
          .background(Tokens.sunken, in: Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .fill(Tokens.surface)
        .overlay(
          RoundedRectangle(cornerRadius: 32, style: .continuous)
            .strokeBorder(Tokens.ink, lineWidth: 3)
        )
    )
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .onTapGesture { isFocused = true }
  }
}

struct CategoryPickerView: View {
  let categories: [GroupCategory]
  let selected: TransactionCategory?
  let selectedCustomId: GroupCategory.ID?
  let onSelect: (TransactionCategory?) -> Void
  let onSelectCustom: (GroupCategory.ID?) -> Void
  let onManageCategories: () -> Void

  var body: some View {
    let visibleCustom = categories.filter { !$0.archived || $0.id == selectedCustomId }
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(TransactionCategory.allCases, id: \.self) { cat in
          let isSelected = (selected == cat && selectedCustomId == nil)
          Button {
            onSelect(isSelected ? nil : cat)
          } label: {
            Text(CategoryDisplay.localizedName(for: cat))
              .font(Typography.captionBold)
              .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
              .padding(.horizontal, 16)
              .frame(minHeight: 44)
              .background(
                isSelected ? Tokens.ink : Tokens.surface,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
              )
          }
          .buttonStyle(.plain)
        }

        ForEach(visibleCustom) { custom in
          let isSelected = (selectedCustomId == custom.id)
          Button {
            onSelectCustom(isSelected ? nil : custom.id)
          } label: {
            HStack(spacing: 8) {
              Circle()
                .fill(Tokens.color(for: custom.color))
                .frame(width: 12, height: 12)
              Text(CategoryDisplay.displayName(for: custom))
                .font(Typography.captionBold)
                .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
              isSelected ? Tokens.ink : Tokens.surface,
              in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
          }
          .buttonStyle(.plain)
        }

        Button {
          onManageCategories()
        } label: {
          Text("+ \(L10n.tr("categories.add"))")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
              Tokens.sunken,
              in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .accessibilityLabel(L10n.tr("expenseForm.categoryLabel"))
  }
}

struct MemberToggleGridView: View {
  let members: [Member]
  let selectedIds: [Member.ID]
  let disabledIds: [Member.ID]
  let isCaptionDimmed: Bool
  let captionFor: (Member) -> String
  let onToggle: (Member.ID) -> Void

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
      spacing: 6
    ) {
      ForEach(members) { member in
        let isSelected = selectedIds.contains(member.id)
        let isDisabled = disabledIds.contains(member.id)
        Button {
          onToggle(member.id)
        } label: {
          VStack(spacing: 4) {
            MemberShapeView(member: member, size: 44)
            Text(captionFor(member))
              .font(Typography.captionBold)
              .foregroundStyle(isSelected ? Tokens.ink : Tokens.muted)
              .lineLimit(1)
              .opacity(isSelected && isCaptionDimmed ? 0.45 : 1.0)
          }
          .padding(.horizontal, 4)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, minHeight: 76)
          .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .fill(isSelected ? Tokens.surface : Tokens.bg)
              .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                  .strokeBorder(
                    isSelected ? Tokens.ink : Color.clear,
                    lineWidth: 3
                  )
              )
          )
          .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
      }
    }
  }
}

struct PayerAmountsView: View {
  let members: [Member]
  let values: [Member.ID: String]
  let totalAmount: Money
  let onChange: (Member.ID, String) -> Void

  var body: some View {
    let enteredTotal = members.reduce(Money.zero) { acc, member in
      acc + (MoneyFormat.parseInput(values[member.id] ?? "") ?? .zero)
    }
    let difference = totalAmount - enteredTotal

    VStack(alignment: .leading, spacing: 8) {
      ForEach(members) { member in
        HStack(spacing: 8) {
          MemberShapeView(member: member, size: 32)
          Text(member.name)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, alignment: .leading)

          TextField(
            "0",
            text: Binding(
              get: { values[member.id] ?? "" },
              set: { onChange(member.id, $0) }
            )
          )
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .frame(width: 120, height: 48)
          .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          .accessibilityLabel(L10n.t("expenseForm.payerAmountLabel", ["name": member.name]))
        }
        .padding(12)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
      }

      let statusText: String = {
        if difference.isZero {
          return L10n.t("expenseForm.payersMatch", ["amount": MoneyFormat.full(totalAmount)])
        } else if difference.isPositive {
          return L10n.t("expenseForm.payersShort", ["amount": MoneyFormat.full(difference)])
        } else {
          return L10n.t(
            "expenseForm.payersOver",
            ["amount": MoneyFormat.full(difference.magnitude)]
          )
        }
      }()

      Text(statusText)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          difference.isZero ? Tokens.phraseSplit : Tokens.debtSoft,
          in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
  }
}

struct TransferFieldsView: View {
  let members: [Member]
  let fromId: Member.ID?
  let toId: Member.ID?
  let onFrom: (Member.ID) -> Void
  let onTo: (Member.ID) -> Void

  var body: some View {
    VStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("expenseForm.transferFrom"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
        MemberToggleGridView(
          members: members,
          selectedIds: fromId.map { [$0] } ?? [],
          disabledIds: [],
          isCaptionDimmed: false,
          captionFor: \.name,
          onToggle: onFrom
        )
      }
      .padding(12)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("expenseForm.transferTo"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
        MemberToggleGridView(
          members: members,
          selectedIds: toId.map { [$0] } ?? [],
          disabledIds: fromId.map { [$0] } ?? [],
          isCaptionDimmed: false,
          captionFor: \.name,
          onToggle: onTo
        )
      }
      .padding(12)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
  }
}
