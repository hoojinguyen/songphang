public import Domain
public import SwiftUI

public struct FundBlockView: View {
  private let fund: FundSummary
  private let members: [Member]
  private let onTap: () -> Void

  public init(
    fund: FundSummary,
    members: [Member],
    onTap: @escaping () -> Void
  ) {
    self.fund = fund
    self.members = members
    self.onTap = onTap
  }

  public var body: some View {
    let holder = fund.holderMemberId.flatMap { holderId in
      members.first(where: { $0.id == holderId })
    }
    let title =
      fund.cash.isNegative
      ? L10n.t("balances.fundNegative", ["amount": MoneyFormat.full(fund.cash.magnitude)])
      : L10n.t("balances.fundRemaining", ["amount": MoneyFormat.full(fund.cash)])

    Button(action: onTap) {
      HStack(spacing: 16) {
        FundShapeView(name: fund.name, size: 36)

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(title)
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
            if !fund.active {
              Text(L10n.tr("fund.inactiveTag"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.muted)
            }
          }

          if let holder {
            Text(L10n.t("fund.holderLine", ["name": holder.name]))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
          }
        }
        Spacer(minLength: 4)
        Image(systemName: "chevron.right")
          .spIconFont(size: 14, weight: .bold, relativeTo: .subheadline)
          .foregroundStyle(Tokens.muted)
      }
      .padding(20)
      .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
