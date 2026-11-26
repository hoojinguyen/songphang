public import Domain
import Foundation
import GeneratedAPI

public final class LiveSettlementCyclesRepository: SettlementCyclesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> SettlementCyclesOverview {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_cycles(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        let body = try ok.body.json
        return SettlementCyclesOverview(
          cycles: body.cycles.map(Self.mapCycle),
          currentPeriod: Self.mapCurrentPeriod(body.currentPeriod)
        )
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func close(
    groupId: ExpenseGroup.ID,
    title: String?,
    idempotencyKey: IdempotencyKey
  ) async throws(AppError) -> SettlementCycle {
    do {
      let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
      let body: Components.Schemas.CreateSettlementCycleRequest = .init(
        title: (trimmed?.isEmpty == false) ? trimmed : nil
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_cycles(
          .init(
            path: .init(groupId: groupId.rawValue),
            headers: .init(idempotency_hyphen_key: idempotencyKey.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .created(let created):
        return Self.mapCycle(try created.body.json.cycle)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func reopen(
    groupId: ExpenseGroup.ID,
    cycleId: SettlementCycle.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_cycles_sol__lcub_cycleId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, cycleId: cycleId.rawValue))
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

  static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapCurrentPeriod(
    _ dto: Components.Schemas.CurrentPeriodSummaryDto
  ) -> CurrentPeriodSummary {
    CurrentPeriodSummary(
      startedAt: formatISO(dto.startedAt),
      expenseCount: dto.expenseCount,
      totalExpenseAmount: Money(Int64(dto.totalExpenseAmount)),
      countedTransactionCount: dto.countedTransactionCount
    )
  }

  static func mapCycle(_ dto: Components.Schemas.SettlementCycleDto) -> SettlementCycle {
    SettlementCycle(
      id: SettlementCycle.ID(dto.id),
      cycleNumber: dto.cycleNumber,
      title: dto.title,
      startedAt: formatISO(dto.startedAt),
      closedAt: formatISO(dto.closedAt),
      closedBy: dto.closedBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      expenseCount: dto.expenseCount,
      totalExpenseAmount: Money(Int64(dto.totalExpenseAmount)),
      snapshot: SettlementCycle.Snapshot(
        balances: dto.snapshot.balances.map {
          SettlementCycle.BalanceSnapshot(
            memberId: Member.ID($0.memberId),
            name: $0.name,
            shape: MemberShape(code: $0.shape.rawValue),
            color: MemberColor(code: $0.color.rawValue),
            balance: Money(Int64($0.balance))
          )
        },
        transfers: dto.snapshot.transfers.map {
          SettlementCycle.TransferSnapshot(
            fromMemberId: Member.ID($0.fromMemberId),
            fromName: $0.fromName,
            toMemberId: Member.ID($0.toMemberId),
            toName: $0.toName,
            amount: Money(Int64($0.amount))
          )
        },
        fundBalance: dto.snapshot.fundBalance.map { Money(Int64($0)) }
      )
    )
  }
}
