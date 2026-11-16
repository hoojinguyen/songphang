public enum Role: Sendable, Hashable {
  case owner
  case editor
  case viewer
  case unknown(String)

  public init(code: String) {
    switch code {
    case "owner": self = .owner
    case "editor": self = .editor
    case "viewer": self = .viewer
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .owner: return "owner"
    case .editor: return "editor"
    case .viewer: return "viewer"
    case .unknown(let raw): return raw
    }
  }

  public var canWrite: Bool {
    switch self {
    case .owner, .editor:
      return true
    case .viewer, .unknown:
      return false
    }
  }

  public var isOwner: Bool {
    self == .owner
  }
}
