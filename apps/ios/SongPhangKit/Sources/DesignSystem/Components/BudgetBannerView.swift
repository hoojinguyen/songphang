public import Domain
public import SwiftUI

public struct BudgetBannerView: View {
  private let budget: GroupBudget?
  private let onTap: () -> Void

  public init(budget: GroupBudget?, onTap: @escaping () -> Void = {}) {
    self.budget = budget
    self.onTap = onTap
  }

  public var body: some View {
    if let budget, budget.state == .near || budget.state == .over {
      let isOver = (budget.state == .over)
      let message =
        isOver
        ? L10n.t("budget.overBanner", ["over": MoneyFormat.full(budget.spent - budget.amount)])
        : L10n.t(
          "budget.nearBanner",
          [
            "spent": MoneyFormat.full(budget.spent),
            "amount": MoneyFormat.full(budget.amount),
          ]
        )
      Button(action: onTap) {
        Text(message)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(
            isOver ? Tokens.coral : Tokens.sunken,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
          )
      }
      .buttonStyle(.plain)
    }
  }
}
