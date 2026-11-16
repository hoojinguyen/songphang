import AccountFeature
import AuthFeature
import DesignSystem
import Domain
import GroupsFeature
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
  @State private var sessionModel: SessionModel
  @State private var groupListModel: GroupListModel
  @State private var signInModel: SignInModel
  @State private var path: [Route] = []
  @State private var statusNotice: String?
  @State private var isShowingDebugPanel = false

  public init(dependencies: AppDependencies? = nil) {
    #if DEBUG
      let resolved: AppDependencies
      if let dependencies {
        resolved = dependencies
      } else {
        let args = ProcessInfo.processInfo.arguments
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
      }
      self.dependencies = resolved
      let session = SessionModel(
        authRepository: resolved.auth,
        initialState: ProcessInfo.processInfo.arguments.contains("--signed-out")
          ? .signedOut : .signedIn(PreviewSamples.user)
      )
      self._sessionModel = State(initialValue: session)
      self._groupListModel = State(
        initialValue: GroupListModel(repository: resolved.groups)
      )
      let args = ProcessInfo.processInfo.arguments
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
      fatalError("Live repositories arrive in the integration stage")
    #endif
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
          sessionModel: sessionModel,
          onOpenJoinToken: { token in
            path.append(.joinGroup(token: token))
          },
          onOpenGallery: {
            path.append(.debugGallery)
          },
          onDismiss: {
            isShowingDebugPanel = false
            Task { await groupListModel.load() }
          }
        )
      }
    #endif
    .task {
      let args = ProcessInfo.processInfo.arguments
      #if DEBUG
        if args.contains("--unverified-user") {
          await dependencies.world.setCurrentUser(PreviewSamples.unverifiedUser)
          sessionModel.didSignIn(PreviewSamples.unverifiedUser)
        }
        if args.contains("--all-settled") {
          for transfer in TripScenario.step4Balances.transfers {
            _ = try? await dependencies.world.createTransaction(
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
          try? await dependencies.world.deleteTransaction(
            groupId: TripScenario.groupId,
            id: TripScenario.t4Transaction.id
          )
        }
        if args.contains("--empty-activity") {
          await dependencies.world.clearActivity(groupId: TripScenario.groupId)
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
            _ = try? await dependencies.world.createTransaction(
              groupId: TripScenario.groupId,
              draft: draft,
              key: IdempotencyKey()
            )
          }
        }
        if args.contains("--emit-changed") {
          try? await Task.sleep(for: .milliseconds(400))
          await dependencies.world.emitEvent(
            .changed(["group", "members", "balances", "transactions"])
          )
        }
        if args.contains("--emit-removed") {
          try? await Task.sleep(for: .milliseconds(400))
          await dependencies.world.emitEvent(.removed)
        }
      #endif
    }
  }

  @ViewBuilder
  private var mainContent: some View {
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
      }
    )
    .id(route)
  }
}
