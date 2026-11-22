import AccountFeature
import AuthFeature
import DesignSystem
public import Domain
import GroupsFeature
import LedgerFeature
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
  private let onNavigate: (Route) -> Void
  private let onReplaceTop: (Route) -> Void
  private let onPop: () -> Void
  private let onPopToRoot: (String?) -> Void
  private let onExpenseSaved: () -> Void
  @Binding private var deletedTransactionId: LedgerTransaction.ID?

  private struct PaymentSheet: Identifiable {
    var id: SuggestedTransfer.ID { transfer.id }
    let transfer: SuggestedTransfer
    let fromMember: Member
    let toMember: Member
  }

  @State private var paymentSheet: PaymentSheet?
  @State private var editingPaymentMember: Member?
  @State private var registerModel: RegisterModel?
  @State private var forgotPasswordModel: ForgotPasswordModel?
  @State private var accountModel: AccountModel?
  @State private var createGroupModel: CreateGroupModel?
  @State private var joinModel: JoinModel?
  @State private var membersModel: MembersModel?
  @State private var settingsModel: GroupSettingsModel?
  @State private var feedModel: GroupFeedModel?
  @State private var balancesModel: BalancesModel?
  @State private var statsModel: StatsModel?
  @State private var activityModel: ActivityModel?
  @State private var quickEntryModel: QuickEntryModel?
  @State private var expenseFormModel: ExpenseFormModel?
  @State private var settleModel: SettleModel?

  public init(
    route: Route,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    currentUser: User?,
    onNavigate: @escaping (Route) -> Void,
    onReplaceTop: @escaping (Route) -> Void,
    onPop: @escaping () -> Void,
    onPopToRoot: @escaping (String?) -> Void,
    onExpenseSaved: @escaping () -> Void = {},
    deletedTransactionId: Binding<LedgerTransaction.ID?>
  ) {
    self._deletedTransactionId = deletedTransactionId
    self.route = route
    self.dependencies = dependencies
    self.sessionModel = sessionModel
    self.currentUser = currentUser
    self.onNavigate = onNavigate
    self.onReplaceTop = onReplaceTop
    self.onPop = onPop
    self.onPopToRoot = onPopToRoot
    self.onExpenseSaved = onExpenseSaved

    let args = ProcessInfo.processInfo.arguments
    switch route {
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
          accountName: currentUser?.name ?? "Lan",
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
          invitesRepository: dependencies.invites
        )
      )
    case .groupSettings(let groupId):
      self._settingsModel = State(
        initialValue: GroupSettingsModel(
          groupId: groupId,
          groupsRepository: dependencies.groups,
          invitesRepository: dependencies.invites,
          membersRepository: dependencies.members,
          categoriesRepository: dependencies.categories
        )
      )
    case .groupFeed(let groupId, let initialFilter):
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
          transactionsRepository: dependencies.transactions,
          eventsRepository: dependencies.groupEvents,
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
          statisticsRepository: dependencies.statistics,
          onUnauthorized: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
          }
        )
      )
    case .groupBalances(let groupId):
      self._balancesModel = State(
        initialValue: BalancesModel(
          groupId: groupId,
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          balancesRepository: dependencies.balances,
          transactionsRepository: dependencies.transactions,
          settlementRequests: dependencies.settlementRequests,
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
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          quickEntryRepository: dependencies.quickEntry,
          transactionsRepository: dependencies.transactions,
          onSaved: {
            onPop()
            onExpenseSaved()
          },
          onOpenManualForm: { reading in
            onReplaceTop(.newTransactionForm(groupId: groupId, initialReading: reading))
          }
        )
      )
    case .newTransactionForm(let groupId, let initialReading):
      self._expenseFormModel = State(
        initialValue: ExpenseFormModel(
          groupId: groupId,
          editingTransactionId: nil,
          initialReading: initialReading,
          initialSplitEditorOpen: args.contains("--open-split-editor"),
          groupsRepository: dependencies.groups,
          membersRepository: dependencies.members,
          transactionsRepository: dependencies.transactions,
          categoriesRepository: dependencies.categories,
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
          transactionsRepository: dependencies.transactions,
          categoriesRepository: dependencies.categories,
          onSaved: onPop,
          onDeleted: { id in
            deletedTransactionId.wrappedValue = id
            onPop()
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
          onSaved: onPop
        )
      )
    default:
      break
    }
  }

  public var body: some View {
    content
      .onChange(of: deletedTransactionId) { _, id in
        guard let id, let feedModel else { return }
        feedModel.lastDeletedTransactionId = id
        deletedTransactionId = nil
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
          creatorName: currentUser?.name ?? "Minh",
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
    case .groupMembers(let groupId):
      if let membersModel {
        MembersView(
          model: membersModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onOpenActivity: { id in onNavigate(.groupActivity(groupId: id)) },
          onOpenSettings: { id in onNavigate(.groupSettings(groupId: id)) },
          onEditPaymentDetails: { member in editingPaymentMember = member },
          onLeftGroup: { onPopToRoot(nil) }
        )
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
    case .groupSettings:
      if let settingsModel {
        GroupSettingsView(
          model: settingsModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onBackToGroups: { onPopToRoot(nil) },
          onDeletedGroup: { onPopToRoot(L10n.tr("groups.deleted")) }
        )
      }
    case .groupFeed:
      if let feedModel {
        GroupFeedView(
          model: feedModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onOpenMembers: { id in onNavigate(.groupMembers(groupId: id)) },
          onOpenBalances: { id in onNavigate(.groupBalances(groupId: id)) },
          onOpenStats: { id in onNavigate(.groupStats(groupId: id)) },
          onOpenQuickEntry: { id, sentence in
            onNavigate(.quickEntry(groupId: id, initialSentence: sentence))
          },
          onOpenNewTransactionForm: { id in
            onNavigate(.newTransactionForm(groupId: id, initialReading: nil))
          },
          onOpenEditTransaction: { id, txId in
            onNavigate(.editTransaction(groupId: id, transactionId: txId))
          },
          onRemovedFromGroup: {
            onPopToRoot(L10n.tr("common.removed"))
          }
        )
      }
    case .groupStats(let groupId):
      if let statsModel {
        StatsView(
          model: statsModel,
          onBack: onPop,
          onOpenFilteredFeed: { filter in
            onNavigate(.groupFeed(groupId: groupId, initialFilter: filter))
          }
        )
      }
    case .groupBalances(let groupId):
      if let balancesModel {
        BalancesView(
          model: balancesModel,
          currentUserId: currentUser?.id,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onBackToGroups: { onPopToRoot(nil) },
          onOpenPay: { transfer, fromMember, toMember in
            paymentSheet = PaymentSheet(
              transfer: transfer,
              fromMember: fromMember,
              toMember: toMember
            )
          },
          onOpenSettle: { transfer in
            onNavigate(
              .settle(
                groupId: groupId,
                fromMemberId: transfer.fromMemberId,
                toMemberId: transfer.toMemberId,
                initialAmount: transfer.amount
              )
            )
          }
        )
        .sheet(
          item: $paymentSheet,
          onDismiss: {
            Task { await balancesModel.load() }
          },
          content: { selection in
            let group = balancesModel.state.value?.group
            let isVerified = currentUser?.emailVerified == true
            let isOffline = balancesModel.refreshError == .offline
            let role = group?.role ?? .viewer
            let myMemberId = group?.myMemberId
            let canEdit = isVerified && role.canWrite
            let payModel = PayModel(
              transfer: selection.transfer,
              fromMember: selection.fromMember,
              toMember: selection.toMember,
              groupId: groupId,
              myMemberId: myMemberId,
              role: role,
              isEmailVerified: isVerified,
              repository: dependencies.settlementRequests,
              onReload: { await balancesModel.load() },
              onUnauthorized: {
                paymentSheet = nil
                onPopToRoot(nil)
                Task { await sessionModel.signOut() }
              }
            )
            PayView(
              model: payModel,
              isOffline: isOffline,
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
                    ))
                } : nil,
              onFinished: { _ in
                paymentSheet = nil
              }
            )
          }
        )
      }
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
    case .settle:
      if let settleModel {
        SettleView(
          model: settleModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onCancel: onPop,
          onBackToGroups: { onPopToRoot(nil) }
        )
      }
    case .debugGallery:
      DebugGalleryView()
    }
  }
}
