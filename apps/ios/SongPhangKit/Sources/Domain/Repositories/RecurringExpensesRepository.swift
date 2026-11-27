public protocol RecurringExpensesRepository: Sendable {
  func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [RecurringExpense]
  func create(
    groupId: ExpenseGroup.ID,
    input: CreateRecurringExpenseInput,
    key: IdempotencyKey
  ) async throws(AppError) -> RecurringExpense
  func update(
    groupId: ExpenseGroup.ID,
    id: RecurringExpense.ID,
    input: UpdateRecurringExpenseInput
  ) async throws(AppError) -> RecurringExpense
  func delete(groupId: ExpenseGroup.ID, id: RecurringExpense.ID) async throws(AppError)
  func skip(
    groupId: ExpenseGroup.ID,
    id: RecurringExpense.ID
  ) async throws(AppError) -> RecurringExpense
}
