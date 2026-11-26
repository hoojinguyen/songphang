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
  public let fromHousehold: HouseholdTransferRef?
  public let toHousehold: HouseholdTransferRef?
  public let amount: Money
  public let paymentMethods: [PaymentMethod]
  public let purpose: String?
  public let pendingSettlement: PendingSettlement?

  public init(
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    fromHousehold: HouseholdTransferRef? = nil,
    toHousehold: HouseholdTransferRef? = nil,
    amount: Money,
    paymentMethods: [PaymentMethod] = [],
    purpose: String? = nil,
    pendingSettlement: PendingSettlement? = nil
  ) {
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.fromHousehold = fromHousehold
    self.toHousehold = toHousehold
    self.amount = amount
    self.paymentMethods = paymentMethods
    self.purpose = purpose
    self.pendingSettlement = pendingSettlement
  }
}

public struct GroupBalances: Sendable, Hashable {
  public let currency: String
  public let minimized: Bool
  public let balances: [Balance]
  public let households: [HouseholdBalance]
  public let transfers: [SuggestedTransfer]
  public let fund: FundSummary?

  public init(
    currency: String = "VND",
    minimized: Bool = true,
    balances: [Balance],
    households: [HouseholdBalance] = [],
    transfers: [SuggestedTransfer],
    fund: FundSummary? = nil
  ) {
    self.currency = currency
    self.minimized = minimized
    self.balances = balances
    self.households = households
    self.transfers = transfers
    self.fund = fund
  }
}
