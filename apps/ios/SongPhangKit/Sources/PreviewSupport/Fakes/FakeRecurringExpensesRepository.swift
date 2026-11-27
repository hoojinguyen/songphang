#if DEBUG
  public import Domain

  public nonisolated struct FakeRecurringExpensesRepository: RecurringExpensesRepository {
    private let world: FakeWorld

    public init(world: FakeWorld) {
      self.world = world
    }

    public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [RecurringExpense] {
      try await world.listRecurringExpenses(groupId: groupId)
    }

    public func create(
      groupId: ExpenseGroup.ID,
      input: CreateRecurringExpenseInput,
      key: IdempotencyKey
    ) async throws(AppError) -> RecurringExpense {
      try await world.createRecurringExpense(groupId: groupId, input: input, key: key)
    }

    public func update(
      groupId: ExpenseGroup.ID,
      id: RecurringExpense.ID,
      input: UpdateRecurringExpenseInput
    ) async throws(AppError) -> RecurringExpense {
      try await world.updateRecurringExpense(groupId: groupId, id: id, input: input)
    }

    public func delete(groupId: ExpenseGroup.ID, id: RecurringExpense.ID) async throws(AppError) {
      try await world.deleteRecurringExpense(groupId: groupId, id: id)
    }

    public func skip(
      groupId: ExpenseGroup.ID,
      id: RecurringExpense.ID
    ) async throws(AppError) -> RecurringExpense {
      try await world.skipRecurringExpense(groupId: groupId, id: id)
    }
  }
#endif
