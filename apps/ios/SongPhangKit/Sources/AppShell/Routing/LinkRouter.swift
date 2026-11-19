public import Foundation

public struct LinkRouter: Sendable, Hashable {
  public let webBaseURL: URL
  private let requireHTTPS: Bool

  public init(webBaseURL: URL, requireHTTPS: Bool? = nil) {
    self.webBaseURL = webBaseURL
    if let requireHTTPS {
      self.requireHTTPS = requireHTTPS
    } else {
      #if DEBUG
        self.requireHTTPS = false
      #else
        self.requireHTTPS = true
      #endif
    }
  }

  public func route(for url: URL) -> Route? {
    guard let expected = URLComponents(url: webBaseURL, resolvingAgainstBaseURL: false),
      let actual = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let expectedScheme = expected.scheme?.lowercased(),
      let actualScheme = actual.scheme?.lowercased(),
      let expectedHost = expected.host?.lowercased(),
      let actualHost = actual.host?.lowercased()
    else {
      return nil
    }

    if requireHTTPS && actualScheme != "https" {
      return nil
    }
    guard actualScheme == expectedScheme,
      actualHost == expectedHost,
      Self.effectivePort(for: actual, scheme: actualScheme)
        == Self.effectivePort(for: expected, scheme: expectedScheme)
    else {
      return nil
    }

    let rawPath = actual.percentEncodedPath
    guard !rawPath.contains("..") else { return nil }
    let segments = rawPath.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

    guard segments.count == 2, segments[0] == "join" else {
      return nil
    }
    let token = segments[1]
    guard Self.isValidInviteToken(token) else {
      return nil
    }
    return .joinGroup(token: token)
  }

  private static func effectivePort(for components: URLComponents, scheme: String) -> Int? {
    if let port = components.port {
      return port
    }
    switch scheme {
    case "https": return 443
    case "http": return 80
    default: return nil
    }
  }

  private static func isValidInviteToken(_ token: String) -> Bool {
    guard !token.isEmpty, token.count <= 128 else { return false }
    return token.unicodeScalars.allSatisfy { scalar in
      (scalar >= "A" && scalar <= "Z")
        || (scalar >= "a" && scalar <= "z")
        || (scalar >= "0" && scalar <= "9")
        || scalar == "-"
        || scalar == "_"
    }
  }
}
