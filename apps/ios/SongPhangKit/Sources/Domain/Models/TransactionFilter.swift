import Foundation

public struct TransactionFilter: Sendable, Hashable {
  public var query: String?
  public var memberId: Member.ID?
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var uncategorized: Bool
  public var spendingOnly: Bool
  public var type: TransactionType?
  public var from: String?
  public var to: String?

  public init(
    query: String? = nil,
    memberId: Member.ID? = nil,
    category: TransactionCategory? = nil,
    categoryId: GroupCategory.ID? = nil,
    uncategorized: Bool = false,
    spendingOnly: Bool = false,
    type: TransactionType? = nil,
    from: String? = nil,
    to: String? = nil
  ) {
    let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.query = (trimmedQuery?.isEmpty == false) ? trimmedQuery : nil
    self.memberId = memberId

    if let categoryId {
      self.category = nil
      self.categoryId = categoryId
      self.uncategorized = false
    } else if let category {
      self.category = category
      self.categoryId = nil
      self.uncategorized = false
    } else {
      self.category = nil
      self.categoryId = nil
      self.uncategorized = uncategorized
    }

    self.type = type
    self.spendingOnly = (type == .transfer) ? false : spendingOnly
    let trimmedFrom = from?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTo = to?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.from = (trimmedFrom?.isEmpty == false) ? trimmedFrom : nil
    self.to = (trimmedTo?.isEmpty == false) ? trimmedTo : nil
  }

  public var isEmpty: Bool {
    query == nil && !hasModalFilters
  }

  public var hasModalFilters: Bool {
    memberId != nil
      || category != nil
      || categoryId != nil
      || uncategorized
      || spendingOnly
      || type != nil
      || from != nil
      || to != nil
  }
}
