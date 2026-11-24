public import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveRemindersRepository: RemindersRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func sendReminder(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID
  ) async throws(AppError) -> SendReminderResult {
    do {
      let body = Components.Schemas.SendReminderRequest(
        value1: .init(
          fromMemberId: fromMemberId.rawValue,
          toMemberId: toMemberId.rawValue
        )
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_reminders(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .ok(let ok):
        return try NotificationsMapping.mapReminderResult(ok.body.json)
      case .undocumented(let status, let payload):
        if status == 429, let body = payload.body {
          if let data = try? await Data(collecting: body, upTo: 64 * 1024),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let errObj = json["error"] as? [String: Any],
            let code = errObj["code"] as? String,
            code == "REMINDER_TOO_SOON",
            let details = errObj["details"] as? [String: Any],
            let nextAt = details["nextAt"] as? String
          {
            throw AppError.reminderTooSoon(nextAt: nextAt)
          }
        }
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func sendAllReminders(groupId: ExpenseGroup.ID) async throws(AppError)
    -> SendReminderResult
  {
    do {
      let body = Components.Schemas.SendReminderRequest(
        value2: .init(all: true)
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_reminders(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .ok(let ok):
        return try NotificationsMapping.mapReminderResult(ok.body.json)
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
