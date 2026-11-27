public enum GroupEvent: Sendable, Hashable {
  public enum Resource: String, Sendable, Hashable {
    case group
    case members
    case users
    case transactions
    case balances
    case activity
    case settlementRequests
    case categories
    case budget
    case receiptScans
    case comments
    case settlementCycles
    case households
    case recurringExpenses
  }

  case changed([String])
  case removed
  case reconnected

  public var changedResources: Set<Resource> {
    guard case .changed(let names) = self else { return [] }
    return Set(names.compactMap(Resource.init(rawValue:)))
  }
}
