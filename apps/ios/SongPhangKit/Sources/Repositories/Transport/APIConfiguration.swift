public import Foundation

public struct APIConfiguration: Sendable, Hashable {
  public let apiBaseURL: URL
  public let webBaseURL: URL
  public let appVersion: String
  public let deviceName: String

  public init(
    apiBaseURL: URL,
    webBaseURL: URL,
    appVersion: String,
    deviceName: String
  ) {
    self.apiBaseURL = apiBaseURL
    self.webBaseURL = webBaseURL
    self.appVersion = appVersion
    self.deviceName = deviceName
  }

  /// Server origin passed to the generated OpenAPI client so `/api/v1/...` paths
  /// are composed exactly once regardless of whether `apiBaseURL` ends in `/api/v1`.
  public var serverOriginURL: URL {
    guard var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false) else {
      return apiBaseURL
    }
    var trimmedPath = components.path
    while trimmedPath.hasSuffix("/") {
      trimmedPath.removeLast()
    }
    if trimmedPath.hasSuffix("/api/v1") {
      trimmedPath.removeLast("/api/v1".count)
    }
    components.path = trimmedPath
    return components.url ?? apiBaseURL
  }

  public func v1URL(path: String) -> URL {
    let normalized = path.hasPrefix("/") ? path : "/\(path)"
    let base = serverOriginURL.absoluteString.trimmingCharacters(
      in: CharacterSet(charactersIn: "/"))
    return URL(string: "\(base)/api/v1\(normalized)") ?? apiBaseURL
  }
}
