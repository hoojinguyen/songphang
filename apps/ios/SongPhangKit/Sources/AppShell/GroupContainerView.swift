import DesignSystem
public import Domain
import GroupsFeature
import LedgerFeature
import NotificationsFeature
import PaymentsFeature
import StatisticsFeature
public import SwiftUI

public enum GroupSegment: String, Sendable, Hashable, CaseIterable {
  case expenses
  case payments
  case fundAndStats

  public var title: String {
    switch self {
    case .expenses: return L10n.tr("groupSegments.expenses")
    case .payments: return L10n.tr("groupSegments.payments")
    case .fundAndStats: return L10n.tr("groupSegments.fundAndStats")
    }
  }
}

public struct GroupContainerView: View {
  public enum FundSubTab: String, CaseIterable, Sendable {
    case stats
    case fund

    public var title: String {
      switch self {
      case .stats: return L10n.tr("stats.title")
      case .fund: return L10n.tr("fund.defaultName")
      }
    }
  }

  private struct PaymentSheet: Identifiable {
    var id: SuggestedTransfer.ID { transfer.id }
    let transfer: SuggestedTransfer
    let fromMember: Member
    let toMember: Member
  }

  private let groupId: ExpenseGroup.ID
  private let dependencies: AppDependencies
  private let sessionModel: SessionModel
  private let currentUser: User?
  private let onBack: () -> Void
  private let onNavigate: (Route) -> Void
  private let onReplaceTop: (Route) -> Void
  private let onPopToRoot: (String?) -> Void
  private let onExpenseSaved: () -> Void
  @Binding private var deletedTransactionId: LedgerTransaction.ID?

  @State private var selectedSegment: GroupSegment
  @State private var fundSubTab: FundSubTab = .stats
  @State private var isCloneSheetPresented = false
  @State private var isArchiveConfirmPresented = false
  @State private var isReceiptCaptureOpen = false
  @State private var isGuestLinkSheetOpen = false
  @State private var isShareCardSheetOpen = false
  @State private var isArchiving = false
  @State private var paymentSheet: PaymentSheet?

  @State private var feedModel: GroupFeedModel
  @State private var balancesModel: BalancesModel
  @State private var statsModel: StatsModel
  @State private var recurringExpensesModel: RecurringExpensesModel
  @State private var fundModel: FundModel
  @State private var guestLinkSheetModel: GuestLinkSheetModel

  public init(
    groupId: ExpenseGroup.ID,
    initialSegment: GroupSegment = .expenses,
    initialFilter: TransactionFilter? = nil,
    initialFundSubTab: FundSubTab? = nil,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    currentUser: User?,
    deletedTransactionId: Binding<LedgerTransaction.ID?>,
    onBack: @escaping () -> Void,
    onNavigate: @escaping (Route) -> Void,
    onReplaceTop: @escaping (Route) -> Void,
    onPopToRoot: @escaping (String?) -> Void,
    onExpenseSaved: @escaping () -> Void
  ) {
    self.groupId = groupId
    self.dependencies = dependencies
    self.sessionModel = sessionModel
    self.currentUser = currentUser
    self._deletedTransactionId = deletedTransactionId
    self.onBack = onBack
    self.onNavigate = onNavigate
    self.onReplaceTop = onReplaceTop
    self.onPopToRoot = onPopToRoot
    self.onExpenseSaved = onExpenseSaved
    self._selectedSegment = State(initialValue: initialSegment)
    if let initialFundSubTab {
      self._fundSubTab = State(initialValue: initialFundSubTab)
    }

    let feed = GroupFeedModel(
      groupId: groupId,
      groupsRepository: dependencies.groups,
      membersRepository: dependencies.members,
      balancesRepository: dependencies.balances,
      categoriesRepository: dependencies.categories,
      budgetRepository: dependencies.budget,
      transactionsRepository: dependencies.transactions,
      eventsRepository: dependencies.groupEvents,
      attachmentsRepository: dependencies.attachments,
      settlementCyclesRepository: dependencies.settlementCycles,
      initialFilter: initialFilter
    )
    self._feedModel = State(initialValue: feed)

    let balances = BalancesModel(
      groupId: groupId,
      groupsRepository: dependencies.groups,
      membersRepository: dependencies.members,
      balancesRepository: dependencies.balances,
      transactionsRepository: dependencies.transactions,
      settlementRequests: dependencies.settlementRequests,
      remindersRepository: dependencies.reminders,
      settlementCyclesRepository: dependencies.settlementCycles,
      eventsRepository: dependencies.groupEvents,
      onUnauthorized: {
        onPopToRoot(nil)
        Task { await sessionModel.signOut() }
      }
    )
    self._balancesModel = State(initialValue: balances)

    let stats = StatsModel(
      groupId: groupId,
      groupsRepository: dependencies.groups,
      membersRepository: dependencies.members,
      categoriesRepository: dependencies.categories,
      budgetRepository: dependencies.budget,
      statisticsRepository: dependencies.statistics,
      onUnauthorized: {
        onPopToRoot(nil)
        Task { await sessionModel.signOut() }
      }
    )
    self._statsModel = State(initialValue: stats)

    let recurring = RecurringExpensesModel(
      groupId: groupId,
      repository: dependencies.recurringExpenses,
      onUnauthorized: {
        onPopToRoot(nil)
        Task { await sessionModel.signOut() }
      }
    )
    self._recurringExpensesModel = State(initialValue: recurring)

    let fund = FundModel(
      groupId: groupId,
      groupsRepository: dependencies.groups,
      membersRepository: dependencies.members,
      balancesRepository: dependencies.balances,
      fundRepository: dependencies.fund,
      onUnauthorized: {
        onPopToRoot(nil)
        Task { await sessionModel.signOut() }
      }
    )
    self._fundModel = State(initialValue: fund)

    let guestLinkSheet = GuestLinkSheetModel(
      groupId: groupId,
      guestLinksRepository: dependencies.guestLinks,
      onUnauthorized: {
        Task { await sessionModel.signOut() }
      }
    )
    self._guestLinkSheetModel = State(initialValue: guestLinkSheet)
  }

  private var currentGroup: ExpenseGroup? {
    feedModel.state.value?.group
      ?? balancesModel.state.value?.group
      ?? statsModel.state.value?.group
      ?? fundModel.state.value?.group
  }

  private var currentMembers: [Member] {
    feedModel.state.value?.members
      ?? balancesModel.state.value?.members
      ?? statsModel.state.value?.members
      ?? fundModel.state.value?.members
      ?? []
  }

  private var isArchived: Bool {
    currentGroup?.isArchived == true
  }

  private var canWrite: Bool {
    (currentGroup?.role.canWrite == true) && (currentUser?.emailVerified ?? true)
  }

  private var isOwner: Bool {
    currentGroup?.role == .owner
  }

  public var body: some View {
    VStack(spacing: 8) {
      persistentHeader
        .padding(.horizontal, 20)
        .padding(.top, 8)

      segmentSwitcher
        .padding(.horizontal, 20)

      if isArchived {
        Text(L10n.tr("groups.archivedBanner"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .padding(.horizontal, 20)
      }

      contentView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .confirmationDialog(
      L10n.tr("groups.archiveAction"),
      isPresented: $isArchiveConfirmPresented,
      titleVisibility: .visible
    ) {
      Button(L10n.tr("groups.archiveAction"), role: .destructive) {
        Task { await archiveCurrentGroup() }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {}
    } message: {
      Text(L10n.tr("groups.archiveConfirmBody"))
    }
    .sheet(isPresented: $isCloneSheetPresented) {
      if let group = currentGroup {
        CloneGroupSheetView(
          group: group,
          repository: dependencies.groups,
          onDismiss: {
            isCloneSheetPresented = false
          },
          onCloned: { newGroup in
            isCloneSheetPresented = false
            onNavigate(.groupFeed(groupId: newGroup.id))
          }
        )
      }
    }
    .sheet(isPresented: $isReceiptCaptureOpen) {
      ReceiptCaptureSheet(
        groupId: groupId,
        attachmentsRepository: dependencies.attachments,
        receiptScansRepository: dependencies.receiptScans,
        onScanStarted: { scan in
          isReceiptCaptureOpen = false
          onNavigate(.receiptReview(groupId: groupId, scanId: scan.id))
        },
        onManualFallback: { attachmentId in
          isReceiptCaptureOpen = false
          onNavigate(
            .newTransactionForm(
              groupId: groupId,
              initialReading: nil,
              initialAttachmentId: attachmentId
            )
          )
        },
        onDismiss: { isReceiptCaptureOpen = false }
      )
    }
    .onChange(of: deletedTransactionId) { _, id in
      guard let id else { return }
      feedModel.markDeleted(id)
      deletedTransactionId = nil
    }
    #if DEBUG
      .task {
        if ProcessInfo.processInfo.arguments.contains("--open-share-card") {
          while balancesModel.state.value == nil {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }
          }
          isShareCardSheetOpen = true
        }
      }
    #endif
    .sheet(isPresented: $isGuestLinkSheetOpen) {
      GuestLinkSheetView(
        model: guestLinkSheetModel,
        isOffline: sessionModel.isOffline || balancesModel.refreshError == .offline,
        isArchived: balancesModel.state.value?.group.isArchived ?? false,
        onDismiss: { isGuestLinkSheetOpen = false }
      )
    }
    .sheet(isPresented: $isShareCardSheetOpen) {
      if let balancesData = balancesModel.state.value {
        ShareCardPreviewSheet(
          data: balancesData,
          loadGuestLink: {
            try? await dependencies.guestLinks.status(groupId: groupId)
          },
          onDismiss: { isShareCardSheetOpen = false }
        )
      }
    }
    .sheet(item: $paymentSheet) { selection in
      let role = balancesModel.state.value?.group.role ?? .editor
      let myMemberId = balancesModel.state.value?.group.myMemberId
      let isVerified = currentUser?.emailVerified ?? true
      let canEdit = role.canWrite
      let payModel = PayModel(
        transfer: selection.transfer,
        fromMember: selection.fromMember,
        toMember: selection.toMember,
        groupId: groupId,
        myMemberId: myMemberId,
        role: role,
        isEmailVerified: isVerified,
        isFromHouseholdMember: {
          guard let myMemberId else { return false }
          return selection.transfer.fromHousehold?.memberIds.contains(myMemberId) == true
        }(),
        repository: dependencies.settlementRequests,
        uploadProof: { data, filename, contentType async throws(AppError) in
          try await dependencies.attachments.upload(
            groupId: groupId,
            data: data,
            filename: filename,
            contentType: contentType,
            purpose: .transferProof
          )
        },
        loadAttachment: { attachmentId in
          try await dependencies.attachments.content(groupId: groupId, attachmentId: attachmentId)
        },
        onReload: { await balancesModel.load() },
        onUnauthorized: {
          paymentSheet = nil
          onPopToRoot(nil)
          Task { await sessionModel.signOut() }
        }
      )
      NavigationStack {
        PayView(
          model: payModel,
          isOffline: sessionModel.isOffline || balancesModel.refreshError == .offline,
          onBack: { paymentSheet = nil },
          onAddDetails: payModel.canAddDetails
            ? {
              paymentSheet = nil
              onNavigate(.groupMembers(groupId: groupId))
            } : nil,
          onRecordDirectly: canEdit && selection.transfer.pendingSettlement == nil
            ? {
              paymentSheet = nil
              onNavigate(
                .settle(
                  groupId: groupId,
                  fromMemberId: selection.transfer.fromMemberId,
                  toMemberId: selection.transfer.toMemberId,
                  initialAmount: selection.transfer.amount
                )
              )
            } : nil,
          onFinished: { _ in
            paymentSheet = nil
            onExpenseSaved()
          }
        )
      }
    }
  }

  private var persistentHeader: some View {
    HStack(spacing: 8) {
      Button(action: onBack) {
        Image(systemName: "chevron.backward")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Tokens.ink)
          .frame(width: 44, height: 44)
          .background(Tokens.surface, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(L10n.tr("common.back"))

      HStack(spacing: 6) {
        Text(currentGroup?.name ?? "")
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .lineLimit(1)

        if isArchived {
          Text(L10n.tr("groups.tabArchived"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Tokens.sunken, in: Capsule())
        }
      }

      Spacer(minLength: 4)

      HStack(spacing: 8) {
        NotificationBellButton(
          unreadCount: sessionModel.unreadNotificationCount,
          onOpen: { onNavigate(.notifications) }
        )

        Button {
          onNavigate(.groupMembers(groupId: groupId))
        } label: {
          HStack(spacing: 2) {
            ForEach(Array(currentMembers.prefix(4))) { member in
              MemberShapeView(
                shape: member.shape,
                color: member.color,
                name: member.name,
                size: 24,
                showInitial: false
              )
            }
          }
          .padding(.horizontal, 10)
          .frame(minHeight: 44)
          .background(Tokens.surface)
          .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("feed.membersLink"))

        overflowMenu
      }
    }
  }

  private var overflowMenu: some View {
    Menu {
      Button {
        onNavigate(.groupActivity(groupId: groupId))
      } label: {
        Label(L10n.tr("activity.title"), systemImage: "clock.arrow.circlepath")
      }

      Button {
        onNavigate(.groupSettings(groupId: groupId))
      } label: {
        Label(L10n.tr("categories.title"), systemImage: "tag")
      }

      if sessionModel.latestFeatures?.telegram == true {
        Button {
          onNavigate(.groupSettings(groupId: groupId))
        } label: {
          Label(L10n.tr("telegram.settingsTitle"), systemImage: "paperplane")
        }
      }

      if canWrite {
        Button {
          isCloneSheetPresented = true
        } label: {
          Label(L10n.tr("clone.title"), systemImage: "doc.on.doc")
        }
      }

      if isOwner {
        if isArchived {
          Button {
            Task { await unarchiveCurrentGroup() }
          } label: {
            Label(L10n.tr("groups.unarchiveAction"), systemImage: "arrow.uturn.backward")
          }
        } else {
          Button(role: .destructive) {
            isArchiveConfirmPresented = true
          } label: {
            Label(L10n.tr("groups.archiveAction"), systemImage: "archivebox")
          }
        }

        Button {
          onNavigate(.groupSettings(groupId: groupId))
        } label: {
          Label(L10n.tr("settings.title"), systemImage: "gearshape")
        }
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(Tokens.ink)
        .frame(width: 44, height: 44)
        .background(Tokens.surface, in: Circle())
    }
  }

  private var segmentSwitcher: some View {
    HStack(spacing: 4) {
      ForEach(GroupSegment.allCases, id: \.self) { segment in
        Button {
          Haptics.light()
          withAnimation(.easeInOut(duration: 0.18)) {
            selectedSegment = segment
          }
        } label: {
          Text(segment.title)
            .font(Typography.captionBold)
            .foregroundStyle(selectedSegment == segment ? Tokens.surface : Tokens.muted)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
              selectedSegment == segment ? Tokens.ink : Color.clear,
              in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  @ViewBuilder
  private var contentView: some View {
    switch selectedSegment {
    case .expenses:
      GroupFeedView(
        model: feedModel,
        showHeader: false,
        isEmailVerified: currentUser?.emailVerified ?? true,
        unreadNotificationCount: sessionModel.unreadNotificationCount,
        onBack: onBack,
        onOpenMembers: { id in onNavigate(.groupMembers(groupId: id)) },
        onOpenBalances: { _ in
          withAnimation(.easeInOut(duration: 0.18)) {
            selectedSegment = .payments
          }
        },
        onOpenStats: { _ in
          withAnimation(.easeInOut(duration: 0.18)) {
            selectedSegment = .fundAndStats
          }
        },
        onOpenQuickEntry: { id, sentence in
          onNavigate(.quickEntry(groupId: id, initialSentence: sentence))
        },
        onOpenNewTransactionForm: { id in
          onNavigate(.newTransactionForm(groupId: id, initialReading: nil))
        },
        onOpenEditTransaction: { id, txId in
          onNavigate(.editTransaction(groupId: id, transactionId: txId))
        },
        onOpenTransactionDetail: { id, txId in
          onNavigate(.transactionDetail(groupId: id, transactionId: txId))
        },
        onOpenReceiptCapture: sessionModel.latestFeatures?.receiptReading == true
          ? { _ in isReceiptCaptureOpen = true }
          : nil,
        onOpenNotifications: { onNavigate(.notifications) },
        onRemovedFromGroup: {
          onPopToRoot(L10n.tr("common.removed"))
        }
      )

    case .payments:
      BalancesView(
        model: balancesModel,
        showHeader: false,
        currentUserId: currentUser?.id,
        isEmailVerified: currentUser?.emailVerified ?? true,
        onBack: onBack,
        onBackToGroups: { onPopToRoot(nil) },
        onOpenPay: isArchived
          ? nil
          : { transfer, fromMember, toMember in
            paymentSheet = PaymentSheet(
              transfer: transfer,
              fromMember: fromMember,
              toMember: toMember
            )
          },
        onOpenSettle: isArchived
          ? { _ in }
          : { transfer in
            onNavigate(
              .settle(
                groupId: groupId,
                fromMemberId: transfer.fromMemberId,
                toMemberId: transfer.toMemberId,
                initialAmount: transfer.amount
              )
            )
          },
        onOpenFund: { _ in
          withAnimation(.easeInOut(duration: 0.18)) {
            selectedSegment = .fundAndStats
            fundSubTab = .fund
          }
        },
        onCreateFund: isArchived
          ? nil
          : {
            onNavigate(.groupMembers(groupId: groupId))
          },
        loadAttachment: { attachmentId in
          try await dependencies.attachments.content(groupId: groupId, attachmentId: attachmentId)
        },
        onOpenShareCard: {
          isShareCardSheetOpen = true
        },
        onOpenGuestLink: {
          isGuestLinkSheetOpen = true
        },
        onOpenTransaction: { txId in
          onNavigate(.transactionDetail(groupId: groupId, transactionId: txId))
        },
        onViewCycleExpenses: { cycleId in
          withAnimation(.easeInOut(duration: 0.18)) {
            selectedSegment = .expenses
          }
          Task { await feedModel.selectCycle(.cycle(cycleId)) }
        }
      )

    case .fundAndStats:
      VStack(spacing: 8) {
        HStack(spacing: 4) {
          ForEach(FundSubTab.allCases, id: \.self) { subTab in
            Button {
              Haptics.light()
              withAnimation(.easeInOut(duration: 0.15)) {
                fundSubTab = subTab
              }
            } label: {
              Text(subTab.title)
                .font(Typography.captionBold)
                .foregroundStyle(fundSubTab == subTab ? Tokens.surface : Tokens.muted)
                .padding(.horizontal, 14)
                .frame(minHeight: 32)
                .background(
                  fundSubTab == subTab ? Tokens.ink : Color.clear,
                  in: Capsule()
                )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(3)
        .background(Tokens.sunken, in: Capsule())
        .padding(.horizontal, 20)

        switch fundSubTab {
        case .stats:
          StatsView(
            model: statsModel,
            recurringExpensesModel: recurringExpensesModel,
            isEmailVerified: currentUser?.emailVerified ?? true,
            showHeader: false,
            onBack: onBack,
            onOpenFilteredFeed: { filter in
              onNavigate(.groupFeed(groupId: groupId, initialFilter: filter))
            },
            onCompleteDueRecurring: { item in
              onNavigate(.newTransactionForm(groupId: groupId, initialRecurringExpense: item))
            }
          )
        case .fund:
          FundView(
            model: fundModel,
            showHeader: false,
            isEmailVerified: currentUser?.emailVerified ?? true,
            onBack: onBack,
            onContribute: isArchived
              ? { _ in }
              : { fundMemberId in
                onNavigate(
                  .newTransactionForm(
                    groupId: groupId,
                    initialReading: nil,
                    initialTransferFrom: nil,
                    initialTransferTo: fundMemberId
                  )
                )
              },
            onWithdraw: isArchived
              ? { _ in }
              : { fundMemberId in
                onNavigate(
                  .newTransactionForm(
                    groupId: groupId,
                    initialReading: nil,
                    initialTransferFrom: fundMemberId,
                    initialTransferTo: nil
                  )
                )
              },
            onDeleted: {
              fundSubTab = .stats
            }
          )
        }
      }
    }
  }

  private func archiveCurrentGroup() async {
    isArchiving = true
    defer { isArchiving = false }
    do throws(AppError) {
      _ = try await dependencies.groups.archive(groupId: groupId)
      Haptics.success()
      await feedModel.load()
      await balancesModel.load()
      await statsModel.load()
      await fundModel.load()
    } catch {
      Haptics.warning()
    }
  }

  private func unarchiveCurrentGroup() async {
    isArchiving = true
    defer { isArchiving = false }
    do throws(AppError) {
      _ = try await dependencies.groups.unarchive(groupId: groupId)
      Haptics.success()
      await feedModel.load()
      await balancesModel.load()
      await statsModel.load()
      await fundModel.load()
    } catch {
      Haptics.warning()
    }
  }
}
