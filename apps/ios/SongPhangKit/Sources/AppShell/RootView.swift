import AccountFeature
import AuthFeature
import DesignSystem
import Domain
import GroupsFeature
public import Repositories
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

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

public struct RootView: View {
  private let dependencies: AppDependencies
  @Environment(\.scenePhase) private var scenePhase
  @State private var sessionModel: SessionModel
  @State private var groupListModel: GroupListModel
  @State private var signInModel: SignInModel
  @State private var pushCoordinator: PushCoordinator
  @State private var path: [Route] = []
  @State private var pendingInviteState = PendingInviteState()
  @State private var pendingPushTap: PushTapPayload?
  @State private var statusNotice: String?
  @State private var deletedTransactionId: LedgerTransaction.ID?
  @State private var isShowingDebugPanel = false
  @State private var hasCompletedInitialAppear = false

  private var linkRouter: LinkRouter {
    LinkRouter(webBaseURL: dependencies.webBaseURL)
  }

  public init(dependencies: AppDependencies? = nil, configuration: APIConfiguration? = nil) {
    #if DEBUG
      let args = ProcessInfo.processInfo.arguments
      let useScripted =
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

        let world = FakeWorld(preset: preset, behavior: behavior, signedIn: signedIn)
        resolved = .scripted(world: world)
        initialSessionState = signedIn ? .signedIn(PreviewSamples.user) : .signedOut
      } else {
        let liveConfig = configuration ?? Self.bundleConfiguration()
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

  private static func bundleConfiguration() -> APIConfiguration {
    let info = Bundle.main.infoDictionary
    let apiString = (info?["API_BASE_URL"] as? String) ?? "http://127.0.0.1:4000/api/v1"
    let webString = (info?["WEB_BASE_URL"] as? String) ?? "http://localhost:3000"
    var version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    #if DEBUG
      let args = ProcessInfo.processInfo.arguments
      if let idx = args.firstIndex(of: "--app-version"), idx + 1 < args.count {
        version = args[idx + 1]
      }
    #endif
    let apiURL = URL(string: apiString) ?? URL(filePath: "/")
    let webURL = URL(string: webString) ?? URL(filePath: "/")
    let rawStoreURL = (info?["APP_STORE_URL"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let appStoreURL = rawStoreURL.flatMap { value in
      value.isEmpty ? nil : URL(string: value)
    }
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

  public var body: some View {
    Group {
      let args = ProcessInfo.processInfo.arguments
      if args.contains("--gallery-tokens") || args.contains("--gallery-shapes")
        || args.contains("--gallery-components")
      {
        DebugGalleryView()
      } else {
        mainContent
          .scrollDismissesKeyboard(.interactively)
      }
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
          path = [.createGroup]
        } else if args.contains("--route-account") {
          path = [.account]
        } else if args.contains("--route-members") {
          path = [.groupMembers(groupId: targetGroupId)]
        } else if args.contains("--route-settings") {
          path = [.groupSettings(groupId: targetGroupId)]
        } else if args.contains("--route-join") {
          path = [.joinGroup(token: TripScenario.invite.token)]
        } else if args.contains("--route-join-invalid") {
          path = [.joinGroup(token: "invalid-token")]
        } else if args.contains("--route-feed") {
          path = [.groupFeed(groupId: targetGroupId)]
        } else if args.contains("--route-balances") {
          path = [.groupBalances(groupId: targetGroupId)]
        } else if args.contains("--route-activity") {
          path = [.groupActivity(groupId: targetGroupId)]
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
          path = [.quickEntry(groupId: targetGroupId, initialSentence: sentence)]
        } else if args.contains("--route-new-tx") {
          path = [.newTransactionForm(groupId: targetGroupId, initialReading: nil)]
        } else if args.contains("--route-edit-t1") {
          path = [
            .editTransaction(groupId: targetGroupId, transactionId: TripScenario.t1Transaction.id)
          ]
        } else if args.contains("--route-edit-t4") {
          path = [
            .editTransaction(groupId: targetGroupId, transactionId: TripScenario.t4Transaction.id)
          ]
        } else if args.contains("--route-settle") {
          path = [
            .settle(
              groupId: targetGroupId,
              fromMemberId: TripScenario.thuId,
              toMemberId: TripScenario.minhId,
              initialAmount: Money(210_000)
            )
          ]
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
            path.append(.debugGallery)
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
    .sheet(isPresented: $pushCoordinator.isPermissionSheetPresented) {
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
    .task {
      for await _ in dependencies.makeSessionInvalidations() {
        resetToSignedOut()
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active, hasCompletedInitialAppear {
        Task {
          await sessionModel.refreshOnForeground()
          _ = await pushCoordinator.refreshAuthorizationStatus()
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
          statusNotice = nil
          groupListModel = GroupListModel(repository: dependencies.groups)
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
          path.removeAll()
          statusNotice = nil
        }
        groupListModel = GroupListModel(repository: dependencies.groups)
        consumePendingRouteIfSignedIn()
        Task { await consumePendingPushIfSignedIn() }
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
      await consumePendingPushIfSignedIn()
      hasCompletedInitialAppear = true
      let args = ProcessInfo.processInfo.arguments
      #if DEBUG
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
      #endif
    }
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

  private func routeValidated(_ route: Route) {
    if let immediate = pendingInviteState.receiveValidated(route, isSignedIn: isSignedIn) {
      path.append(immediate)
    }
  }

  private func consumePendingRouteIfSignedIn() {
    if let route = pendingInviteState.consumeIfSignedIn(isSignedIn) {
      path.append(route)
    }
  }

  private func resetToSignedOut() {
    pushCoordinator.clearSessionState()
    path.removeAll()
    pendingInviteState.clear()
    pendingPushTap = nil
    statusNotice = nil
    groupListModel = GroupListModel(repository: dependencies.groups)
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
      path.removeAll()
      await groupListModel.load()
      return
    }

    let groupId: ExpenseGroup.ID
    switch destination {
    case .groupFeed(let id), .groupBalances(let id), .groupStats(let id), .groupFund(let id):
      groupId = id
    }

    do throws(AppError) {
      _ = try await dependencies.groups.group(id: groupId)
      statusNotice = nil
      switch destination {
      case .groupFeed(let id):
        path = [.groupFeed(groupId: id)]
      case .groupBalances(let id):
        path = [.groupFeed(groupId: id), .groupBalances(groupId: id)]
      case .groupStats(let id):
        path = [.groupFeed(groupId: id), .groupStats(groupId: id)]
      case .groupFund(let id):
        path = [.groupFeed(groupId: id), .groupFund(groupId: id)]
      }
    } catch {
      if error == .unauthorized {
        await sessionModel.signOut()
      } else if case .api(_, let status) = error, status == 404 {
        statusNotice = L10n.tr("common.removed")
        path.removeAll()
        await groupListModel.load()
      } else {
        path.removeAll()
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
          destinationView(for: route, currentUser: nil)
        }
      }

    case .signedIn(let user):
      NavigationStack(path: $path) {
        GroupListView(
          model: groupListModel,
          user: user,
          statusNotice: statusNotice,
          onOpenGroup: { groupId in
            statusNotice = nil
            path.append(.groupFeed(groupId: groupId))
          },
          onOpenCreateGroup: {
            statusNotice = nil
            path.append(.createGroup)
          },
          onOpenAccount: {
            statusNotice = nil
            path.append(.account)
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
          destinationView(for: route, currentUser: user)
        }
      }
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

  private func destinationView(for route: Route, currentUser: User?) -> some View {
    RouteDestination(
      route: route,
      dependencies: dependencies,
      sessionModel: sessionModel,
      currentUser: currentUser,
      onNavigate: { path.append($0) },
      onReplaceTop: { newRoute in
        if path.isEmpty {
          path = [newRoute]
        } else {
          path[path.count - 1] = newRoute
        }
      },
      onPop: {
        if !path.isEmpty { path.removeLast() }
      },
      onPopToRoot: { notice in
        if let notice {
          statusNotice = notice
        }
        path.removeAll()
        Task { await groupListModel.load() }
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
