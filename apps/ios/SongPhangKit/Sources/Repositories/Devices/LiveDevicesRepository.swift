public import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveDevicesRepository: DevicesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func registerDevice(
    token: String,
    environment env: PushRegistrationEnvironment
  ) async throws(AppError) -> String {
    do {
      let body = Components.Schemas.RegisterDeviceRequest(
        environment: env == .production ? .production : .sandbox,
        platform: .ios,
        token: token
      )
      let output = try await environment.client.post_sol_api_sol_v1_sol_me_sol_devices(
        .init(body: .json(body))
      )
      switch output {
      case .ok(let ok):
        return try ok.body.json.id
      case .badRequest(let badRequest):
        let code = try? badRequest.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(
          statusCode: 400,
          code: code ?? "VALIDATION_FAILED"
        )
      case .unauthorized(let unauthorized):
        let code = try? unauthorized.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
      case .forbidden(let forbidden):
        let code = try? forbidden.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 403, code: code ?? "FORBIDDEN")
      case .unprocessableContent(let unprocessable):
        let code = try? unprocessable.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(
          statusCode: 422,
          code: code ?? "LIMIT_REACHED"
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

  public func removeDevice(id: String) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_me_sol_devices_sol__lcub_id_rcub_(
          .init(path: .init(id: id))
        )
      switch output {
      case .noContent:
        return
      case .unauthorized(let unauthorized):
        let code = try? unauthorized.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
      case .notFound(let notFound):
        let code = try? notFound.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 404, code: code ?? "NOT_FOUND")
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func updateHidePushContent(_ hideContent: Bool) async throws(AppError) -> Bool {
    do {
      let output = try await environment.client.put_sol_api_sol_v1_sol_me_sol_push_hyphen_settings(
        .init(body: .json(.init(hideContent: hideContent)))
      )
      switch output {
      case .ok(let ok):
        return try ok.body.json.hideContent
      case .unauthorized(let unauthorized):
        let code = try? unauthorized.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
      case .notFound(let notFound):
        let code = try? notFound.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(statusCode: 404, code: code ?? "NOT_FOUND")
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
