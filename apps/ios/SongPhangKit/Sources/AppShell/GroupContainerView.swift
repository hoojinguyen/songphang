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
  private let recurringRefreshTick: Int
  @Binding private var deletedTransactionId: LedgerTransaction.ID?

  @State private var selectedSegment: GroupSegment
  @State private var fundSubTab: FundSubTab = .stats
  @Namespace private var segmentNamespace
  @Namespace private var fundSubTabNamespace
  @State private var isCloneSheetPresented = false
  @State private var isArchiveConfirmPresented = false
  @State private var isReceiptCaptureOpen = false
  @State private var isGuestLinkSheetOpen = false
  @State private var isShareCardSheetOpen = false
  @State private var isArchiving = false
  @State private var archiveSuccessTick = 0
  @State private var archiveWarningTick = 0
  @State private var paymentSheet: PaymentSheet?
  @State private var pendingProofAttachmentId: Attachment.ID?
  @State private var completingRecurringId: RecurringExpense.ID?

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
    initialTransferProofAttachmentId: Attachment.ID? = nil,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    currentUser: User?,
    deletedTransactionId: Binding<LedgerTransaction.ID?>,
    onBack: @escaping () -> Void,
    onNavigate: @escaping (Route) -> Void,
    onReplaceTop: @escaping (Route) -> Void,
    onPopToRoot: @escaping (String?) -> Void,
    onExpenseSaved: @escaping () -> Void,
    recurringRefreshTick: Int = 0
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
    self.recurringRefreshTick = recurringRefreshTick
    self._selectedSegment = State(initialValue: initialSegment)
    self._pendingProofAttachmentId = State(initialValue: initialTransferProofAttachmentId)
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
      segmentSwitcher
        .padding(.horizontal, 20)
        .padding(.top, 8)

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
    .spFeedback(.success, trigger: archiveSuccessTick)
    .spFeedback(.warning, trigger: archiveWarningTick)
    .navigationTitle(currentGroup?.name ?? "")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        memberCapsuleButton
        overflowMenu
      }
    }
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
    .onChange(of: recurringRefreshTick) { _, _ in
      if let id = completingRecurringId {
        recurringExpensesModel.clearPendingDueDate(id: id)
        completingRecurringId = nil
      }
      Task { await recurringExpensesModel.load() }
    }
    #if DEBUG
      .task {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--open-share-card") {
          while balancesModel.state.value == nil {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }
          }
          isShareCardSheetOpen = true
        }
        if args.contains("--exercise-segment-switch") {
          try? await Task.sleep(for: .milliseconds(800))
          guard !Task.isCancelled else { return }
          selectedSegment = .payments
          try? await Task.sleep(for: .milliseconds(800))
          guard !Task.isCancelled else { return }
          selectedSegment = .fundAndStats
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
    .sheet(
      item: $paymentSheet,
      onDismiss: { pendingProofAttachmentId = nil },
      content: { selection in
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
          initialProofAttachment: pendingProofAttachmentId.map {
            Attachment(id: $0, contentType: "image/jpeg", byteSize: 1)
          },
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
              pendingProofAttachmentId = nil
              paymentSheet = nil
              onExpenseSaved()
            }
          )
        }
      }
    )
  }

  private var memberCapsuleButton: some View {
    Button {
      onNavigate(.groupMembers(groupId: groupId))
    } label: {
      HStack(spacing: 2) {
        ForEach(Array(currentMembers.prefix(3))) { member in
          MemberShapeView(member: member, size: 22)
        }
      }
    }
    .accessibilityLabel(L10n.tr("feed.membersLink"))
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
        .accessibilityLabel(L10n.tr("settings.title"))
    }
  }

  private var segmentSwitcher: some View {
    HStack(spacing: 4) {
      ForEach(GroupSegment.allCases, id: \.self) { segment in
        Button {
          selectedSegment = segment
        } label: {
          Text(segment.title)
            .font(Typography.captionBold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 4)
            .foregroundStyle(selectedSegment == segment ? Tokens.onInk : Tokens.muted)
            .frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: segment, in: segmentNamespace)
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Tokens.ink)
        .matchedGeometryEffect(
          id: selectedSegment,
          in: segmentNamespace,
          properties: .frame,
          isSource: false
        )
    }
    .spAnimation(Motion.quick, value: selectedSegment)
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
          selectedSegment = .payments
        },
        onOpenStats: { _ in
          selectedSegment = .fundAndStats
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
          selectedSegment = .fundAndStats
          fundSubTab = .fund
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
          selectedSegment = .expenses
          Task { await feedModel.selectCycle(.cycle(cycleId)) }
        }
      )

    case .fundAndStats:
      VStack(spacing: 8) {
        HStack(spacing: 4) {
          ForEach(FundSubTab.allCases, id: \.self) { subTab in
            Button {
              fundSubTab = subTab
            } label: {
              Text(subTab.title)
                .font(Typography.captionBold)
                .foregroundStyle(fundSubTab == subTab ? Tokens.surface : Tokens.muted)
                .padding(.horizontal, 14)
                .frame(minHeight: 32)
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: subTab, in: fundSubTabNamespace)
          }
        }
        .background {
          Capsule()
            .fill(Tokens.ink)
            .matchedGeometryEffect(
              id: fundSubTab,
              in: fundSubTabNamespace,
              properties: .frame,
              isSource: false
            )
        }
        .spAnimation(Motion.quick, value: fundSubTab)
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
              completingRecurringId = item.id
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
      archiveSuccessTick &+= 1
      await feedModel.load()
      await balancesModel.load()
      await statsModel.load()
      await fundModel.load()
    } catch {
      archiveWarningTick &+= 1
    }
  }

  private func unarchiveCurrentGroup() async {
    isArchiving = true
    defer { isArchiving = false }
    do throws(AppError) {
      _ = try await dependencies.groups.unarchive(groupId: groupId)
      archiveSuccessTick &+= 1
      await feedModel.load()
      await balancesModel.load()
      await statsModel.load()
      await fundModel.load()
    } catch {
      archiveWarningTick &+= 1
    }
  }
}
