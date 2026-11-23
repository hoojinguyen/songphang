public import Domain
import Foundation
public import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
public final class PushCoordinator {
  public enum AuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
  }

  public var isPermissionSheetPresented = false
  public private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
  public private(set) var currentDeviceId: String?
  private var registeredToken: String?

  private let devicesRepository: any DevicesRepository
  private let authorizationStatusProvider: @Sendable () async -> AuthorizationStatus
  private let requestRemoteRegistration: @MainActor () -> Void
  private var sessionGeneration: UInt64 = 0
  private var lastDeviceToken: String?
  private var isRegistering = false

  public init(
    devicesRepository: any DevicesRepository,
    authorizationStatusProvider: (@Sendable () async -> AuthorizationStatus)? = nil,
    requestRemoteRegistration: (@MainActor () -> Void)? = nil
  ) {
    self.devicesRepository = devicesRepository
    self.authorizationStatusProvider =
      authorizationStatusProvider ?? {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return Self.mapAuthorizationStatus(settings.authorizationStatus)
      }
    self.requestRemoteRegistration =
      requestRemoteRegistration ?? {
        UIApplication.shared.registerForRemoteNotifications()
      }
  }

  private func deferralKey(userId: User.ID) -> String {
    "sp.push.promptDeferred.\(userId.rawValue)"
  }

  public func hasDeferred(userId: User.ID) -> Bool {
    UserDefaults.standard.bool(forKey: deferralKey(userId: userId))
  }

  public func deferPrompt(userId: User.ID) {
    UserDefaults.standard.set(true, forKey: deferralKey(userId: userId))
    isPermissionSheetPresented = false
  }

  public func refreshAuthorizationStatus() async -> AuthorizationStatus {
    let mapped = await authorizationStatusProvider()
    authorizationStatus = mapped
    return mapped
  }

  public func handleFirstExpenseSaved(userId: User.ID, features: ServerFeatures?) async {
    guard features?.push == true else { return }
    let gen = sessionGeneration
    let status = await refreshAuthorizationStatus()
    guard sessionGeneration == gen else { return }
    if status == .authorized {
      await syncRegistrationIfAuthorized(features: features)
      return
    }
    guard !hasDeferred(userId: userId) else { return }
    guard status == .notDetermined else { return }
    isPermissionSheetPresented = true
  }

  public func enableFromPrompt() async {
    isPermissionSheetPresented = false
    _ = await requestPermissionAndRegister()
  }

  public func requestPermissionAndRegister() async -> AuthorizationStatus {
    let gen = sessionGeneration
    _ = try? await UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    )
    let status = await refreshAuthorizationStatus()
    guard sessionGeneration == gen else { return status }
    if status == .authorized {
      requestRemoteRegistration()
      if let token = lastDeviceToken {
        await registerDeviceToken(token, expectedGeneration: gen)
      }
    }
    return status
  }

  public func syncRegistrationIfAuthorized(features: ServerFeatures?) async {
    guard features?.push == true else { return }
    let gen = sessionGeneration
    let status = await refreshAuthorizationStatus()
    guard sessionGeneration == gen, status == .authorized else { return }
    guard currentDeviceId == nil || (lastDeviceToken != nil && lastDeviceToken != registeredToken)
    else { return }
    requestRemoteRegistration()
    if let token = lastDeviceToken {
      await registerDeviceToken(token, expectedGeneration: gen)
    }
  }

  public func registerDeviceToken(_ hexToken: String) async {
    lastDeviceToken = hexToken
    let gen = sessionGeneration
    await registerDeviceToken(hexToken, expectedGeneration: gen)
  }

  private func registerDeviceToken(_ hexToken: String, expectedGeneration: UInt64) async {
    guard !hexToken.isEmpty else { return }
    lastDeviceToken = hexToken
    guard !isRegistering else { return }
    isRegistering = true
    defer {
      if sessionGeneration == expectedGeneration {
        isRegistering = false
      }
    }

    let env: PushRegistrationEnvironment
    #if DEBUG
      env = .sandbox
    #else
      env = .production
    #endif

    while sessionGeneration == expectedGeneration,
      let tokenToRegister = lastDeviceToken,
      !tokenToRegister.isEmpty,
      currentDeviceId == nil || registeredToken != tokenToRegister
    {
      if let deviceId = try? await devicesRepository.registerDevice(
        token: tokenToRegister,
        environment: env
      ), sessionGeneration == expectedGeneration {
        currentDeviceId = deviceId
        registeredToken = tokenToRegister
      } else {
        break
      }
    }
  }

  #if DEBUG
    public func registerDebugDeviceToken(_ token: String) async throws(AppError) -> String {
      let gen = sessionGeneration
      lastDeviceToken = token
      let id = try await devicesRepository.registerDevice(token: token, environment: .sandbox)
      if sessionGeneration == gen {
        currentDeviceId = id
        registeredToken = token
      }
      return id
    }

    public func removeCurrentDevice() async throws(AppError) {
      guard let id = currentDeviceId else { return }
      try await devicesRepository.removeDevice(id: id)
      currentDeviceId = nil
      registeredToken = nil
    }
  #endif

  public func clearSessionState() {
    sessionGeneration &+= 1
    currentDeviceId = nil
    registeredToken = nil
    isPermissionSheetPresented = false
    isRegistering = false
  }

  nonisolated private static func mapAuthorizationStatus(
    _ status: UNAuthorizationStatus
  ) -> AuthorizationStatus {
    switch status {
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
}
