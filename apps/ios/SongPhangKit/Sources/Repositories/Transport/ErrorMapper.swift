import Domain
import Foundation
import OpenAPIRuntime

struct StaleSessionError: Error, Sendable {}

struct APIErrorPayload: Decodable, Sendable {
  struct Inner: Decodable, Sendable {
    let code: String
    let message: String?
  }

  let error: Inner
}

struct ErrorMapper: Sendable {
  private let onUnauthorized: @Sendable (UInt64) async -> Bool

  init(onUnauthorized: @escaping @Sendable (UInt64) async -> Bool) {
    self.onUnauthorized = onUnauthorized
  }

  func mapTransportError(_ error: any Error) -> AppError {
    if error is StaleSessionError {
      return .api(code: "STALE_SESSION", status: 0)
    }
    if let appError = error as? AppError {
      return appError
    }
    if let clientError = error as? ClientError {
      return mapTransportError(clientError.underlyingError)
    }
    if let urlError = error as? URLError {
      switch urlError.code {
      case .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .cannotConnectToHost,
        .cannotFindHost,
        .dnsLookupFailed,
        .dataNotAllowed,
        .internationalRoamingOff:
        return .offline
      default:
        return .unexpected
      }
    }
    return .unexpected
  }

  func mapUndocumented(
    statusCode: Int,
    payload: UndocumentedPayload,
    clearSessionOnUnauthorized: Bool = true,
    sessionGeneration: UInt64? = nil
  ) async -> AppError {
    var errorCode: String?
    if let body = payload.body {
      if let data = try? await Data(collecting: body, upTo: 64 * 1024),
        let decoded = try? JSONDecoder().decode(APIErrorPayload.self, from: data)
      {
        errorCode = decoded.error.code
      }
    }
    return await mapStatus(
      statusCode: statusCode,
      code: errorCode,
      clearSessionOnUnauthorized: clearSessionOnUnauthorized,
      sessionGeneration: sessionGeneration
    )
  }

  func mapStatus(
    statusCode: Int,
    code: String?,
    clearSessionOnUnauthorized: Bool = true,
    sessionGeneration: UInt64? = nil
  ) async -> AppError {
    if statusCode == 401 {
      if code == "INVALID_CREDENTIALS" {
        return .api(code: "INVALID_CREDENTIALS", status: 401)
      }
      if clearSessionOnUnauthorized, let sessionGeneration {
        let invalidated = await onUnauthorized(sessionGeneration)
        if !invalidated {
          return .api(code: "STALE_SESSION", status: 0)
        }
      }
      return .unauthorized
    }
    if statusCode == 409 {
      if code == nil || code == "VERSION_CONFLICT" || code == "CONFLICT" {
        return .conflict
      }
      if let code {
        return .api(code: code, status: 409)
      }
    }
    if statusCode == 429 || code == "RATE_LIMITED" {
      return .rateLimited
    }
    if let code {
      return .api(code: code, status: statusCode)
    }
    return .api(code: "HTTP_\(statusCode)", status: statusCode)
  }
}
