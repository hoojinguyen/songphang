import DesignSystem
public import Domain
public import Observation

@Observable
public final class AccountModel {
  public private(set) var user: Loadable<User>
  public private(set) var refreshError: AppError?
  public var currentPassword = ""
  public var newPassword = ""
  public var revokeOtherSessions = false
  public private(set) var isSavingPassword = false
  public private(set) var passwordSaved = false
  public private(set) var passwordError: String?

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

  public func load() async {
    do throws(AppError) {
      if let fetched = try await repository.currentUser() {
        user = .loaded(fetched)
        refreshError = nil
      } else {
        onSignedOut()
      }
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .loaded = user {
        refreshError = error
      } else {
        user = .failed(error)
      }
    }
  }

  public func savePassword() async {
    guard !isSavingPassword else { return }
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
    } catch {
      if case .api("INVALID_CREDENTIALS", _) = error {
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
      !isDeletingAccount
    else { return }
    isDeletingAccount = true
    deleteError = nil
    defer { isDeletingAccount = false }
    do throws(AppError) {
      try await repository.deleteAccount(email: deleteConfirmationEmail)
      onSignedOut()
    } catch {
      if case .api("OWNER_REQUIRED", _) = error {
        deleteError = L10n.t("account.ownerRequired", ["count": "1"])
      } else {
        deleteError = L10n.tr("common.saveError")
      }
    }
  }
}
