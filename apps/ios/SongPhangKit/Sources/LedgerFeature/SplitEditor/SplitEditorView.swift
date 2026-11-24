import DesignSystem
public import Domain
public import SwiftUI

public struct SplitStatusBannerView: View {
  private let status: SplitStatusInfo

  public init(status: SplitStatusInfo) {
    self.status = status
  }

  public var body: some View {
    HStack(spacing: 8) {
      Image(systemName: status.matched ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Tokens.ink)
      Text(status.text)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
      Spacer(minLength: 0)
    }
    .padding(16)
    .background(
      status.matched ? Tokens.phraseSplit : Tokens.debtSoft,
      in: RoundedRectangle(cornerRadius: 22, style: .continuous)
    )
  }
}

public struct SplitEditorView: View {
  @Binding private var splitState: SplitEditorState
  private let members: [Member]
  private let amount: Money
  private let description: String
  private let payerLine: String
  private let shares: [MemberAmount]
  private let isPreviewPending: Bool
  private let allowItems: Bool
  private let itemsPreview: ItemsPreview?
  private let isItemsPreviewCurrent: Bool
  private let itemsPreviewError: AppError?
  private let onItemsChange: () -> Void
  private let onDone: () -> Void

  public init(
    splitState: Binding<SplitEditorState>,
    members: [Member],
    amount: Money,
    description: String,
    payerLine: String,
    shares: [MemberAmount],
    isPreviewPending: Bool,
    allowItems: Bool = true,
    itemsPreview: ItemsPreview? = nil,
    isItemsPreviewCurrent: Bool = false,
    itemsPreviewError: AppError? = nil,
    onItemsChange: @escaping () -> Void = {},
    onDone: @escaping () -> Void
  ) {
    self._splitState = splitState
    self.members = members
    self.amount = amount
    self.description = description
    self.payerLine = payerLine
    self.shares = shares
    self.isPreviewPending = isPreviewPending
    self.allowItems = allowItems
    self.itemsPreview = itemsPreview
    self.isItemsPreviewCurrent = isItemsPreviewCurrent
    self.itemsPreviewError = itemsPreviewError
    self.onItemsChange = onItemsChange
    self.onDone = onDone
  }

  public var body: some View {
    let selected = splitState.selectedMembers(from: members)
    let unselected = members.filter { !splitState.ids.contains($0.id) }
    let blanks = splitState.blankCount(from: members)
    let rest = splitState.restAmount(from: members, totalAmount: amount)
    let displayedAmount =
      (splitState.method == .items && isItemsPreviewCurrent)
      ? (itemsPreview?.computedAmount ?? amount)
      : amount
    let status = splitState.status(
      from: members,
      totalAmount: amount,
      itemsPreview: itemsPreview,
      isItemsPreviewCurrent: isItemsPreviewCurrent
    )

    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          Button(action: onDone) {
            Image(systemName: "chevron.left")
              .font(.system(size: 18, weight: .bold))
              .foregroundStyle(Tokens.ink)
              .frame(width: 44, height: 44)
              .background(Tokens.surface, in: Circle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("common.back"))

          VStack(alignment: .leading, spacing: 2) {
            Text(description)
              .font(Typography.screenHeaderTitle)
              .foregroundStyle(Tokens.ink)
            Text(payerLine)
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          MoneyText(
            displayedAmount,
            style: .full,
            font: Typography.sectionTitle,
            color: Tokens.ink
          )
        }

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(SplitMethod.available(allowItems: allowItems), id: \.self) { method in
              let isSelected = splitState.method == method
              Button {
                splitState.changeMode(
                  method,
                  members: members,
                  amount: amount,
                  defaultItemTitle: L10n.tr("receipts.title")
                )
                onItemsChange()
              } label: {
                Text(method.modeLabel)
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
                  .padding(.horizontal, 12)
                  .frame(minHeight: 52)
                  .background(
                    isSelected ? Tokens.ink : Tokens.surface,
                    in: RoundedRectangle(cornerRadius: isSelected ? 20 : 26, style: .continuous)
                  )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .accessibilityLabel(L10n.tr("split.changeLabel"))

        if splitState.method == .items {
          ReceiptItemsAssignmentView(
            draft: $splitState.itemsDraft,
            activePeople: members,
            preview: itemsPreview,
            isPreviewCurrent: isItemsPreviewCurrent,
            previewError: itemsPreviewError,
            onChange: {
              splitState.hasCustomizedItems = true
              onItemsChange()
            }
          )
        } else {
          if !selected.isEmpty {
            let shapeItems = selected.map { member in
              let shareAmount =
                shares.first(where: { $0.memberId == member.id })?.amount ?? .zero
              return ShareShapeItem(member: member, amount: shareAmount)
            }
            ShareShapesView(shares: shapeItems, isDimmed: isPreviewPending)
          }

          ForEach(selected) { member in
            SplitMemberRowView(
              member: member,
              method: splitState.method,
              value: splitState.values[member.id]
                ?? (splitState.method == .shares ? member.defaultWeight : ""),
              onChange: { newValue in
                splitState.setValue(newValue, for: member.id)
              },
              onRemove: {
                splitState.toggle(member.id, members: members)
              }
            )
          }

          ForEach(unselected) { member in
            Button {
              splitState.toggle(member.id, members: members)
            } label: {
              Text(L10n.t("split.addMember", ["name": member.name]))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                  RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                      Tokens.dashed,
                      style: StrokeStyle(lineWidth: 2, dash: [6, 6])
                    )
                )
            }
            .buttonStyle(.plain)
          }

          if splitState.method == .exact && blanks == 0 && rest.isPositive {
            Button {
              splitState.spread.toggle()
            } label: {
              Text(
                splitState.spread
                  ? L10n.tr("split.undoSpread")
                  : L10n.t(
                    "split.spreadRest",
                    [
                      "amount": MoneyFormat.full(rest),
                      "count": String(selected.count),
                    ]
                  )
              )
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
              .frame(maxWidth: .infinity, minHeight: 56)
              .background(
                Tokens.phraseRest,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
              )
            }
            .buttonStyle(.plain)
          }
        }

        SplitStatusBannerView(status: status)

        SPButton(
          L10n.tr("split.done"),
          variant: .primary,
          size: .lg,
          isFullWidth: true,
          action: onDone
        )
      }
      .padding(20)
    }
    .background(Tokens.bg.ignoresSafeArea())
  }
}

private struct SplitMemberRowView: View {
  let member: Member
  let method: SplitMethod
  let value: String
  let onChange: (String) -> Void
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      MemberShapeView(
        shape: member.shape,
        color: member.color,
        name: member.name,
        size: 32,
        showInitial: false
      )

      Text(member.name)
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .frame(maxWidth: .infinity, alignment: .leading)

      if method != .equal {
        HStack(spacing: 4) {
          TextField(
            "",
            text: Binding(
              get: { value },
              set: { raw in
                if method == .exact {
                  let digits = raw.filter { $0.isWholeNumber && $0.isASCII }
                  if digits.isEmpty {
                    onChange("")
                  } else if let money = MoneyFormat.parseInput(digits) {
                    onChange(MoneyFormat.amount(money))
                  }
                } else {
                  let normalized = raw.replacingOccurrences(of: ",", with: ".")
                  onChange(normalized)
                }
              }
            )
          )
          .keyboardType(method == .exact ? .numberPad : .decimalPad)
          .multilineTextAlignment(.trailing)
          .font(Typography.sectionTitle)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .foregroundStyle(Tokens.ink)
          .accessibilityLabel(L10n.t("split.memberField", ["name": member.name]))

          Text(unitLabel)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        .padding(.horizontal, 10)
        .frame(width: 132, height: 48)
        .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(Tokens.ink)
          .frame(width: 44, height: 44)
          .background(Tokens.bg, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(L10n.t("split.removeMember", ["name": member.name]))
    }
    .padding(12)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private var unitLabel: String {
    switch method {
    case .equal, .exact, .items: return L10n.tr("split.unitMoney")
    case .shares: return L10n.tr("split.unitShares")
    case .percent: return L10n.tr("split.unitPercent")
    }
  }
}
