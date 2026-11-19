import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct GroupSettingsView: View {
  @Bindable private var model: GroupSettingsModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onBackToGroups: () -> Void
  private let onDeletedGroup: () -> Void

  @State private var transferTarget: GroupUser?
  @State private var isShowingDeleteSheet = false
  @State private var deleteConfirmationText = ""

  public init(
    model: GroupSettingsModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onBackToGroups: @escaping () -> Void,
    onDeletedGroup: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onBackToGroups = onBackToGroups
    self.onDeletedGroup = onDeletedGroup
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        switch model.state {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 96)

        case .failed(let error):
          if case .api(_, 404) = error {
            VStack(spacing: 16) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBackToGroups)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
          } else {
            LoadError {
              Task { await model.load() }
            }
          }

        case .loaded(let data):
          if !data.group.role.isOwner {
            VStack(spacing: 16) {
              Text(L10n.tr("common.forbidden"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBackToGroups)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
          } else {
            loadedContent(data)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .task {
      if ProcessInfo.processInfo.arguments.contains("--open-delete-sheet") {
        isShowingDeleteSheet = true
      }
      await model.load()
    }
    .confirmationDialog(
      transferTarget.map { L10n.t("settings.transferConfirmTitle", ["name": $0.name]) } ?? "",
      isPresented: Binding(
        get: { transferTarget != nil },
        set: { if !$0 { transferTarget = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let target = transferTarget {
        Button(L10n.tr("settings.transferConfirm")) {
          Task {
            await model.transferOwnership(to: target.userId) {
              transferTarget = nil
              onBack()
            }
          }
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        transferTarget = nil
      }
    } message: {
      Text(L10n.tr("settings.transferConfirmBody"))
    }
    .sheet(isPresented: $isShowingDeleteSheet) {
      deleteGroupSheet(groupName: model.state.value?.group.name ?? "")
    }
  }

  @ViewBuilder
  private func loadedContent(_ data: GroupSettingsModel.ScreenData) -> some View {
    SPScreenHeader(
      title: L10n.tr("settings.title"),
      subtitle: L10n.tr("settings.ownerOnly"),
      onBack: onBack
    )

    if !isEmailVerified {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    } else {
      let isOffline = model.refreshError == .offline
      let trimmed = model.nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)

      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("settings.nameLabel"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)

        TextField("", text: $model.nameDraft)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 20)
          .frame(minHeight: 64)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
          .onChange(of: model.nameDraft) { _, newValue in
            if newValue.count > 80 {
              model.nameDraft = String(newValue.prefix(80))
            }
          }
          .accessibilityLabel(L10n.tr("settings.nameLabel"))
      }

      SPButton(
        L10n.tr("settings.saveName"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: isOffline || model.isPerformingAction || trimmed.isEmpty
          || trimmed == data.group.name
      ) {
        Task { await model.saveName() }
      }

      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(L10n.tr("settings.minimizeTitle"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
          Text(L10n.tr("settings.minimizeHint"))
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        Spacer(minLength: 8)
        SPSwitch(
          checked: data.group.minimizeDebts,
          label: L10n.tr("settings.minimizeTitle"),
          isDisabled: isOffline || model.isPerformingAction
        ) { newValue in
          Task { await model.setMinimizeDebts(newValue) }
        }
      }
      .padding(20)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("settings.defaultRoleTitle"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        Text(L10n.tr("settings.defaultRoleHint"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        SPSegmentedControl(
          label: L10n.tr("settings.defaultRoleTitle"),
          options: [
            SPSegmentedControl.Option(value: "editor", label: L10n.tr("members.roleEditor")),
            SPSegmentedControl.Option(value: "viewer", label: L10n.tr("members.roleViewer")),
          ],
          value: data.group.defaultRole.code,
          isDisabled: isOffline || model.isPerformingAction
        ) { selected in
          let role: Role = selected == "viewer" ? .viewer : .editor
          Task { await model.setDefaultRole(role) }
        }
      }
      .padding(20)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

      inviteLinkCard(invite: data.invite)
      transferOwnershipCard(users: data.users)
      deleteGroupCard()

      if model.actionError != nil {
        Text(L10n.tr("common.saveError"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
  }

  private func inviteLinkCard(invite: Invite) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("settings.linkTitle"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
      Text(invite.active ? L10n.tr("settings.linkOn") : L10n.tr("settings.linkOff"))
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)

      SPButton(
        invite.active ? L10n.tr("settings.disableLink") : L10n.tr("settings.enableLink"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: model.isPerformingAction
      ) {
        Task { await model.setInviteActive(!invite.active) }
      }

      SPButton(
        L10n.tr("settings.rotateLink"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: model.isPerformingAction
      ) {
        Task { await model.rotateInvite() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func transferOwnershipCard(users: [GroupUser]) -> some View {
    let others = users.filter { !$0.isMe }
    return VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("settings.transferTitle"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
      Text(L10n.tr("settings.transferHint"))
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)

      if others.isEmpty {
        Text(L10n.tr("settings.transferNobody"))
          .font(Typography.body)
          .foregroundStyle(Tokens.ink)
      } else {
        ForEach(others) { user in
          SPButton(
            user.name,
            variant: .surface,
            isFullWidth: true,
            isDisabled: model.isPerformingAction
          ) {
            transferTarget = user
          }
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func deleteGroupCard() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("settings.deleteHint"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("settings.deleteButton"),
        variant: .primary,
        isFullWidth: true
      ) {
        deleteConfirmationText = ""
        isShowingDeleteSheet = true
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.debtSoft)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func deleteGroupSheet(groupName: String) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(L10n.t("settings.deleteTitle", ["name": groupName]))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      Text(L10n.tr("settings.deleteBody"))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.ink)

      SPTextField(
        label: L10n.tr("settings.nameLabel"),
        text: $deleteConfirmationText,
        maxLength: 80
      )

      HStack(spacing: 12) {
        SPButton(
          L10n.tr("members.removeCancel"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: model.isPerformingAction
        ) {
          isShowingDeleteSheet = false
        }

        SPButton(
          L10n.tr("settings.deleteButton"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: deleteConfirmationText != groupName || model.isPerformingAction,
          isPending: model.isPerformingAction
        ) {
          Task {
            await model.deleteGroup(confirmName: deleteConfirmationText) {
              isShowingDeleteSheet = false
              onDeletedGroup()
            }
          }
        }
      }
      Spacer()
    }
    .padding(24)
    .background(Tokens.bg.ignoresSafeArea())
    .presentationDetents([.medium])
  }
}

#if DEBUG
  #Preview("Loaded Owner") {
    let world = FakeWorld(preset: .tripStep4)
    GroupSettingsView(
      model: GroupSettingsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world),
        membersRepository: FakeMembersRepository(world: world)
      ),
      onBack: {},
      onBackToGroups: {},
      onDeletedGroup: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    GroupSettingsView(
      model: GroupSettingsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world),
        membersRepository: FakeMembersRepository(world: world)
      ),
      onBack: {},
      onBackToGroups: {},
      onDeletedGroup: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    GroupSettingsView(
      model: GroupSettingsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world),
        membersRepository: FakeMembersRepository(world: world)
      ),
      onBack: {},
      onBackToGroups: {},
      onDeletedGroup: {}
    )
  }
#endif
