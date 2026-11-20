public import Domain
import Foundation
import GeneratedAPI

public final class LiveActivityRepository: ActivityRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<ActivityItem>? {
    await environment.snapshots.read(.activityFirstPage(groupId.rawValue)) { data in
      try ActivityMapping.decodeResilientPage(from: data)
    }
  }

  public func page(
    groupId: ExpenseGroup.ID,
    cursor: String?
  ) async throws(AppError) -> Page<ActivityItem> {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let pageResult: Page<ActivityItem> = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_activity(
            .init(
              path: .init(groupId: groupId.rawValue),
              query: .init(cursor: cursor, limit: 50)
            )
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          return Page(
            items: body.activity.map(ActivityMapping.mapItem),
            nextCursor: body.nextCursor
          )
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try ActivityMapping.decodeResilientPage(from: data)
      }

      if cursor == nil, let scope, let encoded = ActivityMapping.encodePageSnapshot(pageResult) {
        await environment.snapshots.writeData(
          encoded,
          for: .activityFirstPage(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return pageResult
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
