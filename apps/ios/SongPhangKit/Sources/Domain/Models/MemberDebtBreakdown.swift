public enum BreakdownCycleSelection: Sendable, Hashable {
  case auto
  case current
  case cycle(SettlementCycle.ID)
}

public struct MemberBreakdownLine: Sendable, Hashable, Identifiable {
  public var id: String { "\(transactionId.rawValue)-\(isPostCloseoutTransfer)" }
  public let transactionId: LedgerTransaction.ID
  public let type: TransactionType
  public let description: String
  public let occurredAt: String
  public let totalAmount: Money
  public let payerSummary: String
  public let memberPaid: Money
  public let memberShare: Money
  public let delta: Money
  public let isPostCloseoutTransfer: Bool

  public init(
    transactionId: LedgerTransaction.ID,
    type: TransactionType,
    description: String,
    occurredAt: String,
    totalAmount: Money,
    payerSummary: String,
    memberPaid: Money,
    memberShare: Money,
    delta: Money,
    isPostCloseoutTransfer: Bool
  ) {
    self.transactionId = transactionId
    self.type = type
    self.description = description
    self.occurredAt = occurredAt
    self.totalAmount = totalAmount
    self.payerSummary = payerSummary
    self.memberPaid = memberPaid
    self.memberShare = memberShare
    self.delta = delta
    self.isPostCloseoutTransfer = isPostCloseoutTransfer
  }
}

public struct MemberDebtBreakdown: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let memberName: String
  public let shape: MemberShape
  public let color: MemberColor
  public let carryOverBalance: Money
  public let focusExpenseDelta: Money
  public let focusTransferDelta: Money
  public let postCycleDelta: Money
  public let netBalance: Money
  public let lines: [MemberBreakdownLine]

  public init(
    memberId: Member.ID,
    memberName: String,
    shape: MemberShape,
    color: MemberColor,
    carryOverBalance: Money,
    focusExpenseDelta: Money,
    focusTransferDelta: Money,
    postCycleDelta: Money,
    netBalance: Money,
    lines: [MemberBreakdownLine]
  ) {
    self.memberId = memberId
    self.memberName = memberName
    self.shape = shape
    self.color = color
    self.carryOverBalance = carryOverBalance
    self.focusExpenseDelta = focusExpenseDelta
    self.focusTransferDelta = focusTransferDelta
    self.postCycleDelta = postCycleDelta
    self.netBalance = netBalance
    self.lines = lines
  }
}

public struct MemberBreakdownsResolvedFocus: Sendable, Hashable {
  public enum Kind: Sendable, Hashable {
    case all
    case current
    case cycle
    case unknown(String)

    public init(code: String) {
      switch code {
      case "all": self = .all
      case "current": self = .current
      case "cycle": self = .cycle
      default: self = .unknown(code)
      }
    }
  }

  public let kind: Kind
  public let cycleId: SettlementCycle.ID?
  public let label: String

  public init(kind: Kind, cycleId: SettlementCycle.ID? = nil, label: String) {
    self.kind = kind
    self.cycleId = cycleId
    self.label = label
  }
}

public struct MemberBreakdownsResult: Sendable, Hashable {
  public let hasClosedCycles: Bool
  public let resolvedFocus: MemberBreakdownsResolvedFocus
  public let breakdowns: [MemberDebtBreakdown]
  public let householdBreakdowns: [HouseholdDebtBreakdown]

  public init(
    hasClosedCycles: Bool,
    resolvedFocus: MemberBreakdownsResolvedFocus,
    breakdowns: [MemberDebtBreakdown],
    householdBreakdowns: [HouseholdDebtBreakdown] = []
  ) {
    self.hasClosedCycles = hasClosedCycles
    self.resolvedFocus = resolvedFocus
    self.breakdowns = breakdowns
    self.householdBreakdowns = householdBreakdowns
  }
}
