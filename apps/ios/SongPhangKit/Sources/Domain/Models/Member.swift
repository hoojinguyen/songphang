public struct Member: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public var name: String
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
