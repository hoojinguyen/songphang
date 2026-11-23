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
  let uploadSession: URLSession
  let client: Client
  let errorMapper: ErrorMapper
  private let invalidationHub: SessionInvalidationHub
  private let onSessionInvalidated: @Sendable () async -> Void

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
    self.onSessionInvalidated = onSessionInvalidated

    let invalidateForGeneration: @Sendable (UInt64) async -> Bool = { expectedGeneration in
      await Self.performInvalidation(
        expectedGeneration: expectedGeneration,
        tokenStore: store,
        snapshots: snapshotStore,
        invalidationHub: hub,
        onSessionInvalidated: onSessionInvalidated
      )
    }

    let session = BearerURLSession.makeSession()
    self.urlSession = session
    self.streamingSession = BearerURLSession.makeStreamingSession()
    self.uploadSession = BearerURLSession.makeUploadSession()
    let middleware = AuthMiddleware(
      tokenStore: store,
      appVersion: configuration.appVersion,
      onUnauthorized: invalidateForGeneration
    )
    self.client = Client(
      serverURL: configuration.serverOriginURL,
      configuration: Configuration(dateTranscoder: FlexibleISO8601DateTranscoder()),
      transport: BearerURLSession.makeTransport(session: session),
      middlewares: [middleware]
    )
    self.errorMapper = ErrorMapper(onUnauthorized: invalidateForGeneration)
  }

  public func sessionInvalidations() -> AsyncStream<UInt64> {
    invalidationHub.makeStream()
  }

  @discardableResult
  func invalidateSessionIfMatching(_ expectedGeneration: UInt64) async -> Bool {
    await Self.performInvalidation(
      expectedGeneration: expectedGeneration,
      tokenStore: tokenStore,
      snapshots: snapshots,
      invalidationHub: invalidationHub,
      onSessionInvalidated: onSessionInvalidated
    )
  }

  func invalidateSession() async {
    _ = await Self.performInvalidation(
      expectedGeneration: nil,
      tokenStore: tokenStore,
      snapshots: snapshots,
      invalidationHub: invalidationHub,
      onSessionInvalidated: onSessionInvalidated
    )
  }

  private static func performInvalidation(
    expectedGeneration: UInt64?,
    tokenStore: TokenStore,
    snapshots: SnapshotStore,
    invalidationHub: SessionInvalidationHub,
    onSessionInvalidated: @Sendable () async -> Void
  ) async -> Bool {
    let newGeneration: UInt64
    if let expectedGeneration {
      guard let gen = await tokenStore.clearIfGeneration(expectedGeneration) else {
        return false
      }
      newGeneration = gen
    } else {
      newGeneration = await tokenStore.clear()
    }
    await snapshots.invalidateSession(atLeastTokenGeneration: newGeneration)
    invalidationHub.broadcast(newGeneration)
    await onSessionInvalidated()
    return true
  }

  func performAuthorizedDataRequest(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse, TokenStore.TokenSnapshot) {
    let snapshot = await tokenStore.readSnapshot()
    var modified = request
    modified.setValue(configuration.appVersion, forHTTPHeaderField: "X-App-Version")
    if let token = snapshot.token, !token.isEmpty {
      modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    let (data, response) = try await urlSession.data(for: modified)
    let currentGeneration = await tokenStore.currentGeneration()
    if currentGeneration != snapshot.generation {
      throw StaleSessionError()
    }
    guard let http = response as? HTTPURLResponse else {
      throw AppError.unexpected
    }
    return (data, http, snapshot)
  }

  func performAuthorizedUploadRequest(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse, TokenStore.TokenSnapshot) {
    let snapshot = await tokenStore.readSnapshot()
    var modified = request
    modified.setValue(configuration.appVersion, forHTTPHeaderField: "X-App-Version")
    if let token = snapshot.token, !token.isEmpty {
      modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    let (data, response) = try await uploadSession.data(for: modified)
    let currentGeneration = await tokenStore.currentGeneration()
    if currentGeneration != snapshot.generation {
      throw StaleSessionError()
    }
    guard let http = response as? HTTPURLResponse else {
      throw AppError.unexpected
    }
    return (data, http, snapshot)
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
