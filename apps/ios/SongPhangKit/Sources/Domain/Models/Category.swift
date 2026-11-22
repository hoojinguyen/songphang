public struct GroupCategory: Sendable, Hashable, Identifiable {
  public struct ID: Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }

  public let id: ID
  public var name: String
  public var color: MemberColor
  public var archived: Bool

  public init(
    id: ID,
    name: String,
    color: MemberColor,
    archived: Bool = false
  ) {
    self.id = id
    self.name = name
    self.color = color
    self.archived = archived
  }
}
