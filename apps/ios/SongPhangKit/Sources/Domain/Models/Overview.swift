public import Foundation

public enum OverviewPendingActionKind: String, Sendable, Hashable {
  case settlementConfirmation
  case expenseApproval
  case unknown

  public init(raw: String) {
    switch raw {
    case "settlement_confirmation": self = .settlementConfirmation
    case "expense_approval": self = .expenseApproval
    default: self = .unknown
    }
  }
}

public struct OverviewPendingAction: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let kind: OverviewPendingActionKind
  public let groupId: ExpenseGroup.ID
  public let groupName: String
  public let transactionId: LedgerTransaction.ID?
  public let description: String
  public let amount: Money
  public let occurredAt: String
  public let actorName: String

  public init(
    id: ID,
    kind: OverviewPendingActionKind,
    groupId: ExpenseGroup.ID,
    groupName: String,
    transactionId: LedgerTransaction.ID? = nil,
    description: String,
    amount: Money,
    occurredAt: String,
    actorName: String = ""
  ) {
    self.id = id
    self.kind = kind
    self.groupId = groupId
    self.groupName = groupName
    self.transactionId = transactionId
    self.description = description
    self.amount = amount
    self.occurredAt = occurredAt
    self.actorName = actorName
  }
}

public struct OverviewGroupBalance: Sendable, Hashable, Identifiable {
  public var id: ExpenseGroup.ID { groupId }
  public let groupId: ExpenseGroup.ID
  public let groupName: String
  public let myBalance: Money
  public let role: Role
  public let archivedAt: Date?
  public let memberCount: Int
  public let previewMembers: [ExpenseGroup.PreviewMember]

  public init(
    groupId: ExpenseGroup.ID,
    groupName: String,
    myBalance: Money,
    role: Role = .editor,
    archivedAt: Date? = nil,
    memberCount: Int = 0,
    previewMembers: [ExpenseGroup.PreviewMember] = []
  ) {
    self.groupId = groupId
    self.groupName = groupName
    self.myBalance = myBalance
    self.role = role
    self.archivedAt = archivedAt
    self.memberCount = memberCount
    self.previewMembers = previewMembers
  }
}

public struct OverviewSummary: Sendable, Hashable {
  public let totalOwedToMe: Money
  public let totalIOwe: Money
  public let netBalance: Money
  public let pendingActions: [OverviewPendingAction]
  public let groupBalances: [OverviewGroupBalance]

  public init(
    totalOwedToMe: Money,
    totalIOwe: Money,
    netBalance: Money,
    pendingActions: [OverviewPendingAction],
    groupBalances: [OverviewGroupBalance]
  ) {
    self.totalOwedToMe = totalOwedToMe
    self.totalIOwe = totalIOwe
    self.netBalance = netBalance
    self.pendingActions = pendingActions
    self.groupBalances = groupBalances
  }

  public var isAllSettled: Bool {
    netBalance == .zero && pendingActions.isEmpty
  }
}

public struct PersonalTransaction: Sendable, Hashable, Identifiable {
  public var id: LedgerTransaction.ID { transactionId }
  public let transactionId: LedgerTransaction.ID
  public let groupId: ExpenseGroup.ID
  public let groupName: String
  public let type: TransactionType
  public let description: String
  public let amount: Money
  public let myDelta: Money
  public let occurredAt: String
  public let category: TransactionCategory?
  public let payerSummary: String

  public init(
    transactionId: LedgerTransaction.ID,
    groupId: ExpenseGroup.ID,
    groupName: String,
    type: TransactionType,
    description: String,
    amount: Money,
    myDelta: Money,
    occurredAt: String,
    category: TransactionCategory? = nil,
    payerSummary: String = ""
  ) {
    self.transactionId = transactionId
    self.groupId = groupId
    self.groupName = groupName
    self.type = type
    self.description = description
    self.amount = amount
    self.myDelta = myDelta
    self.occurredAt = occurredAt
    self.category = category
    self.payerSummary = payerSummary
  }
}

public struct PersonalTransactionsPage: Sendable, Hashable {
  public let items: [PersonalTransaction]
  public let nextCursor: String?

  public init(items: [PersonalTransaction], nextCursor: String?) {
    self.items = items
    self.nextCursor = nextCursor
  }
}
