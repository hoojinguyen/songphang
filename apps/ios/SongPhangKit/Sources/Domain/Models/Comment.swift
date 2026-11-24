import Foundation

public struct Comment: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public let body: String
  public let authorName: String
  public let createdAt: String
  public let mine: Bool

  public init(
    id: ID,
    body: String,
    authorName: String,
    createdAt: String,
    mine: Bool
  ) {
    self.id = id
    self.body = body
    self.authorName = authorName
    self.createdAt = createdAt
    self.mine = mine
  }
}
