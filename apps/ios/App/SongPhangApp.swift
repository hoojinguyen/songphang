import AppShell
import DesignSystem
import SwiftUI
import UIKit
import UserNotifications
import os

final class SongPhangAppDelegate: NSObject, UIApplicationDelegate,
  UNUserNotificationCenterDelegate
{
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  nonisolated func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task { @MainActor in
      PushEventBridge.shared.didRegisterDeviceToken(deviceToken)
    }
  }

  nonisolated func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: any Error
  ) {
    let logger = Logger(subsystem: "vn.songphang.app", category: "Push")
    let nsError = error as NSError
    logger.error(
      "APNs registration failed: \(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
    )
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let groupId = userInfo["groupId"] as? String
    let target = userInfo["target"] as? String
    Task { @MainActor in
      PushEventBridge.shared.didReceiveTap(groupId: groupId, target: target)
    }
    completionHandler()
  }
}

@main
struct SongPhangApp: App {
  @UIApplicationDelegateAdaptor(SongPhangAppDelegate.self) private var appDelegate

  init() {
    Typography.registerFontsIfAvailable()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}
