public import Domain
import Foundation
import GeneratedAPI

public final class LiveOverviewRepository: OverviewRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownOverview() async -> OverviewSummary? {
    await environment.snapshots.read(.overview) { data in
      try OverviewMapping.decodeResilientOverview(from: data)
    }
  }

  public func overview() async throws(AppError) -> OverviewSummary {
    let scope = await environment.snapshots.currentScope()
    do {
      let summary: OverviewSummary = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client.get_sol_api_sol_v1_sol_me_sol_overview(.init())
        switch output {
        case .ok(let ok):
          let json = try ok.body.json
          return OverviewMapping.mapSummary(json)
        case .unauthorized(let unauth):
          let code = try? unauth.body.json.error.code.rawValue
          throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try OverviewMapping.decodeResilientOverview(from: data)
      }

      if let scope, let encoded = OverviewMapping.encodeOverviewSnapshot(summary) {
        await environment.snapshots.writeData(encoded, for: .overview, scope: scope)
      }
      return summary
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func transactions(
    cursor: String?,
    limit: Int,
    type: TransactionType?,
    groupId: ExpenseGroup.ID?,
    query: String?
  ) async throws(AppError) -> PersonalTransactionsPage {
    let queryType: Operations.get_sol_api_sol_v1_sol_me_sol_transactions.Input.Query._typePayload? =
      {
        guard let type else { return nil }
        switch type {
        case .expense: return .expense
        case .income: return .income
        case .transfer: return .transfer
        case .unknown: return nil
        }
      }()

    do {
      let output = try await environment.client.get_sol_api_sol_v1_sol_me_sol_transactions(
        .init(
          query: .init(
            cursor: cursor,
            limit: limit,
            _type: queryType,
            groupId: groupId?.rawValue,
            q: query
          )
        )
      )
      switch output {
      case .ok(let ok):
        let body = try ok.body.json
        let items = body.items.map(OverviewMapping.mapPersonalTransaction)
        return PersonalTransactionsPage(items: items, nextCursor: body.nextCursor)
      case .badRequest:
        throw await environment.errorMapper.mapStatus(statusCode: 400, code: nil)
      case .unauthorized:
        throw await environment.errorMapper.mapStatus(statusCode: 401, code: nil)
      case .notFound:
        throw await environment.errorMapper.mapStatus(statusCode: 404, code: nil)
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
