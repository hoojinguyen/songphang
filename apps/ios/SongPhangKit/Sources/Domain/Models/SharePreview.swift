public struct SharePreview: Sendable, Hashable {
  public let shares: [MemberAmount]
  public let warnings: [TransactionWarning]

  public init(shares: [MemberAmount], warnings: [TransactionWarning] = []) {
    self.shares = shares
    self.warnings = warnings
  }
}
