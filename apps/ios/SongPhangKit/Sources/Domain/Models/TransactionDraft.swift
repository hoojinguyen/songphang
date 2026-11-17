public enum TransactionDraft: Sendable, Hashable {
  public struct SplitPayload: Sendable, Hashable {
    public var isIncome: Bool
    public var description: String
    public var amount: Money
    public var occurredAt: String
    public var category: TransactionCategory?
    public var payers: [MemberAmount]
    public var split: SplitSpec

    public init(
      isIncome: Bool = false,
      description: String,
      amount: Money,
      occurredAt: String,
      category: TransactionCategory? = nil,
      payers: [MemberAmount],
      split: SplitSpec
    ) {
      self.isIncome = isIncome
      self.description = description
      self.amount = amount
      self.occurredAt = occurredAt
      self.category = category
      self.payers = payers
      self.split = split
    }
  }

  public struct TransferPayload: Sendable, Hashable {
    public var amount: Money
    public var occurredAt: String
    public var fromMemberId: Member.ID
    public var toMemberId: Member.ID
    public var description: String?

    public init(
      amount: Money,
      occurredAt: String,
      fromMemberId: Member.ID,
      toMemberId: Member.ID,
      description: String? = nil
    ) {
      self.amount = amount
      self.occurredAt = occurredAt
      self.fromMemberId = fromMemberId
      self.toMemberId = toMemberId
      self.description = description
    }
  }

  case split(SplitPayload)
  case transfer(TransferPayload)
}
