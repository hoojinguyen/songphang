import DesignSystem
public import Domain
public import SwiftUI

public struct ReceiptItemsAssignmentView: View {
  @Binding private var draft: ItemsSplitDraft
  private let activePeople: [Member]
  private let preview: ItemsPreview?
  private let isPreviewCurrent: Bool
  private let previewError: AppError?
  private let onChange: () -> Void

  public init(
    draft: Binding<ItemsSplitDraft>,
    activePeople: [Member],
    preview: ItemsPreview?,
    isPreviewCurrent: Bool,
    previewError: AppError?,
    onChange: @escaping () -> Void = {}
  ) {
    self._draft = draft
    self.activePeople = activePeople
    self.preview = preview
    self.isPreviewCurrent = isPreviewCurrent
    self.previewError = previewError
    self.onChange = onChange
  }

  public var body: some View {
    let selectedItem = draft.selectedItem
    let unassignedCount = draft.unassignedCount
    let groupExceedsCap = activePeople.count > ItemsSplitDraft.maxItemMembers
    let selectedCount = selectedItem?.memberIds.count ?? 0
    let itemMembersFull = selectedCount >= ItemsSplitDraft.maxItemMembers
    let hasInvalidTotal =
      isPreviewCurrent && (preview?.issues.contains(where: { $0.code == .invalidTotal }) == true)
    let hasUnassigned =
      unassignedCount > 0
      || (isPreviewCurrent
        && preview?.issues.contains(where: { $0.code == .itemUnassigned }) == true)

    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Button {
          draft.splitRemainingEqual(among: activePeople)
          onChange()
        } label: {
          Text(L10n.tr("receipts.splitRemainingEqual"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Tokens.phraseSplit, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(unassignedCount == 0 || activePeople.isEmpty || groupExceedsCap)
        .opacity((unassignedCount == 0 || activePeople.isEmpty || groupExceedsCap) ? 0.4 : 1.0)

        Spacer(minLength: 4)

        Button {
          draft.addItem()
          onChange()
        } label: {
          Text("+ \(L10n.tr("receipts.addItem"))")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Tokens.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(draft.items.count >= ItemsSplitDraft.maxItems)
        .opacity(draft.items.count >= ItemsSplitDraft.maxItems ? 0.4 : 1.0)
      }

      VStack(spacing: 8) {
        ForEach($draft.items) { $item in
          itemRow(
            item: $item,
            isSelected: selectedItem?.id == item.id,
            canRemove: draft.items.count > 1
          )
        }
      }

      extrasSection

      memberAssignmentCard(
        selectedItem: selectedItem,
        groupExceedsCap: groupExceedsCap,
        itemMembersFull: itemMembersFull,
        unassignedCount: unassignedCount,
        hasUnassigned: hasUnassigned,
        hasInvalidTotal: hasInvalidTotal
      )
    }
  }

  @ViewBuilder
  private func itemRow(
    item: Binding<EditableReceiptItem>,
    isSelected: Bool,
    canRemove: Bool
  ) -> some View {
    let assigned = activePeople.filter { item.wrappedValue.memberIds.contains($0.id) }

    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Button {
          draft.selectedItemId = item.wrappedValue.id
        } label: {
          Text(isSelected ? "●" : "○")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
            .frame(minWidth: 32, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          item.wrappedValue.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? L10n.tr("receipts.itemNameLabel")
            : item.wrappedValue.name
        )

        TextField(
          L10n.tr("receipts.itemNameLabel"),
          text: Binding(
            get: { item.wrappedValue.name },
            set: { next in
              item.wrappedValue.name = String(next.prefix(80))
              draft.selectedItemId = item.wrappedValue.id
              onChange()
            }
          )
        )
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 8)
        .frame(minHeight: 44)
        .accessibilityLabel(L10n.tr("receipts.itemNameLabel"))

        TextField(
          "0",
          text: Binding(
            get: { item.wrappedValue.amountText },
            set: { next in
              item.wrappedValue.amountText = next.filter { $0.isWholeNumber && $0.isASCII }
              draft.selectedItemId = item.wrappedValue.id
              onChange()
            }
          )
        )
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .frame(width: 96)
        .frame(minHeight: 44)
        .padding(.horizontal, 8)
        .accessibilityLabel(L10n.tr("receipts.itemAmountLabel"))

        if canRemove {
          Button {
            draft.removeItem(id: item.wrappedValue.id)
            onChange()
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Tokens.muted)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("receipts.removeItem"))
        }
      }

      HStack(spacing: 6) {
        if assigned.isEmpty {
          Text(L10n.tr("receipts.nobody"))
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        } else {
          ForEach(assigned) { member in
            MemberShapeView(
              shape: member.shape,
              color: member.color,
              name: member.name,
              size: 24,
              showInitial: false
            )
          }
        }
      }
      .padding(.leading, 40)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Tokens.surface)
        .overlay(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(isSelected ? Tokens.ink : Color.clear, lineWidth: 3)
        )
    )
    .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .onTapGesture {
      draft.selectedItemId = item.wrappedValue.id
    }
  }

  private var extrasSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text(L10n.tr("receipts.extrasHint"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer(minLength: 4)
        Button {
          draft.addExtra()
          onChange()
        } label: {
          Text("+ \(L10n.tr("receipts.addExtra"))")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Tokens.sunken, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(draft.isExtrasFull)
        .opacity(draft.isExtrasFull ? 0.4 : 1.0)
      }

      if draft.isExtrasFull {
        Text(L10n.tr("receipts.maxExtras"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }

      ForEach($draft.extras) { $extra in
        HStack(spacing: 8) {
          Menu {
            ForEach(ReceiptExtraKind.allCases, id: \.self) { kind in
              Button(extraKindLabel(kind)) {
                extra.kind = kind
                onChange()
              }
            }
          } label: {
            Text(extraKindLabel(extra.kind))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 10)
              .frame(minHeight: 44)
              .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          }

          TextField(
            extraKindLabel(extra.kind),
            text: Binding(
              get: { extra.label },
              set: { next in
                extra.label = String(next.prefix(40))
                onChange()
              }
            )
          )
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 10)
          .frame(minHeight: 44)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .accessibilityLabel(L10n.tr("receipts.extraLabelLabel"))

          TextField(
            "0",
            text: Binding(
              get: { extra.amountText },
              set: { next in
                extra.amountText = next.filter { $0.isWholeNumber && $0.isASCII }
                onChange()
              }
            )
          )
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 8)
          .frame(width: 84)
          .frame(minHeight: 44)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .accessibilityLabel(L10n.tr("receipts.extraAmountLabel"))

          Button {
            draft.removeExtra(id: extra.id)
            onChange()
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Tokens.muted)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("receipts.removeExtra"))
        }
      }

      if !draft.extras.isEmpty {
        HStack(spacing: 6) {
          ForEach(
            [
              (ExtrasAllocation.equal, L10n.tr("extras.allocEqual")),
              (ExtrasAllocation.proportional, L10n.tr("extras.allocProportional")),
            ],
            id: \.0
          ) { option, title in
            let selected = draft.extrasAllocation == option
            Button {
              draft.extrasAllocation = option
              onChange()
            } label: {
              Text(title)
                .font(Typography.captionBold)
                .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(selected ? Tokens.ink : Tokens.sunken, in: Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .padding(14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func memberAssignmentCard(
    selectedItem: EditableReceiptItem?,
    groupExceedsCap: Bool,
    itemMembersFull: Bool,
    unassignedCount: Int,
    hasUnassigned: Bool,
    hasInvalidTotal: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
        spacing: 8
      ) {
        ForEach(activePeople) { member in
          let assigned = selectedItem?.memberIds.contains(member.id) == true
          let share =
            isPreviewCurrent
            ? preview?.shares.first(where: { $0.memberId == member.id })?.amount
            : nil
          Button {
            draft.toggleMemberOnSelected(member.id)
            onChange()
          } label: {
            VStack(spacing: 4) {
              MemberShapeView(
                shape: member.shape,
                color: member.color,
                name: member.name,
                size: 32
              )
              Text(member.name)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)
              Text(
                share.map { MoneyFormat.amount($0) } ?? L10n.tr("common.pendingValue")
              )
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(
              RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(assigned ? Tokens.sunken : Tokens.bg)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(assigned ? Tokens.ink : Color.clear, lineWidth: 2)
            )
            .opacity(assigned ? 1.0 : ((!assigned && itemMembersFull) ? 0.4 : 0.7))
          }
          .buttonStyle(.plain)
          .disabled(!assigned && itemMembersFull)
        }
      }

      if groupExceedsCap || itemMembersFull {
        Text(L10n.tr("receipts.maxItemMembers"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
      if previewError != nil {
        Text(L10n.tr("common.loadError"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
      }
      if hasUnassigned {
        Text(L10n.t("receipts.saveBlocked", ["count": String(max(unassignedCount, 1))]))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      } else if hasInvalidTotal {
        Text(L10n.tr("receipts.invalidTotal"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
    }
    .padding(14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func extraKindLabel(_ kind: ReceiptExtraKind) -> String {
    kind.localizedTitle
  }
}
