public import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveAPIEnvironment: Sendable {
  public let configuration: APIConfiguration
  let tokenStore: TokenStore
  let urlSession: URLSession
  let streamingSession: URLSession
  let client: Client
  let errorMapper: ErrorMapper

  public init(
    configuration: APIConfiguration,
    onSessionInvalidated: @escaping @Sendable () async -> Void = {}
  ) {
    self.configuration = configuration
    let store = TokenStore()
    self.tokenStore = store
    let session = BearerURLSession.makeSession()
    self.urlSession = session
    self.streamingSession = BearerURLSession.makeStreamingSession()
    let middleware = AuthMiddleware(
      tokenStore: store,
      appVersion: configuration.appVersion
    )
    self.client = Client(
      serverURL: configuration.serverOriginURL,
      transport: BearerURLSession.makeTransport(session: session),
      middlewares: [middleware]
    )
    self.errorMapper = ErrorMapper {
      await store.clear()
      await onSessionInvalidated()
    }
  }

  public func fetchServerFeatures() async throws(AppError) -> ServerFeatures {
    do {
      async let featuresCall = client.get_sol_api_sol_v1_sol_features(.init())
      async let providersCall = client.get_sol_api_sol_v1_sol_auth_sol_providers(.init())
      let (featuresOutput, providersOutput) = try await (featuresCall, providersCall)

      let featuresBody: Components.Schemas.FeaturesResponse
      switch featuresOutput {
      case .ok(let ok):
        featuresBody = try ok.body.json
      case .undocumented(let status, let payload):
        throw await errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }

      let providersBody: Components.Schemas.ProvidersResponse
      switch providersOutput {
      case .ok(let ok):
        providersBody = try ok.body.json
      case .undocumented(let status, let payload):
        throw await errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }

      return ServerFeatures(
        google: providersBody.google,
        apple: featuresBody.appleSignIn,
        devLogin: providersBody.devLogin,
        minAppVersion: ServerFeatures.MinAppVersion(
          ios: featuresBody.minAppVersion.ios,
          android: featuresBody.minAppVersion.android
        )
      )
    } catch let error as AppError {
      throw error
    } catch {
      throw errorMapper.mapTransportError(error)
    }
  }
}
