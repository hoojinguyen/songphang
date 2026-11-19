import DesignSystem
public import Domain
public import Observation

@Observable
public final class AccountModel {
  public private(set) var user: Loadable<User>
  public private(set) var sessions: Loadable<[UserSession]> = .loading
  public private(set) var refreshError: AppError?
  public var currentPassword = ""
  public var newPassword = ""
  public var revokeOtherSessions = false
  public private(set) var isSavingPassword = false
  public private(set) var passwordSaved = false
  public private(set) var passwordError: String?

  public private(set) var revokingSessionId: UserSession.ID?
  public private(set) var revokeSessionError: String?

  public var deleteConfirmationEmail = ""
  public private(set) var isDeletingAccount = false
  public private(set) var deleteError: String?
  public private(set) var isSigningOut = false
  public private(set) var signOutError: String?

  private let repository: any AuthRepository
  private let onSignedOut: () -> Void

  public init(
    repository: any AuthRepository,
    initialUser: User? = nil,
    onSignedOut: @escaping () -> Void
  ) {
    self.repository = repository
    if let initialUser {
      self.user = .loaded(initialUser)
    } else {
      self.user = .loading
    }
    self.onSignedOut = onSignedOut
  }

  public var isOffline: Bool {
    refreshError == .offline
  }

  public func load() async {
    async let userTask: Result<User?, AppError> = {
      do throws(AppError) {
        return .success(try await repository.currentUser())
      } catch {
        return .failure(error)
      }
    }()
    async let sessionsTask: Result<[UserSession], AppError> = {
      do throws(AppError) {
        return .success(try await repository.sessions())
      } catch {
        return .failure(error)
      }
    }()

    let (userResult, sessionsResult) = await (userTask, sessionsTask)

    switch userResult {
    case .success(let fetched):
      if let fetched {
        user = .loaded(fetched)
        refreshError = nil
      } else {
        onSignedOut()
        return
      }
    case .failure(let error):
      if error == .unauthorized {
        onSignedOut()
        return
      }
      if case .loaded = user {
        refreshError = error
      } else {
        user = .failed(error)
      }
    }

    switch sessionsResult {
    case .success(let list):
      sessions = .loaded(list)
    case .failure(let error):
      if error == .unauthorized {
        onSignedOut()
        return
      }
      if case .loaded = sessions {
        refreshError = refreshError ?? error
      } else {
        sessions = .failed(error)
      }
    }
  }

  public func reloadSessions() async {
    sessions = .loading
    revokeSessionError = nil
    do throws(AppError) {
      sessions = .loaded(try await repository.sessions())
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else {
        sessions = .failed(error)
      }
    }
  }

  public func revokeSession(_ session: UserSession) async {
    guard revokingSessionId == nil, !isOffline else { return }
    revokingSessionId = session.id
    revokeSessionError = nil
    defer { revokingSessionId = nil }
    do throws(AppError) {
      try await repository.revokeSession(id: session.id)
      if session.current {
        onSignedOut()
        return
      }
      if case .loaded(var currentList) = sessions {
        currentList.removeAll { $0.id == session.id }
        sessions = .loaded(currentList)
      }
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else {
        revokeSessionError = L10n.tr("common.saveError")
      }
    }
  }

  public func savePassword() async {
    guard !isSavingPassword, !isOffline else { return }
    if newPassword.count < 10 {
      passwordError = L10n.tr("auth.tooShort")
      return
    }
    if newPassword.count > 128 {
      passwordError = L10n.tr("auth.passwordTooLong")
      return
    }
    passwordError = nil
    passwordSaved = false
    isSavingPassword = true
    defer { isSavingPassword = false }
    do throws(AppError) {
      try await repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        revokeOtherSessions: revokeOtherSessions
      )
      currentPassword = ""
      newPassword = ""
      passwordSaved = true
      if revokeOtherSessions {
        await reloadSessions()
      }
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .api("INVALID_CREDENTIALS", _) = error {
        passwordError = L10n.tr("account.wrongPassword")
      } else if case .api("WEAK_PASSWORD", _) = error {
        passwordError = L10n.tr("auth.tooShort")
      } else {
        passwordError = L10n.tr("common.saveError")
      }
    }
  }

  public func signOut() async {
    guard !isSigningOut else { return }
    isSigningOut = true
    signOutError = nil
    defer { isSigningOut = false }
    do throws(AppError) {
      try await repository.signOut()
      onSignedOut()
    } catch {
      signOutError = L10n.tr("common.saveError")
    }
  }

  public func deleteAccount() async {
    guard let current = user.value,
      deleteConfirmationEmail == current.email,
      !isDeletingAccount,
      !isOffline
    else { return }
    isDeletingAccount = true
    deleteError = nil
    defer { isDeletingAccount = false }
    do throws(AppError) {
      try await repository.deleteAccount(email: deleteConfirmationEmail)
      onSignedOut()
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .api("OWNER_REQUIRED", _) = error {
        deleteError = L10n.t("account.ownerRequired", ["count": "1"])
      } else {
        deleteError = L10n.tr("common.saveError")
      }
    }
  }
}
