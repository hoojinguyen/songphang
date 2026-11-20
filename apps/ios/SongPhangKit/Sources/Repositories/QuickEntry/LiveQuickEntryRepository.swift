public import Domain
import Foundation
import GeneratedAPI

public final class LiveQuickEntryRepository: QuickEntryRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func parse(
    groupId: ExpenseGroup.ID,
    text: String
  ) async throws(AppError) -> QuickEntryReading {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol_parse(
            .init(
              path: .init(groupId: groupId.rawValue),
              body: .json(.init(text: text))
            )
          )
        switch output {
        case .ok(let ok):
          return QuickEntryMapping.mapResponse(try ok.body.json)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try QuickEntryMapping.decodeResilient(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
