public struct Page<Item: Sendable>: Sendable {
  public let items: [Item]
  public let nextCursor: String?

  public init(items: [Item], nextCursor: String? = nil) {
    self.items = items
    self.nextCursor = nextCursor
  }
}

extension Page: Equatable where Item: Equatable {}
extension Page: Hashable where Item: Hashable {}
