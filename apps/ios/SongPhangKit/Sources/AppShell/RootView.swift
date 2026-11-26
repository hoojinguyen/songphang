import AccountFeature
import AuthFeature
import DesignSystem
import Domain
import GroupsFeature
import NotificationsFeature
import OverviewFeature
public import Repositories
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

#if DEBUG
  extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("SPDeviceDidShakeNotification")
  }

  extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
      super.motionEnded(motion, with: event)
      if motion == .motionShake {
        NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
      }
    }
  }
#endif

public struct RootView: View {
  public enum Tab: String, Hashable, Sendable {
    case overview
    case groups
    case notifications
    case account
  }

  private struct GuestSharePresentation: Identifiable {
    var id: String { model.token }
    let model: GuestGroupModel
  }

  private let dependencies: AppDependencies
  @Environment(\.scenePhase) private var scenePhase
  @State private var sessionModel: SessionModel
  @State private var groupListModel: GroupListModel
  @State private var overviewModel: OverviewModel
  @State private var notificationsModel: NotificationsModel
  @State private var accountModel: AccountModel
  @State private var signInModel: SignInModel
  @State private var pushCoordinator: PushCoordinator
  @State private var selectedTab: Tab = .overview
  @State private var path: [Route] = []
  @State private var overviewPath: [Route] = []
  @State private var groupsPath: [Route] = []
  @State private var notificationsPath: [Route] = []
  @State private var accountPath: [Route] = []
  @State private var pendingInviteState = PendingInviteState()
  @State private var pendingPushTap: PushTapPayload?
  @State private var activeGuestShare: GuestSharePresentation?
  @State private var statusNotice: String?
  @State private var deletedTransactionId: LedgerTransaction.ID?
  #if DEBUG
    @State private var isShowingDebugPanel = false
  #endif
  @State private var hasCompletedInitialAppear = false
  @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.system
    .rawValue

  private var linkRouter: LinkRouter {
    LinkRouter(webBaseURL: dependencies.webBaseURL)
  }

  public init(dependencies: AppDependencies? = nil, configuration: APIConfiguration? = nil) {
    Typography.registerFontsIfAvailable()
    #if DEBUG
      let args = ProcessInfo.processInfo.arguments
      let hasScriptedArg =
        args.contains("--scripted")
        || args.contains("--scenario-empty")
        || args.contains("--scenario-trip0")
        || args.contains("--scenario-large")
        || args.contains("--signed-out")
        || args.contains("--fail-offline")
        || args.contains("--fail-rate-limited")
        || args.contains("--fail-invalid-credentials")
        || args.contains("--role-editor")
        || args.contains("--role-viewer")
        || args.contains("--latency-2s")
        || args.contains("--latency-300ms")
        || args.contains("--no-snapshot")
        || args.contains("--unverified-user")
        || args.contains("--all-settled")
        || args.contains("--delete-t4")
        || args.contains("--empty-activity")
        || args.contains("--enter-step1")
        || args.contains("--enter-step2")
        || args.contains("--enter-step3")
        || args.contains("--enter-step4")
        || args.contains("--emit-changed")
        || args.contains("--emit-removed")
      let useScripted = hasScriptedArg || DebugOverrides.useScripted

      let resolved: AppDependencies
      let initialSessionState: SessionModel.State
      if let dependencies {
        resolved = dependencies
        initialSessionState = dependencies.world == nil ? .loading : .signedIn(PreviewSamples.user)
      } else if useScripted {
        let signedIn = !args.contains("--signed-out")
        let preset: ScenarioPreset
        if args.contains("--scenario-empty") {
          preset = .empty
        } else if args.contains("--scenario-trip0") {
          preset = .tripStep0
        } else if args.contains("--scenario-large") {
          preset = .large
        } else {
          preset = .tripStep4
        }

        var behavior = FakeBehavior()
        if args.contains("--latency-2s") {
          behavior.latency = .seconds(2)
        } else if args.contains("--latency-300ms") {
          behavior.latency = .milliseconds(300)
        }
        if args.contains("--no-snapshot") {
          behavior.hasSnapshot = false
        }
        if args.contains("--role-editor") {
          behavior.role = .editor
        } else if args.contains("--role-viewer") {
          behavior.role = .viewer
        }
        if args.contains("--fail-offline") {
          behavior.failure = .offline
        } else if args.contains("--fail-rate-limited") && !signedIn {
          behavior.failure = .rateLimited
        }

        let debugConfig = configuration ?? Self.resolvedDebugConfiguration()
        let world = FakeWorld(preset: preset, behavior: behavior, signedIn: signedIn)
        resolved = .scripted(
          world: world,
          webBaseURL: debugConfig.webBaseURL,
          appVersion: debugConfig.appVersion
        )
        initialSessionState = signedIn ? .signedIn(PreviewSamples.user) : .signedOut
      } else {
        let liveConfig = configuration ?? Self.resolvedDebugConfiguration()
        resolved = .live(configuration: liveConfig)
        initialSessionState = .loading
      }
      self.dependencies = resolved
      let session = SessionModel(
        authRepository: resolved.auth,
        appVersion: resolved.appVersion,
        initialState: initialSessionState
      )
      self._sessionModel = State(initialValue: session)
      self._pushCoordinator = State(
        initialValue: PushCoordinator(devicesRepository: resolved.devices)
      )
      self._groupListModel = State(
        initialValue: GroupListModel(repository: resolved.groups)
      )
      self._overviewModel = State(
        initialValue: OverviewModel(repository: resolved.overview)
      )
      self._notificationsModel = State(
        initialValue: NotificationsModel(
          repository: resolved.notifications,
          onUnauthorized: {
            Task { await session.signOut() }
          }
        )
      )
      self._accountModel = State(
        initialValue: AccountModel(
          repository: resolved.auth,
          devicesRepository: resolved.devices,
          notificationsRepository: resolved.notifications,
          chatLinksRepository: resolved.chatLinks,
          onSignedOut: {
            Task { await session.signOut() }
          }
        )
      )
      let initialError: AppError?
      if args.contains("--fail-rate-limited") {
        initialError = .rateLimited
      } else if args.contains("--fail-invalid-credentials") {
        initialError = .api(code: "INVALID_CREDENTIALS", status: 401)
      } else {
        initialError = nil
      }
      self._signInModel = State(
        initialValue: SignInModel(
          repository: resolved.auth,
          initialEmail: initialError != nil ? "minh@dev.songphang.local" : "",
          initialPassword: initialError != nil ? "wrong" : "",
          initialSubmitError: initialError,
          onSignedIn: { user in
            session.didSignIn(user)
          }
        )
      )
    #else
      let resolved =
        dependencies
        ?? .live(configuration: configuration ?? Self.bundleConfiguration())
      self.dependencies = resolved
      let session = SessionModel(
        authRepository: resolved.auth,
        appVersion: resolved.appVersion,
        initialState: .loading
      )
      self._sessionModel = State(initialValue: session)
      self._pushCoordinator = State(
        initialValue: PushCoordinator(devicesRepository: resolved.devices)
      )
      self._groupListModel = State(
        initialValue: GroupListModel(repository: resolved.groups)
      )
      self._overviewModel = State(
        initialValue: OverviewModel(repository: resolved.overview)
      )
      self._notificationsModel = State(
        initialValue: NotificationsModel(
          repository: resolved.notifications,
          onUnauthorized: {
            Task { await session.signOut() }
          }
        )
      )
      self._accountModel = State(
        initialValue: AccountModel(
          repository: resolved.auth,
          devicesRepository: resolved.devices,
          notificationsRepository: resolved.notifications,
          chatLinksRepository: resolved.chatLinks,
          onSignedOut: {
            Task { await session.signOut() }
          }
        )
      )
      self._signInModel = State(
        initialValue: SignInModel(
          repository: resolved.auth,
          onSignedIn: { user in
            session.didSignIn(user)
          }
        )
      )
    #endif
  }

  static func bundleConfiguration() -> APIConfiguration {
    let info = Bundle.main.infoDictionary
    #if DEBUG
      let defaultAPIString = "http://127.0.0.1:4000/api/v1"
      let defaultWebString = "http://localhost:3000"
    #else
      let defaultAPIString = "https://example.invalid/api/v1"
      let defaultWebString = "https://example.invalid"
    #endif
    let apiURL =
      Self.parseOptionalHTTPURL(info?["API_BASE_URL"] as? String)
      ?? URL(string: defaultAPIString)
      ?? URL(filePath: "/")
    let webURL =
      Self.parseOptionalHTTPURL(info?["WEB_BASE_URL"] as? String)
      ?? URL(string: defaultWebString)
      ?? URL(filePath: "/")
    var version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    #if DEBUG
      let args = ProcessInfo.processInfo.arguments
      if let idx = args.firstIndex(of: "--app-version"), idx + 1 < args.count {
        version = args[idx + 1]
      }
    #endif
    let rawStoreURL = (info?["APP_STORE_URL"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let appStoreURL = Self.parseOptionalHTTPURL(rawStoreURL)
    let rawDevice = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let deviceName = rawDevice.isEmpty ? "iPhone" : String(rawDevice.prefix(60))
    return APIConfiguration(
      apiBaseURL: apiURL,
      webBaseURL: webURL,
      appVersion: version,
      deviceName: deviceName,
      appStoreURL: appStoreURL
    )
  }

  #if DEBUG
    static func resolvedDebugConfiguration() -> APIConfiguration {
      let base = bundleConfiguration()
      let apiURL = parseOptionalHTTPURL(DebugOverrides.apiBaseURL) ?? base.apiBaseURL
      let webURL = parseOptionalHTTPURL(DebugOverrides.webBaseURL) ?? base.webBaseURL
      return APIConfiguration(
        apiBaseURL: apiURL,
        webBaseURL: webURL,
        appVersion: base.appVersion,
        deviceName: base.deviceName,
        appStoreURL: base.appStoreURL
      )
    }
  #endif

  public static func parseOptionalHTTPURL(_ rawValue: String?) -> URL? {
    guard let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
      !trimmed.isEmpty,
      !trimmed.contains("$("),
      let url = URL(string: trimmed),
      let scheme = url.scheme?.lowercased(),
      scheme == "https" || scheme == "http",
      url.host?.isEmpty == false
    else {
      return nil
    }
    return url
  }

  public var body: some View {
    Group {
      #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--gallery-tokens") || args.contains("--gallery-shapes")
          || args.contains("--gallery-components")
        {
          DebugGalleryView()
        } else {
          mainContent
            .scrollDismissesKeyboard(.interactively)
        }
      #else
        mainContent
          .scrollDismissesKeyboard(.interactively)
      #endif
    }
    #if DEBUG
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) {
        _ in
        isShowingDebugPanel = true
      }
      .onAppear {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--open-debug") {
          isShowingDebugPanel = true
        }
        if args.contains("--removed-notice") {
          statusNotice = L10n.tr("common.removed")
        }
        let targetGroupId =
          args.contains("--scenario-large") ? LargeScenario.groupId : TripScenario.groupId
        if args.contains("--route-register") {
          path = [.register]
        } else if args.contains("--route-forgot") {
          path = [.forgotPassword]
        } else if args.contains("--route-create-group") {
          selectedTab = .groups
          groupsPath = [.createGroup]
        } else if args.contains("--route-account") {
          selectedTab = .account
        } else if args.contains("--route-members") {
          selectedTab = .groups
          groupsPath = [.groupMembers(groupId: targetGroupId)]
        } else if args.contains("--route-settings") {
          selectedTab = .groups
          groupsPath = [.groupSettings(groupId: targetGroupId)]
        } else if args.contains("--route-join") {
          selectedTab = .groups
          groupsPath = [.joinGroup(token: TripScenario.invite.token)]
        } else if args.contains("--route-join-invalid") {
          selectedTab = .groups
          groupsPath = [.joinGroup(token: "invalid-token")]
        } else if args.contains("--route-feed") {
          selectedTab = .groups
          groupsPath = [.groupFeed(groupId: targetGroupId)]
        } else if args.contains("--route-balances") {
          selectedTab = .groups
          groupsPath = [.groupBalances(groupId: targetGroupId)]
        } else if args.contains("--route-activity") {
          selectedTab = .groups
          groupsPath = [.groupActivity(groupId: targetGroupId)]
        } else if args.contains("--route-quick-entry") {
          let sentence: String? = {
            if args.contains("--sentence-1") { return "cà phê 180k chia 4" }
            if args.contains("--sentence-2") { return "taxi 250k lan trả" }
            if args.contains("--sentence-3") { return "nước 100k chia lan, hùng, thu" }
            if args.contains("--sentence-4") {
              return "lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều"
            }
            if args.contains("--sentence-5") { return "kẹo 1001" }
            if args.contains("--sentence-6") { return "chợ 500k thu trả, lan 200 thu 300" }
            if args.contains("--sentence-7") { return "cà phê 180k chia 3" }
            if args.contains("--sentence-8") { return "180k" }
            if args.contains("--sentence-9") { return "cà phê" }
            if args.contains("--sentence-10") { return "cà phê 180k chia 9" }
            return nil
          }()
          selectedTab = .groups
          groupsPath = [.quickEntry(groupId: targetGroupId, initialSentence: sentence)]
        } else if args.contains("--route-new-tx") {
          selectedTab = .groups
          groupsPath = [.newTransactionForm(groupId: targetGroupId, initialReading: nil)]
        } else if args.contains("--route-edit-t1") {
          selectedTab = .groups
          groupsPath = [
            .editTransaction(groupId: targetGroupId, transactionId: TripScenario.t1Transaction.id)
          ]
        } else if args.contains("--route-edit-t4") {
          selectedTab = .groups
          groupsPath = [
            .editTransaction(groupId: targetGroupId, transactionId: TripScenario.t4Transaction.id)
          ]
        } else if args.contains("--route-settle") {
          selectedTab = .groups
          groupsPath = [
            .settle(
              groupId: targetGroupId,
              fromMemberId: TripScenario.thuId,
              toMemberId: TripScenario.minhId,
              initialAmount: Money(210_000)
            )
          ]
        } else if args.contains("--route-notifications") {
          selectedTab = .notifications
        } else if args.contains("--route-overview") {
          selectedTab = .overview
        } else if args.contains("--route-ledger") {
          selectedTab = .overview
          overviewPath = [.personalLedger]
        }
      }
      .sheet(isPresented: $isShowingDebugPanel) {
        DebugPanel(
          world: dependencies.world,
          liveConfiguration: dependencies.liveConfiguration,
          sessionModel: sessionModel,
          pushCoordinator: pushCoordinator,
          onOpenJoinToken: { token in
            routeValidated(.joinGroup(token: token))
          },
          onOpenLinkURL: { url in
            handleIncomingURL(url)
          },
          onSimulatePushTap: { groupId, target in
            Task { await handlePushTap(PushTapPayload(groupId: groupId, target: target)) }
          },
          onOpenGallery: {
            selectedTab = .groups
            groupsPath.append(.debugGallery)
          },
          onReloadEnvironment: {
            isShowingDebugPanel = false
            DebugOverrides.notifyEnvironmentDidChange()
          },
          onDismiss: {
            isShowingDebugPanel = false
            if case .signedIn = sessionModel.state {
              Task { await groupListModel.load() }
            }
          }
        )
      }
    #endif
    .sheet(
      isPresented: $pushCoordinator.isPermissionSheetPresented,
      onDismiss: {
        if case .signedIn(let user) = sessionModel.state {
          pushCoordinator.deferPrompt(userId: user.id)
        }
      }
    ) {
      if case .signedIn(let user) = sessionModel.state {
        PushPermissionSheet(
          onEnable: {
            Task { await pushCoordinator.enableFromPrompt() }
          },
          onLater: {
            pushCoordinator.deferPrompt(userId: user.id)
          }
        )
      }
    }
    .onOpenURL { url in
      _ = handleIncomingURL(url)
    }
    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
      guard let url = activity.webpageURL else { return }
      _ = handleIncomingURL(url)
    }
    .fullScreenCover(item: $activeGuestShare) { item in
      GuestGroupView(
        model: item.model,
        onClose: { activeGuestShare = nil }
      )
    }
    .task {
      for await generation in dependencies.makeSessionInvalidations() {
        if await sessionModel.handleSessionInvalidation(atGeneration: generation) {
          resetToSignedOut()
        }
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active, hasCompletedInitialAppear {
        Task {
          await sessionModel.refreshOnForeground()
          await sessionModel.refreshUnreadNotificationCount(using: dependencies.notifications)
          await syncPushRegistrationIfSignedIn()
        }
      }
    }
    .onChange(of: sessionModel.state) { oldState, newState in
      if case .signedOut = newState {
        pushCoordinator.clearSessionState()
        pendingPushTap = nil
        if case .signedIn = oldState {
          pendingInviteState.clear()
          path.removeAll()
          overviewPath.removeAll()
          groupsPath.removeAll()
          notificationsPath.removeAll()
          accountPath.removeAll()
          statusNotice = nil
          selectedTab = .overview
          overviewModel = OverviewModel(repository: dependencies.overview)
          groupListModel = GroupListModel(repository: dependencies.groups)
          notificationsModel = NotificationsModel(
            repository: dependencies.notifications,
            onUnauthorized: {
              Task { await sessionModel.signOut() }
            }
          )
          accountModel = AccountModel(
            repository: dependencies.auth,
            devicesRepository: dependencies.devices,
            notificationsRepository: dependencies.notifications,
            chatLinksRepository: dependencies.chatLinks,
            onSignedOut: {
              Task { await sessionModel.signOut() }
            }
          )
          signInModel = SignInModel(
            repository: dependencies.auth,
            onSignedIn: { user in
              sessionModel.didSignIn(user)
            }
          )
        }
      } else if case .signedIn(let newUser) = newState {
        if case .signedIn(let oldUser) = oldState, oldUser.id == newUser.id {
          return
        }
        if case .signedIn = oldState {
          pushCoordinator.clearSessionState()
          path.removeAll()
          overviewPath.removeAll()
          groupsPath.removeAll()
          notificationsPath.removeAll()
          accountPath.removeAll()
          statusNotice = nil
          selectedTab = .overview
        }
        overviewModel = OverviewModel(repository: dependencies.overview)
        groupListModel = GroupListModel(repository: dependencies.groups)
        notificationsModel = NotificationsModel(
          repository: dependencies.notifications,
          onUnauthorized: {
            Task { await sessionModel.signOut() }
          }
        )
        accountModel = AccountModel(
          repository: dependencies.auth,
          devicesRepository: dependencies.devices,
          notificationsRepository: dependencies.notifications,
          chatLinksRepository: dependencies.chatLinks,
          onSignedOut: {
            Task { await sessionModel.signOut() }
          }
        )
        consumePendingRouteIfSignedIn()
        Task {
          await sessionModel.refreshUnreadNotificationCount(using: dependencies.notifications)
          await consumePendingPushIfSignedIn()
          await syncPushRegistrationIfSignedIn()
        }
      }
    }
    .task {
      PushEventBridge.shared.onDeviceTokenRegistered = { hexToken in
        Task { await pushCoordinator.registerDeviceToken(hexToken) }
      }
      PushEventBridge.shared.onPushTapReceived = { payload in
        Task { await handlePushTap(payload) }
      }
      if case .loading = sessionModel.state {
        await sessionModel.loadSession()
      }
      await sessionModel.refreshUnreadNotificationCount(using: dependencies.notifications)
      await consumePendingPushIfSignedIn()
      await syncPushRegistrationIfSignedIn()
      hasCompletedInitialAppear = true
      let args = ProcessInfo.processInfo.arguments
      #if DEBUG
        if let tokenIdx = args.firstIndex(of: "--guest-token"), tokenIdx + 1 < args.count {
          activeGuestShare = GuestSharePresentation(
            model: GuestGroupModel(
              token: args[tokenIdx + 1],
              guestLinksRepository: dependencies.guestLinks
            )
          )
        }
        guard let world = dependencies.world else { return }
        if args.contains("--unverified-user") {
          await world.setCurrentUser(PreviewSamples.unverifiedUser)
          sessionModel.didSignIn(PreviewSamples.unverifiedUser)
        }
        if args.contains("--all-settled") {
          for transfer in TripScenario.step4Balances.transfers {
            _ = try? await world.createTransaction(
              groupId: TripScenario.groupId,
              draft: .transfer(
                TransactionDraft.TransferPayload(
                  amount: transfer.amount,
                  occurredAt: "2026-11-16T15:05:00.000Z",
                  fromMemberId: transfer.fromMemberId,
                  toMemberId: transfer.toMemberId
                )
              ),
              key: IdempotencyKey()
            )
          }
        }
        if args.contains("--delete-t4") {
          try? await world.deleteTransaction(
            groupId: TripScenario.groupId,
            id: TripScenario.t4Transaction.id
          )
        }
        if args.contains("--empty-activity") {
          await world.clearActivity(groupId: TripScenario.groupId)
        }
        let stepCount: Int = {
          if args.contains("--enter-step1") { return 1 }
          if args.contains("--enter-step2") { return 2 }
          if args.contains("--enter-step3") { return 3 }
          if args.contains("--enter-step4") { return 4 }
          return 0
        }()
        if stepCount > 0 {
          let allTxs = [
            TripScenario.t1Transaction,
            TripScenario.t2Transaction,
            TripScenario.t3Transaction,
            TripScenario.t4Transaction,
          ]
          for idx in 0..<stepCount {
            let tx = allTxs[idx]
            let draft = TransactionDraft.split(
              TransactionDraft.SplitPayload(
                isIncome: tx.type == .income,
                description: tx.description,
                amount: tx.amount,
                occurredAt: tx.occurredAt,
                category: tx.category,
                payers: tx.payers,
                split: tx.split
              )
            )
            _ = try? await world.createTransaction(
              groupId: TripScenario.groupId,
              draft: draft,
              key: IdempotencyKey()
            )
          }
        }
        if args.contains("--emit-changed") {
          try? await Task.sleep(for: .milliseconds(400))
          await world.emitEvent(
            .changed(["group", "members", "balances", "transactions"])
          )
        }
        if args.contains("--emit-removed") {
          try? await Task.sleep(for: .milliseconds(400))
          await world.emitEvent(.removed)
        }
        if args.contains("--with-closed-cycle") {
          _ = try? await world.closeSettlementCycle(
            groupId: TripScenario.groupId,
            title: "Đợt 1 · Đà Lạt",
            idempotencyKey: IdempotencyKey()
          )
        }
      #endif
    }
    .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
  }

  private var isSignedIn: Bool {
    if case .signedIn = sessionModel.state { return true }
    return false
  }

  private func handleIncomingURL(_ url: URL) -> Bool {
    guard let route = linkRouter.route(for: url) else {
      return false
    }
    routeValidated(route)
    return true
  }

  private func navigate(to route: Route) {
    statusNotice = nil
    switch route {
    case .account:
      selectedTab = .account
    case .notifications:
      selectedTab = .notifications
    case .personalLedger:
      selectedTab = .overview
      overviewPath.append(.personalLedger)
    default:
      selectedTab = .groups
      groupsPath.append(route)
    }
  }

  private func routeValidated(_ route: Route) {
    if case .guestShare(let token) = route {
      activeGuestShare = GuestSharePresentation(
        model: GuestGroupModel(
          token: token,
          guestLinksRepository: dependencies.guestLinks
        )
      )
      return
    }
    if let immediate = pendingInviteState.receiveValidated(route, isSignedIn: isSignedIn) {
      if isSignedIn {
        navigate(to: immediate)
      } else {
        path.append(immediate)
      }
    }
  }

  private func consumePendingRouteIfSignedIn() {
    if let route = pendingInviteState.consumeIfSignedIn(isSignedIn) {
      navigate(to: route)
    }
  }

  private func syncPushRegistrationIfSignedIn() async {
    guard isSignedIn else {
      _ = await pushCoordinator.refreshAuthorizationStatus()
      return
    }
    let features: ServerFeatures?
    if let latest = sessionModel.latestFeatures {
      features = latest
    } else {
      features = try? await dependencies.auth.serverFeatures()
    }
    await pushCoordinator.syncRegistrationIfAuthorized(features: features)
  }

  private func resetToSignedOut() {
    pushCoordinator.clearSessionState()
    path.removeAll()
    overviewPath.removeAll()
    groupsPath.removeAll()
    notificationsPath.removeAll()
    accountPath.removeAll()
    pendingInviteState.clear()
    pendingPushTap = nil
    statusNotice = nil
    selectedTab = .overview
    overviewModel = OverviewModel(repository: dependencies.overview)
    groupListModel = GroupListModel(repository: dependencies.groups)
    notificationsModel = NotificationsModel(
      repository: dependencies.notifications,
      onUnauthorized: {
        Task { await sessionModel.signOut() }
      }
    )
    accountModel = AccountModel(
      repository: dependencies.auth,
      devicesRepository: dependencies.devices,
      notificationsRepository: dependencies.notifications,
      chatLinksRepository: dependencies.chatLinks,
      onSignedOut: {
        Task { await sessionModel.signOut() }
      }
    )
    signInModel = SignInModel(
      repository: dependencies.auth,
      onSignedIn: { user in
        sessionModel.didSignIn(user)
      }
    )
    sessionModel.markSignedOut()
  }

  private func handlePushTap(_ payload: PushTapPayload) async {
    switch sessionModel.state {
    case .loading:
      pendingPushTap = payload
    case .signedOut:
      pendingPushTap = nil
    case .signedIn:
      pendingPushTap = nil
      await applyPushTap(payload)
    }
  }

  private func consumePendingPushIfSignedIn() async {
    guard case .signedIn = sessionModel.state, let payload = pendingPushTap else {
      return
    }
    pendingPushTap = nil
    await applyPushTap(payload)
  }

  private func applyPushTap(_ payload: PushTapPayload) async {
    guard
      let destination = linkRouter.pushDestination(
        groupId: payload.groupId,
        target: payload.target
      )
    else {
      statusNotice = nil
      groupsPath.removeAll()
      await groupListModel.load()
      return
    }

    let groupId: ExpenseGroup.ID
    switch destination {
    case .notifications:
      statusNotice = nil
      selectedTab = .notifications
      notificationsPath.removeAll()
      return
    case .groupFeed(let id),
      .groupBalances(let id),
      .groupStats(let id),
      .groupFund(let id),
      .transactionDetail(let id, _):
      groupId = id
    }

    do throws(AppError) {
      _ = try await dependencies.groups.group(id: groupId)
      statusNotice = nil
      selectedTab = .groups
      switch destination {
      case .notifications:
        selectedTab = .notifications
        notificationsPath.removeAll()
      case .groupFeed(let id):
        groupsPath = [.groupFeed(groupId: id)]
      case .groupBalances(let id):
        groupsPath = [.groupFeed(groupId: id), .groupBalances(groupId: id)]
      case .groupStats(let id):
        groupsPath = [.groupFeed(groupId: id), .groupStats(groupId: id)]
      case .groupFund(let id):
        groupsPath = [.groupFeed(groupId: id), .groupFund(groupId: id)]
      case .transactionDetail(let id, let txId):
        if (try? await dependencies.transactions.transaction(groupId: id, id: txId)) != nil {
          groupsPath = [
            .groupFeed(groupId: id), .transactionDetail(groupId: id, transactionId: txId),
          ]
        } else {
          groupsPath = [.groupFeed(groupId: id)]
        }
      }
    } catch {
      if error == .unauthorized {
        await sessionModel.signOut()
      } else if case .api(_, let status) = error, status == 404 {
        statusNotice = L10n.tr("common.removed")
        groupsPath.removeAll()
        selectedTab = .groups
        await groupListModel.load()
      } else {
        groupsPath.removeAll()
        selectedTab = .groups
        await groupListModel.load()
      }
    }
  }

  @ViewBuilder
  private var mainContent: some View {
    if sessionModel.isUpgradeRequired {
      UpgradeRequiredView(appStoreURL: dependencies.appStoreURL)
    } else {
      sessionContent
    }
  }

  @ViewBuilder
  private var sessionContent: some View {
    switch sessionModel.state {
    case .loading:
      VStack {
        LoadingSkeleton(rowCount: 3, rowHeight: 72)
          .padding(20)
        Spacer()
      }
      .background(Tokens.bg.ignoresSafeArea())

    case .signedOut:
      NavigationStack(path: $path) {
        SignInView(
          model: signInModel,
          onOpenRegister: { path.append(.register) },
          onOpenForgotPassword: { path.append(.forgotPassword) }
        )
        .toolbar {
          #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
              Button("Debug") {
                isShowingDebugPanel = true
              }
            }
          #endif
        }
        .toolbar { keyboardDoneToolbar }
        .navigationDestination(for: Route.self) { route in
          destinationView(for: route, currentUser: nil, path: $path)
        }
      }

    case .signedIn(let user):
      TabView(selection: $selectedTab) {
        NavigationStack(path: $overviewPath) {
          OverviewView(
            model: overviewModel,
            user: user,
            unreadNotificationCount: sessionModel.unreadNotificationCount,
            onOpenGroup: { groupId in
              selectedTab = .groups
              groupsPath = [.groupFeed(groupId: groupId)]
            },
            onOpenBalances: { groupId in
              selectedTab = .groups
              groupsPath = [.groupBalances(groupId: groupId)]
            },
            onOpenTransaction: { groupId, txId in
              selectedTab = .groups
              groupsPath = [
                .groupFeed(groupId: groupId),
                .transactionDetail(groupId: groupId, transactionId: txId),
              ]
            },
            onOpenPersonalLedger: {
              overviewPath.append(.personalLedger)
            },
            onOpenNotifications: {
              selectedTab = .notifications
            },
            onOpenAccount: {
              selectedTab = .account
            }
          )
          .toolbar {
            #if DEBUG
              ToolbarItem(placement: .topBarTrailing) {
                Button("Debug") {
                  isShowingDebugPanel = true
                }
              }
            #endif
          }
          .navigationDestination(for: Route.self) { route in
            destinationView(for: route, currentUser: user, path: $overviewPath)
          }
        }
        .tabItem {
          Label(L10n.tr("tabs.overview"), systemImage: "sparkles")
        }
        .tag(Tab.overview)

        NavigationStack(path: $groupsPath) {
          GroupListView(
            model: groupListModel,
            user: user,
            statusNotice: statusNotice,
            unreadNotificationCount: sessionModel.unreadNotificationCount,
            onOpenGroup: { groupId in
              statusNotice = nil
              groupsPath.append(.groupFeed(groupId: groupId))
            },
            onOpenCreateGroup: {
              statusNotice = nil
              groupsPath.append(.createGroup)
            },
            onOpenAccount: {
              selectedTab = .account
            },
            onOpenNotifications: {
              selectedTab = .notifications
            },
            onResendVerification: { () async throws(AppError) in
              try await dependencies.auth.resendVerification()
            }
          )
          .toolbar {
            #if DEBUG
              ToolbarItem(placement: .topBarTrailing) {
                Button("Debug") {
                  isShowingDebugPanel = true
                }
              }
            #endif
          }
          .navigationDestination(for: Route.self) { route in
            destinationView(for: route, currentUser: user, path: $groupsPath)
          }
        }
        .tabItem {
          Label(L10n.tr("tabs.groups"), systemImage: "person.2")
        }
        .tag(Tab.groups)

        NavigationStack(path: $notificationsPath) {
          NotificationsView(
            model: notificationsModel,
            onBack: {},
            onSelectTarget: { target in
              let route = RouteDestination.notificationDestination(for: target)
              navigate(to: route)
            }
          )
          .toolbar {
            #if DEBUG
              ToolbarItem(placement: .topBarTrailing) {
                Button("Debug") {
                  isShowingDebugPanel = true
                }
              }
            #endif
          }
          .navigationDestination(for: Route.self) { route in
            destinationView(for: route, currentUser: user, path: $notificationsPath)
          }
        }
        .tabItem {
          Label(L10n.tr("tabs.notifications"), systemImage: "bell")
        }
        .badge(sessionModel.unreadNotificationCount)
        .tag(Tab.notifications)

        NavigationStack(path: $accountPath) {
          AccountView(
            model: accountModel,
            onBack: {}
          )
          .toolbar {
            #if DEBUG
              ToolbarItem(placement: .topBarTrailing) {
                Button("Debug") {
                  isShowingDebugPanel = true
                }
              }
            #endif
          }
          .navigationDestination(for: Route.self) { route in
            destinationView(for: route, currentUser: user, path: $accountPath)
          }
        }
        .tabItem {
          Label(L10n.tr("tabs.account"), systemImage: "person.crop.circle")
        }
        .tag(Tab.account)
      }
      .tint(Tokens.ink)
    }
  }

  @ToolbarContentBuilder
  private var keyboardDoneToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .keyboard) {
      Spacer()
      Button(L10n.tr("split.done")) {
        UIApplication.shared.sendAction(
          #selector(UIResponder.resignFirstResponder),
          to: nil,
          from: nil,
          for: nil
        )
      }
    }
  }

  private func destinationView(
    for route: Route,
    currentUser: User?,
    path: Binding<[Route]>
  ) -> some View {
    RouteDestination(
      route: route,
      dependencies: dependencies,
      sessionModel: sessionModel,
      currentUser: currentUser,
      onNavigate: { path.wrappedValue.append($0) },
      onReplaceTop: { newRoute in
        if path.wrappedValue.isEmpty {
          path.wrappedValue = [newRoute]
        } else {
          path.wrappedValue[path.wrappedValue.count - 1] = newRoute
        }
      },
      onPop: {
        if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() }
      },
      onPopToRoot: { notice in
        if let notice {
          statusNotice = notice
        }
        path.wrappedValue.removeAll()
        Task {
          await groupListModel.load()
          await overviewModel.load()
        }
      },
      onExpenseSaved: {
        guard case .signedIn(let signedInUser) = sessionModel.state else { return }
        Task {
          let features: ServerFeatures?
          if let latest = sessionModel.latestFeatures {
            features = latest
          } else {
            features = try? await dependencies.auth.serverFeatures()
          }
          await pushCoordinator.handleFirstExpenseSaved(
            userId: signedInUser.id,
            features: features
          )
        }
      },
      deletedTransactionId: $deletedTransactionId
    )
    .toolbar { keyboardDoneToolbar }
    .overlay { StatusBarCover() }
    .background(PopGestureEnabler())
    .id(route)
  }
}
