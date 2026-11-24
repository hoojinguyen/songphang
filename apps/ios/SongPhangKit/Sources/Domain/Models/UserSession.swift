public struct UserSession: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public enum Client: Sendable, Hashable {
    case web
    case ios
    case android
    case unknown(String)

    public init(code: String) {
      switch code {
      case "web": self = .web
      case "ios": self = .ios
      case "android": self = .android
      default: self = .unknown(code)
      }
    }

    public var code: String {
      switch self {
      case .web: return "web"
      case .ios: return "ios"
      case .android: return "android"
      case .unknown(let raw): return raw
      }
    }
  }

  public let id: ID
  public let client: Client
  public let deviceName: String?
  public let createdAt: String
  public let lastSeenAt: String
  public let current: Bool

  public init(
    id: ID,
    client: Client,
    deviceName: String?,
    createdAt: String,
    lastSeenAt: String,
    current: Bool
  ) {
    self.id = id
    self.client = client
    self.deviceName = deviceName
    self.createdAt = createdAt
    self.lastSeenAt = lastSeenAt
    self.current = current
  }
}
