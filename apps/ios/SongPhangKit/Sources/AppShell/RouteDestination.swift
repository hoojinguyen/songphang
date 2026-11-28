import AccountFeature
import AuthFeature
import DesignSystem
public import Domain
import GroupsFeature
import LedgerFeature
import NotificationsFeature
import OverviewFeature
import PaymentsFeature
import StatisticsFeature
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct RouteDestination: View {
  private let route: Route
  private let dependencies: AppDependencies
  private let sessionModel: SessionModel
  private let currentUser: User?
  private let groupSummaryLookup: (ExpenseGroup.ID) -> GroupHeaderHint?
  private let onNavigate: (Route) -> Void
  private let onReplaceTop: (Route) -> Void
  private let onReplaceGroup: (ExpenseGroup.ID, Route) -> Void
  private let onPop: () -> Void
  private let onPopToRoot: (String?) -> Void
  private let onExpenseSaved: () -> Void
  private let recurringRefreshTick: Int
  @Binding private var deletedTransactionId: LedgerTransaction.ID?

  private struct PaymentSheet: Identifiable {
    var id: SuggestedTransfer.ID { transfer.id }
    let transfer: SuggestedTransfer
    let fromMember: Member
    let toMember: Member
  }

  @State private var paymentSheet: PaymentSheet?
  @State private var editingPaymentMember: Member?
  @State private var isCreatingFund = false
  @State private var isReceiptCaptureOpen = false
  @State private var isGuestLinkSheetOpen = false
  @State private var registerModel: RegisterModel?
  @State private var forgotPasswordModel: ForgotPasswordModel?
  @State private var accountModel: AccountModel?
  @State private var createGroupModel: CreateGroupModel?
  @State private var joinModel: JoinModel?
  @State private var membersModel: MembersModel?
  @State private var fundModel: FundModel?
  @State private var settingsModel: GroupSettingsModel?
  @State private var feedModel: GroupFeedModel?
  @State private var balancesModel: BalancesModel?
  @State private var statsModel: StatsModel?
  @State private var activityModel: ActivityModel?
  @State private var quickEntryModel: QuickEntryModel?
  @State private var expenseFormModel: ExpenseFormModel?
  @State private var receiptReviewModel: ReceiptReviewModel?
  @State private var settleModel: SettleModel?
  @State private var notificationsModel: NotificationsModel?
  @State private var transactionDetailModel: TransactionDetailModel?
  @State private var personalLedgerModel: PersonalLedgerModel?

  public init(
    route: Route,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    currentUser: User?,
    groupSummaryLookup: @escaping (ExpenseGroup.ID) -> GroupHeaderHint? = { _ in nil },
    onNavigate: @escaping (Route) -> Void,
    onReplaceTop: @escaping (Route) -> Void,
    onReplaceGroup: @escaping (ExpenseGroup.ID, Route) -> Void = { _, _ in },
    onPop: @escaping () -> Void,
    onPopToRoot: @escaping (String?) -> Void,
    onExpenseSaved: @escaping () -> Void = {},
    recurringRefreshTick: Int = 0,
    deletedTransactionId: Binding<LedgerTransaction.ID?>
  ) {
    self._deletedTransactionId = deletedTransactionId
    self.recurringRefreshTick = recurringRefreshTick
    self.route = route
    self.dependencies = dependencies
    self.sessionModel = sessionModel
    self.currentUser = currentUser
    self.groupSummaryLookup = groupSummaryLookup
    self.onNavigate = onNavigate
    self.onReplaceTop = onReplaceTop
    self.onReplaceGroup = onReplaceGroup
    self.onPop = onPop
    self.onPopToRoot = onPopToRoot
    self.onExpenseSaved = onExpenseSaved

    let args = ProcessInfo.processInfo.arguments
    switch route {
    case .guestShare:
      break
    case .register:
      self._registerModel = State(
        initialValue: RegisterModel(
          repository: dependencies.auth,
          initialSubmitted: args.contains("--submitted")
        )
      )
    case .forgotPassword:
      self._forgotPasswordModel = State(
        initialValue: ForgotPasswordModel(
          repository: dependencies.auth,
          initialSubmitted: args.contains("--submitted")
        )
      )
    case .account:
      let hasSnap = !args.contains("--no-snapshot")
      self._accountModel = State(
        initialValue: AccountModel(
          repository: dependencies.auth,
          devicesRepository: dependencies.devices,
          notificationsRepository: dependencies.notifications,
          chatLinksRepository: dependencies.chatLinks,
          initialUser: hasSnap ? currentUser : nil,
          onSignedOut: {
            sessionModel.markSignedOut()
          },
          onUserUpdated: { updated in
            sessionModel.didSignIn(updated)
          }
        )
      )
    case .createGroup:
      self._createGroupModel = State(
        initialValue: CreateGroupModel(
          repository: dependencies.groups,
          onCreated: { groupId in
            onReplaceTop(.groupFeed(groupId: groupId))
          }
        )
      )
    case .joinGroup(let token):
      self._joinModel = State(
        initialValue: JoinModel(
          token: token,
          accountName: currentUser?.name ?? L10n.tr("activity.someone"),
          repository: dependencies.invites,
          onJoined: { groupId in
            onReplaceTop(.groupFeed(groupId: groupId))
          }
        )
      )
    case .groupMembers(let groupId):
      self._membersModel = State(
        initialValue: MembersModel(
          groupId: groupId,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          balancesRepository: dependencies.balances,
          invitesRepository: dependencies.invites,
          householdsRepository: dependencies.households
        )
      )
    case .groupFund(let groupId):
      self._fundModel = State(
        initialValue: FundModel(
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
      )
    case .groupSettings(let groupId, _):
      self._settingsModel = State(
        initialValue: GroupSettingsModel(
          groupId: groupId,
          groupsRepository: dependencies.groups,
          invitesRepository: dependencies.invites,
          membersRepository: dependencies.members,
          categoriesRepository: dependencies.categories,
          budgetRepository: dependencies.budget,
          chatLinksRepository: dependencies.chatLinks,
          telegramFeatureEnabled: sessionModel.latestFeatures?.telegram == true
        )
      )
    case .groupFeed(let groupId, let initialFilter, _):
      #if DEBUG
        let deletedId =
          args.contains("--delete-t4") ? TripScenario.t4Transaction.id : nil
      #else
        let deletedId: LedgerTransaction.ID? = nil
      #endif
      self._feedModel = State(
        initialValue: GroupFeedModel(
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
          initialFilter: initialFilter,
          initialHasNewItemsPill: args.contains("--new-items-pill"),
          initialDeletedTransactionId: deletedId
        )
      )
    case .groupStats(let groupId):
      self._statsModel = State(
        initialValue: StatsModel(
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
      )
    case .groupBalances(let groupId, _):
      self._balancesModel = State(
        initialValue: BalancesModel(
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
      )
    case .groupActivity(let groupId):
      self._activityModel = State(
        initialValue: ActivityModel(
          groupId: groupId,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          activityRepository: dependencies.activity,
          transactionsRepository: dependencies.transactions,
          onUnauthorized: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
          }
        )
      )
    case .quickEntry(let groupId, let initialSentence):
      self._quickEntryModel = State(
        initialValue: QuickEntryModel(
          groupId: groupId,
          initialSentence: initialSentence,
          canUseAI: sessionModel.latestFeatures?.sentenceAi == true,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          categoriesRepository: dependencies.categories,
          quickEntryRepository: dependencies.quickEntry,
          transactionsRepository: dependencies.transactions,
          onSaved: {
            onPop()
            onExpenseSaved()
          },
          onDraftSaved: onExpenseSaved,
          onSkippedToFeed: onPop,
          onOpenManualForm: { reading in
            onReplaceTop(.newTransactionForm(groupId: groupId, initialReading: reading))
          }
        )
      )
    case .newTransactionForm(
      let groupId,
      let initialReading,
      let initialTransferFrom,
      let initialTransferTo,
      let initialAttachmentId,
      let initialAttachmentIds,
      let initialPendingImageDatas,
      let initialRecurringExpense,
      let initialRecurringDueAction
    ):
      self._expenseFormModel = State(
        initialValue: ExpenseFormModel(
          groupId: groupId,
          editingTransactionId: nil,
          initialReading: initialReading,
          initialTransferFrom: initialTransferFrom,
          initialTransferTo: initialTransferTo,
          initialAttachmentId: initialAttachmentId,
          initialAttachmentIds: initialAttachmentIds,
          initialPendingImageDatas: initialPendingImageDatas,
          initialRecurringExpense: initialRecurringExpense,
          initialRecurringDueAction: initialRecurringDueAction,
          initialSplitEditorOpen: args.contains("--open-split-editor"),
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          balancesRepository: dependencies.balances,
          transactionsRepository: dependencies.transactions,
          categoriesRepository: dependencies.categories,
          attachmentsRepository: dependencies.attachments,
          recurringExpensesRepository: dependencies.recurringExpenses,
          onSaved: {
            onPop()
            onExpenseSaved()
          }
        )
      )
    case .editTransaction(let groupId, let transactionId):
      self._expenseFormModel = State(
        initialValue: ExpenseFormModel(
          groupId: groupId,
          editingTransactionId: transactionId,
          initialReading: nil,
          initialSplitEditorOpen: args.contains("--open-split-editor"),
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          balancesRepository: dependencies.balances,
          transactionsRepository: dependencies.transactions,
          categoriesRepository: dependencies.categories,
          attachmentsRepository: dependencies.attachments,
          onSaved: {
            onPop()
            onExpenseSaved()
          },
          onDeleted: { id in
            deletedTransactionId.wrappedValue = id
            onPop()
          }
        )
      )
    case .transactionDetail(let groupId, let transactionId):
      self._transactionDetailModel = State(
        initialValue: TransactionDetailModel(
          groupId: groupId,
          transactionId: transactionId,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          categoriesRepository: dependencies.categories,
          transactionsRepository: dependencies.transactions,
          attachmentsRepository: dependencies.attachments,
          eventsRepository: dependencies.groupEvents,
          currentUserProvider: { sessionModel.currentUser },
          onUnauthorized: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
          }
        )
      )
    case .receiptReview(let groupId, let scanId):
      self._receiptReviewModel = State(
        initialValue: ReceiptReviewModel(
          groupId: groupId,
          scanId: scanId,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          attachmentsRepository: dependencies.attachments,
          receiptScansRepository: dependencies.receiptScans,
          transactionsRepository: dependencies.transactions,
          onSaved: {
            onPop()
            onExpenseSaved()
          },
          onManualFallback: { attachmentId in
            onReplaceTop(
              .newTransactionForm(
                groupId: groupId,
                initialAttachmentId: attachmentId
              )
            )
          },
          onUnauthorized: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
          }
        )
      )
    case .settle(let groupId, let fromMemberId, let toMemberId, let initialAmount):
      self._settleModel = State(
        initialValue: SettleModel(
          groupId: groupId,
          fromMemberId: fromMemberId,
          toMemberId: toMemberId,
          initialAmount: initialAmount,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          balancesRepository: dependencies.balances,
          transactionsRepository: dependencies.transactions,
          attachmentsRepository: dependencies.attachments,
          onSaved: {
            onPop()
            onExpenseSaved()
          }
        )
      )
    case .notifications:
      self._notificationsModel = State(
        initialValue: NotificationsModel(
          repository: dependencies.notifications,
          onUnauthorized: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
          }
        )
      )
    case .personalLedger:
      self._personalLedgerModel = State(
        initialValue: PersonalLedgerModel(
          repository: dependencies.overview,
          groupsRepository: dependencies.groups
        )
      )
    #if DEBUG
      case .debugGallery:
        break
    #endif
    }
  }

  public var body: some View {
    content
      .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
      .onChange(of: deletedTransactionId) { _, id in
        guard let id, let feedModel else { return }
        feedModel.markDeleted(id)
        deletedTransactionId = nil
      }
  }

  private var hidesTabBar: Bool {
    switch route {
    case .quickEntry, .newTransactionForm, .editTransaction, .settle, .receiptReview:
      return true
    case .register, .forgotPassword, .account, .createGroup, .joinGroup, .guestShare,
      .groupFeed, .groupBalances, .groupStats, .groupActivity, .groupMembers, .groupFund,
      .groupSettings, .transactionDetail, .notifications, .personalLedger:
      return false
    #if DEBUG
      case .debugGallery:
        return false
    #endif
    }
  }

  @ViewBuilder
  private var content: some View {
    switch route {
    case .register:
      if let registerModel {
        RegisterView(model: registerModel, onBackToSignIn: onPop)
      }
    case .forgotPassword:
      if let forgotPasswordModel {
        ForgotPasswordView(model: forgotPasswordModel, onBackToSignIn: onPop)
      }
    case .account:
      if let accountModel {
        AccountView(model: accountModel, onBack: onPop)
      }
    case .createGroup:
      if let createGroupModel {
        CreateGroupView(
          model: createGroupModel,
          creatorName: currentUser?.name ?? L10n.tr("activity.someone"),
          onBack: onPop
        )
      }
    case .joinGroup:
      if let joinModel {
        JoinView(
          model: joinModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBackToGroups: { onPopToRoot(nil) }
        )
      }
    case .guestShare(let token):
      GuestGroupView(
        model: GuestGroupModel(
          token: token,
          guestLinksRepository: dependencies.guestLinks
        ),
        onClose: onPop
      )
    case .groupMembers(let groupId):
      if let membersModel {
        let people = (membersModel.state.value?.members ?? []).filter {
          $0.kind == .person && $0.active
        }
        MembersView(
          model: membersModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onOpenActivity: { id in onNavigate(.groupActivity(groupId: id)) },
          onOpenSettings: { id in onNavigate(.groupSettings(groupId: id)) },
          onEditPaymentDetails: { member in editingPaymentMember = member },
          onOpenFund: { id in onNavigate(.groupFund(groupId: id)) },
          onCreateFund: { isCreatingFund = true },
          onOpenGuestLink: { _ in isGuestLinkSheetOpen = true },
          onLeftGroup: { onPopToRoot(nil) }
        )
        .sheet(isPresented: $isGuestLinkSheetOpen) {
          GuestLinkSheetView(
            model: GuestLinkSheetModel(
              groupId: groupId,
              guestLinksRepository: dependencies.guestLinks,
              onUnauthorized: {
                isGuestLinkSheetOpen = false
                onPopToRoot(nil)
                Task { await sessionModel.signOut() }
              }
            ),
            isOffline: membersModel.refreshError == .offline,
            isArchived: membersModel.state.value?.group.isArchived ?? false,
            onDismiss: { isGuestLinkSheetOpen = false }
          )
        }
        .sheet(isPresented: $isCreatingFund) {
          createFundSheet(
            groupId: groupId,
            people: people,
            isOffline: membersModel.refreshError == .offline,
            reload: { await membersModel.load() }
          )
        }
        .sheet(
          item: $editingPaymentMember,
          onDismiss: {
            Task { await membersModel.load() }
          },
          content: { member in
            PaymentDetailsView(
              model: PaymentDetailsModel(
                groupId: groupId,
                member: member,
                repository: dependencies.members,
                onSaved: {
                  Task { await membersModel.load() }
                },
                onUnauthorized: {
                  editingPaymentMember = nil
                  onPopToRoot(nil)
                  Task { await sessionModel.signOut() }
                }
              ),
              isOffline: membersModel.refreshError == .offline,
              onDismiss: { editingPaymentMember = nil }
            )
          }
        )
      }
    case .groupFund(let groupId):
      GroupContainerView(
        groupId: groupId,
        initialSegment: .fundAndStats,
        initialFilter: nil,
        initialFundSubTab: .fund,
        initialGroupHint: groupSummaryLookup(groupId),
        dependencies: dependencies,
        sessionModel: sessionModel,
        currentUser: currentUser,
        deletedTransactionId: $deletedTransactionId,
        onBack: onPop,
        onNavigate: onNavigate,
        onReplaceTop: onReplaceTop,
        onPopToRoot: onPopToRoot,
        onExpenseSaved: onExpenseSaved,
        recurringRefreshTick: recurringRefreshTick
      )
    case .groupSettings(let groupId, let initialSection):
      if let settingsModel {
        let mappedSection: GroupSettingsView.SectionAnchor? =
          initialSection == .categories ? .categories : nil
        GroupSettingsView(
          model: settingsModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          initialSection: mappedSection,
          onBack: onPop,
          onBackToGroups: { onPopToRoot(nil) },
          onDeletedGroup: { onPopToRoot(L10n.tr("groups.deleted")) },
          onClonedGroup: { newGroup in
            onReplaceGroup(
              groupId,
              .groupFeed(
                groupId: newGroup.id,
                initialToast: L10n.t("ios.groups.createdToast", ["name": newGroup.name])
              )
            )
          }
        )
      }
    case .groupFeed(let groupId, let initialFilter, let initialToast):
      GroupContainerView(
        groupId: groupId,
        initialSegment: .expenses,
        initialFilter: initialFilter,
        initialToast: initialToast,
        initialGroupHint: groupSummaryLookup(groupId),
        dependencies: dependencies,
        sessionModel: sessionModel,
        currentUser: currentUser,
        deletedTransactionId: $deletedTransactionId,
        onBack: onPop,
        onNavigate: onNavigate,
        onReplaceTop: onReplaceTop,
        onPopToRoot: onPopToRoot,
        onExpenseSaved: onExpenseSaved,
        recurringRefreshTick: recurringRefreshTick
      )
    case .groupStats(let groupId):
      GroupContainerView(
        groupId: groupId,
        initialSegment: .fundAndStats,
        initialFilter: nil,
        initialGroupHint: groupSummaryLookup(groupId),
        dependencies: dependencies,
        sessionModel: sessionModel,
        currentUser: currentUser,
        deletedTransactionId: $deletedTransactionId,
        onBack: onPop,
        onNavigate: onNavigate,
        onReplaceTop: onReplaceTop,
        onPopToRoot: onPopToRoot,
        onExpenseSaved: onExpenseSaved,
        recurringRefreshTick: recurringRefreshTick
      )
    case .groupBalances(let groupId, let initialTransferProofAttachmentId):
      GroupContainerView(
        groupId: groupId,
        initialSegment: .payments,
        initialFilter: nil,
        initialTransferProofAttachmentId: initialTransferProofAttachmentId,
        initialGroupHint: groupSummaryLookup(groupId),
        dependencies: dependencies,
        sessionModel: sessionModel,
        currentUser: currentUser,
        deletedTransactionId: $deletedTransactionId,
        onBack: onPop,
        onNavigate: onNavigate,
        onReplaceTop: onReplaceTop,
        onPopToRoot: onPopToRoot,
        onExpenseSaved: onExpenseSaved,
        recurringRefreshTick: recurringRefreshTick
      )
    case .groupActivity:
      if let activityModel {
        ActivityView(
          model: activityModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop
        )
      }
    case .quickEntry:
      if let quickEntryModel {
        QuickEntryView(
          model: quickEntryModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onCancel: onPop
        )
      }
    case .newTransactionForm, .editTransaction:
      if let expenseFormModel {
        ExpenseFormView(
          model: expenseFormModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onCancel: onPop
        )
      }
    case .transactionDetail:
      if let transactionDetailModel {
        TransactionDetailView(
          model: transactionDetailModel,
          verifyEmailBanner: AnyView(
            VerifyEmailBannerView(model: VerifyEmailBannerModel(repository: dependencies.auth))
          ),
          onBack: onPop,
          onOpenEdit: { gid, tid in
            onNavigate(.editTransaction(groupId: gid, transactionId: tid))
          },
          onRemoved: {
            onPopToRoot(L10n.tr("common.removed"))
          }
        )
      }
    case .receiptReview:
      if let receiptReviewModel {
        ReceiptReviewView(
          model: receiptReviewModel,
          onBack: onPop
        )
      }
    case .settle:
      if let settleModel {
        SettleView(
          model: settleModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onCancel: onPop,
          onBackToGroups: { onPopToRoot(nil) }
        )
      }
    case .notifications:
      if let notificationsModel {
        NotificationsView(
          model: notificationsModel,
          onBack: {
            Task {
              await sessionModel.refreshUnreadNotificationCount(using: dependencies.notifications)
            }
          },
          onSelectTarget: { target in
            Task {
              await sessionModel.refreshUnreadNotificationCount(using: dependencies.notifications)
            }
            onNavigate(Self.notificationDestination(for: target))
          }
        )
      }
    case .personalLedger:
      if let personalLedgerModel {
        PersonalLedgerView(
          model: personalLedgerModel,
          onBack: onPop,
          onOpenTransaction: { groupId, txId in
            onNavigate(.transactionDetail(groupId: groupId, transactionId: txId))
          }
        )
      }
    #if DEBUG
      case .debugGallery:
        DebugGalleryView()
    #endif
    }
  }

  private func createFundSheet(
    groupId: ExpenseGroup.ID,
    people: [Member],
    isOffline: Bool,
    reload: @escaping () async -> Void
  ) -> some View {
    CreateFundSheetView(
      groupId: groupId,
      people: people,
      fundRepository: dependencies.fund,
      isOffline: isOffline,
      onCreated: {
        isCreatingFund = false
        Task { await reload() }
      },
      onDismiss: { isCreatingFund = false },
      onUnauthorized: {
        isCreatingFund = false
        onPopToRoot(nil)
        Task { await sessionModel.signOut() }
      }
    )
  }

  public static func notificationDestination(for target: AppNotification.Target) -> Route {
    switch target {
    case .transaction(let groupId, let txId):
      return .transactionDetail(
        groupId: groupId,
        transactionId: LedgerTransaction.ID(txId)
      )
    case .balances(let groupId):
      return .groupBalances(groupId: groupId)
    case .stats(let groupId):
      return .groupStats(groupId: groupId)
    case .group(let groupId):
      return .groupFeed(groupId: groupId)
    }
  }
}
