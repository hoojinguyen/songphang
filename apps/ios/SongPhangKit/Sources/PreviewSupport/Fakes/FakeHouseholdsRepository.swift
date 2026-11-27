#if DEBUG
  public import Domain

  public nonisolated struct FakeHouseholdsRepository: HouseholdsRepository {
    private let world: FakeWorld

    public init(world: FakeWorld) {
      self.world = world
    }

    public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [Household] {
      try await world.listHouseholds(groupId: groupId)
    }

    public func create(
      groupId: ExpenseGroup.ID,
      input: CreateHouseholdInput,
      key: IdempotencyKey
    ) async throws(AppError) -> Household {
      try await world.createHousehold(groupId: groupId, input: input, key: key)
    }

    public func update(
      groupId: ExpenseGroup.ID,
      id: Household.ID,
      input: UpdateHouseholdInput
    ) async throws(AppError) -> Household {
      try await world.updateHousehold(groupId: groupId, id: id, input: input)
    }

    public func delete(groupId: ExpenseGroup.ID, id: Household.ID) async throws(AppError) {
      try await world.deleteHousehold(groupId: groupId, id: id)
    }
  }
#endif
