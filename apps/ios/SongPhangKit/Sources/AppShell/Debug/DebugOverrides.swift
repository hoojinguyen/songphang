#if DEBUG
  public import Foundation

  public enum DebugOverrides {
    private enum Keys {
      static let useScripted = "sp.debug.useScripted"
      static let apiBaseURL = "sp.debug.apiBaseURL"
      static let webBaseURL = "sp.debug.webBaseURL"
    }

    public static let environmentDidChangeNotification = Notification.Name(
      "SPDebugEnvironmentDidChange"
    )

    public static var useScripted: Bool {
      get { UserDefaults.standard.bool(forKey: Keys.useScripted) }
      set { UserDefaults.standard.set(newValue, forKey: Keys.useScripted) }
    }

    public static var apiBaseURL: String? {
      get { UserDefaults.standard.string(forKey: Keys.apiBaseURL) }
      set {
        if let newValue, !newValue.isEmpty {
          UserDefaults.standard.set(newValue, forKey: Keys.apiBaseURL)
        } else {
          UserDefaults.standard.removeObject(forKey: Keys.apiBaseURL)
        }
      }
    }

    public static var webBaseURL: String? {
      get { UserDefaults.standard.string(forKey: Keys.webBaseURL) }
      set {
        if let newValue, !newValue.isEmpty {
          UserDefaults.standard.set(newValue, forKey: Keys.webBaseURL)
        } else {
          UserDefaults.standard.removeObject(forKey: Keys.webBaseURL)
        }
      }
    }

    public static func resetURLs() {
      UserDefaults.standard.removeObject(forKey: Keys.apiBaseURL)
      UserDefaults.standard.removeObject(forKey: Keys.webBaseURL)
    }

    public static func notifyEnvironmentDidChange() {
      NotificationCenter.default.post(name: environmentDidChangeNotification, object: nil)
    }
  }
#endif
