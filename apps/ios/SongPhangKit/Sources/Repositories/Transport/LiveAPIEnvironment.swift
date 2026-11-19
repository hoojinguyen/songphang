public import Domain
import Foundation
import GeneratedAPI
import OpenAPIRuntime

public final class LiveAPIEnvironment: Sendable {
  public let configuration: APIConfiguration
  let tokenStore: TokenStore
  let snapshots: SnapshotStore
  let urlSession: URLSession
  let streamingSession: URLSession
  let client: Client
  let errorMapper: ErrorMapper
  private let invalidationHub: SessionInvalidationHub

  public init(
    configuration: APIConfiguration,
    onSessionInvalidated: @escaping @Sendable () async -> Void = {}
  ) {
    self.configuration = configuration
    let store = TokenStore()
    let snapshotStore = SnapshotStore()
    let hub = SessionInvalidationHub()
    self.tokenStore = store
    self.snapshots = snapshotStore
    self.invalidationHub = hub

    let session = BearerURLSession.makeSession()
    self.urlSession = session
    self.streamingSession = BearerURLSession.makeStreamingSession()
    let middleware = AuthMiddleware(
      tokenStore: store,
      appVersion: configuration.appVersion
    )
    self.client = Client(
      serverURL: configuration.serverOriginURL,
      configuration: Configuration(dateTranscoder: FlexibleISO8601DateTranscoder()),
      transport: BearerURLSession.makeTransport(session: session),
      middlewares: [middleware]
    )
    self.errorMapper = ErrorMapper {
      await store.clear()
      await snapshotStore.invalidateSession()
      hub.broadcast()
      await onSessionInvalidated()
    }
  }

  public func sessionInvalidations() -> AsyncStream<Void> {
    invalidationHub.makeStream()
  }

  func invalidateSession() async {
    await tokenStore.clear()
    await snapshots.invalidateSession()
    invalidationHub.broadcast()
  }

  func hasToken() async -> Bool {
    guard let token = await tokenStore.read() else { return false }
    return !token.isEmpty
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
        push: featuresBody.push,
        receiptReading: featuresBody.receiptReading,
        sentenceAi: featuresBody.sentenceAi,
        telegram: featuresBody.telegram,
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
