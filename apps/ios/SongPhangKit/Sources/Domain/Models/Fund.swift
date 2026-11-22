public struct FundContribution: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let amount: Money

  public init(memberId: Member.ID, amount: Money) {
    self.memberId = memberId
    self.amount = amount
  }
}

public struct FundSummary: Sendable, Hashable {
  public let memberId: Member.ID
  public let name: String
  public let holderMemberId: Member.ID?
  public let active: Bool
  public let cash: Money
  public let contributions: [FundContribution]

  public init(
    memberId: Member.ID,
    name: String,
    holderMemberId: Member.ID?,
    active: Bool,
    cash: Money,
    contributions: [FundContribution]
  ) {
    self.memberId = memberId
    self.name = name
    self.holderMemberId = holderMemberId
    self.active = active
    self.cash = cash
    self.contributions = contributions
  }
}

public enum TransactionWarning: Sendable, Hashable {
  case fundOverdrawn
  case budgetNear
  case budgetOver
  case unknown(String)

  public init(code: String) {
    switch code {
    case "FUND_OVERDRAWN": self = .fundOverdrawn
    case "BUDGET_NEAR": self = .budgetNear
    case "BUDGET_OVER": self = .budgetOver
    default: self = .unknown(code)
    }
  }
}
