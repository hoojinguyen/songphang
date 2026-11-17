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
  private let authRepository: any AuthRepository

  public init(authRepository: any AuthRepository, initialState: State = .loading) {
    self.authRepository = authRepository
    self.state = initialState
  }

  public func loadSession() async {
    do throws(AppError) {
      if let user = try await authRepository.currentUser() {
        state = .signedIn(user)
      } else {
        state = .signedOut
      }
    } catch {
      if error == .unauthorized {
        state = .signedOut
      } else if case .loading = state {
        state = .signedOut
      }
    }
  }

  public func didSignIn(_ user: User) {
    state = .signedIn(user)
  }

  public func handleError(_ error: AppError) {
    if error == .unauthorized {
      state = .signedOut
    }
  }

  public func signOut() async {
    try? await authRepository.signOut()
    state = .signedOut
  }
}
