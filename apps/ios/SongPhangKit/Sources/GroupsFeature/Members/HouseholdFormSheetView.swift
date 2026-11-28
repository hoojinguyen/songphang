import DesignSystem
public import Domain
public import SwiftUI

struct HouseholdFormSheetView: View {
  let members: [Member]
  let existingHouseholds: [Household]
  let editing: Household?
  let isPending: Bool
  let error: AppError?
  let onSaveCreate: (String, Member.ID, [Member.ID]) async -> Void
  let onSaveUpdate: (Household.ID, UpdateHouseholdInput) async -> Void
  let onDismiss: () -> Void

  private let initialNameText: String
  private let initialSelectedIds: [Member.ID]
  private let initialRepresentativeId: Member.ID?

  @State private var nameText: String
  @State private var selectedIds: [Member.ID]
  @State private var representativeId: Member.ID?

  init(
    members: [Member],
    existingHouseholds: [Household],
    editing: Household?,
    isPending: Bool,
    error: AppError?,
    onSaveCreate: @escaping (String, Member.ID, [Member.ID]) async -> Void,
    onSaveUpdate: @escaping (Household.ID, UpdateHouseholdInput) async -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.members = members
    self.existingHouseholds = existingHouseholds
    self.editing = editing
    self.isPending = isPending
    self.error = error
    self.onSaveCreate = onSaveCreate
    self.onSaveUpdate = onSaveUpdate
    self.onDismiss = onDismiss

    let initialMembers = editing?.memberIds ?? []
    let initName = editing?.name ?? ""
    let initRep = editing?.representativeMemberId ?? initialMembers.first
    self.initialNameText = initName
    self.initialSelectedIds = initialMembers
    self.initialRepresentativeId = initRep
    self._nameText = State(initialValue: initName)
    self._selectedIds = State(initialValue: initialMembers)
    self._representativeId = State(initialValue: initRep)
  }

  private var isDirty: Bool {
    nameText != initialNameText || selectedIds != initialSelectedIds
      || representativeId != initialRepresentativeId
  }

  private func conflictingHousehold(for memberId: Member.ID) -> Household? {
    existingHouseholds.first { hh in
      hh.id != editing?.id && hh.memberIds.contains(memberId)
    }
  }

  private func hasVietQR(_ member: Member) -> Bool {
    member.paymentMethods.contains { method in
      if case .bank = method { return true }
      return false
    }
  }

  private var selectedMembers: [Member] {
    members.filter { selectedIds.contains($0.id) }
  }

  private var activeSelectedMembers: [Member] {
    selectedMembers.filter(\.active)
  }

  private var canSave: Bool {
    let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty,
      selectedIds.count >= 2,
      selectedIds.count <= 20,
      selectedMembers.allSatisfy(\.active),
      let repId = representativeId,
      activeSelectedMembers.contains(where: { $0.id == repId }),
      !isPending
    else { return false }
    return true
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("households.nameLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            TextField(
              L10n.tr("households.namePlaceholder"),
              text: Binding(
                get: { nameText },
                set: { nameText = String($0.prefix(50)) }
              )
            )
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          }

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("households.membersLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            ForEach(members) { member in
              let conflict = conflictingHousehold(for: member.id)
              let selected = selectedIds.contains(member.id)
              Button {
                toggleMember(member.id)
              } label: {
                HStack(spacing: 10) {
                  MemberShapeView(member: member, size: 28)
                  VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                      .font(Typography.subheadlineBold)
                      .foregroundStyle(conflict == nil ? Tokens.ink : Tokens.muted)
                    if let conflict {
                      Text(conflict.name)
                        .font(Typography.caption)
                        .foregroundStyle(Tokens.muted)
                    }
                  }
                  Spacer()
                  Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selected ? Tokens.ink : Tokens.muted)
                }
                .padding(12)
                .background(
                  Tokens.surface,
                  in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
              }
              .buttonStyle(.plain)
              .disabled(conflict != nil)
              .opacity(conflict != nil ? 0.55 : 1)
            }
          }

          if !activeSelectedMembers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text(L10n.tr("households.representativeLabel"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.muted)

              ForEach(activeSelectedMembers) { member in
                let isRep = representativeId == member.id
                Button {
                  representativeId = member.id
                } label: {
                  HStack(spacing: 10) {
                    Text(member.name)
                      .font(Typography.subheadlineBold)
                      .foregroundStyle(Tokens.ink)
                    if hasVietQR(member) {
                      Text(L10n.tr("households.hasVietQrHint"))
                        .font(Typography.captionBold)
                        .foregroundStyle(Tokens.onAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Tokens.accent, in: Capsule())
                    }
                    Spacer()
                    Image(systemName: isRep ? "largecircle.fill.circle" : "circle")
                      .font(.system(size: 18, weight: .semibold))
                      .foregroundStyle(isRep ? Tokens.ink : Tokens.muted)
                  }
                  .padding(12)
                  .background(
                    Tokens.surface,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }

          if let error {
            Text(errorText(for: error))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.debt)
          }

          SPButton(
            L10n.tr("households.saveAction"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: !canSave,
            isPending: isPending
          ) {
            Task { await submit() }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(
        editing == nil
          ? L10n.tr("households.createTitle")
          : L10n.tr("households.editTitle")
      )
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          SheetCancelButton(action: onDismiss)
            .disabled(isPending)
        }
      }
    }
    .spSheet(.form, embedsNavigationStack: true)
    .discardGuard(isDirty: isDirty && !isPending, onDiscard: onDismiss)
  }

  private func toggleMember(_ id: Member.ID) {
    if selectedIds.contains(id) {
      selectedIds.removeAll { $0 == id }
      if representativeId == id {
        representativeId = activeSelectedMembers.first?.id
      }
    } else if selectedIds.count < 20,
      members.first(where: { $0.id == id })?.active == true
    {
      selectedIds.append(id)
      if representativeId == nil {
        representativeId = id
      }
    }
  }

  private func submit() async {
    guard let repId = representativeId else { return }
    let trimmed = String(nameText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(50))
    if let editing {
      await onSaveUpdate(
        editing.id,
        UpdateHouseholdInput(
          name: trimmed,
          memberIds: selectedIds,
          representativeMemberId: repId
        )
      )
    } else {
      await onSaveCreate(trimmed, repId, selectedIds)
    }
  }

  private func errorText(for error: AppError) -> String {
    switch error {
    case .householdMemberConflict:
      return L10n.tr("households.conflictError")
    case .householdRepresentativeActiveRequired:
      return L10n.tr("households.repActiveError")
    default:
      return L10n.tr("common.saveError")
    }
  }
}
