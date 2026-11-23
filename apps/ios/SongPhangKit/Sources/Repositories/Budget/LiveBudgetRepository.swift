public import Domain
import Foundation
import GeneratedAPI

public final class LiveBudgetRepository: BudgetRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownBudget(groupId: ExpenseGroup.ID) async -> GroupBudget? {
    await environment.snapshots.read(.budget(groupId.rawValue)) { data in
      try BudgetMapping.decodeResilientResponse(from: data)
    } ?? nil
  }

  public func budget(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBudget? {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let result: GroupBudget? = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_budget(
            .init(path: .init(groupId: groupId.rawValue))
          )
        switch output {
        case .ok(let ok):
          return try ok.body.json.budget.flatMap(BudgetMapping.mapBudget)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try BudgetMapping.decodeResilientResponse(from: data)
      }

      if let scope, let encoded = BudgetMapping.encodeSnapshot(result) {
        await environment.snapshots.writeData(
          encoded,
          for: .budget(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return result
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func setBudget(
    groupId: ExpenseGroup.ID,
    period: BudgetPeriod,
    amount: Money
  ) async throws(AppError) -> GroupBudget {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let body = BudgetMapping.encodePutRequest(period: period, amount: amount)
      let saved: GroupBudget = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .put_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_budget(
            .init(
              path: .init(groupId: groupId.rawValue),
              body: .json(body)
            )
          )
        switch output {
        case .ok(let ok):
          guard let budget = try ok.body.json.budget.flatMap(BudgetMapping.mapBudget) else {
            throw AppError.unexpected
          }
          return budget
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        guard let budget = try BudgetMapping.decodeResilientResponse(from: data) else {
          throw AppError.unexpected
        }
        return budget
      }

      if let scope, let encoded = BudgetMapping.encodeSnapshot(saved) {
        await environment.snapshots.writeData(
          encoded,
          for: .budget(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return saved
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func deleteBudget(groupId: ExpenseGroup.ID) async throws(AppError) {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_budget(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .noContent:
        if let scope, let encoded = BudgetMapping.encodeSnapshot(nil) {
          await environment.snapshots.writeData(
            encoded,
            for: .budget(groupId.rawValue),
            scope: scope,
            groupGeneration: groupGen
          )
        }
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
