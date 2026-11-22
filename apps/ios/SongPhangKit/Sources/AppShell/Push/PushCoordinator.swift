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

  private let devicesRepository: any DevicesRepository

  public init(devicesRepository: any DevicesRepository) {
    self.devicesRepository = devicesRepository
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
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    let mapped = Self.mapAuthorizationStatus(settings.authorizationStatus)
    authorizationStatus = mapped
    return mapped
  }

  public func handleFirstExpenseSaved(userId: User.ID, features: ServerFeatures?) async {
    guard features?.push == true else { return }
    guard !hasDeferred(userId: userId) else { return }
    let status = await refreshAuthorizationStatus()
    guard status == .notDetermined else { return }
    isPermissionSheetPresented = true
  }

  public func enableFromPrompt() async {
    isPermissionSheetPresented = false
    _ = await requestPermissionAndRegister()
  }

  public func requestPermissionAndRegister() async -> AuthorizationStatus {
    _ = try? await UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    )
    let status = await refreshAuthorizationStatus()
    if status == .authorized {
      UIApplication.shared.registerForRemoteNotifications()
    }
    return status
  }

  public func registerDeviceToken(_ hexToken: String) async {
    guard !hexToken.isEmpty else { return }
    let env: PushRegistrationEnvironment
    #if DEBUG
      env = .sandbox
    #else
      env = .production
    #endif
    if let deviceId = try? await devicesRepository.registerDevice(token: hexToken, environment: env)
    {
      currentDeviceId = deviceId
    }
  }

  #if DEBUG
    public func registerDebugDeviceToken(_ token: String) async throws(AppError) -> String {
      let id = try await devicesRepository.registerDevice(token: token, environment: .sandbox)
      currentDeviceId = id
      return id
    }

    public func removeCurrentDevice() async throws(AppError) {
      guard let id = currentDeviceId else { return }
      try await devicesRepository.removeDevice(id: id)
      currentDeviceId = nil
    }
  #endif

  public func clearSessionState() {
    currentDeviceId = nil
    isPermissionSheetPresented = false
  }

  private static func mapAuthorizationStatus(
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
