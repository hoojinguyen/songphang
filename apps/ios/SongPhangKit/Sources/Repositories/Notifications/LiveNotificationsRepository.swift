public import Domain
import Foundation
import GeneratedAPI

public final class LiveNotificationsRepository: NotificationsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func list(cursor: String?, limit: Int) async throws(AppError) -> (
    notifications: [AppNotification], nextCursor: String?
  ) {
    do {
      let output = try await environment.client.get_sol_api_sol_v1_sol_me_sol_notifications(
        .init(
          query: .init(
            cursor: cursor,
            limit: limit
          )
        )
      )
      switch output {
      case .ok(let ok):
        let dtos = try ok.body.json.notifications
        let nextCursor = try ok.body.json.nextCursor
        let mapped = dtos.map(NotificationsMapping.mapNotification)
        return (mapped, nextCursor)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func unreadCount() async throws(AppError) -> Int {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_me_sol_notifications_sol_unread_hyphen_count(
          .init()
        )
      switch output {
      case .ok(let ok):
        return try ok.body.json.count
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func markRead(ids: [AppNotification.ID]) async throws(AppError) {
    guard !ids.isEmpty else { return }
    do {
      let body = Components.Schemas.MarkNotificationsReadRequest(
        value1: .init(ids: ids.map(\.rawValue))
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_me_sol_notifications_sol_read(
          .init(body: .json(body))
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

  public func markAllRead() async throws(AppError) {
    do {
      let body = Components.Schemas.MarkNotificationsReadRequest(
        value2: .init(all: true)
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_me_sol_notifications_sol_read(
          .init(body: .json(body))
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

  public func settings() async throws(AppError) -> NotificationSettings {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_me_sol_notification_hyphen_settings(
          .init()
        )
      switch output {
      case .ok(let ok):
        return try NotificationsMapping.mapSettings(ok.body.json)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func updateSettings(emailImmediate: Bool?, emailDigest: Bool?) async throws(AppError)
    -> NotificationSettings
  {
    do {
      let body = Components.Schemas.UpdateNotificationSettingsRequest(
        emailDigest: emailDigest,
        emailImmediate: emailImmediate
      )
      let output = try await environment.client
        .put_sol_api_sol_v1_sol_me_sol_notification_hyphen_settings(
          .init(body: .json(body))
        )
      switch output {
      case .ok(let ok):
        return try NotificationsMapping.mapSettings(ok.body.json)
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
