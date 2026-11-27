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

public enum ExtrasAllocation: Sendable, Hashable, Codable {
  case equal
  case proportional
  case unknown(String)

  public init(code: String) {
    switch code {
    case "equal": self = .equal
    case "proportional": self = .proportional
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .equal: return "equal"
    case .proportional: return "proportional"
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

  public struct ItemEntry: Sendable, Hashable {
    public let name: String
    public let amount: Money
    public let memberIds: [Member.ID]

    public init(name: String, amount: Money, memberIds: [Member.ID]) {
      self.name = name
      self.amount = amount
      self.memberIds = memberIds
    }
  }

  public struct ItemsExtra: Sendable, Hashable {
    public let kind: ReceiptExtraKind
    public let label: String
    public let amount: Money
    public let ratePercent: String?

    public init(
      kind: ReceiptExtraKind,
      label: String,
      amount: Money,
      ratePercent: String? = nil
    ) {
      self.kind = kind
      self.label = label
      self.amount = amount
      self.ratePercent = ratePercent
    }
  }

  case equal(
    members: [Member.ID],
    extras: [ItemsExtra] = [],
    extrasAllocation: ExtrasAllocation? = nil
  )
  case exact(
    members: [Member.ID],
    entries: [ExactEntry],
    remainder: ExactRemainderMode,
    extras: [ItemsExtra] = [],
    extrasAllocation: ExtrasAllocation? = nil
  )
  case shares(
    entries: [ShareWeightEntry],
    extras: [ItemsExtra] = [],
    extrasAllocation: ExtrasAllocation? = nil
  )
  case percent(
    entries: [PercentEntry],
    extras: [ItemsExtra] = [],
    extrasAllocation: ExtrasAllocation? = nil
  )
  case items(
    items: [ItemEntry],
    extras: [ItemsExtra],
    extrasAllocation: ExtrasAllocation? = nil
  )

  public var extras: [ItemsExtra] {
    switch self {
    case .equal(_, let extras, _),
      .exact(_, _, _, let extras, _),
      .shares(_, let extras, _),
      .percent(_, let extras, _),
      .items(_, let extras, _):
      return extras
    }
  }

  public var extrasAllocation: ExtrasAllocation? {
    switch self {
    case .equal(_, _, let allocation),
      .exact(_, _, _, _, let allocation),
      .shares(_, _, let allocation),
      .percent(_, _, let allocation),
      .items(_, _, let allocation):
      return allocation
    }
  }

  public func withExtras(
    _ newExtras: [ItemsExtra],
    allocation: ExtrasAllocation?
  ) -> SplitSpec {
    switch self {
    case .equal(let members, _, _):
      return .equal(members: members, extras: newExtras, extrasAllocation: allocation)
    case .exact(let members, let entries, let remainder, _, _):
      return .exact(
        members: members,
        entries: entries,
        remainder: remainder,
        extras: newExtras,
        extrasAllocation: allocation
      )
    case .shares(let entries, _, _):
      return .shares(entries: entries, extras: newExtras, extrasAllocation: allocation)
    case .percent(let entries, _, _):
      return .percent(entries: entries, extras: newExtras, extrasAllocation: allocation)
    case .items(let items, _, _):
      return .items(items: items, extras: newExtras, extrasAllocation: allocation)
    }
  }
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

  public struct TransactionApproval: Sendable, Hashable {
    public enum Status: String, Sendable, Hashable {
      case none
      case pending
      case approved
      case rejected
    }

    public var status: Status
    public var note: String?
    public var decidedByName: String?
    public var decidedAt: String?

    public init(
      status: Status = .none,
      note: String? = nil,
      decidedByName: String? = nil,
      decidedAt: String? = nil
    ) {
      self.status = status
      self.note = note
      self.decidedByName = decidedByName
      self.decidedAt = decidedAt
    }
  }

  public struct TransactionDispute: Sendable, Hashable {
    public struct ID: Sendable, Hashable {
      public let rawValue: String
      public init(_ rawValue: String) { self.rawValue = rawValue }
    }

    public var id: ID
    public var reason: String
    public var openedByName: String
    public var openedAt: String
    public var mine: Bool

    public init(
      id: ID,
      reason: String,
      openedByName: String,
      openedAt: String,
      mine: Bool
    ) {
      self.id = id
      self.reason = reason
      self.openedByName = openedByName
      self.openedAt = openedAt
      self.mine = mine
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
  public var warnings: [TransactionWarning]
  public var attachments: [Attachment]
  public var attachmentCount: Int
  public var firstAttachmentId: Attachment.ID?
  public var approval: TransactionApproval
  public var dispute: TransactionDispute?
  public var commentCount: Int
  public var myDelta: Money?
  public var paymentChannel: PaymentChannel?
  public var paymentNote: String?
  public var cycleId: SettlementCycle.ID?
  public var recurringExpenseId: RecurringExpense.ID?

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
    deletedAt: String? = nil,
    warnings: [TransactionWarning] = [],
    attachments: [Attachment] = [],
    attachmentCount: Int? = nil,
    firstAttachmentId: Attachment.ID? = nil,
    approval: TransactionApproval = .init(),
    dispute: TransactionDispute? = nil,
    commentCount: Int = 0,
    myDelta: Money? = nil,
    paymentChannel: PaymentChannel? = nil,
    paymentNote: String? = nil,
    cycleId: SettlementCycle.ID? = nil,
    recurringExpenseId: RecurringExpense.ID? = nil
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
    self.warnings = warnings
    self.attachments = attachments
    self.attachmentCount = attachmentCount ?? attachments.count
    self.firstAttachmentId = firstAttachmentId ?? attachments.first?.id
    self.approval = approval
    self.dispute = dispute
    self.commentCount = commentCount
    self.myDelta = myDelta
    self.paymentChannel = paymentChannel
    self.paymentNote = paymentNote
    self.cycleId = cycleId
    self.recurringExpenseId = recurringExpenseId
  }
}
