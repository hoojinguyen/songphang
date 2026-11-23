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

  public var currentUser: User? {
    if case .signedIn(let user) = state {
      return user
    }
    return nil
  }

  private let authRepository: any AuthRepository
  private let appVersion: String
  private var sessionGeneration: UInt64 = 0

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
    let generation = sessionGeneration
    let shouldCheckCache: Bool
    switch state {
    case .loading, .signedOut:
      shouldCheckCache = true
    case .signedIn:
      shouldCheckCache = false
    }
    if shouldCheckCache, let cached = await authRepository.lastKnownUser() {
      guard sessionGeneration == generation else { return }
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

    guard sessionGeneration == generation else { return }
    if case .failure(.api(code: "STALE_SESSION", status: _)) = userResult {
      return
    }
    applyUserResult(userResult)
  }

  public func refreshOnForeground() async {
    if let features = try? await authRepository.serverFeatures() {
      applyFeatures(features)
    }
    guard case .signedIn = state else {
      await loadSession()
      return
    }
    let generation = sessionGeneration
    do throws(AppError) {
      let user = try await authRepository.currentUser()
      guard sessionGeneration == generation else { return }
      if let user {
        state = .signedIn(user)
        isOffline = false
      } else {
        markSignedOut()
      }
    } catch {
      guard sessionGeneration == generation else { return }
      if error == .api(code: "STALE_SESSION", status: 0) {
        return
      }
      if error == .unauthorized {
        markSignedOut()
      } else if error == .offline {
        isOffline = true
      }
    }
  }

  public func didSignIn(_ user: User) {
    sessionGeneration &+= 1
    state = .signedIn(user)
    isOffline = false
    unreadNotificationCount = 0
  }

  public func refreshUnreadNotificationCount(using repo: any NotificationsRepository) async {
    let generation = sessionGeneration
    guard case .signedIn = state else { return }
    if let count = try? await repo.unreadCount() {
      guard sessionGeneration == generation, case .signedIn = state else { return }
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

  public func handleSessionInvalidation(atGeneration generation: UInt64) async -> Bool {
    let current = await authRepository.sessionGeneration()
    guard generation >= current else {
      return false
    }
    markSignedOut()
    return true
  }

  public func markSignedOut() {
    sessionGeneration &+= 1
    state = .signedOut
    isOffline = false
    unreadNotificationCount = 0
  }

  public func signOut() async {
    sessionGeneration &+= 1
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
