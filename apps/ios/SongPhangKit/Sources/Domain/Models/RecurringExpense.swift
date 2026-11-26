public enum RecurringMode: Sendable, Hashable, Codable {
  case fixed
  case variable
  case unknown(String)

  public init(code: String) {
    switch code {
    case "fixed": self = .fixed
    case "variable": self = .variable
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .fixed: return "fixed"
    case .variable: return "variable"
    case .unknown(let raw): return raw
    }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(code: try container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(code)
  }
}

public enum RecurringFrequency: Sendable, Hashable, Codable, CaseIterable {
  case weekly
  case monthly
  case quarterly
  case yearly
  case unknown(String)

  public static var allCases: [RecurringFrequency] {
    [.weekly, .monthly, .quarterly, .yearly]
  }

  public init(code: String) {
    switch code {
    case "weekly": self = .weekly
    case "monthly": self = .monthly
    case "quarterly": self = .quarterly
    case "yearly": self = .yearly
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .weekly: return "weekly"
    case .monthly: return "monthly"
    case .quarterly: return "quarterly"
    case .yearly: return "yearly"
    case .unknown(let raw): return raw
    }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(code: try container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(code)
  }
}

public enum RecurringPauseReason: Sendable, Hashable, Codable {
  case memberInvalid
  case splitInvalid
  case unknown(String)

  public init(code: String) {
    switch code {
    case "member_invalid": self = .memberInvalid
    case "split_invalid": self = .splitInvalid
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .memberInvalid: return "member_invalid"
    case .splitInvalid: return "split_invalid"
    case .unknown(let raw): return raw
    }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(code: try container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(code)
  }
}

public struct RecurringPayerTemplateEntry: Sendable, Hashable {
  public let memberId: Member.ID
  public let amount: Money?

  public init(memberId: Member.ID, amount: Money? = nil) {
    self.memberId = memberId
    self.amount = amount
  }
}

public struct CreateInlineRecurringInput: Sendable, Hashable {
  public var mode: RecurringMode
  public var frequency: RecurringFrequency
  public var dayOfWeek: Int?
  public var dayOfMonth: Int?
  public var monthOfYear: Int?

  public init(
    mode: RecurringMode,
    frequency: RecurringFrequency,
    dayOfWeek: Int? = nil,
    dayOfMonth: Int? = nil,
    monthOfYear: Int? = nil
  ) {
    self.mode = mode
    self.frequency = frequency
    self.dayOfWeek = dayOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
  }
}

public struct RecurringExpense: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let groupId: ExpenseGroup.ID
  public var mode: RecurringMode
  public var active: Bool
  public var description: String
  public var amount: Money?
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var payersTemplate: [RecurringPayerTemplateEntry]
  public var splitTemplate: SplitSpec
  public var frequency: RecurringFrequency
  public var dayOfWeek: Int?
  public var dayOfMonth: Int?
  public var monthOfYear: Int?
  public var nextDueDate: String
  public var pendingDueDate: String?
  public var lastProcessedDueDate: String?
  public var lastPostedAt: String?
  public var lastTransactionId: LedgerTransaction.ID?
  public var pauseReason: RecurringPauseReason?
  public let createdAt: String
  public var updatedAt: String

  public init(
    id: ID,
    groupId: ExpenseGroup.ID,
    mode: RecurringMode,
    active: Bool = true,
    description: String,
    amount: Money? = nil,
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    payersTemplate: [RecurringPayerTemplateEntry],
    splitTemplate: SplitSpec,
    frequency: RecurringFrequency,
    dayOfWeek: Int? = nil,
    dayOfMonth: Int? = nil,
    monthOfYear: Int? = nil,
    nextDueDate: String,
    pendingDueDate: String? = nil,
    lastProcessedDueDate: String? = nil,
    lastPostedAt: String? = nil,
    lastTransactionId: LedgerTransaction.ID? = nil,
    pauseReason: RecurringPauseReason? = nil,
    createdAt: String = "2026-11-26T00:00:00.000Z",
    updatedAt: String = "2026-11-26T00:00:00.000Z"
  ) {
    self.id = id
    self.groupId = groupId
    self.mode = mode
    self.active = active
    self.description = description
    self.amount = amount
    self.category = category
    self.categoryId = categoryId
    self.payersTemplate = payersTemplate
    self.splitTemplate = splitTemplate
    self.frequency = frequency
    self.dayOfWeek = dayOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
    self.nextDueDate = nextDueDate
    self.pendingDueDate = pendingDueDate
    self.lastProcessedDueDate = lastProcessedDueDate
    self.lastPostedAt = lastPostedAt
    self.lastTransactionId = lastTransactionId
    self.pauseReason = pauseReason
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct CreateRecurringExpenseInput: Sendable, Hashable {
  public var mode: RecurringMode
  public var description: String
  public var amount: Money?
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var payersTemplate: [RecurringPayerTemplateEntry]
  public var splitTemplate: SplitSpec
  public var frequency: RecurringFrequency
  public var dayOfWeek: Int?
  public var dayOfMonth: Int?
  public var monthOfYear: Int?

  public init(
    mode: RecurringMode,
    description: String,
    amount: Money? = nil,
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    payersTemplate: [RecurringPayerTemplateEntry],
    splitTemplate: SplitSpec,
    frequency: RecurringFrequency,
    dayOfWeek: Int? = nil,
    dayOfMonth: Int? = nil,
    monthOfYear: Int? = nil
  ) {
    self.mode = mode
    self.description = description
    self.amount = amount
    self.category = categoryId == nil ? category : nil
    self.categoryId = categoryId
    self.payersTemplate = payersTemplate
    self.splitTemplate = splitTemplate
    self.frequency = frequency
    self.dayOfWeek = dayOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
  }
}

public struct UpdateRecurringExpenseInput: Sendable, Hashable {
  public enum NullableValue<Value: Sendable & Hashable>: Sendable, Hashable {
    case unchanged
    case clear
    case set(Value)
  }

  public var mode: RecurringMode?
  public var active: Bool?
  public var description: String?
  public var amount: NullableValue<Money>
  public var category: NullableValue<TransactionCategory>
  public var categoryId: NullableValue<GroupCategory.ID>
  public var payersTemplate: [RecurringPayerTemplateEntry]?
  public var splitTemplate: SplitSpec?
  public var frequency: RecurringFrequency?
  public var dayOfWeek: NullableValue<Int>
  public var dayOfMonth: NullableValue<Int>
  public var monthOfYear: NullableValue<Int>

  public init(
    mode: RecurringMode? = nil,
    active: Bool? = nil,
    description: String? = nil,
    amount: NullableValue<Money> = .unchanged,
    category: NullableValue<TransactionCategory> = .unchanged,
    categoryId: NullableValue<GroupCategory.ID> = .unchanged,
    payersTemplate: [RecurringPayerTemplateEntry]? = nil,
    splitTemplate: SplitSpec? = nil,
    frequency: RecurringFrequency? = nil,
    dayOfWeek: NullableValue<Int> = .unchanged,
    dayOfMonth: NullableValue<Int> = .unchanged,
    monthOfYear: NullableValue<Int> = .unchanged
  ) {
    self.mode = mode
    self.active = active
    self.description = description
    self.amount = amount
    self.category = category
    self.categoryId = categoryId
    self.payersTemplate = payersTemplate
    self.splitTemplate = splitTemplate
    self.frequency = frequency
    self.dayOfWeek = dayOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
  }
}
