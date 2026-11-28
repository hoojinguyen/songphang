public import Domain
import Foundation

public enum MoneyFormat {
  public static func amount(_ money: Money) -> String {
    formatUnsigned(money.magnitude.amount)
  }

  public static func full(_ money: Money, showsPositiveSign: Bool = false) -> String {
    let formatted = formatUnsigned(money.magnitude.amount)
    if money.isNegative {
      return "−\(formatted)\u{00A0}đ"
    }
    if showsPositiveSign && money.isPositive {
      return "+\(formatted)\u{00A0}đ"
    }
    return "\(formatted)\u{00A0}đ"
  }

  public static func signedAmount(_ money: Money) -> String {
    if money.isZero {
      return "0"
    }
    let sign = money.isPositive ? "+" : "−"
    return "\(sign)\(formatUnsigned(money.magnitude.amount))"
  }

  public static func compact(_ money: Money) -> String {
    let raw = String(money.magnitude.amount)
    if raw.count > 3 && raw.hasSuffix("000") {
      return String(raw.dropLast(3))
    }
    if money.isZero {
      return "0"
    }
    return formatUnsigned(money.magnitude.amount)
  }

  public static func parseInput(_ text: String) -> Money? {
    let digits = text.filter { $0.isWholeNumber && $0.isASCII }
    guard !digits.isEmpty, digits.count <= 12, let value = Int64(digits), value <= 999_999_999_999
    else {
      return nil
    }
    return Money(value)
  }

  private static func formatUnsigned(_ value: Int64) -> String {
    let raw = String(value)
    guard raw.count > 3 else { return raw }
    var characters: [Character] = []
    let reversed = Array(raw.reversed())
    for (index, char) in reversed.enumerated() {
      if index > 0 && index.isMultiple(of: 3) {
        characters.append(".")
      }
      characters.append(char)
    }
    return String(characters.reversed())
  }
}
