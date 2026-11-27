public import Domain
import Foundation
import GeneratedAPI

public final class LiveRecurringExpensesRepository: RecurringExpensesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [RecurringExpense] {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_recurring_hyphen_expenses(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return try ok.body.json.recurringExpenses.map(Self.mapDto)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func create(
    groupId: ExpenseGroup.ID,
    input: CreateRecurringExpenseInput,
    key: IdempotencyKey
  ) async throws(AppError) -> RecurringExpense {
    do {
      let body = try Self.encodeCreateRequest(input)
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_recurring_hyphen_expenses(
          .init(
            path: .init(groupId: groupId.rawValue),
            headers: .init(idempotency_hyphen_key: key.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .created(let created):
        return Self.mapDto(try created.body.json.recurringExpense)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    groupId: ExpenseGroup.ID,
    id: RecurringExpense.ID,
    input: UpdateRecurringExpenseInput
  ) async throws(AppError) -> RecurringExpense {
    do {
      let hasClear =
        isClear(input.amount)
        || isClear(input.category)
        || isClear(input.categoryId)
        || isClear(input.dayOfWeek)
        || isClear(input.dayOfMonth)
        || isClear(input.monthOfYear)

      if !hasClear {
        let body = try Self.encodeUpdateRequest(input)
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_recurring_hyphen_expenses_sol__lcub_recurringId_rcub_(
            .init(
              path: .init(groupId: groupId.rawValue, recurringId: id.rawValue),
              body: .json(body)
            )
          )
        switch output {
        case .ok(let ok):
          return Self.mapDto(try ok.body.json.recurringExpense)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      }

      let body = try Self.encodeUpdateRequest(input)
      let encoder = JSONEncoder()
      let encoded = try encoder.encode(body)
      guard var json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
        throw AppError.unexpected
      }
      if case .clear = input.amount { json["amount"] = NSNull() }
      if case .clear = input.category { json["category"] = NSNull() }
      if case .clear = input.categoryId { json["categoryId"] = NSNull() }
      if case .clear = input.dayOfWeek { json["dayOfWeek"] = NSNull() }
      if case .clear = input.dayOfMonth { json["dayOfMonth"] = NSNull() }
      if case .clear = input.monthOfYear { json["monthOfYear"] = NSNull() }

      let url = environment.configuration.apiBaseURL
        .appendingPathComponent("groups")
        .appendingPathComponent(groupId.rawValue)
        .appendingPathComponent("recurring-expenses")
        .appendingPathComponent(id.rawValue)
      var request = URLRequest(url: url)
      request.httpMethod = "PATCH"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: json)

      let (data, http, snapshot) = try await environment.performAuthorizedDataRequest(request)
      guard http.statusCode == 200 else {
        let code = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        return try FlexibleISO8601DateTranscoder().decode(raw)
      }
      let decoded = try decoder.decode(Components.Schemas.RecurringExpenseResponse.self, from: data)
      return Self.mapDto(decoded.recurringExpense)
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(
    groupId: ExpenseGroup.ID,
    id: RecurringExpense.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_recurring_hyphen_expenses_sol__lcub_recurringId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, recurringId: id.rawValue))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func skip(
    groupId: ExpenseGroup.ID,
    id: RecurringExpense.ID
  ) async throws(AppError) -> RecurringExpense {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_recurring_hyphen_expenses_sol__lcub_recurringId_rcub__sol_skip(
          .init(path: .init(groupId: groupId.rawValue, recurringId: id.rawValue))
        )
      switch output {
      case .ok(let ok):
        return Self.mapDto(try ok.body.json.recurringExpense)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  private func isClear<T>(_ value: UpdateRecurringExpenseInput.NullableValue<T>) -> Bool {
    if case .clear = value { return true }
    return false
  }

  static func mapDto(_ dto: Components.Schemas.RecurringExpenseDto) -> RecurringExpense {
    RecurringExpense(
      id: RecurringExpense.ID(dto.id),
      groupId: ExpenseGroup.ID(dto.groupId),
      mode: RecurringMode(code: dto.mode.rawValue),
      active: dto.active,
      description: dto.description,
      amount: dto.amount.map { Money(Int64($0)) },
      category: dto.category.flatMap {
        $0 == ._empty ? nil : TransactionMapping.mapCategory($0.rawValue)
      },
      categoryId: dto.categoryId.map(GroupCategory.ID.init),
      payersTemplate: dto.payersTemplate.map {
        RecurringPayerTemplateEntry(
          memberId: Member.ID($0.memberId),
          amount: $0.amount.map { Money(Int64($0)) }
        )
      },
      splitTemplate: TransactionMapping.mapSplitInput(dto.splitTemplate),
      frequency: RecurringFrequency(code: dto.frequency.rawValue),
      dayOfWeek: dto.dayOfWeek,
      dayOfMonth: dto.dayOfMonth,
      monthOfYear: dto.monthOfYear,
      nextDueDate: dto.nextDueDate,
      pendingDueDate: dto.pendingDueDate,
      lastProcessedDueDate: dto.lastProcessedDueDate,
      lastPostedAt: dto.lastPostedAt.map(TransactionMapping.formatISO),
      lastTransactionId: dto.lastTransactionId.map(LedgerTransaction.ID.init),
      pauseReason: dto.pauseReason.flatMap {
        $0 == ._empty ? nil : RecurringPauseReason(code: $0.rawValue)
      },
      createdAt: TransactionMapping.formatISO(dto.createdAt),
      updatedAt: TransactionMapping.formatISO(dto.updatedAt)
    )
  }

  private static func encodeCreateRequest(
    _ input: CreateRecurringExpenseInput
  ) throws(AppError) -> Components.Schemas.CreateRecurringExpenseRequest {
    let freq: Components.Schemas.CreateRecurringExpenseRequest.frequencyPayload
    switch input.frequency {
    case .weekly: freq = .weekly
    case .monthly: freq = .monthly
    case .quarterly: freq = .quarterly
    case .yearly: freq = .yearly
    case .unknown:
      throw .api(code: "VALIDATION_FAILED", status: 400)
    }
    let mode: Components.Schemas.CreateRecurringExpenseRequest.modePayload
    switch input.mode {
    case .fixed: mode = .fixed
    case .variable: mode = .variable
    case .unknown:
      throw .api(code: "VALIDATION_FAILED", status: 400)
    }
    let category: Components.Schemas.CreateRecurringExpenseRequest.categoryPayload? =
      input.categoryId == nil
      ? input.category.flatMap { .init(rawValue: $0.code) }
      : nil
    return Components.Schemas.CreateRecurringExpenseRequest(
      amount: input.amount.map { Int($0.amount) },
      category: category,
      categoryId: input.categoryId?.rawValue,
      dayOfMonth: input.dayOfMonth,
      dayOfWeek: input.dayOfWeek,
      description: input.description,
      frequency: freq,
      mode: mode,
      monthOfYear: input.monthOfYear,
      payersTemplate: input.payersTemplate.map {
        .init(amount: $0.amount.map { Int($0.amount) }, memberId: $0.memberId.rawValue)
      },
      splitTemplate: TransactionMapping.encodeSplitInput(input.splitTemplate)
    )
  }

  private static func encodeUpdateRequest(
    _ input: UpdateRecurringExpenseInput
  ) throws(AppError) -> Components.Schemas.UpdateRecurringExpenseRequest {
    let freq: Components.Schemas.UpdateRecurringExpenseRequest.frequencyPayload?
    if let frequency = input.frequency {
      switch frequency {
      case .weekly: freq = .weekly
      case .monthly: freq = .monthly
      case .quarterly: freq = .quarterly
      case .yearly: freq = .yearly
      case .unknown:
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
    } else {
      freq = nil
    }
    let mode: Components.Schemas.UpdateRecurringExpenseRequest.modePayload?
    if let inputMode = input.mode {
      switch inputMode {
      case .fixed: mode = .fixed
      case .variable: mode = .variable
      case .unknown:
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
    } else {
      mode = nil
    }
    let amount: Int? = {
      if case .set(let val) = input.amount { return Int(val.amount) }
      return nil
    }()
    let category: Components.Schemas.UpdateRecurringExpenseRequest.categoryPayload? = {
      if case .set(let val) = input.category {
        return .init(rawValue: val.code)
      }
      return nil
    }()
    let categoryId: String? = {
      if case .set(let val) = input.categoryId { return val.rawValue }
      return nil
    }()
    let dayOfMonth: Int? = {
      if case .set(let val) = input.dayOfMonth { return val }
      return nil
    }()
    let dayOfWeek: Int? = {
      if case .set(let val) = input.dayOfWeek { return val }
      return nil
    }()
    let monthOfYear: Int? = {
      if case .set(let val) = input.monthOfYear { return val }
      return nil
    }()
    return Components.Schemas.UpdateRecurringExpenseRequest(
      active: input.active,
      amount: amount,
      category: category,
      categoryId: categoryId,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      description: input.description,
      frequency: freq,
      mode: mode,
      monthOfYear: monthOfYear,
      payersTemplate: input.payersTemplate?.map {
        .init(amount: $0.amount.map { Int($0.amount) }, memberId: $0.memberId.rawValue)
      },
      splitTemplate: input.splitTemplate.map(TransactionMapping.encodeSplitInput)
    )
  }
}
