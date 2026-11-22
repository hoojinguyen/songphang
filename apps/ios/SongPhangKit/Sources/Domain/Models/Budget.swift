public enum BudgetPeriod: String, Sendable, Hashable, CaseIterable {
  case month
  case total
}

public enum BudgetState: Sendable, Hashable {
  case ok
  case near
  case over
  case unknown(String)

  public init(code: String) {
    switch code {
    case "ok": self = .ok
    case "near": self = .near
    case "over": self = .over
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .ok: return "ok"
    case .near: return "near"
    case .over: return "over"
    case .unknown(let raw): return raw
    }
  }
}

public struct GroupBudget: Sendable, Hashable {
  public let period: BudgetPeriod
  public let amount: Money
  public let spent: Money
  public let state: BudgetState
  public let periodStart: String?
  public let periodEnd: String?

  public init(
    period: BudgetPeriod,
    amount: Money,
    spent: Money,
    state: BudgetState,
    periodStart: String? = nil,
    periodEnd: String? = nil
  ) {
    self.period = period
    self.amount = amount
    self.spent = spent
    self.state = state
    self.periodStart = periodStart
    self.periodEnd = periodEnd
  }
}
