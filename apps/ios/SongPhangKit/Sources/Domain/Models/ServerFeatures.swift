import Foundation

public struct SemanticVersion: Sendable, Hashable, Comparable {
  public let major: Int
  public let minor: Int
  public let patch: Int

  public init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  public init?(string: String) {
    let parts = string.trimmingCharacters(in: .whitespacesAndNewlines).split(
      separator: ".",
      omittingEmptySubsequences: false
    )
    guard parts.count == 3,
      let major = Int(parts[0]), major >= 0,
      let minor = Int(parts[1]), minor >= 0,
      let patch = Int(parts[2]), patch >= 0,
      parts.allSatisfy({ part in
        !part.isEmpty && part.allSatisfy(\.isASCII) && part.allSatisfy(\.isNumber)
      })
    else {
      return nil
    }
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    return lhs.patch < rhs.patch
  }

  public static func isBuild(_ build: String, belowMinimum minimum: String) -> Bool {
    guard let buildVersion = SemanticVersion(string: build),
      let minVersion = SemanticVersion(string: minimum)
    else {
      return false
    }
    return buildVersion < minVersion
  }
}

public struct ServerFeatures: Sendable, Hashable {
  public struct MinAppVersion: Sendable, Hashable {
    public let ios: String
    public let android: String

    public init(ios: String = "0.0.0", android: String = "0.0.0") {
      self.ios = ios
      self.android = android
    }
  }

  public let google: Bool
  public let apple: Bool
  public let devLogin: Bool
  public let push: Bool
  public let receiptReading: Bool
  public let sentenceAi: Bool
  public let telegram: Bool
  public let minAppVersion: MinAppVersion

  public init(
    google: Bool = true,
    apple: Bool = true,
    devLogin: Bool = false,
    push: Bool = false,
    receiptReading: Bool = false,
    sentenceAi: Bool = false,
    telegram: Bool = false,
    minAppVersion: MinAppVersion = MinAppVersion()
  ) {
    self.google = google
    self.apple = apple
    self.devLogin = devLogin
    self.push = push
    self.receiptReading = receiptReading
    self.sentenceAi = sentenceAi
    self.telegram = telegram
    self.minAppVersion = minAppVersion
  }
}
