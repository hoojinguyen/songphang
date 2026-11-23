import DesignSystem
public import Domain
public import Observation
import UIKit
import UserNotifications

@Observable
public final class AccountModel {
  public enum PushStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
  }

  public enum PairingTerminalStatus: Sendable, Equatable {
    case invalid
    case identityTaken
  }

  public private(set) var user: Loadable<User>
  public private(set) var sessions: Loadable<[UserSession]> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var pushFeatureEnabled = false
  public private(set) var pushStatus: PushStatus = .notDetermined
  public private(set) var isSavingPushSettings = false
  public private(set) var pushSettingsError: String?

  public private(set) var telegramFeatureEnabled = false
  public internal(set) var chatIdentities: Loadable<[ChatIdentity]> = .loading
  public internal(set) var startedPairing: StartedTelegramPairing?
  public internal(set) var currentPairing: TelegramPairing?
  public internal(set) var pairingCompleted = false
  public internal(set) var isStartingPairing = false
  public internal(set) var isSubmittingPairingAction = false
  public internal(set) var isUnlinkingTelegram = false
  public internal(set) var telegramError: String?
  public internal(set) var pairingError: String?
  public internal(set) var pairingTerminalStatus: PairingTerminalStatus?

  public private(set) var notificationSettings: Loadable<NotificationSettings> = .loading
  public private(set) var isUpdatingNotificationSettings = false
  public private(set) var notificationSettingsError: String?
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

  internal let repository: any AuthRepository
  private let devicesRepository: (any DevicesRepository)?
  private let notificationsRepository: (any NotificationsRepository)?
  internal let chatLinksRepository: (any ChatLinksRepository)?
  internal let onSignedOut: () -> Void
  private let onUserUpdated: ((User) -> Void)?
  private let checkPushStatus: @Sendable () async -> PushStatus
  private let requestPushPermission: @Sendable () async -> PushStatus

  public init(
    repository: any AuthRepository,
    devicesRepository: (any DevicesRepository)? = nil,
    notificationsRepository: (any NotificationsRepository)? = nil,
    chatLinksRepository: (any ChatLinksRepository)? = nil,
    initialUser: User? = nil,
    onSignedOut: @escaping () -> Void,
    onUserUpdated: ((User) -> Void)? = nil,
    checkPushStatus: (@Sendable () async -> PushStatus)? = nil,
    requestPushPermission: (@Sendable () async -> PushStatus)? = nil
  ) {
    self.repository = repository
    self.devicesRepository = devicesRepository
    self.notificationsRepository = notificationsRepository
    self.chatLinksRepository = chatLinksRepository
    if let initialUser {
      self.user = .loaded(initialUser)
    } else {
      self.user = .loading
    }
    self.onSignedOut = onSignedOut
    self.onUserUpdated = onUserUpdated
    self.checkPushStatus = checkPushStatus ?? { await AccountModel.systemPushStatus() }
    self.requestPushPermission =
      requestPushPermission ?? { await AccountModel.requestSystemPushPermission() }
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
    async let featuresTask: ServerFeatures? = try? await repository.serverFeatures()
    async let pushStatusTask: PushStatus = await checkPushStatus()
    async let notifTask: Result<NotificationSettings, AppError>? = {
      guard let notificationsRepository else { return nil }
      do throws(AppError) {
        return .success(try await notificationsRepository.settings())
      } catch {
        return .failure(error)
      }
    }()

    let (userResult, sessionsResult, serverFeatures, currentPushStatus, notifResult) = await (
      userTask,
      sessionsTask,
      featuresTask,
      pushStatusTask,
      notifTask
    )
    if let serverFeatures {
      pushFeatureEnabled = serverFeatures.push
      telegramFeatureEnabled = serverFeatures.telegram
    }
    pushStatus = currentPushStatus
    if telegramFeatureEnabled {
      await loadChatIdentities()
    }

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

    if let notifResult {
      switch notifResult {
      case .success(let settings):
        notificationSettings = .loaded(settings)
      case .failure(let error):
        if error == .unauthorized {
          onSignedOut()
          return
        }
        if case .loaded = notificationSettings {
          refreshError = refreshError ?? error
        } else {
          notificationSettings = .failed(error)
        }
      }
    }
  }

  public func updateNotificationSettings(
    emailImmediate: Bool? = nil,
    emailDigest: Bool? = nil
  ) async {
    guard let notificationsRepository,
      case .loaded(let current) = notificationSettings,
      !isUpdatingNotificationSettings,
      !isOffline
    else { return }
    let nextImmediate = emailImmediate ?? current.emailImmediate
    let nextDigest = emailDigest ?? current.emailDigest
    let updated = NotificationSettings(emailImmediate: nextImmediate, emailDigest: nextDigest)
    notificationSettings = .loaded(updated)
    notificationSettingsError = nil
    isUpdatingNotificationSettings = true
    defer { isUpdatingNotificationSettings = false }
    do throws(AppError) {
      let persisted = try await notificationsRepository.updateSettings(
        emailImmediate: nextImmediate,
        emailDigest: nextDigest
      )
      notificationSettings = .loaded(persisted)
    } catch {
      notificationSettings = .loaded(current)
      if error == .unauthorized {
        onSignedOut()
      } else {
        notificationSettingsError = L10n.tr("common.saveError")
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

  public func enablePushNotifications() async {
    pushStatus = await requestPushPermission()
  }

  public func setHidePushContent(_ hideContent: Bool) async {
    guard let devicesRepository,
      let current = user.value,
      !isSavingPushSettings,
      !isOffline
    else { return }
    let previous = current
    var updated = current
    updated.hidePushContent = hideContent
    user = .loaded(updated)
    pushSettingsError = nil
    isSavingPushSettings = true
    defer { isSavingPushSettings = false }
    do throws(AppError) {
      let persisted = try await devicesRepository.updateHidePushContent(hideContent)
      updated.hidePushContent = persisted
      user = .loaded(updated)
      onUserUpdated?(updated)
    } catch {
      user = .loaded(previous)
      if error == .unauthorized {
        onSignedOut()
      } else {
        pushSettingsError = L10n.tr("common.saveError")
      }
    }
  }

  private static func systemPushStatus() async -> PushStatus {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    switch settings.authorizationStatus {
    case .notDetermined:
      return .notDetermined
    case .authorized, .provisional, .ephemeral:
      return .authorized
    case .denied:
      return .denied
    @unknown default:
      return .denied
    }
  }

  private static func requestSystemPushPermission() async -> PushStatus {
    _ = try? await UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    )
    let status = await systemPushStatus()
    if status == .authorized {
      UIApplication.shared.registerForRemoteNotifications()
    }
    return status
  }
}
