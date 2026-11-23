import Foundation
import HTTPTypes
import OpenAPIRuntime

struct AuthMiddleware: ClientMiddleware {
  private static let unauthenticatedAuthPaths: Set<String> = [
    "/api/v1/auth/login",
    "/api/v1/auth/token",
    "/api/v1/auth/apple",
    "/api/v1/auth/exchange",
    "/api/v1/auth/register",
    "/api/v1/auth/forgot-password",
    "/api/v1/auth/reset-password",
    "/api/v1/auth/verify-email",
    "/api/v1/auth/providers",
    "/api/v1/features",
  ]

  private let tokenStore: TokenStore
  private let appVersion: String
  private let onUnauthorized: @Sendable (UInt64) async -> Bool

  init(
    tokenStore: TokenStore,
    appVersion: String,
    onUnauthorized: @escaping @Sendable (UInt64) async -> Bool
  ) {
    self.tokenStore = tokenStore
    self.appVersion = appVersion
    self.onUnauthorized = onUnauthorized
  }

  @concurrent
  func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next:
      @concurrent @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
        HTTPResponse, HTTPBody?
      )
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var modified = request
    if let versionHeader = HTTPField.Name("X-App-Version") {
      modified.headerFields[versionHeader] = appVersion
    }

    let requestPath = modified.path?.split(separator: "?").first.map(String.init) ?? ""
    let isUnauthenticatedPath = Self.unauthenticatedAuthPaths.contains(requestPath)
    let snapshot = await tokenStore.readSnapshot()
    if !isUnauthenticatedPath, let token = snapshot.token, !token.isEmpty {
      modified.headerFields[.authorization] = "Bearer \(token)"
    }

    let (response, responseBody) = try await next(modified, body, baseURL)

    if !isUnauthenticatedPath, await tokenStore.currentGeneration() != snapshot.generation {
      throw StaleSessionError()
    }

    if response.status.code == 401,
      !isUnauthenticatedPath,
      let token = snapshot.token,
      !token.isEmpty
    {
      var errorCode: String?
      var bufferedBody: HTTPBody?
      if let responseBody {
        let data = try await Data(collecting: responseBody, upTo: 64 * 1024)
        bufferedBody = HTTPBody(data)
        errorCode = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
      }
      if errorCode != "INVALID_CREDENTIALS" {
        let invalidated = await onUnauthorized(snapshot.generation)
        if !invalidated {
          throw StaleSessionError()
        }
      }
      return (response, bufferedBody)
    }

    if let captureBox = ResponseBodyCapture.box,
      (200..<300).contains(response.status.code),
      let contentType = response.headerFields[.contentType]?.lowercased(),
      contentType.contains("application/json"),
      let responseBody
    {
      let data = try await Data(collecting: responseBody, upTo: 8 * 1024 * 1024)
      captureBox.store(data)
      return (response, HTTPBody(data))
    }

    return (response, responseBody)
  }
}
