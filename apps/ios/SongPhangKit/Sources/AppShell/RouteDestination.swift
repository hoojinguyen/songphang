import AuthFeature
import DesignSystem
import Domain
public import SwiftUI

public struct RouteDestination: View {
  private let route: Route
  private let dependencies: AppDependencies
  private let sessionModel: SessionModel
  private let onNavigate: (Route) -> Void
  private let onPop: () -> Void
  private let onPopToRoot: () -> Void

  public init(
    route: Route,
    dependencies: AppDependencies,
    sessionModel: SessionModel,
    onNavigate: @escaping (Route) -> Void,
    onPop: @escaping () -> Void,
    onPopToRoot: @escaping () -> Void
  ) {
    self.route = route
    self.dependencies = dependencies
    self.sessionModel = sessionModel
    self.onNavigate = onNavigate
    self.onPop = onPop
    self.onPopToRoot = onPopToRoot
  }

  public var body: some View {
    switch route {
    case .register:
      RegisterView(
        model: RegisterModel(
          repository: dependencies.auth,
          initialSubmitted: ProcessInfo.processInfo.arguments.contains("--submitted")
        ),
        onBackToSignIn: onPop
      )
    case .forgotPassword:
      ForgotPasswordView(
        model: ForgotPasswordModel(
          repository: dependencies.auth,
          initialSubmitted: ProcessInfo.processInfo.arguments.contains("--submitted")
        ),
        onBackToSignIn: onPop
      )
    case .debugGallery:
      DebugGalleryView()
    default:
      SPCard {
        Text(L10n.tr("common.appName"))
          .font(Typography.sectionTitle)
      }
      .padding(20)
    }
  }
}
