public struct Balance: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let balance: Money

  public init(memberId: Member.ID, balance: Money) {
    self.memberId = memberId
    self.balance = balance
  }
}

public struct SuggestedTransfer: Sendable, Hashable, Identifiable {
  public var id: String { "\(fromMemberId.rawValue)-\(toMemberId.rawValue)-\(amount.amount)" }
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let amount: Money

  public init(fromMemberId: Member.ID, toMemberId: Member.ID, amount: Money) {
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.amount = amount
  }
}

public struct GroupBalances: Sendable, Hashable {
  public let currency: String
  public let minimized: Bool
  public let balances: [Balance]
  public let transfers: [SuggestedTransfer]

  public init(
    currency: String = "VND",
    minimized: Bool = true,
    balances: [Balance],
    transfers: [SuggestedTransfer]
  ) {
    self.currency = currency
    self.minimized = minimized
    self.balances = balances
    self.transfers = transfers
  }
}
