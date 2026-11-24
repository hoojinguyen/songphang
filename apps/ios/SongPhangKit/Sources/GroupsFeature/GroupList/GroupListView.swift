import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct GroupListView: View {
  private let model: GroupListModel
  private let user: User
  private let statusNotice: String?
  private let unreadNotificationCount: Int
  private let onOpenGroup: (ExpenseGroup.ID) -> Void
  private let onOpenCreateGroup: () -> Void
  private let onOpenAccount: () -> Void
  private let onOpenNotifications: (() -> Void)?
  private let onResendVerification: () async throws(AppError) -> Void

  @State private var isResendingVerification = false
  @State private var verificationResent = false
  @State private var verificationError: String?
  @State private var archivingGroup: ExpenseGroup?
  @State private var cloningGroup: ExpenseGroup?

  public init(
    model: GroupListModel,
    user: User,
    statusNotice: String? = nil,
    unreadNotificationCount: Int = 0,
    onOpenGroup: @escaping (ExpenseGroup.ID) -> Void,
    onOpenCreateGroup: @escaping () -> Void,
    onOpenAccount: @escaping () -> Void,
    onOpenNotifications: (() -> Void)? = nil,
    onResendVerification: @escaping () async throws(AppError) -> Void = {}
  ) {
    self.model = model
    self.user = user
    self.statusNotice = statusNotice
    self.unreadNotificationCount = unreadNotificationCount
    self.onOpenGroup = onOpenGroup
    self.onOpenCreateGroup = onOpenCreateGroup
    self.onOpenAccount = onOpenAccount
    self.onOpenNotifications = onOpenNotifications
    self.onResendVerification = onResendVerification
  }

  private var isOffline: Bool {
    if model.refreshError == .offline { return true }
    if case .failed(.offline) = model.groups { return true }
    return false
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if model.refreshError != nil || model.actionError == .offline {
          OfflineBanner()
        }

        headerView

        if let statusNotice {
          Text(statusNotice)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
        }

        if let actionError = model.actionError, actionError != .offline {
          Text(L10n.tr("common.saveError"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.debt)
        }

        contentSection

        Spacer(minLength: 16)

        bottomSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .refreshable {
      await model.load()
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task {
      await model.load()
    }
    .confirmationDialog(
      archivingGroup.map { L10n.t("groups.archiveConfirmBody", ["name": $0.name]) }
        ?? L10n.tr("groups.archiveConfirmBody"),
      isPresented: Binding(
        get: { archivingGroup != nil },
        set: { if !$0 { archivingGroup = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let target = archivingGroup {
        Button(L10n.tr("groups.archiveAction"), role: .destructive) {
          Task {
            _ = await model.archive(groupId: target.id)
            archivingGroup = nil
          }
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        archivingGroup = nil
      }
    } message: {
      Text(L10n.tr("groups.archiveConfirmBody"))
    }
    .sheet(item: $cloningGroup) { group in
      CloneGroupSheetView(
        group: group,
        repository: model.repository,
        onDismiss: { cloningGroup = nil },
        onCloned: { newGroup in
          cloningGroup = nil
          Task {
            await model.load()
            onOpenGroup(newGroup.id)
          }
        }
      )
    }
  }

  private var headerView: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.t("groups.greeting", ["name": user.name]))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
        Text(L10n.tr("groups.title"))
          .font(Typography.pageTitle)
          .foregroundStyle(Tokens.ink)
      }
      Spacer()
      HStack(spacing: 8) {
        if let onOpenNotifications {
          NotificationBellButton(unreadCount: unreadNotificationCount, onOpen: onOpenNotifications)
        }
        Button(action: onOpenAccount) {
          MemberShapeView(
            shape: .circle,
            color: .mint,
            name: user.name,
            size: 52
          )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("account.title"))
      }
    }
  }

  @ViewBuilder
  private var contentSection: some View {
    SPSegmentedControl(
      label: L10n.tr("groups.title"),
      options: [
        SPSegmentedControl.Option(value: "active", label: L10n.tr("groups.tabActive")),
        SPSegmentedControl.Option(value: "archived", label: L10n.tr("groups.tabArchived")),
      ],
      value: model.selectedTab.rawValue
    ) { newValue in
      if let tab = GroupListModel.Tab(rawValue: newValue) {
        model.selectedTab = tab
      }
    }

    switch model.groups {
    case .loading:
      LoadingSkeleton(rowCount: 2, rowHeight: 160)

    case .failed:
      LoadError(isRetrying: model.isRefreshing) {
        Task { await model.load() }
      }

    case .loaded:
      let items = model.displayedGroups
      if items.isEmpty {
        VStack(spacing: 12) {
          Text(
            model.selectedTab == .archived
              ? L10n.tr("groups.archivedEmpty") : L10n.tr("groups.emptyTitle")
          )
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
          if model.selectedTab == .active {
            Text(L10n.tr("groups.emptyHint"))
              .font(Typography.body)
              .foregroundStyle(Tokens.muted)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
      } else {
        VStack(spacing: 16) {
          ForEach(Array(items.enumerated()), id: \.element.id) { index, group in
            if index == 0 && model.selectedTab == .active {
              featuredCard(for: group)
            } else {
              regularCard(for: group)
            }
          }
        }
      }
    }
  }

  private func groupContextMenu(for group: ExpenseGroup) -> some View {
    Group {
      if group.role.isOwner {
        if group.isArchived {
          Button {
            Task { _ = await model.unarchive(groupId: group.id) }
          } label: {
            Label(L10n.tr("groups.unarchiveAction"), systemImage: "arrow.uturn.backward")
          }
        } else {
          Button(role: .destructive) {
            archivingGroup = group
          } label: {
            Label(L10n.tr("groups.archiveAction"), systemImage: "archivebox")
          }
        }
      }
      if group.role.canWrite {
        Button {
          cloningGroup = group
        } label: {
          Label(L10n.tr("clone.title"), systemImage: "doc.on.doc")
        }
      }
    }
  }

  private func featuredCard(for group: ExpenseGroup) -> some View {
    let caption =
      group.myBalance.isPositive
      ? L10n.tr("groups.owedToYou")
      : group.myBalance.isNegative
        ? L10n.tr("groups.youOwe")
        : L10n.tr("groups.settled")

    return Button {
      onOpenGroup(group.id)
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 4) {
          ForEach(group.previewMembers) { member in
            MemberShapeView(
              shape: member.shape,
              color: member.color,
              name: member.name,
              size: 30
            )
          }
          Spacer()
          if group.pendingActionCount > 0 {
            Text(L10n.tr("groups.needsAction"))
              .font(Typography.captionBold)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Tokens.debt)
              .foregroundStyle(Tokens.surface)
              .clipShape(Capsule())
          }
        }
        .padding(.bottom, 4)

        Text(group.name)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        MoneyText(
          group.myBalance,
          style: .signed,
          font: Typography.heroNumber,
          color: Tokens.ink
        )

        Text(caption)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
      .padding(.horizontal, 22)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.accent)
      .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
    }
    .buttonStyle(.plain)
    .contextMenu {
      groupContextMenu(for: group)
    }
  }

  private func regularCard(for group: ExpenseGroup) -> some View {
    let chipColor: Color =
      group.myBalance.isPositive
      ? Tokens.accent
      : group.myBalance.isNegative
        ? Tokens.debtSoft
        : Tokens.sunken

    let chipCaption =
      group.myBalance.isPositive
      ? L10n.tr("groups.chipOwedToYou")
      : group.myBalance.isNegative
        ? L10n.tr("groups.chipYouOwe")
        : L10n.tr("groups.chipSettled")

    return Button {
      onOpenGroup(group.id)
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 4) {
            ForEach(group.previewMembers) { member in
              MemberShapeView(
                shape: member.shape,
                color: member.color,
                name: member.name,
                size: 22
              )
            }
            if group.memberCount > 4 {
              Text(L10n.t("groups.moreMembers", ["count": String(group.memberCount - 4)]))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
            }
          }

          HStack(spacing: 6) {
            Text(group.name)
              .font(Typography.screenHeaderTitle)
              .foregroundStyle(Tokens.ink)

            if group.pendingActionCount > 0 {
              Text(L10n.tr("groups.needsAction"))
                .font(Typography.captionBold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Tokens.debt)
                .foregroundStyle(Tokens.surface)
                .clipShape(Capsule())
            }
          }

          HStack(spacing: 8) {
            Text(L10n.t("groups.memberCount", ["count": String(group.memberCount)]))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            let roleLabel: String = {
              switch group.role {
              case .owner: return L10n.tr("members.roleOwner")
              case .editor: return L10n.tr("members.roleEditor")
              case .viewer: return L10n.tr("members.roleViewer")
              case .unknown: return ""
              }
            }()
            Text(roleLabel)
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 2) {
          MoneyText(
            group.myBalance,
            style: .signed,
            font: Typography.screenHeaderTitle,
            color: Tokens.ink
          )
          Text(chipCaption)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(chipColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
    .buttonStyle(.plain)
    .contextMenu {
      groupContextMenu(for: group)
    }
  }

  @ViewBuilder
  private var bottomSection: some View {
    if !user.emailVerified {
      SPCard(tone: .accent, padding: 20) {
        VStack(alignment: .leading, spacing: 12) {
          Text(L10n.tr("verify.banner"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)

          SPButton(
            L10n.tr("verify.resend"),
            variant: .surface,
            isPending: isResendingVerification
          ) {
            Task {
              isResendingVerification = true
              defer { isResendingVerification = false }
              do throws(AppError) {
                try await onResendVerification()
                verificationResent = true
                verificationError = nil
              } catch {
                verificationError = L10n.tr("common.saveError")
              }
            }
          }

          if verificationResent {
            Text(L10n.tr("verify.resent"))
              .font(Typography.subheadlineBold)
          }
          if let verificationError {
            Text(verificationError)
              .font(Typography.subheadlineBold)
          }
        }
      }
    } else {
      SPButton(
        L10n.tr("groups.create"),
        variant: .primary,
        size: .lg,
        isFullWidth: true,
        isOfflineBlocked: isOffline,
        action: onOpenCreateGroup
      )
    }
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    GroupListView(
      model: GroupListModel(repository: FakeGroupsRepository(world: world)),
      user: PreviewSamples.user,
      onOpenGroup: { _ in },
      onOpenCreateGroup: {},
      onOpenAccount: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    GroupListView(
      model: GroupListModel(repository: FakeGroupsRepository(world: world)),
      user: PreviewSamples.user,
      onOpenGroup: { _ in },
      onOpenCreateGroup: {},
      onOpenAccount: {}
    )
  }

  #Preview("Empty") {
    let world = FakeWorld(preset: .empty)
    GroupListView(
      model: GroupListModel(repository: FakeGroupsRepository(world: world)),
      user: PreviewSamples.user,
      onOpenGroup: { _ in },
      onOpenCreateGroup: {},
      onOpenAccount: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    GroupListView(
      model: GroupListModel(repository: FakeGroupsRepository(world: world)),
      user: PreviewSamples.user,
      onOpenGroup: { _ in },
      onOpenCreateGroup: {},
      onOpenAccount: {}
    )
  }
#endif
