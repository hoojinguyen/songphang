import Foundation

public struct Attachment: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let contentType: String
  public let byteSize: Int
  public let transactionId: LedgerTransaction.ID?
  public let createdAt: String

  public init(
    id: ID,
    contentType: String,
    byteSize: Int,
    transactionId: LedgerTransaction.ID? = nil,
    createdAt: String = "2026-11-16T14:23:26.466Z"
  ) {
    self.id = id
    self.contentType = contentType
    self.byteSize = byteSize
    self.transactionId = transactionId
    self.createdAt = createdAt
  }
}

public enum ReceiptExtraKind: Sendable, Hashable, CaseIterable {
  case tax
  case service
  case shipping
  case discount
  case other
  case unknown(String)

  public static var allCases: [ReceiptExtraKind] {
    [.tax, .service, .shipping, .discount, .other]
  }

  public init(code: String) {
    switch code {
    case "tax": self = .tax
    case "service": self = .service
    case "shipping": self = .shipping
    case "discount": self = .discount
    case "other": self = .other
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .tax: return "tax"
    case .service: return "service"
    case .shipping: return "shipping"
    case .discount: return "discount"
    case .other: return "other"
    case .unknown(let raw): return raw
    }
  }
}

public struct ReceiptItem: Sendable, Hashable {
  public let name: String
  public let quantity: Int
  public let amount: Money

  public init(name: String, quantity: Int, amount: Money) {
    self.name = name
    self.quantity = quantity
    self.amount = amount
  }
}

public struct ReceiptExtra: Sendable, Hashable {
  public let kind: ReceiptExtraKind
  public let label: String
  public let amount: Money

  public init(kind: ReceiptExtraKind, label: String, amount: Money) {
    self.kind = kind
    self.label = label
    self.amount = amount
  }
}

public struct ReceiptReading: Sendable, Hashable {
  public let merchant: String?
  public let occurredOn: String?
  public let items: [ReceiptItem]
  public let extras: [ReceiptExtra]
  public let total: Money?

  public init(
    merchant: String?,
    occurredOn: String?,
    items: [ReceiptItem],
    extras: [ReceiptExtra],
    total: Money?
  ) {
    self.merchant = merchant
    self.occurredOn = occurredOn
    self.items = items
    self.extras = extras
    self.total = total
  }
}

public enum ReceiptFlag: Sendable, Hashable {
  case totalMismatch
  case totalMissing
  case noItems
  case unknown(String)

  public init(code: String) {
    switch code {
    case "TOTAL_MISMATCH": self = .totalMismatch
    case "TOTAL_MISSING": self = .totalMissing
    case "NO_ITEMS": self = .noItems
    default: self = .unknown(code)
    }
  }
}

public enum ReceiptScanStatus: Sendable, Hashable {
  case queued
  case processing
  case done
  case failed
  case unknown(String)

  public init(code: String) {
    switch code {
    case "queued": self = .queued
    case "processing": self = .processing
    case "done": self = .done
    case "failed": self = .failed
    default: self = .unknown(code)
    }
  }
}

public struct ReceiptScan: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let attachmentId: Attachment.ID
  public let status: ReceiptScanStatus
  public let reading: ReceiptReading?
  public let computed: Money?
  public let flags: [ReceiptFlag]
  public let errorCode: String?
  public let createdAt: String

  public init(
    id: ID,
    attachmentId: Attachment.ID,
    status: ReceiptScanStatus,
    reading: ReceiptReading?,
    computed: Money?,
    flags: [ReceiptFlag],
    errorCode: String?,
    createdAt: String
  ) {
    self.id = id
    self.attachmentId = attachmentId
    self.status = status
    self.reading = reading
    self.computed = computed
    self.flags = flags
    self.errorCode = errorCode
    self.createdAt = createdAt
  }
}

public enum ItemsSplitIssueCode: Sendable, Hashable {
  case itemUnassigned
  case invalidTotal
  case unknown(String)

  public init(code: String) {
    switch code {
    case "ITEM_UNASSIGNED": self = .itemUnassigned
    case "INVALID_TOTAL": self = .invalidTotal
    default: self = .unknown(code)
    }
  }
}

public struct ItemsSplitIssue: Sendable, Hashable {
  public let code: ItemsSplitIssueCode
  public let itemIndex: Int?

  public init(code: ItemsSplitIssueCode, itemIndex: Int? = nil) {
    self.code = code
    self.itemIndex = itemIndex
  }
}

public struct TargetAdjustment: Sendable, Hashable {
  public let kind: ReceiptExtraKind
  public let amount: Money

  public init(kind: ReceiptExtraKind, amount: Money) {
    self.kind = kind
    self.amount = amount
  }
}

public struct ItemsPreview: Sendable, Hashable {
  public let computedAmount: Money
  public let shares: [MemberAmount]
  public let issues: [ItemsSplitIssue]
  public let targetAdjustment: TargetAdjustment?

  public init(
    computedAmount: Money,
    shares: [MemberAmount],
    issues: [ItemsSplitIssue],
    targetAdjustment: TargetAdjustment?
  ) {
    self.computedAmount = computedAmount
    self.shares = shares
    self.issues = issues
    self.targetAdjustment = targetAdjustment
  }
}
