public import Foundation

public struct ExpenseGroup: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public struct PreviewMember: Sendable, Hashable, Identifiable {
    public let id: Member.ID
    public let name: String
    public let shape: MemberShape
    public let color: MemberColor

    public init(id: Member.ID, name: String, shape: MemberShape, color: MemberColor) {
      self.id = id
      self.name = name
      self.shape = shape
      self.color = color
    }
  }

  public let id: ID
  public var name: String
  public var currency: String
  public var memberCount: Int
  public var previewMembers: [PreviewMember]
  public var myBalance: Money
  public var myIndividualBalance: Money?
  public var householdName: String?
  public var minimizeDebts: Bool
  public var defaultRole: Role
  public var role: Role
  public var myMemberId: Member.ID?
  public var muted: Bool
  public var reminderIntervalDays: Int?
  public var approvalThreshold: Money?
  public var ownerName: String
  public var createdAt: String
  public var archivedAt: Date?
  public var pendingActionCount: Int

  public var isArchived: Bool { archivedAt != nil }

  public init(
    id: ID,
    name: String,
    currency: String = "VND",
    memberCount: Int,
    previewMembers: [PreviewMember],
    myBalance: Money,
    myIndividualBalance: Money? = nil,
    householdName: String? = nil,
    minimizeDebts: Bool = true,
    defaultRole: Role = .editor,
    role: Role = .owner,
    myMemberId: Member.ID? = nil,
    muted: Bool = false,
    reminderIntervalDays: Int? = nil,
    approvalThreshold: Money? = nil,
    ownerName: String = "",
    createdAt: String = "2026-11-16T14:23:26.244Z",
    archivedAt: Date? = nil,
    pendingActionCount: Int = 0
  ) {
    self.id = id
    self.name = name
    self.currency = currency
    self.memberCount = memberCount
    self.previewMembers = previewMembers
    self.myBalance = myBalance
    self.myIndividualBalance = myIndividualBalance
    self.householdName = householdName
    self.minimizeDebts = minimizeDebts
    self.defaultRole = defaultRole
    self.role = role
    self.myMemberId = myMemberId
    self.muted = muted
    self.reminderIntervalDays = reminderIntervalDays
    self.approvalThreshold = approvalThreshold
    self.ownerName = ownerName
    self.createdAt = createdAt
    self.archivedAt = archivedAt
    self.pendingActionCount = pendingActionCount
  }
}
