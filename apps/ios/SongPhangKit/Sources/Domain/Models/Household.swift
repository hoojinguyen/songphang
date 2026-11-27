public struct Household: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public var name: String
  public var representativeMemberId: Member.ID
  public var memberIds: [Member.ID]
  public let createdAt: String
  public var updatedAt: String

  public init(
    id: ID,
    name: String,
    representativeMemberId: Member.ID,
    memberIds: [Member.ID],
    createdAt: String = "2026-11-26T00:00:00.000Z",
    updatedAt: String = "2026-11-26T00:00:00.000Z"
  ) {
    self.id = id
    self.name = name
    self.representativeMemberId = representativeMemberId
    self.memberIds = memberIds
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct HouseholdTransferRef: Sendable, Hashable {
  public let id: Household.ID
  public let name: String
  public let memberIds: [Member.ID]

  public init(id: Household.ID, name: String, memberIds: [Member.ID]) {
    self.id = id
    self.name = name
    self.memberIds = memberIds
  }
}

public struct HouseholdMemberBalance: Sendable, Hashable, Identifiable {
  public var id: Member.ID { memberId }
  public let memberId: Member.ID
  public let balance: Money

  public init(memberId: Member.ID, balance: Money) {
    self.memberId = memberId
    self.balance = balance
  }
}

public struct HouseholdBalance: Sendable, Hashable, Identifiable {
  public let id: Household.ID
  public let name: String
  public let representativeMemberId: Member.ID
  public let memberIds: [Member.ID]
  public let netBalance: Money
  public let memberBalances: [HouseholdMemberBalance]

  public init(
    id: Household.ID,
    name: String,
    representativeMemberId: Member.ID,
    memberIds: [Member.ID],
    netBalance: Money,
    memberBalances: [HouseholdMemberBalance]
  ) {
    self.id = id
    self.name = name
    self.representativeMemberId = representativeMemberId
    self.memberIds = memberIds
    self.netBalance = netBalance
    self.memberBalances = memberBalances
  }
}

public struct HouseholdDebtBreakdown: Sendable, Hashable, Identifiable {
  public var id: Household.ID { householdId }
  public let householdId: Household.ID
  public let name: String
  public let representativeMemberId: Member.ID
  public let memberIds: [Member.ID]
  public let carryOverBalance: Money
  public let focusExpenseDelta: Money
  public let focusTransferDelta: Money
  public let postCycleDelta: Money
  public let netBalance: Money

  public init(
    householdId: Household.ID,
    name: String,
    representativeMemberId: Member.ID,
    memberIds: [Member.ID],
    carryOverBalance: Money,
    focusExpenseDelta: Money,
    focusTransferDelta: Money,
    postCycleDelta: Money,
    netBalance: Money
  ) {
    self.householdId = householdId
    self.name = name
    self.representativeMemberId = representativeMemberId
    self.memberIds = memberIds
    self.carryOverBalance = carryOverBalance
    self.focusExpenseDelta = focusExpenseDelta
    self.focusTransferDelta = focusTransferDelta
    self.postCycleDelta = postCycleDelta
    self.netBalance = netBalance
  }
}

public struct CreateHouseholdInput: Sendable, Hashable {
  public var name: String
  public var memberIds: [Member.ID]
  public var representativeMemberId: Member.ID

  public init(name: String, memberIds: [Member.ID], representativeMemberId: Member.ID) {
    self.name = name
    self.memberIds = memberIds
    self.representativeMemberId = representativeMemberId
  }
}

public struct UpdateHouseholdInput: Sendable, Hashable {
  public var name: String?
  public var memberIds: [Member.ID]?
  public var representativeMemberId: Member.ID?

  public init(
    name: String? = nil,
    memberIds: [Member.ID]? = nil,
    representativeMemberId: Member.ID? = nil
  ) {
    self.name = name
    self.memberIds = memberIds
    self.representativeMemberId = representativeMemberId
  }
}
