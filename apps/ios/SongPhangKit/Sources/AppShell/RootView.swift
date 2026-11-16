import AuthFeature
import DesignSystem
import Domain
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
  @State private var path: [Route] = []
  @State private var isShowingDebugPanel = false

  @State private var signInModel: SignInModel

  public init(dependencies: AppDependencies? = nil) {
    #if DEBUG
      let resolved: AppDependencies
      if let dependencies {
        resolved = dependencies
      } else {
        let args = ProcessInfo.processInfo.arguments
        let signedIn = !args.contains("--signed-out")
        let world = FakeWorld(preset: .tripStep4, behavior: FakeBehavior(), signedIn: signedIn)
        resolved = .scripted(world: world)
      }
      self.dependencies = resolved
      let session = SessionModel(authRepository: resolved.auth)
      self._sessionModel = State(initialValue: session)
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
        if ProcessInfo.processInfo.arguments.contains("--open-debug") {
          isShowingDebugPanel = true
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
          }
        )
      }
    #endif
    .task {
      let args = ProcessInfo.processInfo.arguments
      if args.contains("--unverified-user") {
        #if DEBUG
          await dependencies.world.setCurrentUser(PreviewSamples.unverifiedUser)
          sessionModel.didSignIn(PreviewSamples.unverifiedUser)
        #endif
      } else if args.contains("--signed-out") {
        sessionModel = SessionModel(authRepository: dependencies.auth, initialState: .signedOut)
        if args.contains("--route-register") {
          path = [.register]
        } else if args.contains("--route-forgot") {
          path = [.forgotPassword]
        }
      } else {
        await sessionModel.loadSession()
      }
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
          RouteDestination(
            route: route,
            dependencies: dependencies,
            sessionModel: sessionModel,
            onNavigate: { path.append($0) },
            onPop: {
              if !path.isEmpty { path.removeLast() }
            },
            onPopToRoot: { path.removeAll() }
          )
        }
      }

    case .signedIn(let user):
      NavigationStack(path: $path) {
        signedInHomePlaceholder(user: user)
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
            RouteDestination(
              route: route,
              dependencies: dependencies,
              sessionModel: sessionModel,
              onNavigate: { path.append($0) },
              onPop: {
                if !path.isEmpty { path.removeLast() }
              },
              onPopToRoot: { path.removeAll() }
            )
          }
      }
    }
  }

  private func signedInHomePlaceholder(user: User) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if !user.emailVerified {
          VerifyEmailBannerView(
            model: VerifyEmailBannerModel(repository: dependencies.auth)
          )
        }

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("groups.greeting", ["name": user.name]))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.muted)
            Text(L10n.tr("groups.title"))
              .font(Typography.pageTitle)
              .foregroundStyle(Tokens.ink)
          }
          Spacer()
          MemberShapeView(shape: .circle, color: .mint, name: user.name, size: 48)
        }

        SPButton(L10n.tr("common.logout"), variant: .surface) {
          Task { await sessionModel.signOut() }
        }
      }
      .padding(20)
    }
    .background(Tokens.bg.ignoresSafeArea())
  }
}
