public struct SharePreview: Sendable, Hashable {
  public let shares: [MemberAmount]

  public init(shares: [MemberAmount]) {
    self.shares = shares
  }
}
