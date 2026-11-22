public enum TransactionType: Sendable, Hashable {
  case expense
  case income
  case transfer
  case unknown(String)

  public init(code: String) {
    switch code {
    case "expense": self = .expense
    case "income": self = .income
    case "transfer": self = .transfer
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .expense: return "expense"
    case .income: return "income"
    case .transfer: return "transfer"
    case .unknown(let raw): return raw
    }
  }
}

public enum TransactionCategory: Sendable, Hashable, CaseIterable {
  case food
  case transport
  case lodging
  case shopping
  case entertainment
  case bills
  case other
  case unknown(String)

  public static var allCases: [TransactionCategory] {
    [.food, .transport, .lodging, .shopping, .entertainment, .bills, .other]
  }

  public init(code: String) {
    switch code {
    case "food": self = .food
    case "transport": self = .transport
    case "lodging": self = .lodging
    case "shopping": self = .shopping
    case "entertainment": self = .entertainment
    case "bills": self = .bills
    case "other": self = .other
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .food: return "food"
    case .transport: return "transport"
    case .lodging: return "lodging"
    case .shopping: return "shopping"
    case .entertainment: return "entertainment"
    case .bills: return "bills"
    case .other: return "other"
    case .unknown(let raw): return raw
    }
  }
}

public enum ExactRemainderMode: Sendable, Hashable {
  case none
  case equalAmongBlank
  case equalAmongAll
  case unknown(String)

  public init(code: String) {
    switch code {
    case "none": self = .none
    case "equal_among_blank": self = .equalAmongBlank
    case "equal_among_all": self = .equalAmongAll
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .none: return "none"
    case .equalAmongBlank: return "equal_among_blank"
    case .equalAmongAll: return "equal_among_all"
    case .unknown(let raw): return raw
    }
  }
}

public enum SplitSpec: Sendable, Hashable {
  public struct ExactEntry: Sendable, Hashable {
    public let memberId: Member.ID
    public let amount: Money
    public init(memberId: Member.ID, amount: Money) {
      self.memberId = memberId
      self.amount = amount
    }
  }

  public struct ShareWeightEntry: Sendable, Hashable {
    public let memberId: Member.ID
    public let weight: String
    public init(memberId: Member.ID, weight: String) {
      self.memberId = memberId
      self.weight = weight
    }
  }

  public struct PercentEntry: Sendable, Hashable {
    public let memberId: Member.ID
    public let percent: String
    public init(memberId: Member.ID, percent: String) {
      self.memberId = memberId
      self.percent = percent
    }
  }

  case equal(members: [Member.ID])
  case exact(members: [Member.ID], entries: [ExactEntry], remainder: ExactRemainderMode)
  case shares(entries: [ShareWeightEntry])
  case percent(entries: [PercentEntry])
}

public struct MemberAmount: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let amount: Money

  public init(memberId: Member.ID, amount: Money) {
    self.memberId = memberId
    self.amount = amount
  }
}

public struct LedgerTransaction: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public struct ActorRef: Sendable, Hashable {
    public let id: User.ID
    public let name: String
    public init(id: User.ID, name: String) {
      self.id = id
      self.name = name
    }
  }

  public let id: ID
  public var type: TransactionType
  public var description: String
  public var amount: Money
  public var currency: String
  public var occurredAt: String
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var payers: [MemberAmount]
  public var split: SplitSpec
  public var shares: [MemberAmount]
  public var version: Int
  public var updatedBy: ActorRef?
  public var createdBy: ActorRef?
  public var createdAt: String
  public var updatedAt: String
  public var deletedAt: String?

  public init(
    id: ID,
    type: TransactionType,
    description: String,
    amount: Money,
    currency: String = "VND",
    occurredAt: String,
    category: TransactionCategory?,
    categoryId: GroupCategory.ID? = nil,
    payers: [MemberAmount],
    split: SplitSpec,
    shares: [MemberAmount],
    version: Int = 1,
    updatedBy: ActorRef? = nil,
    createdBy: ActorRef? = nil,
    createdAt: String = "2026-11-16T14:23:26.466Z",
    updatedAt: String = "2026-11-16T14:23:26.466Z",
    deletedAt: String? = nil
  ) {
    self.id = id
    self.type = type
    self.description = description
    self.amount = amount
    self.currency = currency
    self.occurredAt = occurredAt
    self.category = category
    self.categoryId = categoryId
    self.payers = payers
    self.split = split
    self.shares = shares
    self.version = version
    self.updatedBy = updatedBy
    self.createdBy = createdBy
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.deletedAt = deletedAt
  }
}
