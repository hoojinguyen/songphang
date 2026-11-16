public struct Invite: Sendable, Hashable {
  public var token: String
  public var active: Bool
  public var url: String

  public init(token: String, active: Bool, url: String) {
    self.token = token
    self.active = active
    self.url = url
  }
}

public struct InvitePreview: Sendable, Hashable {
  public struct PreviewMember: Sendable, Hashable, Identifiable {
    public let id: Member.ID
    public let name: String
    public let shape: MemberShape
    public let color: MemberColor
    public let claimed: Bool
    public let balance: Money?

    public init(
      id: Member.ID,
      name: String,
      shape: MemberShape,
      color: MemberColor,
      claimed: Bool,
      balance: Money?
    ) {
      self.id = id
      self.name = name
      self.shape = shape
      self.color = color
      self.claimed = claimed
      self.balance = balance
    }
  }

  public let groupId: ExpenseGroup.ID
  public let groupName: String
  public let ownerName: String
  public let memberCount: Int
  public let transactionCount: Int
  public let members: [PreviewMember]
  public let alreadyJoined: Bool

  public init(
    groupId: ExpenseGroup.ID,
    groupName: String,
    ownerName: String,
    memberCount: Int,
    transactionCount: Int,
    members: [PreviewMember],
    alreadyJoined: Bool
  ) {
    self.groupId = groupId
    self.groupName = groupName
    self.ownerName = ownerName
    self.memberCount = memberCount
    self.transactionCount = transactionCount
    self.members = members
    self.alreadyJoined = alreadyJoined
  }
}

public enum JoinChoice: Sendable, Hashable {
  case existingMember(Member.ID)
  case newMember(name: String)
}
