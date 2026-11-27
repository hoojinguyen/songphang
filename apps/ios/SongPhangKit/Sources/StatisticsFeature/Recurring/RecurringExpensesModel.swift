public import Domain
import Foundation
public import Observation

@Observable
public final class RecurringExpensesModel {
  public let groupId: ExpenseGroup.ID
  private let repository: any RecurringExpensesRepository
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<[RecurringExpense]> = .loading
  public private(set) var isMutating = false
  public private(set) var mutationError: AppError?
  private var createIdempotencyKey = IdempotencyKey()

  public init(
    groupId: ExpenseGroup.ID,
    repository: any RecurringExpensesRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.repository = repository
    self.onUnauthorized = onUnauthorized
  }

  public func load() async {
    if case .failed = state {
      state = .loading
    }
    do throws(AppError) {
      let items = try await repository.list(groupId: groupId)
      state = .loaded(items)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      if case .loaded = state {
        mutationError = error
      } else {
        state = .failed(error)
      }
    }
  }

  public func create(_ input: CreateRecurringExpenseInput) async -> Bool {
    guard !isMutating else { return false }
    isMutating = true
    mutationError = nil
    defer { isMutating = false }
    do throws(AppError) {
      let created = try await repository.create(
        groupId: groupId,
        input: input,
        key: createIdempotencyKey
      )
      var list = state.value ?? []
      list.insert(created, at: 0)
      state = .loaded(list)
      createIdempotencyKey = IdempotencyKey()
      return true
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return false
      }
      mutationError = error
      return false
    }
  }

  public func update(id: RecurringExpense.ID, input: UpdateRecurringExpenseInput) async -> Bool {
    guard !isMutating else { return false }
    isMutating = true
    mutationError = nil
    defer { isMutating = false }
    do throws(AppError) {
      let updated = try await repository.update(groupId: groupId, id: id, input: input)
      var list = state.value ?? []
      if let idx = list.firstIndex(where: { $0.id == id }) {
        list[idx] = updated
      }
      state = .loaded(list)
      return true
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return false
      }
      mutationError = error
      return false
    }
  }

  public func toggleActive(_ item: RecurringExpense) async {
    _ = await update(
      id: item.id,
      input: UpdateRecurringExpenseInput(active: !item.active)
    )
  }

  public func clearPendingDueDate(id: RecurringExpense.ID) {
    guard case .loaded(var list) = state,
      let idx = list.firstIndex(where: { $0.id == id })
    else { return }
    list[idx].pendingDueDate = nil
    state = .loaded(list)
  }

  public func skip(_ item: RecurringExpense) async {
    guard !isMutating else { return }
    isMutating = true
    mutationError = nil
    defer { isMutating = false }
    do throws(AppError) {
      let updated = try await repository.skip(groupId: groupId, id: item.id)
      var list = state.value ?? []
      if let idx = list.firstIndex(where: { $0.id == item.id }) {
        list[idx] = updated
      }
      state = .loaded(list)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      mutationError = error
    }
  }

  public func delete(_ item: RecurringExpense) async {
    guard !isMutating else { return }
    isMutating = true
    mutationError = nil
    defer { isMutating = false }
    do throws(AppError) {
      try await repository.delete(groupId: groupId, id: item.id)
      var list = state.value ?? []
      list.removeAll { $0.id == item.id }
      state = .loaded(list)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      mutationError = error
    }
  }
}
