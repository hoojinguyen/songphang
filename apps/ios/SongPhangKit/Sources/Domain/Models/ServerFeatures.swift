public struct ServerFeatures: Sendable, Hashable {
  public struct MinAppVersion: Sendable, Hashable {
    public let ios: String
    public let android: String

    public init(ios: String = "1.0.0", android: String = "1.0.0") {
      self.ios = ios
      self.android = android
    }
  }

  public let google: Bool
  public let apple: Bool
  public let devLogin: Bool
  public let minAppVersion: MinAppVersion

  public init(
    google: Bool = true,
    apple: Bool = true,
    devLogin: Bool = false,
    minAppVersion: MinAppVersion = MinAppVersion()
  ) {
    self.google = google
    self.apple = apple
    self.devLogin = devLogin
    self.minAppVersion = minAppVersion
  }
}
