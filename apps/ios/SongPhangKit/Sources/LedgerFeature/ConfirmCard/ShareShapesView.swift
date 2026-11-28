import DesignSystem
public import Domain
public import SwiftUI

public struct ShareShapeItem: Sendable, Hashable, Identifiable {
  public var id: Member.ID { member.id }
  public let member: Member
  public let amount: Money

  public init(member: Member, amount: Money) {
    self.member = member
    self.amount = amount
  }
}

public struct ShareShapesView: View {
  private let shares: [ShareShapeItem]
  private let isDimmed: Bool

  public init(shares: [ShareShapeItem], isDimmed: Bool = false) {
    self.shares = shares
    self.isDimmed = isDimmed
  }

  public var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 12) {
      ForEach(shares) { item in
        let shapeSize = size(for: item)
        VStack(spacing: 6) {
          MemberShapeView(
            shape: item.member.shape,
            color: item.member.color,
            name: item.member.name,
            size: shapeSize
          )
          .spAnimation(Motion.bounce, value: shapeSize)

          Text(item.member.name)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .lineLimit(1)

          MoneyText(
            item.amount,
            style: .amountOnly,
            font: Typography.captionBold,
            color: Tokens.ink
          )
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .opacity(isDimmed ? 0.45 : 1.0)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func size(for item: ShareShapeItem) -> CGFloat {
    guard !shares.isEmpty else { return 44 }
    if shares.count > 6 {
      return 44
    }
    if shares.count == 1 {
      return 88
    }
    let firstAmount = shares[0].amount
    let allEqual = shares.allSatisfy { $0.amount == firstAmount }
    if allEqual {
      switch shares.count {
      case 2: return 72
      case 3: return 64
      case 4: return 56
      default: return 48
      }
    }
    let smallerCount = shares.filter { $0.amount < item.amount }.count
    let table: [CGFloat] = [48, 56, 64, 76]
    let clampedIndex = min(smallerCount, table.count - 1)
    return table[clampedIndex]
  }
}
