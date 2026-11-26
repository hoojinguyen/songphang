public import Domain
import Foundation
import GeneratedAPI

public final class LiveBalancesRepository: BalancesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownBalances(groupId: ExpenseGroup.ID) async -> GroupBalances? {
    await environment.snapshots.read(.balances(groupId.rawValue)) { data in
      try BalanceMapping.decodeResilientBalances(from: data)
    }
  }

  public func balances(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBalances {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let result: GroupBalances = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_balances(
            .init(path: .init(groupId: groupId.rawValue))
          )
        switch output {
        case .ok(let ok):
          return BalanceMapping.mapBalances(try ok.body.json)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try BalanceMapping.decodeResilientBalances(from: data)
      }

      if let scope, let encoded = BalanceMapping.encodeBalancesSnapshot(result) {
        await environment.snapshots.writeData(
          encoded,
          for: .balances(groupId.rawValue),
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

  public func breakdowns(
    groupId: ExpenseGroup.ID,
    cycleId: BreakdownCycleSelection
  ) async throws(AppError) -> MemberBreakdownsResult {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_balances_sol_breakdowns(
          .init(
            path: .init(groupId: groupId.rawValue),
            query: .init(cycleId: LiveMemberBreakdownsMapping.encodeQuery(cycleId))
          )
        )
      switch output {
      case .ok(let ok):
        return LiveMemberBreakdownsMapping.mapResult(try ok.body.json)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func settlementVault(
    groupId: ExpenseGroup.ID,
    filter: SettlementVaultFilter,
    cycleId: TransactionCycleFilter?,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> SettlementVaultPage {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_vault(
          .init(
            path: .init(groupId: groupId.rawValue),
            query: .init(
              filter: LiveSettlementVaultMapping.encodeFilter(filter),
              cycleId: LiveSettlementVaultMapping.encodeCycleQuery(cycleId),
              cursor: cursor,
              limit: limit
            )
          )
        )
      switch output {
      case .ok(let ok):
        return LiveSettlementVaultMapping.mapPage(try ok.body.json)
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
