import Foundation

public struct AppNotification: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public enum Target: Sendable, Hashable {
    case transaction(groupId: ExpenseGroup.ID, transactionId: String)
    case balances(groupId: ExpenseGroup.ID)
    case stats(groupId: ExpenseGroup.ID)
    case group(groupId: ExpenseGroup.ID)
  }

  public enum Payload: Sendable, Hashable {
    case expenseAdded(
      actorName: String, groupName: String, transactionId: String, description: String, share: Money
    )
    case expenseChanged(
      actorName: String, groupName: String, transactionId: String, description: String,
      action: String)
    case commentAdded(
      actorName: String, groupName: String, transactionId: String, description: String)
    case disputeOpened(
      actorName: String, groupName: String, transactionId: String, description: String,
      reason: String)
    case disputeResolved(
      actorName: String, groupName: String, transactionId: String, description: String)
    case settlementRequested(actorName: String, groupName: String, amount: Money)
    case settlementConfirmed(actorName: String, groupName: String, amount: Money)
    case settlementRejected(actorName: String, groupName: String, amount: Money)
    case debtReminder(actorName: String, groupName: String, toName: String, amount: Money)
    case approvalRequested(
      actorName: String, groupName: String, transactionId: String, description: String,
      amount: Money)
    case approvalDecided(
      actorName: String, groupName: String, transactionId: String, description: String,
      decision: String)
    case budgetState(actorName: String, groupName: String, state: String)
    case unknown(kind: String, groupName: String?)
  }

  public let id: ID
  public let kind: String
  public let groupId: ExpenseGroup.ID
  public let groupName: String
  public var read: Bool
  public let createdAt: String
  public let payload: Payload
  public let target: Target

  public init(
    id: ID,
    kind: String,
    groupId: ExpenseGroup.ID,
    groupName: String,
    read: Bool,
    createdAt: String,
    payload: Payload,
    target: Target
  ) {
    self.id = id
    self.kind = kind
    self.groupId = groupId
    self.groupName = groupName
    self.read = read
    self.createdAt = createdAt
    self.payload = payload
    self.target = target
  }
}

public struct NotificationSettings: Sendable, Hashable {
  public var emailImmediate: Bool
  public var emailDigest: Bool

  public init(emailImmediate: Bool, emailDigest: Bool) {
    self.emailImmediate = emailImmediate
    self.emailDigest = emailDigest
  }
}

public struct ReminderPair: Sendable, Hashable {
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID

  public init(fromMemberId: Member.ID, toMemberId: Member.ID) {
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
  }
}

public struct SkippedReminder: Sendable, Hashable {
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let reason: String

  public init(fromMemberId: Member.ID, toMemberId: Member.ID, reason: String) {
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.reason = reason
  }
}

public struct SendReminderResult: Sendable, Hashable {
  public let reminded: [ReminderPair]
  public let skipped: [SkippedReminder]

  public init(reminded: [ReminderPair], skipped: [SkippedReminder]) {
    self.reminded = reminded
    self.skipped = skipped
  }
}
