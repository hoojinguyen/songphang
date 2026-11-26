public enum SettlementVaultFilter: String, Sendable, Hashable, CaseIterable {
  case all
  case pending
  case confirmed
  case withProof = "with_proof"
}

public struct SettlementVaultItem: Sendable, Hashable, Identifiable {
  public enum Kind: Sendable, Hashable {
    case transfer
    case request
    case unknown(String)

    public init(code: String) {
      switch code {
      case "transfer": self = .transfer
      case "request": self = .request
      default: self = .unknown(code)
      }
    }

    public var code: String {
      switch self {
      case .transfer: return "transfer"
      case .request: return "request"
      case .unknown(let raw): return raw
      }
    }
  }

  public let id: String
  public let kind: Kind
  public let status: SettlementRequestStatus
  public let transactionId: LedgerTransaction.ID?
  public let settlementRequestId: String?
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let amount: Money
  public let channel: PaymentChannel?
  public let note: String?
  public let description: String?
  public let attachments: [Attachment]
  public let createdBy: LedgerTransaction.ActorRef?
  public let resolvedBy: LedgerTransaction.ActorRef?
  public let occurredAt: String
  public let resolvedAt: String?
  public let cycleId: SettlementCycle.ID?

  public init(
    id: String,
    kind: Kind,
    status: SettlementRequestStatus,
    transactionId: LedgerTransaction.ID? = nil,
    settlementRequestId: String? = nil,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    amount: Money,
    channel: PaymentChannel? = nil,
    note: String? = nil,
    description: String? = nil,
    attachments: [Attachment] = [],
    createdBy: LedgerTransaction.ActorRef? = nil,
    resolvedBy: LedgerTransaction.ActorRef? = nil,
    occurredAt: String,
    resolvedAt: String? = nil,
    cycleId: SettlementCycle.ID? = nil
  ) {
    self.id = id
    self.kind = kind
    self.status = status
    self.transactionId = transactionId
    self.settlementRequestId = settlementRequestId
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.amount = amount
    self.channel = channel
    self.note = note
    self.description = description
    self.attachments = attachments
    self.createdBy = createdBy
    self.resolvedBy = resolvedBy
    self.occurredAt = occurredAt
    self.resolvedAt = resolvedAt
    self.cycleId = cycleId
  }
}

public struct SettlementVaultSummary: Sendable, Hashable {
  public let pendingCount: Int
  public let confirmedCount: Int
  public let confirmedTotalAmount: Money
  public let proofCount: Int

  public init(
    pendingCount: Int,
    confirmedCount: Int,
    confirmedTotalAmount: Money,
    proofCount: Int
  ) {
    self.pendingCount = pendingCount
    self.confirmedCount = confirmedCount
    self.confirmedTotalAmount = confirmedTotalAmount
    self.proofCount = proofCount
  }
}

public struct SettlementVaultPage: Sendable, Hashable {
  public let items: [SettlementVaultItem]
  public let summary: SettlementVaultSummary
  public let nextCursor: String?

  public init(
    items: [SettlementVaultItem],
    summary: SettlementVaultSummary,
    nextCursor: String? = nil
  ) {
    self.items = items
    self.summary = summary
    self.nextCursor = nextCursor
  }
}
