public import Foundation

public struct SharePreview: Sendable, Hashable {
  public let shares: [MemberAmount]
  public let warnings: [TransactionWarning]

  public init(shares: [MemberAmount], warnings: [TransactionWarning] = []) {
    self.shares = shares
    self.warnings = warnings
  }
}

public struct PreviewExtrasItem: Sendable, Hashable {
  public var kind: ReceiptExtraKind
  public var label: String
  public var amount: Money?
  public var ratePercent: String?

  public init(
    kind: ReceiptExtraKind,
    label: String,
    amount: Money? = nil,
    ratePercent: String? = nil
  ) {
    self.kind = kind
    self.label = label
    self.amount = amount
    self.ratePercent = ratePercent
  }
}

public struct PreviewExtrasPayer: Sendable, Hashable {
  public let memberId: Member.ID
  public let amount: Money?

  public init(memberId: Member.ID, amount: Money? = nil) {
    self.memberId = memberId
    self.amount = amount
  }
}

public struct PreviewExtrasInput: Sendable, Hashable {
  public let baseAmount: Money
  public let extras: [PreviewExtrasItem]
  public let extrasAllocation: ExtrasAllocation?
  public let payers: [PreviewExtrasPayer]?
  public let payerMemberId: Member.ID?
  public let occurredAt: Date?
  public let split: SplitSpec?
  public let transactionId: LedgerTransaction.ID?

  public init(
    baseAmount: Money,
    extras: [PreviewExtrasItem],
    extrasAllocation: ExtrasAllocation? = nil,
    payers: [PreviewExtrasPayer]? = nil,
    payerMemberId: Member.ID? = nil,
    occurredAt: Date? = nil,
    split: SplitSpec? = nil,
    transactionId: LedgerTransaction.ID? = nil
  ) {
    self.baseAmount = baseAmount
    self.extras = extras
    self.extrasAllocation = extrasAllocation
    self.payers = payers
    self.payerMemberId = payerMemberId
    self.occurredAt = occurredAt
    self.split = split
    self.transactionId = transactionId
  }
}

public enum ExtrasPreviewIssueCode: Sendable, Hashable {
  case invalidTotal
  case splitTotalMismatch
  case itemUnassigned
  case unknown(String)

  public init(code: String) {
    switch code {
    case "INVALID_TOTAL": self = .invalidTotal
    case "SPLIT_TOTAL_MISMATCH": self = .splitTotalMismatch
    case "ITEM_UNASSIGNED": self = .itemUnassigned
    default: self = .unknown(code)
    }
  }
}

public struct ExtrasPreviewIssue: Sendable, Hashable {
  public let code: ExtrasPreviewIssueCode
  public let itemIndex: Int?

  public init(code: ExtrasPreviewIssueCode, itemIndex: Int? = nil) {
    self.code = code
    self.itemIndex = itemIndex
  }
}

public struct PreviewExtrasResult: Sendable, Hashable {
  public let baseAmount: Money
  public let resolvedExtras: [SplitSpec.ItemsExtra]
  public let netExtras: Money
  public let computedAmount: Money
  public let shares: [MemberAmount]?
  public let issues: [ExtrasPreviewIssue]
  public let warnings: [TransactionWarning]

  public init(
    baseAmount: Money,
    resolvedExtras: [SplitSpec.ItemsExtra],
    netExtras: Money,
    computedAmount: Money,
    shares: [MemberAmount]? = nil,
    issues: [ExtrasPreviewIssue] = [],
    warnings: [TransactionWarning] = []
  ) {
    self.baseAmount = baseAmount
    self.resolvedExtras = resolvedExtras
    self.netExtras = netExtras
    self.computedAmount = computedAmount
    self.shares = shares
    self.issues = issues
    self.warnings = warnings
  }
}
