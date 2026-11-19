public import Domain
import Foundation
import GeneratedAPI
import os

public final class LiveAuthRepository: AuthRepository, Sendable {
  private let environment: LiveAPIEnvironment
  private let currentSessionId = OSAllocatedUnfairLock<UserSession.ID?>(initialState: nil)

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownUser() async -> User? {
    guard await environment.hasToken() else {
      await environment.snapshots.invalidateSession()
      return nil
    }
    return await environment.snapshots.restoreLastUser { data in
      try AuthMapping.decodeCachedUser(from: data)
    }
  }

  public func currentUser() async throws(AppError) -> User? {
    guard await environment.hasToken() else {
      await environment.snapshots.invalidateSession()
      return nil
    }
    do {
      let user: User = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client.get_sol_api_sol_v1_sol_me(.init())
        switch output {
        case .ok(let ok):
          return AuthMapping.mapUser(try ok.body.json.user)
        case .unauthorized(let unauthorized):
          let code = try? unauthorized.body.json.error.code.rawValue
          throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try AuthMapping.decodeCachedUser(from: data).value
      }

      guard await environment.hasToken() else {
        return nil
      }
      let scope = await environment.snapshots.beginSession(userId: user.id.rawValue)
      if let encoded = AuthMapping.encodeCachedUser(user) {
        await environment.snapshots.writeData(encoded, for: .me, scope: scope)
      }
      return user
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func signIn(email: String, password: String) async throws(AppError) -> User {
    do {
      let body = Components.Schemas.TokenLoginRequest(
        client: .ios,
        deviceName: environment.configuration.deviceName,
        email: email,
        password: password
      )
      let output = try await environment.client.post_sol_api_sol_v1_sol_auth_sol_token(
        .init(body: .json(body))
      )
      switch output {
      case .ok(let ok):
        let response = try ok.body.json
        let user = AuthMapping.mapUser(response.user)
        try await environment.tokenStore.write(response.token)
        let scope = await environment.snapshots.beginSession(userId: user.id.rawValue)
        if let encoded = AuthMapping.encodeCachedUser(user) {
          await environment.snapshots.writeData(encoded, for: .me, scope: scope)
        }
        return user
      case .unauthorized(let unauthorized):
        let code = try? unauthorized.body.json.error.code.rawValue
        throw await environment.errorMapper.mapStatus(
          statusCode: 401,
          code: code ?? "INVALID_CREDENTIALS",
          clearSessionOnUnauthorized: false
        )
      case .tooManyRequests:
        throw AppError.rateLimited
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func signInWithGoogle() async throws(AppError) -> User {
    throw .api(code: "NOT_CONNECTED", status: 501)
  }

  public func signInWithApple() async throws(AppError) -> User {
    throw .api(code: "NOT_CONNECTED", status: 501)
  }

  public func register(email: String, name: String, password: String) async throws(AppError) {
    do {
      let body = Components.Schemas.RegisterRequest(email: email, name: name, password: password)
      let output = try await environment.client.post_sol_api_sol_v1_sol_auth_sol_register(
        .init(body: .json(body))
      )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func requestPasswordReset(email: String) async throws(AppError) {
    do {
      let body = Components.Schemas.ForgotPasswordRequest(email: email)
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_auth_sol_forgot_hyphen_password(
          .init(body: .json(body))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func resendVerification() async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_auth_sol_resend_hyphen_verification(.init())
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

  public func changePassword(
    currentPassword: String,
    newPassword: String,
    revokeOtherSessions: Bool
  ) async throws(AppError) {
    do {
      let body = Components.Schemas.ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
        revokeOtherSessions: revokeOtherSessions
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_auth_sol_change_hyphen_password(
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

  public func deleteAccount(email: String) async throws(AppError) {
    do {
      let body = Components.Schemas.DeleteAccountRequest(email: email)
      let output = try await environment.client.delete_sol_api_sol_v1_sol_me(
        .init(body: .json(body))
      )
      switch output {
      case .noContent:
        currentSessionId.withLock { $0 = nil }
        await environment.invalidateSession()
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

  public func sessions() async throws(AppError) -> [UserSession] {
    do {
      let list: [UserSession] = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client.get_sol_api_sol_v1_sol_me_sol_sessions(.init())
        switch output {
        case .ok(let ok):
          return try ok.body.json.sessions.map(AuthMapping.mapSession)
        case .unauthorized(let unauthorized):
          let code = try? unauthorized.body.json.error.code.rawValue
          throw await environment.errorMapper.mapStatus(statusCode: 401, code: code)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try AuthMapping.decodeResilientSessions(from: data)
      }

      let current = list.first(where: \.current)?.id
      currentSessionId.withLock { $0 = current }
      return list
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func revokeSession(id: UserSession.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_me_sol_sessions_sol__lcub_id_rcub_(
          .init(path: .init(id: id.rawValue))
        )
      switch output {
      case .noContent:
        let isCurrent = currentSessionId.withLock { $0 == id }
        if isCurrent {
          currentSessionId.withLock { $0 = nil }
          await environment.invalidateSession()
        }
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

  public func serverFeatures() async throws(AppError) -> ServerFeatures {
    try await environment.fetchServerFeatures()
  }

  public func signOut() async throws(AppError) {
    if await environment.hasToken() {
      _ = try? await environment.client.post_sol_api_sol_v1_sol_auth_sol_logout(.init())
    }
    currentSessionId.withLock { $0 = nil }
    await environment.invalidateSession()
  }
}
