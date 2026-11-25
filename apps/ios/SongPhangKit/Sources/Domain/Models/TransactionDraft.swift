public enum TransactionDraft: Sendable, Hashable {
  public struct SplitPayload: Sendable, Hashable {
    public var isIncome: Bool
    public var description: String
    public var amount: Money
    public var occurredAt: String
    public var category: TransactionCategory?
    public var categoryId: GroupCategory.ID?
    public var payers: [MemberAmount]
    public var split: SplitSpec
    public var attachmentIds: [Attachment.ID]?

    public init(
      isIncome: Bool = false,
      description: String,
      amount: Money,
      occurredAt: String,
      category: TransactionCategory? = nil,
      categoryId: GroupCategory.ID? = nil,
      payers: [MemberAmount],
      split: SplitSpec,
      attachmentIds: [Attachment.ID]? = nil
    ) {
      self.isIncome = isIncome
      self.description = description
      self.amount = amount
      self.occurredAt = occurredAt
      self.category = categoryId == nil ? category : nil
      self.categoryId = categoryId
      self.payers = payers
      self.split = split
      self.attachmentIds = attachmentIds
    }
  }

  public struct TransferPayload: Sendable, Hashable {
    public var amount: Money
    public var occurredAt: String
    public var fromMemberId: Member.ID
    public var toMemberId: Member.ID
    public var description: String?
    public var attachmentIds: [Attachment.ID]?
    public var paymentChannel: PaymentChannel?
    public var paymentNote: String?

    public init(
      amount: Money,
      occurredAt: String,
      fromMemberId: Member.ID,
      toMemberId: Member.ID,
      description: String? = nil,
      attachmentIds: [Attachment.ID]? = nil,
      paymentChannel: PaymentChannel? = nil,
      paymentNote: String? = nil
    ) {
      self.amount = amount
      self.occurredAt = occurredAt
      self.fromMemberId = fromMemberId
      self.toMemberId = toMemberId
      self.description = description
      self.attachmentIds = attachmentIds
      self.paymentChannel = paymentChannel
      self.paymentNote = paymentNote
    }
  }

  case split(SplitPayload)
  case transfer(TransferPayload)
}
