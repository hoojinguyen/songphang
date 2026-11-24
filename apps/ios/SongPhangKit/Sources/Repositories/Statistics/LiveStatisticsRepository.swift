public import Domain
public import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveStatisticsRepository: StatisticsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func stats(
    groupId: ExpenseGroup.ID,
    from: String?,
    to: String?
  ) async throws(AppError) -> GroupStats {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_stats(
            .init(
              path: .init(groupId: groupId.rawValue),
              query: .init(from: from, to: to)
            )
          )
        switch output {
        case .ok(let ok):
          return StatsMapping.mapStats(try ok.body.json)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try StatsMapping.decodeResilientStats(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func exportCSV(groupId: ExpenseGroup.ID) async throws(AppError) -> Data {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_export_period_csv(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        let body = try ok.body.csv
        return try await Data(collecting: body, upTo: 10 * 1024 * 1024)
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
