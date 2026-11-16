import DesignSystem
public import Domain
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

public struct MembersView: View {
  @Bindable private var model: MembersModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onOpenActivity: (ExpenseGroup.ID) -> Void
  private let onOpenSettings: (ExpenseGroup.ID) -> Void
  private let onLeftGroup: () -> Void

  @State private var editingNames: [Member.ID: String] = [:]
  @State private var deactivateWarningMember: Member?
  @State private var removingUser: GroupUser?
  @State private var isConfirmingLeave = false
  @State private var copiedLink = false

  public init(
    model: MembersModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onOpenActivity: @escaping (ExpenseGroup.ID) -> Void,
    onOpenSettings: @escaping (ExpenseGroup.ID) -> Void,
    onLeftGroup: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onOpenActivity = onOpenActivity
    self.onOpenSettings = onOpenSettings
    self.onLeftGroup = onLeftGroup
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        switch model.state {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 84)

        case .failed(let error):
          if case .api(_, 404) = error {
            VStack(spacing: 16) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onLeftGroup)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
          } else {
            LoadError {
              Task { await model.load() }
            }
          }

        case .loaded(let data):
          loadedContent(data)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .task {
      await model.load()
    }
    .confirmationDialog(
      removingUser.map { L10n.t("members.removeTitle", ["name": $0.name]) } ?? "",
      isPresented: Binding(
        get: { removingUser != nil },
        set: { if !$0 { removingUser = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let user = removingUser {
        Button(L10n.tr("members.removeConfirm"), role: .destructive) {
          Task {
            await model.removeUser(userId: user.userId)
            removingUser = nil
          }
        }
      }
      Button(L10n.tr("members.removeCancel"), role: .cancel) {
        removingUser = nil
      }
    } message: {
      Text(L10n.tr("members.removeBody"))
    }
    .confirmationDialog(
      L10n.t("members.leaveTitle", ["name": model.state.value?.group.name ?? ""]),
      isPresented: $isConfirmingLeave,
      titleVisibility: .visible
    ) {
      Button(L10n.tr("members.leave"), role: .destructive) {
        Task { await model.leaveGroup(onLeft: onLeftGroup) }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {}
    } message: {
      Text(L10n.tr("members.leaveBody"))
    }
  }

  @ViewBuilder
  private func loadedContent(_ data: MembersModel.ScreenData) -> some View {
    let canWrite = isEmailVerified && data.group.role.canWrite

    SPScreenHeader(
      title: data.group.name,
      subtitle: L10n.t("members.memberCount", ["count": String(data.members.count)]),
      onBack: onBack
    )

    ForEach(data.members) { member in
      let memberRole = data.users.first(where: { $0.memberId == member.id })?.role
      let isExpanded = model.expandedMemberId == member.id

      VStack(alignment: .leading, spacing: 8) {
        memberRow(member: member, role: memberRole, canEdit: canWrite, isExpanded: isExpanded)

        if canWrite && isExpanded {
          let memberBalance =
            data.balances.balances.first(where: { $0.memberId == member.id })?.balance ?? .zero
          memberEditor(member: member, balance: memberBalance)
        }

        if isEmailVerified && member.active && !member.claimed {
          SPButton(
            L10n.tr("members.thisIsMe"),
            variant: .surface,
            isDisabled: model.isPerformingAction
          ) {
            Task { await model.chooseMyMember(memberId: member.id) }
          }
        }

        if isEmailVerified && data.group.role.isOwner {
          ForEach(data.users.filter { $0.memberId == member.id && !$0.isMe }) { user in
            userControlsCard(user: user)
          }
        }
      }
    }

    if canWrite {
      addMemberSection(members: data.members)
    } else if !isEmailVerified {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }

    ForEach(data.users.filter { $0.memberId == nil }) { user in
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Circle()
            .fill(Tokens.sunken)
            .frame(width: 52, height: 52)
          VStack(alignment: .leading, spacing: 2) {
            Text(user.name)
              .font(Typography.bodyBold)
            Text(L10n.tr("members.noShape"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
        }
        if isEmailVerified && data.group.role.isOwner && !user.isMe {
          userControlsCard(user: user)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    if let actionError = model.actionError {
      Text(errorText(for: actionError))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }

    if !data.group.role.isOwner && isEmailVerified {
      SPButton(
        L10n.tr("members.leave"),
        variant: .surface,
        size: .lg,
        isFullWidth: true
      ) {
        isConfirmingLeave = true
      }
    }

    if data.group.role.canWrite, let invite = data.invite {
      inviteCardSection(invite: invite)
    }

    HStack(spacing: 12) {
      Button {
        onOpenActivity(model.groupId)
      } label: {
        Text(L10n.tr("activity.title"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .frame(maxWidth: .infinity, minHeight: 60)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
      }
      .buttonStyle(.plain)

      if data.group.role.isOwner {
        Button {
          onOpenSettings(model.groupId)
        } label: {
          Text(L10n.tr("members.settingsLink"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func memberRow(
    member: Member,
    role: Role?,
    canEdit: Bool,
    isExpanded: Bool
  ) -> some View {
    let statusTag =
      !member.active
      ? L10n.tr("members.inactiveTag")
      : member.isMe
        ? L10n.tr("members.loggedInYou")
        : member.claimed
          ? L10n.tr("members.joined")
          : L10n.tr("members.unclaimed")

    let content = HStack(spacing: 12) {
      MemberShapeView(
        shape: member.shape,
        color: member.color,
        name: member.name,
        size: 52
      )
      VStack(alignment: .leading, spacing: 2) {
        Text(member.name)
          .font(Typography.bodyBold)
          .foregroundStyle(member.active ? Tokens.ink : Tokens.muted)
        Text(statusTag)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
      Spacer(minLength: 8)
      if let role {
        let badgeText =
          role == .owner
          ? L10n.tr("members.ownerBadge")
          : role == .editor
            ? L10n.tr("members.roleEditor")
            : L10n.tr("members.roleViewer")
        Text(badgeText)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(role == .owner ? Tokens.accent : Tokens.sunken)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

    return Group {
      if canEdit {
        Button {
          if isExpanded {
            model.expandedMemberId = nil
          } else {
            editingNames[member.id] = member.name
            deactivateWarningMember = nil
            model.expandedMemberId = member.id
          }
        } label: {
          content
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.t("members.edit", ["name": member.name]))
      } else {
        content
      }
    }
  }

  private func memberEditor(member: Member, balance: Money) -> some View {
    let currentDraft = editingNames[member.id] ?? member.name
    let trimmed = currentDraft.trimmingCharacters(in: .whitespacesAndNewlines)

    return VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.tr("members.nameLabel"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        TextField(
          "",
          text: Binding(
            get: { editingNames[member.id] ?? member.name },
            set: { editingNames[member.id] = String($0.prefix(50)) }
          )
        )
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(Tokens.bg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      }

      SPButton(
        L10n.tr("members.saveName"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: model.isPerformingAction || trimmed.isEmpty || trimmed == member.name
      ) {
        Task { await model.renameMember(memberId: member.id, newName: trimmed) }
      }

      if deactivateWarningMember?.id == member.id {
        VStack(alignment: .leading, spacing: 8) {
          Text(
            L10n.t(
              "members.deactivateWarning",
              [
                "name": member.name,
                "amount": "\(MoneyFormat.signedAmount(balance)) \(L10n.tr("common.currency"))",
              ]
            )
          )
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)

          SPButton(
            L10n.tr("members.deactivateAnyway"),
            variant: .primary,
            isFullWidth: true,
            isDisabled: model.isPerformingAction
          ) {
            Task {
              await model.setMemberActive(memberId: member.id, active: false)
              deactivateWarningMember = nil
            }
          }

          SPButton(
            L10n.tr("members.keepActive"),
            variant: .surface,
            isFullWidth: true,
            isDisabled: model.isPerformingAction
          ) {
            deactivateWarningMember = nil
          }
        }
      } else {
        SPButton(
          member.active ? L10n.tr("members.deactivate") : L10n.tr("members.reactivate"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: model.isPerformingAction
        ) {
          if member.active && !balance.isZero {
            deactivateWarningMember = member
          } else {
            Task { await model.setMemberActive(memberId: member.id, active: !member.active) }
          }
        }
      }

      SPButton(
        L10n.tr("members.delete"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: model.isPerformingAction
      ) {
        Task { await model.deleteMember(memberId: member.id) }
      }
    }
    .padding(16)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  @ViewBuilder
  private func addMemberSection(members: [Member]) -> some View {
    if members.count >= 100 {
      Text(L10n.tr("members.limitReached"))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.muted)
    } else if model.isAddMemberOpen {
      let usedPairs = members.map { (shape: $0.shape, color: $0.color) }
      let nextPos = (members.last?.position ?? -1) + 1
      NewMemberInputRow(
        appearance: MemberAppearancePalette.nextAppearance(
          usedPairs: usedPairs,
          position: nextPos
        ),
        label: L10n.tr("members.newNameLabel"),
        addLabel: L10n.tr("members.add"),
        isDisabled: model.isPerformingAction
      ) { newName in
        Task { await model.addMember(name: newName) }
      }
    } else {
      Button {
        model.isAddMemberOpen = true
      } label: {
        Text(L10n.tr("members.addName"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .frame(maxWidth: .infinity, minHeight: 56)
          .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
              .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
              .foregroundStyle(Tokens.dashed)
          )
      }
      .buttonStyle(.plain)
    }
  }

  private func userControlsCard(user: GroupUser) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      SPSegmentedControl(
        label: L10n.t("members.roleLabel", ["name": user.name]),
        options: [
          SPSegmentedControl.Option(value: "editor", label: L10n.tr("members.roleEditor")),
          SPSegmentedControl.Option(value: "viewer", label: L10n.tr("members.roleViewer")),
        ],
        value: user.role.code,
        isDisabled: model.isPerformingAction
      ) { selected in
        let newRole: Role = selected == "viewer" ? .viewer : .editor
        Task { await model.updateUserRole(userId: user.userId, role: newRole) }
      }

      SPButton(
        L10n.tr("members.removeUser"),
        variant: .surface,
        isFullWidth: true,
        isDisabled: model.isPerformingAction
      ) {
        removingUser = user
      }
    }
    .padding(16)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func inviteCardSection(invite: Invite) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 16) {
        if invite.active {
          SPQRCodeView(
            payload: invite.url,
            label: L10n.tr("invite.qrLabel"),
            size: 96
          )
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(L10n.tr("invite.title"))
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)
          Text(invite.active ? L10n.tr("invite.hint") : L10n.tr("invite.disabled"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
        }
      }

      if invite.active {
        HStack(spacing: 12) {
          SPButton(L10n.tr("invite.copy"), variant: .primary) {
            UIPasteboard.general.string = invite.url
            copiedLink = true
          }

          if let shareURL = URL(string: invite.url) {
            ShareLink(item: shareURL) {
              Text(L10n.tr("invite.share"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 24)
                .frame(minHeight: Tokens.controlMediumHeight)
                .background(Tokens.surface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }

      if copiedLink {
        Text(L10n.tr("invite.copied"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.accent)
    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
  }

  private func errorText(for error: AppError) -> String {
    if case .api(let code, let status) = error {
      if status == 403 { return L10n.tr("common.forbidden") }
      if code == "MEMBER_ALREADY_CLAIMED" { return L10n.tr("join.claimedMeanwhile") }
      if code == "MEMBER_HAS_TRANSACTIONS" {
        let name =
          model.state.value?.members.first(where: { $0.id == model.expandedMemberId })?.name ?? ""
        return L10n.t("members.hasTransactions", ["name": name])
      }
    }
    return L10n.tr("common.saveError")
  }
}

#if DEBUG
  #Preview("Loaded Owner") {
    let world = FakeWorld(preset: .tripStep4)
    MembersView(
      model: MembersModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world)
      ),
      onBack: {},
      onOpenActivity: { _ in },
      onOpenSettings: { _ in },
      onLeftGroup: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    MembersView(
      model: MembersModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world)
      ),
      onBack: {},
      onOpenActivity: { _ in },
      onOpenSettings: { _ in },
      onLeftGroup: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    MembersView(
      model: MembersModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        invitesRepository: FakeInvitesRepository(world: world)
      ),
      onBack: {},
      onOpenActivity: { _ in },
      onOpenSettings: { _ in },
      onLeftGroup: {}
    )
  }
#endif
