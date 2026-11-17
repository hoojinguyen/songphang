public struct User: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public var email: String
  public var name: String
  public var avatarUrl: String?
  public var emailVerified: Bool
  public var hasPassword: Bool

  public init(
    id: ID,
    email: String,
    name: String,
    avatarUrl: String? = nil,
    emailVerified: Bool,
    hasPassword: Bool
  ) {
    self.id = id
    self.email = email
    self.name = name
    self.avatarUrl = avatarUrl
    self.emailVerified = emailVerified
    self.hasPassword = hasPassword
  }
}
