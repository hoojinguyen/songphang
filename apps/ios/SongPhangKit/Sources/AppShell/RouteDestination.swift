import AccountFeature
import AuthFeature
import DesignSystem
public import Domain
import GroupsFeature
import LedgerFeature
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

  @State private var registerModel: RegisterModel?
  @State private var forgotPasswordModel: ForgotPasswordModel?
  @State private var accountModel: AccountModel?
  @State private var createGroupModel: CreateGroupModel?
  @State private var joinModel: JoinModel?
  @State private var membersModel: MembersModel?
  @State private var settingsModel: GroupSettingsModel?
  @State private var feedModel: GroupFeedModel?
  @State private var balancesModel: BalancesModel?
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
          membersRepository: dependencies.members
        )
      )
    case .groupFeed(let groupId):
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
          transactionsRepository: dependencies.transactions,
          eventsRepository: dependencies.groupEvents,
          initialHasNewItemsPill: args.contains("--new-items-pill"),
          initialDeletedTransactionId: deletedId
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
    case .groupMembers:
      if let membersModel {
        MembersView(
          model: membersModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onOpenActivity: { id in onNavigate(.groupActivity(groupId: id)) },
          onOpenSettings: { id in onNavigate(.groupSettings(groupId: id)) },
          onLeftGroup: { onPopToRoot(nil) }
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
    case .groupBalances(let groupId):
      if let balancesModel {
        BalancesView(
          model: balancesModel,
          isEmailVerified: currentUser?.emailVerified ?? true,
          onBack: onPop,
          onBackToGroups: { onPopToRoot(nil) },
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
