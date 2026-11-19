public import Domain

// Temporary explicitly-gated repositories for unconnected ledger domains.
// Removed completely in Task 5B.4 when ledger and realtime repositories connect.

public struct GatedTransactionsRepository: TransactionsRepository {
  public init() {}
  public func lastKnownFirstPage(
    groupId: ExpenseGroup.ID
  ) async -> Page<LedgerTransaction>? { nil }
  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<LedgerTransaction> {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func transaction(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func preview(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft
  ) async throws(AppError) -> SharePreview {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func create(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft,
    key: IdempotencyKey
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func update(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    draft: TransactionDraft,
    version: Int
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func delete(groupId: ExpenseGroup.ID, id: LedgerTransaction.ID) async throws(AppError) {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
  public func restore(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedBalancesRepository: BalancesRepository {
  public init() {}
  public func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances? { nil }
  public func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedActivityRepository: ActivityRepository {
  public init() {}
  public func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<ActivityItem>? { nil }
  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<ActivityItem> {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedQuickEntryRepository: QuickEntryRepository {
  public init() {}
  public func parse(
    groupId: ExpenseGroup.ID,
    text: String
  ) async throws(AppError) -> QuickEntryReading {
    throw .api(code: "STAGE_5B4_PENDING", status: 501)
  }
}

public struct GatedGroupEventsRepository: GroupEventsRepository {
  public init() {}
  public func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
    AsyncStream { $0.finish() }
  }
}
