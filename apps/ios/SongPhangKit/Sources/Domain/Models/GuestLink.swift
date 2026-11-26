public struct GuestLink: Sendable, Hashable {
  public let active: Bool
  public let url: String?
  public let createdAt: String?

  public init(active: Bool, url: String? = nil, createdAt: String? = nil) {
    self.active = active
    self.url = url
    self.createdAt = createdAt
  }
}

public struct GuestGroupInfo: Sendable, Hashable, Identifiable {
  public let id: ExpenseGroup.ID
  public let name: String
  public let currency: String
  public let minimized: Bool
  public let archivedAt: String?

  public init(
    id: ExpenseGroup.ID,
    name: String,
    currency: String = "VND",
    minimized: Bool = true,
    archivedAt: String? = nil
  ) {
    self.id = id
    self.name = name
    self.currency = currency
    self.minimized = minimized
    self.archivedAt = archivedAt
  }
}

public struct GuestMember: Sendable, Hashable, Identifiable {
  public let id: Member.ID
  public let name: String
  public let kind: MemberKind
  public let active: Bool
  public let shape: MemberShape
  public let color: MemberColor
  public let householdId: Household.ID?

  public init(
    id: Member.ID,
    name: String,
    kind: MemberKind = .person,
    active: Bool = true,
    shape: MemberShape,
    color: MemberColor,
    householdId: Household.ID? = nil
  ) {
    self.id = id
    self.name = name
    self.kind = kind
    self.active = active
    self.shape = shape
    self.color = color
    self.householdId = householdId
  }
}

public struct GuestTransfer: Sendable, Hashable, Identifiable {
  public var id: String { "\(fromMemberId.rawValue)-\(toMemberId.rawValue)-\(amount.amount)" }
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let fromHousehold: HouseholdTransferRef?
  public let toHousehold: HouseholdTransferRef?
  public let amount: Money
  public let purpose: String
  public let paymentMethods: [PaymentMethod]

  public init(
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    fromHousehold: HouseholdTransferRef? = nil,
    toHousehold: HouseholdTransferRef? = nil,
    amount: Money,
    purpose: String,
    paymentMethods: [PaymentMethod] = []
  ) {
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.fromHousehold = fromHousehold
    self.toHousehold = toHousehold
    self.amount = amount
    self.purpose = purpose
    self.paymentMethods = paymentMethods
  }
}

public struct GuestTransaction: Sendable, Hashable, Identifiable {
  public let id: LedgerTransaction.ID
  public let type: TransactionType
  public let description: String
  public let amount: Money
  public let currency: String
  public let occurredAt: String
  public let category: TransactionCategory?
  public let categoryId: GroupCategory.ID?
  public let categoryName: String?
  public let categoryColor: MemberColor?
  public let payers: [MemberAmount]
  public let shares: [MemberAmount]
  public let split: SplitSpec
  public let paymentChannel: PaymentChannel?
  public let paymentNote: String?
  public let cycleId: SettlementCycle.ID?
  public let attachments: [Attachment]

  public init(
    id: LedgerTransaction.ID,
    type: TransactionType,
    description: String,
    amount: Money,
    currency: String = "VND",
    occurredAt: String,
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    categoryName: String? = nil,
    categoryColor: MemberColor? = nil,
    payers: [MemberAmount],
    shares: [MemberAmount],
    split: SplitSpec,
    paymentChannel: PaymentChannel? = nil,
    paymentNote: String? = nil,
    cycleId: SettlementCycle.ID? = nil,
    attachments: [Attachment] = []
  ) {
    self.id = id
    self.type = type
    self.description = description
    self.amount = amount
    self.currency = currency
    self.occurredAt = occurredAt
    self.category = category
    self.categoryId = categoryId
    self.categoryName = categoryName
    self.categoryColor = categoryColor
    self.payers = payers
    self.shares = shares
    self.split = split
    self.paymentChannel = paymentChannel
    self.paymentNote = paymentNote
    self.cycleId = cycleId
    self.attachments = attachments
  }
}

public struct GuestGroupSnapshot: Sendable, Hashable {
  public let group: GuestGroupInfo
  public let members: [GuestMember]
  public let cycles: [SettlementCycle]
  public let selectedCycleId: TransactionCycleFilter
  public let currentPeriod: CurrentPeriodSummary
  public let balances: [Balance]
  public let households: [HouseholdBalance]
  public let transfers: [GuestTransfer]
  public let fund: FundSummary?
  public let resolvedFocus: MemberBreakdownsResolvedFocus
  public let breakdowns: [MemberDebtBreakdown]
  public let householdBreakdowns: [HouseholdDebtBreakdown]
  public let transactions: Page<GuestTransaction>

  public init(
    group: GuestGroupInfo,
    members: [GuestMember],
    cycles: [SettlementCycle],
    selectedCycleId: TransactionCycleFilter,
    currentPeriod: CurrentPeriodSummary,
    balances: [Balance],
    households: [HouseholdBalance] = [],
    transfers: [GuestTransfer],
    fund: FundSummary? = nil,
    resolvedFocus: MemberBreakdownsResolvedFocus,
    breakdowns: [MemberDebtBreakdown],
    householdBreakdowns: [HouseholdDebtBreakdown] = [],
    transactions: Page<GuestTransaction>
  ) {
    self.group = group
    self.members = members
    self.cycles = cycles
    self.selectedCycleId = selectedCycleId
    self.currentPeriod = currentPeriod
    self.balances = balances
    self.households = households
    self.transfers = transfers
    self.fund = fund
    self.resolvedFocus = resolvedFocus
    self.breakdowns = breakdowns
    self.householdBreakdowns = householdBreakdowns
    self.transactions = transactions
  }
}
