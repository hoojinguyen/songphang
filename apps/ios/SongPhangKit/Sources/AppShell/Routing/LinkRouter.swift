public import Domain
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

  public enum PushDestination: Hashable, Sendable {
    case groupFeed(groupId: ExpenseGroup.ID)
    case groupBalances(groupId: ExpenseGroup.ID)
  }

  public func pushDestination(groupId: String?, target: String?) -> PushDestination? {
    guard let groupId,
      UUID(uuidString: groupId) != nil,
      let target,
      !target.isEmpty,
      !target.contains(".."),
      !target.contains("?"),
      !target.contains("#")
    else {
      return nil
    }

    let expectedPrefix = "/g/\(groupId)"
    guard target == expectedPrefix || target.hasPrefix("\(expectedPrefix)/") else {
      return nil
    }

    let segments = target.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    guard segments.count >= 2, segments[0] == "g", segments[1] == groupId else {
      return nil
    }

    let id = ExpenseGroup.ID(groupId)
    if segments.count == 2 {
      return .groupFeed(groupId: id)
    }
    if segments.count == 3 {
      switch segments[2] {
      case "balances":
        return .groupBalances(groupId: id)
      case "stats":
        // Stats detail destination arrives in Stage 5D; land on the authorized feed during 5C.
        return .groupFeed(groupId: id)
      default:
        return nil
      }
    }
    if segments.count == 5,
      segments[2] == "tx",
      UUID(uuidString: segments[3]) != nil,
      segments[4] == "view"
    {
      // Transaction detail (S20) arrives in Stage 5D; land on the authorized feed during 5C.
      return .groupFeed(groupId: id)
    }
    return nil
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

public struct PendingInviteState: Sendable, Equatable {
  public private(set) var pendingRoute: Route?

  public init(pendingRoute: Route? = nil) {
    self.pendingRoute = pendingRoute
  }

  public mutating func receive(url: URL, router: LinkRouter, isSignedIn: Bool) -> Route? {
    guard let route = router.route(for: url) else {
      return nil
    }
    return receiveValidated(route, isSignedIn: isSignedIn)
  }

  public mutating func receiveValidated(_ route: Route, isSignedIn: Bool) -> Route? {
    if isSignedIn {
      pendingRoute = nil
      return route
    }
    pendingRoute = route
    return nil
  }

  public mutating func consumeIfSignedIn(_ isSignedIn: Bool) -> Route? {
    guard isSignedIn, let route = pendingRoute else {
      return nil
    }
    pendingRoute = nil
    return route
  }

  public mutating func clear() {
    pendingRoute = nil
  }
}
