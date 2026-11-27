public struct ActivityItem: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public struct Actor: Sendable, Hashable {
    public let userId: User.ID
    public let name: String
    public let memberId: Member.ID?

    public init(userId: User.ID, name: String, memberId: Member.ID?) {
      self.userId = userId
      self.name = name
      self.memberId = memberId
    }
  }

  public enum EntityType: Sendable, Hashable {
    case transaction
    case member
    case group
    case groupUser
    case household
    case recurringExpense
    case unknown(String)

    public init(code: String) {
      switch code {
      case "transaction": self = .transaction
      case "member": self = .member
      case "group": self = .group
      case "group_user": self = .groupUser
      case "household": self = .household
      case "recurring_expense": self = .recurringExpense
      default: self = .unknown(code)
      }
    }
  }

  public struct SnapshotValues: Sendable, Hashable {
    public var transactionType: TransactionType?
    public var amount: Money?
    public var description: String?
    public var occurredAt: String?
    public var category: TransactionCategory?
    public var payers: [MemberAmount]?
    public var shares: [MemberAmount]?
    public var split: SplitSpec?
    public var name: String?
    public var defaultWeight: String?
    public var active: Bool?
    public var role: Role?
    public var defaultRole: Role?
    public var minimizeDebts: Bool?
    public var inviteActive: Bool?
    public var inviteRotated: Bool?
    public var memberCount: Int?

    public init(
      transactionType: TransactionType? = nil,
      amount: Money? = nil,
      description: String? = nil,
      occurredAt: String? = nil,
      category: TransactionCategory? = nil,
      payers: [MemberAmount]? = nil,
      shares: [MemberAmount]? = nil,
      split: SplitSpec? = nil,
      name: String? = nil,
      defaultWeight: String? = nil,
      active: Bool? = nil,
      role: Role? = nil,
      defaultRole: Role? = nil,
      minimizeDebts: Bool? = nil,
      inviteActive: Bool? = nil,
      inviteRotated: Bool? = nil,
      memberCount: Int? = nil
    ) {
      self.transactionType = transactionType
      self.amount = amount
      self.description = description
      self.occurredAt = occurredAt
      self.category = category
      self.payers = payers
      self.shares = shares
      self.split = split
      self.name = name
      self.defaultWeight = defaultWeight
      self.active = active
      self.role = role
      self.defaultRole = defaultRole
      self.minimizeDebts = minimizeDebts
      self.inviteActive = inviteActive
      self.inviteRotated = inviteRotated
      self.memberCount = memberCount
    }
  }

  public let id: ID
  public let actor: Actor?
  public let action: String
  public let entityType: EntityType
  public let entityId: String?
  public let summary: String
  public let before: SnapshotValues?
  public let after: SnapshotValues?
  public let createdAt: String
  public var canRestore: Bool

  public init(
    id: ID,
    actor: Actor?,
    action: String,
    entityType: EntityType,
    entityId: String?,
    summary: String,
    before: SnapshotValues? = nil,
    after: SnapshotValues? = nil,
    createdAt: String,
    canRestore: Bool
  ) {
    self.id = id
    self.actor = actor
    self.action = action
    self.entityType = entityType
    self.entityId = entityId
    self.summary = summary
    self.before = before
    self.after = after
    self.createdAt = createdAt
    self.canRestore = canRestore
  }
}
