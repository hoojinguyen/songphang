import Foundation
import HTTPTypes
import OpenAPIRuntime

struct AuthMiddleware: ClientMiddleware {
  private let tokenStore: TokenStore
  private let appVersion: String

  init(tokenStore: TokenStore, appVersion: String) {
    self.tokenStore = tokenStore
    self.appVersion = appVersion
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
    if let token = await tokenStore.read(), !token.isEmpty {
      modified.headerFields[.authorization] = "Bearer \(token)"
    }
    return try await next(modified, body, baseURL)
  }
}
