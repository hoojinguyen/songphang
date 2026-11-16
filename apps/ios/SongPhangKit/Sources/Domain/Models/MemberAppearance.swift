public enum MemberShape: Sendable, Hashable, CaseIterable {
  case circle
  case diamond
  case squircle
  case leaf
  case unknown(String)

  public static var allCases: [MemberShape] {
    [.circle, .diamond, .squircle, .leaf]
  }

  public init(code: String) {
    switch code {
    case "circle": self = .circle
    case "diamond": self = .diamond
    case "squircle": self = .squircle
    case "leaf": self = .leaf
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .circle: return "circle"
    case .diamond: return "diamond"
    case .squircle: return "squircle"
    case .leaf: return "leaf"
    case .unknown(let raw): return raw
    }
  }
}

public enum MemberColor: Sendable, Hashable, CaseIterable {
  case mint
  case sky
  case coral
  case lilac
  case unknown(String)

  public static var allCases: [MemberColor] {
    [.mint, .sky, .coral, .lilac]
  }

  public init(code: String) {
    switch code {
    case "mint": self = .mint
    case "sky": self = .sky
    case "coral": self = .coral
    case "lilac": self = .lilac
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .mint: return "mint"
    case .sky: return "sky"
    case .coral: return "coral"
    case .lilac: return "lilac"
    case .unknown(let raw): return raw
    }
  }
}
