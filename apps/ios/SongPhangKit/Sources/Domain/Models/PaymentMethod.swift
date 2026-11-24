public enum PaymentMethod: Sendable, Hashable {
  case bank(BankPayment)
  case momo(phone: String)
  case zalopay(phone: String)
}

public struct BankPayment: Sendable, Hashable {
  public let bin: String
  public let name: String
  public let accountNumber: String
  public let accountName: String
  public let qrPayload: String?

  public init(
    bin: String,
    name: String,
    accountNumber: String,
    accountName: String,
    qrPayload: String? = nil
  ) {
    self.bin = bin
    self.name = name
    self.accountNumber = accountNumber
    self.accountName = accountName
    self.qrPayload = qrPayload
  }
}

public struct PendingSettlement: Sendable, Hashable {
  public let id: String
  public let amount: Money
  public let createdByMe: Bool

  public init(id: String, amount: Money, createdByMe: Bool) {
    self.id = id
    self.amount = amount
    self.createdByMe = createdByMe
  }
}

public enum SettlementRequestStatus: Sendable, Hashable {
  case pending
  case confirmed
  case rejected
  case cancelled
  case unknown(String)

  public init(code: String) {
    switch code {
    case "pending": self = .pending
    case "confirmed": self = .confirmed
    case "rejected": self = .rejected
    case "cancelled": self = .cancelled
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .pending: "pending"
    case .confirmed: "confirmed"
    case .rejected: "rejected"
    case .cancelled: "cancelled"
    case .unknown(let code): code
    }
  }
}

public struct SettlementRequest: Sendable, Hashable, Identifiable {
  public let id: String
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let amount: Money
  public let status: SettlementRequestStatus
  public let transactionId: LedgerTransaction.ID?
  public let createdByUserId: User.ID?
  public let createdByName: String?
  public let createdAt: String
  public let resolvedAt: String?

  public init(
    id: String,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    amount: Money,
    status: SettlementRequestStatus,
    transactionId: LedgerTransaction.ID? = nil,
    createdByUserId: User.ID? = nil,
    createdByName: String? = nil,
    createdAt: String,
    resolvedAt: String? = nil
  ) {
    self.id = id
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.amount = amount
    self.status = status
    self.transactionId = transactionId
    self.createdByUserId = createdByUserId
    self.createdByName = createdByName
    self.createdAt = createdAt
    self.resolvedAt = resolvedAt
  }
}
