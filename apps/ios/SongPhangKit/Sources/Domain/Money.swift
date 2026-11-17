public struct Money: Sendable, Hashable, Comparable, AdditiveArithmetic {
  public let amount: Int64

  public init(_ amount: Int64) {
    self.amount = amount
  }

  public static let zero = Money(0)

  public static func + (lhs: Money, rhs: Money) -> Money {
    Money(lhs.amount + rhs.amount)
  }

  public static func - (lhs: Money, rhs: Money) -> Money {
    Money(lhs.amount - rhs.amount)
  }

  public static func < (lhs: Money, rhs: Money) -> Bool {
    lhs.amount < rhs.amount
  }

  public var isZero: Bool {
    amount == 0
  }

  public var isPositive: Bool {
    amount > 0
  }

  public var isNegative: Bool {
    amount < 0
  }

  public var magnitude: Money {
    Money(amount < 0 ? -amount : amount)
  }
}
