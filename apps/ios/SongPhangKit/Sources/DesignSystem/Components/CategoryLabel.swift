public import Domain
public import SwiftUI

public enum CategoryDisplay {
  public static func localizedName(for category: TransactionCategory) -> String {
    switch category {
    case .food: return L10n.tr("expenseForm.categories.food")
    case .transport: return L10n.tr("expenseForm.categories.transport")
    case .lodging: return L10n.tr("expenseForm.categories.lodging")
    case .shopping: return L10n.tr("expenseForm.categories.shopping")
    case .entertainment: return L10n.tr("expenseForm.categories.entertainment")
    case .bills: return L10n.tr("expenseForm.categories.bills")
    case .other, .unknown: return L10n.tr("expenseForm.categories.other")
    }
  }

  public static func localizedColorName(for color: MemberColor) -> String {
    switch color {
    case .mint, .unknown: return L10n.tr("categories.colors.mint")
    case .sky: return L10n.tr("categories.colors.sky")
    case .coral: return L10n.tr("categories.colors.coral")
    case .lilac: return L10n.tr("categories.colors.lilac")
    }
  }

  public static func displayName(for custom: GroupCategory, includeArchivedTag: Bool = true)
    -> String
  {
    if custom.archived && includeArchivedTag {
      return "\(custom.name) (\(L10n.tr("categories.archivedTag")))"
    }
    return custom.name
  }

  public static func label(
    category: TransactionCategory?,
    categoryId: GroupCategory.ID?,
    categories: [GroupCategory],
    includeArchivedTag: Bool = false
  ) -> (name: String, color: Color?)? {
    if let category {
      return (localizedName(for: category), nil)
    }
    if let categoryId,
      let custom = categories.first(where: { $0.id == categoryId })
    {
      return (
        displayName(for: custom, includeArchivedTag: includeArchivedTag),
        Tokens.color(for: custom.color)
      )
    }
    return nil
  }
}
