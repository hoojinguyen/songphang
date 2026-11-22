public import Domain
public import Observation

@Observable
public final class SessionModel {
  public enum State: Sendable, Equatable {
    case loading
    case signedOut
    case signedIn(User)
  }

  public private(set) var state: State = .loading
  public private(set) var isUpgradeRequired = false
  public private(set) var isOffline = false
  public private(set) var latestFeatures: ServerFeatures?
  public private(set) var unreadNotificationCount: Int = 0

  private let authRepository: any AuthRepository
  private let appVersion: String

  public init(
    authRepository: any AuthRepository,
    appVersion: String = "1.0.0",
    initialState: State = .loading
  ) {
    self.authRepository = authRepository
    self.appVersion = appVersion
    self.state = initialState
  }

  public func loadSession() async {
    if case .loading = state, let cached = await authRepository.lastKnownUser() {
      state = .signedIn(cached)
    }

    async let featuresTask: ServerFeatures? = try? await authRepository.serverFeatures()
    async let userTask: Result<User?, AppError> = {
      do throws(AppError) {
        return .success(try await authRepository.currentUser())
      } catch {
        return .failure(error)
      }
    }()

    let (features, userResult) = await (featuresTask, userTask)

    if let features {
      applyFeatures(features)
    }

    applyUserResult(userResult)
  }

  public func refreshOnForeground() async {
    if let features = try? await authRepository.serverFeatures() {
      applyFeatures(features)
    }
    guard case .signedIn = state else {
      return
    }
    do throws(AppError) {
      if let user = try await authRepository.currentUser() {
        state = .signedIn(user)
        isOffline = false
      } else {
        state = .signedOut
        isOffline = false
      }
    } catch {
      if error == .unauthorized {
        state = .signedOut
        isOffline = false
      } else if error == .offline {
        isOffline = true
      }
    }
  }

  public func didSignIn(_ user: User) {
    state = .signedIn(user)
    isOffline = false
  }

  public func refreshUnreadNotificationCount(using repo: any NotificationsRepository) async {
    guard case .signedIn = state else { return }
    if let count = try? await repo.unreadCount() {
      unreadNotificationCount = count
    }
  }

  public func setUnreadNotificationCount(_ count: Int) {
    unreadNotificationCount = count
  }

  public func handleError(_ error: AppError) {
    if error == .unauthorized {
      markSignedOut()
    }
  }

  public func markSignedOut() {
    state = .signedOut
    isOffline = false
  }

  public func signOut() async {
    try? await authRepository.signOut()
    markSignedOut()
  }

  private func applyFeatures(_ features: ServerFeatures) {
    latestFeatures = features
    isUpgradeRequired = SemanticVersion.isBuild(
      appVersion,
      belowMinimum: features.minAppVersion.ios
    )
  }

  private func applyUserResult(_ result: Result<User?, AppError>) {
    switch result {
    case .success(let user):
      isOffline = false
      if let user {
        state = .signedIn(user)
      } else {
        state = .signedOut
      }
    case .failure(let error):
      if error == .unauthorized {
        markSignedOut()
      } else if case .signedIn = state {
        isOffline = (error == .offline)
      } else {
        state = .signedOut
      }
    }
  }
}
