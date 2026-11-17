import Foundation

public struct IdempotencyKey: Sendable, Hashable {
  public let rawValue: String

  public init() {
    self.rawValue = UUID().uuidString.lowercased()
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
