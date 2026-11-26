#if DEBUG
  public import Domain

  public nonisolated struct FakeSettlementCyclesRepository: SettlementCyclesRepository {
    private let world: FakeWorld

    public init(world: FakeWorld) {
      self.world = world
    }

    public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> SettlementCyclesOverview {
      try await world.listSettlementCycles(groupId: groupId)
    }

    public func close(
      groupId: ExpenseGroup.ID,
      title: String?,
      idempotencyKey: IdempotencyKey
    ) async throws(AppError) -> SettlementCycle {
      try await world.closeSettlementCycle(
        groupId: groupId,
        title: title,
        idempotencyKey: idempotencyKey
      )
    }

    public func reopen(
      groupId: ExpenseGroup.ID,
      cycleId: SettlementCycle.ID
    ) async throws(AppError) {
      try await world.reopenSettlementCycle(groupId: groupId, cycleId: cycleId)
    }
  }
#endif
