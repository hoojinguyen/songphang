import AccountFeature
import AuthFeature
import DesignSystem
public import Domain
import GroupsFeature
public import SwiftUI

public struct RouteDestination: View {
  private let route: Route
  private let dependencies: AppDependencies
  private let sessionModel: SessionModel
  private let currentUser: User?
  private let onNavigate: (Route) -> Void
  private let onReplaceTop: (Route) -> Void
  private let onPop: () -> Void
  private let onPopToRoot: (String?) -> Void

  @State private var registerModel: RegisterModel?
  @State private var forgotPasswordModel: ForgotPasswordModel?
  @State private var accountModel: AccountModel?
  @State private var createGroupModel: CreateGroupModel?
  @State private var joinModel: JoinModel?
  @State private var membersModel: MembersModel?
  @State private var settingsModel: GroupSettingsModel?

  public init(
    route: Route,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    currentUser: User?,
    onNavigate: @escaping (Route) -> Void,
    onReplaceTop: @escaping (Route) -> Void,
    onPop: @escaping () -> Void,
    onPopToRoot: @escaping (String?) -> Void
  ) {
    self.route = route
    self.dependencies = dependencies
    self.sessionModel = sessionModel
    self.currentUser = currentUser
    self.onNavigate = onNavigate
    self.onReplaceTop = onReplaceTop
    self.onPop = onPop
    self.onPopToRoot = onPopToRoot

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
          initialUser: hasSnap ? currentUser : nil,
          onSignedOut: {
            onPopToRoot(nil)
            Task { await sessionModel.signOut() }
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
    default:
      break
    }
  }

  public var body: some View {
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
    case .debugGallery:
      DebugGalleryView()
    default:
      SPCard {
        VStack(alignment: .leading, spacing: 12) {
          Text(L10n.tr("common.appName"))
            .font(Typography.sectionTitle)
          SPButton(L10n.tr("common.back"), variant: .surface, action: onPop)
        }
      }
      .padding(20)
    }
  }
}
