public enum MemberKind: Sendable, Hashable {
  case person
  case fund
  case unknown(String)

  public init(code: String) {
    switch code {
    case "person": self = .person
    case "fund": self = .fund
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .person: return "person"
    case .fund: return "fund"
    case .unknown(let raw): return raw
    }
  }
}

public struct Member: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public var name: String
  public var kind: MemberKind
  public var fundHolderMemberId: Member.ID?
  public var active: Bool
  public var defaultWeight: String
  public var position: Int
  public var shape: MemberShape
  public var color: MemberColor
  public var isMe: Bool
  public var claimed: Bool
  public var paymentMethods: [PaymentMethod]

  public init(
    id: ID,
    name: String,
    kind: MemberKind = .person,
    fundHolderMemberId: Member.ID? = nil,
    active: Bool = true,
    defaultWeight: String = "1.00",
    position: Int,
    shape: MemberShape,
    color: MemberColor,
    isMe: Bool,
    claimed: Bool,
    paymentMethods: [PaymentMethod] = []
  ) {
    self.id = id
    self.name = name
    self.kind = kind
    self.fundHolderMemberId = fundHolderMemberId
    self.active = active
    self.defaultWeight = defaultWeight
    self.position = position
    self.shape = shape
    self.color = color
    self.isMe = isMe
    self.claimed = claimed
    self.paymentMethods = paymentMethods
  }
}

public struct GroupUser: Sendable, Hashable, Identifiable {
  public var id: User.ID { userId }
  public let userId: User.ID
  public var name: String
  public var role: Role
  public var memberId: Member.ID?
  public var isMe: Bool

  public init(
    userId: User.ID,
    name: String,
    role: Role,
    memberId: Member.ID?,
    isMe: Bool
  ) {
    self.userId = userId
    self.name = name
    self.role = role
    self.memberId = memberId
    self.isMe = isMe
  }
}
