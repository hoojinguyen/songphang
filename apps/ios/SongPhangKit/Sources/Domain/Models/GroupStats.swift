public enum StatsPeriod: String, Sendable, Hashable, CaseIterable {
  case all
  case thisMonth
  case lastMonth
  case custom
}

public enum StatsBucket: Sendable, Hashable {
  case day
  case week
  case month
  case unknown(String)

  public init(code: String) {
    switch code {
    case "day": self = .day
    case "week": self = .week
    case "month": self = .month
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .day: return "day"
    case .week: return "week"
    case .month: return "month"
    case .unknown(let raw): return raw
    }
  }
}

public struct CategoryStat: Sendable, Hashable, Identifiable {
  public let category: TransactionCategory?
  public let categoryId: GroupCategory.ID?
  public let amount: Money

  public var id: String {
    if let categoryId {
      return "custom-\(categoryId.rawValue)"
    }
    if let category {
      return "builtin-\(category.code)"
    }
    return "_uncategorized"
  }

  public init(
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    amount: Money
  ) {
    self.category = category
    self.categoryId = categoryId
    self.amount = amount
  }
}

public struct MemberStat: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let paid: Money
  public let share: Money

  public init(memberId: Member.ID, paid: Money, share: Money) {
    self.memberId = memberId
    self.paid = paid
    self.share = share
  }
}

public struct TimeBucketStat: Sendable, Hashable, Identifiable {
  public var id: String { start }
  public let start: String
  public let amount: Money

  public init(start: String, amount: Money) {
    self.start = start
    self.amount = amount
  }
}

public struct GroupStats: Sendable, Hashable {
  public let from: String
  public let to: String
  public let bucket: StatsBucket
  public let total: Money
  public let byCategory: [CategoryStat]
  public let byMember: [MemberStat]
  public let byBucket: [TimeBucketStat]

  public init(
    from: String,
    to: String,
    bucket: StatsBucket,
    total: Money,
    byCategory: [CategoryStat],
    byMember: [MemberStat],
    byBucket: [TimeBucketStat]
  ) {
    self.from = from
    self.to = to
    self.bucket = bucket
    self.total = total
    self.byCategory = byCategory
    self.byMember = byMember
    self.byBucket = byBucket
  }
}
