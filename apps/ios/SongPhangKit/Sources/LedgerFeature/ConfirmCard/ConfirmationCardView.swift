import DesignSystem
public import Domain
public import SwiftUI

public struct ConfirmationCardView<ExtraContent: View>: View {
  private let reading: QuickEntryReading
  private let members: [Member]
  private let categories: [GroupCategory]
  private let isDisabled: Bool
  private let isSaveDisabled: Bool?
  private let isBudgetOver: Bool
  private let indexLabel: String?
  private let saveLabel: String?
  private let skipLabel: String?
  private let onEdit: () -> Void
  private let onSave: () -> Void
  private let onSkip: (() -> Void)?
  private let extraContent: ExtraContent

  public init(
    reading: QuickEntryReading,
    members: [Member],
    categories: [GroupCategory] = [],
    isDisabled: Bool = false,
    isSaveDisabled: Bool? = nil,
    isBudgetOver: Bool = false,
    indexLabel: String? = nil,
    saveLabel: String? = nil,
    skipLabel: String? = nil,
    onEdit: @escaping () -> Void,
    onSave: @escaping () -> Void,
    onSkip: (() -> Void)? = nil,
    @ViewBuilder extraContent: () -> ExtraContent
  ) {
    self.reading = reading
    self.members = members
    self.categories = categories
    self.isDisabled = isDisabled
    self.isSaveDisabled = isSaveDisabled
    self.isBudgetOver = isBudgetOver
    self.indexLabel = indexLabel
    self.saveLabel = saveLabel
    self.skipLabel = skipLabel
    self.onEdit = onEdit
    self.onSave = onSave
    self.onSkip = onSkip
    self.extraContent = extraContent()
  }

  public var body: some View {
    let draft = reading.draft
    let shares = reading.shares ?? []
    let payer = members.first(where: { $0.id == draft.payers.first?.memberId })
    let split = draft.split
    let isEqual = shares.allSatisfy { $0.amount == shares.first?.amount }
    let notIncluded = members.filter { member in
      member.active && member.kind == .person
        && !shares.contains(where: { $0.memberId == member.id })
    }
    let rest: Money = {
      if case .exact(_, let entries, _) = split, let total = draft.amount {
        let entrySum = entries.reduce(Money.zero) { $0 + $1.amount }
        return total - entrySum
      }
      return .zero
    }()

    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .center, spacing: 8) {
        Text(L10n.tr("compose.understood"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
        Spacer()
        if let indexLabel {
          Text(indexLabel)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }

      if reading.reader == .ai {
        Text(L10n.tr("compose.aiNote"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }

      if let description = draft.description, !description.isEmpty {
        Text(description)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
      }

      if let amount = draft.amount {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(MoneyFormat.amount(amount))
            .font(.system(size: 48, weight: .black))
            .foregroundStyle(Tokens.ink)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
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
      }

      VStack(alignment: .leading, spacing: 8) {
        if let payer {
          let payerText =
            (reading.reader == .ai || reading.spans.contains(where: { $0.kind == .payer }))
            ? L10n.t("compose.payer", ["name": payer.name])
            : L10n.tr("compose.payerDefault")
          Text(payerText)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              Tokens.phrasePayer,
              in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }

        if !shares.isEmpty, let split {
          let splitText: String = {
            if case .exact(_, let entries, _) = split {
              let parts = entries.map { entry in
                let memberName =
                  members.first(where: { $0.id == entry.memberId })?.name ?? ""
                return "\(memberName) \(MoneyFormat.compact(entry.amount))"
              }.joined(separator: " · ")
              return L10n.t("compose.exact", ["parts": parts])
            } else {
              return L10n.t(
                isEqual ? "compose.equal" : "compose.equalUneven",
                [
                  "count": String(shares.count),
                  "amount": MoneyFormat.amount(shares.first?.amount ?? .zero),
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

        if rest.isPositive {
          Text(
            L10n.t(
              "compose.rest",
              [
                "amount": MoneyFormat.amount(rest),
                "count": String(shares.count),
              ]
            )
          )
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            Tokens.phraseRest,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )
        }
      }

      if let catDisplay = CategoryDisplay.label(
        category: draft.category,
        categoryId: draft.categoryId,
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

      if !shares.isEmpty {
        let shapeItems = shares.compactMap { share -> ShareShapeItem? in
          guard let member = members.first(where: { $0.id == share.memberId }) else {
            return nil
          }
          return ShareShapeItem(member: member, amount: share.amount)
        }
        ScrollView {
          ShareShapesView(shares: shapeItems)
        }
        .frame(maxHeight: 220)
      }

      extraContent

      if isBudgetOver {
        Text(L10n.tr("budget.overWarning"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(14)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Tokens.coral, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      }

      let footerPrefix =
        (!shares.isEmpty && !notIncluded.isEmpty)
        ? L10n.t(
          "compose.notIncluded",
          ["names": notIncluded.map(\.name).joined(separator: ", ")]
        ) + " "
        : ""
      Text("\(footerPrefix)\(L10n.tr("compose.nothingSaved"))")
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)

      if let onSkip {
        VStack(spacing: 10) {
          SPButton(
            saveLabel ?? L10n.tr("compose.save"),
            variant: .accent,
            size: .lg,
            isFullWidth: true,
            isDisabled: isSaveDisabled ?? isDisabled,
            action: onSave
          )
          HStack(spacing: 12) {
            SPButton(
              L10n.tr("compose.edit"),
              variant: .surface,
              size: .lg,
              isFullWidth: true,
              action: onEdit
            )
            SPButton(
              skipLabel ?? L10n.tr("compose.skipDraft"),
              variant: .surface,
              size: .lg,
              isFullWidth: true,
              isDisabled: isDisabled,
              action: onSkip
            )
          }
        }
      } else {
        HStack(spacing: 12) {
          SPButton(
            L10n.tr("compose.edit"),
            variant: .surface,
            size: .lg,
            isFullWidth: true,
            action: onEdit
          )
          SPButton(
            saveLabel ?? L10n.tr("compose.save"),
            variant: .accent,
            size: .lg,
            isFullWidth: true,
            isDisabled: isSaveDisabled ?? isDisabled,
            action: onSave
          )
        }
      }
    }
    .padding(18)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
  }
}

extension ConfirmationCardView where ExtraContent == EmptyView {
  public init(
    reading: QuickEntryReading,
    members: [Member],
    categories: [GroupCategory] = [],
    isDisabled: Bool = false,
    isSaveDisabled: Bool? = nil,
    isBudgetOver: Bool = false,
    indexLabel: String? = nil,
    saveLabel: String? = nil,
    skipLabel: String? = nil,
    onEdit: @escaping () -> Void,
    onSave: @escaping () -> Void,
    onSkip: (() -> Void)? = nil
  ) {
    self.init(
      reading: reading,
      members: members,
      categories: categories,
      isDisabled: isDisabled,
      isSaveDisabled: isSaveDisabled,
      isBudgetOver: isBudgetOver,
      indexLabel: indexLabel,
      saveLabel: saveLabel,
      skipLabel: skipLabel,
      onEdit: onEdit,
      onSave: onSave,
      onSkip: onSkip
    ) {
      EmptyView()
    }
  }
}
