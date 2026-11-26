public enum TransactionCycleFilter: Sendable, Hashable {
  case current
  case cycle(SettlementCycle.ID)
}

public struct SettlementCycle: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public struct BalanceSnapshot: Sendable, Hashable, Identifiable {
    public var id: Member.ID { memberId }
    public let memberId: Member.ID
    public let name: String
    public let shape: MemberShape
    public let color: MemberColor
    public let balance: Money

    public init(
      memberId: Member.ID,
      name: String,
      shape: MemberShape,
      color: MemberColor,
      balance: Money
    ) {
      self.memberId = memberId
      self.name = name
      self.shape = shape
      self.color = color
      self.balance = balance
    }
  }

  public struct TransferSnapshot: Sendable, Hashable, Identifiable {
    public var id: String { "\(fromMemberId.rawValue)-\(toMemberId.rawValue)-\(amount.amount)" }
    public let fromMemberId: Member.ID
    public let fromName: String
    public let toMemberId: Member.ID
    public let toName: String
    public let amount: Money

    public init(
      fromMemberId: Member.ID,
      fromName: String,
      toMemberId: Member.ID,
      toName: String,
      amount: Money
    ) {
      self.fromMemberId = fromMemberId
      self.fromName = fromName
      self.toMemberId = toMemberId
      self.toName = toName
      self.amount = amount
    }
  }

  public struct Snapshot: Sendable, Hashable {
    public let balances: [BalanceSnapshot]
    public let transfers: [TransferSnapshot]
    public let fundBalance: Money?

    public init(
      balances: [BalanceSnapshot],
      transfers: [TransferSnapshot],
      fundBalance: Money? = nil
    ) {
      self.balances = balances
      self.transfers = transfers
      self.fundBalance = fundBalance
    }
  }

  public let id: ID
  public let cycleNumber: Int
  public let title: String
  public let startedAt: String
  public let closedAt: String
  public let closedBy: LedgerTransaction.ActorRef?
  public let expenseCount: Int
  public let totalExpenseAmount: Money
  public let snapshot: Snapshot

  public init(
    id: ID,
    cycleNumber: Int,
    title: String,
    startedAt: String,
    closedAt: String,
    closedBy: LedgerTransaction.ActorRef? = nil,
    expenseCount: Int,
    totalExpenseAmount: Money,
    snapshot: Snapshot
  ) {
    self.id = id
    self.cycleNumber = cycleNumber
    self.title = title
    self.startedAt = startedAt
    self.closedAt = closedAt
    self.closedBy = closedBy
    self.expenseCount = expenseCount
    self.totalExpenseAmount = totalExpenseAmount
    self.snapshot = snapshot
  }
}

public struct CurrentPeriodSummary: Sendable, Hashable {
  public let startedAt: String
  public let expenseCount: Int
  public let totalExpenseAmount: Money
  public let countedTransactionCount: Int

  public init(
    startedAt: String,
    expenseCount: Int,
    totalExpenseAmount: Money,
    countedTransactionCount: Int
  ) {
    self.startedAt = startedAt
    self.expenseCount = expenseCount
    self.totalExpenseAmount = totalExpenseAmount
    self.countedTransactionCount = countedTransactionCount
  }
}

public struct SettlementCyclesOverview: Sendable, Hashable {
  public let cycles: [SettlementCycle]
  public let currentPeriod: CurrentPeriodSummary

  public init(cycles: [SettlementCycle], currentPeriod: CurrentPeriodSummary) {
    self.cycles = cycles
    self.currentPeriod = currentPeriod
  }
}
