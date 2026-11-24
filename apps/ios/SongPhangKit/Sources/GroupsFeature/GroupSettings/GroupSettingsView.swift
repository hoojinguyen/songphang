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
  @State private var isShowingArchiveDialog = false
  @State private var isShowingCloneSheet = false
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
    .confirmationDialog(
      L10n.tr("groups.archiveAction"),
      isPresented: $isShowingArchiveDialog,
      titleVisibility: .visible
    ) {
      Button(L10n.tr("groups.archiveAction"), role: .destructive) {
        Task { await model.archive() }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {}
    } message: {
      Text(L10n.tr("groups.archiveConfirmBody"))
    }
    .sheet(isPresented: $isShowingCloneSheet) {
      if let group = model.state.value?.group {
        CloneGroupSheetView(
          group: group,
          repository: model.groupsRepository,
          onDismiss: { isShowingCloneSheet = false },
          onCloned: { _ in
            isShowingCloneSheet = false
            onBackToGroups()
          }
        )
      }
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
      let isArchived = data.group.isArchived
      let isReadOnly = isOffline || isArchived || model.isPerformingAction
      let trimmed = model.nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)

      if isArchived {
        SPCard(tone: .sunken, padding: 16) {
          Text(L10n.tr("groups.archivedBanner"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("settings.nameLabel"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)

        TextField("", text: $model.nameDraft)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
          .disabled(isReadOnly)
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
        isDisabled: isReadOnly || trimmed.isEmpty
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
          isDisabled: isReadOnly
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
          isDisabled: isReadOnly
        ) { selected in
          let role: Role = selected == "viewer" ? .viewer : .editor
          Task { await model.setDefaultRole(role) }
        }
      }
      .padding(20)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("reminders.settingTitle"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        SPSegmentedControl(
          label: L10n.tr("reminders.settingTitle"),
          options: [
            SPSegmentedControl.Option(value: "off", label: L10n.tr("reminders.intervalOff")),
            SPSegmentedControl.Option(value: "3", label: L10n.tr("reminders.interval3")),
            SPSegmentedControl.Option(value: "7", label: L10n.tr("reminders.interval7")),
            SPSegmentedControl.Option(value: "14", label: L10n.tr("reminders.interval14")),
          ],
          value: data.group.reminderIntervalDays.map(String.init) ?? "off",
          isDisabled: isReadOnly
        ) { selected in
          let interval: Int? = {
            switch selected {
            case "3": return 3
            case "7": return 7
            case "14": return 14
            default: return nil
            }
          }()
          Task { await model.setReminderInterval(interval) }
        }
      }
      .padding(20)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

      inviteLinkCard(invite: data.invite, isDisabled: isReadOnly)
      CategoryManagementSection(
        groupId: model.groupId,
        categories: data.categories,
        categoriesRepository: model.categoriesRepository,
        isDisabled: isReadOnly,
        onChanged: { model.updateCategories($0) }
      )
      BudgetSettingsCard(
        budget: data.budget,
        isDisabled: isReadOnly,
        isPending: model.isSavingBudget,
        errorMessage: budgetErrorText,
        onSave: { period, amount in
          Task { await model.saveBudget(period: period, amount: amount) }
        },
        onRemove: {
          Task { await model.removeBudget() }
        }
      )
      ApprovalCardView(
        group: data.group,
        isDisabled: isReadOnly,
        isPending: model.isPerformingAction,
        onSave: { threshold in
          Task { await model.setApprovalThreshold(threshold) }
        }
      )
      if model.telegramFeatureEnabled {
        TelegramGroupCardView(
          model: model,
          isDisabled: isReadOnly
        )
      }
      transferOwnershipCard(users: data.users, isDisabled: isReadOnly)
      cloneCard(group: data.group, isOffline: isOffline)
      archiveCard(group: data.group, isOffline: isOffline)
      deleteGroupCard(isOffline: isOffline)

      if model.actionError != nil {
        Text(L10n.tr("common.saveError"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
  }

  private func inviteLinkCard(invite: Invite, isDisabled: Bool) -> some View {
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
        isDisabled: isDisabled
      ) {
        Task { await model.setInviteActive(!invite.active) }
      }

      SPButton(
        L10n.tr("settings.rotateLink"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: isDisabled
      ) {
        Task { await model.rotateInvite() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func transferOwnershipCard(users: [GroupUser], isDisabled: Bool) -> some View {
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
            isDisabled: isDisabled
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

  private func cloneCard(group: ExpenseGroup, isOffline: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("clone.title"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("clone.title"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: isOffline || model.isPerformingAction
      ) {
        isShowingCloneSheet = true
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func archiveCard(group: ExpenseGroup, isOffline: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      if group.isArchived {
        Text(L10n.tr("groups.archivedBanner"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        SPButton(
          L10n.tr("groups.unarchiveAction"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: isOffline || model.isPerformingAction
        ) {
          Task { await model.unarchive() }
        }
      } else {
        Text(L10n.tr("groups.archiveConfirmBody"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        SPButton(
          L10n.tr("groups.archiveAction"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: isOffline || model.isPerformingAction
        ) {
          isShowingArchiveDialog = true
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func deleteGroupCard(isOffline: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("settings.deleteHint"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("settings.deleteButton"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: isOffline || model.isPerformingAction
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

  private var budgetErrorText: String? {
    guard let error = model.budgetError else { return nil }
    if case .api(_, 403) = error {
      return L10n.tr("common.forbidden")
    }
    return L10n.tr("common.saveError")
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
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world)
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
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world)
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
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world)
      ),
      onBack: {},
      onBackToGroups: {},
      onDeletedGroup: {}
    )
  }
#endif
