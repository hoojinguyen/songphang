public import Domain
import Foundation

public final class LiveGroupEventsRepository: GroupEventsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func events(groupId: ExpenseGroup.ID) -> AsyncStream<GroupEvent> {
    let env = environment
    return AsyncStream { continuation in
      let task = Task {
        await Self.runStream(
          groupId: groupId,
          environment: env,
          continuation: continuation
        )
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  private struct ChangedPayload: Decodable {
    let resources: [String]
  }

  private static func runStream(
    groupId: ExpenseGroup.ID,
    environment: LiveAPIEnvironment,
    continuation: AsyncStream<GroupEvent>.Continuation
  ) async {
    var backoffSeconds: UInt64 = 1
    var hasConnectedOnce = false

    while !Task.isCancelled {
      let snapshot = await environment.tokenStore.readSnapshot()
      guard let token = snapshot.token, !token.isEmpty else {
        continuation.finish()
        return
      }

      var request = URLRequest(
        url: environment.configuration.v1URL(path: "/groups/\(groupId.rawValue)/events")
      )
      request.httpMethod = "GET"
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      request.setValue(environment.configuration.appVersion, forHTTPHeaderField: "X-App-Version")
      request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
      request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

      do {
        let (bytes, response) = try await environment.streamingSession.bytes(for: request)
        guard await environment.tokenStore.currentGeneration() == snapshot.generation else {
          continuation.finish()
          return
        }
        guard let http = response as? HTTPURLResponse else {
          try await sleepBackoff(&backoffSeconds)
          continue
        }

        if http.statusCode == 401 {
          await environment.invalidateSessionIfMatching(snapshot.generation)
          continuation.finish()
          return
        }

        if http.statusCode == 404 {
          if await environment.tokenStore.currentGeneration() == snapshot.generation {
            await environment.snapshots.invalidateGroup(groupId.rawValue)
            continuation.yield(.removed)
          }
          continuation.finish()
          return
        }

        guard http.statusCode == 200 else {
          try await sleepBackoff(&backoffSeconds)
          continue
        }

        backoffSeconds = 1
        if hasConnectedOnce {
          continuation.yield(.reconnected)
        }
        hasConnectedOnce = true

        var currentEvent: String?
        var dataLines: [String] = []

        for try await line in bytes.lines {
          if Task.isCancelled {
            continuation.finish()
            return
          }
          if await environment.tokenStore.currentGeneration() != snapshot.generation {
            continuation.finish()
            return
          }
          if line.isEmpty {
            if currentEvent != nil && !dataLines.isEmpty {
              let shouldStop = await dispatchFrame(
                eventName: currentEvent,
                dataLines: dataLines,
                groupId: groupId,
                expectedTokenGeneration: snapshot.generation,
                environment: environment,
                continuation: continuation
              )
              currentEvent = nil
              dataLines.removeAll(keepingCapacity: true)
              if shouldStop {
                continuation.finish()
                return
              }
            }
            continue
          }
          if line.hasPrefix(":") {
            // Keep-alive or connection comment
            continue
          }
          if line.hasPrefix("event:") {
            currentEvent = String(line.dropFirst("event:".count))
              .trimmingCharacters(in: .whitespaces)
          } else if line.hasPrefix("data:") {
            let raw = String(line.dropFirst("data:".count))
            let trimmed = raw.hasPrefix(" ") ? String(raw.dropFirst()) : raw
            dataLines.append(trimmed)

            if currentEvent != nil {
              let shouldStop = await dispatchFrame(
                eventName: currentEvent,
                dataLines: dataLines,
                groupId: groupId,
                expectedTokenGeneration: snapshot.generation,
                environment: environment,
                continuation: continuation
              )
              currentEvent = nil
              dataLines.removeAll(keepingCapacity: true)
              if shouldStop {
                continuation.finish()
                return
              }
            }
          }
        }

        // Stream ended cleanly (e.g. server restart or session revoked on server).
        // Immediately reconnect after short backoff; 401/404 on reconnect handles revocation/removal.
        if Task.isCancelled {
          continuation.finish()
          return
        }
        try await sleepBackoff(&backoffSeconds)
      } catch is CancellationError {
        continuation.finish()
        return
      } catch {
        if Task.isCancelled {
          continuation.finish()
          return
        }
        do {
          try await sleepBackoff(&backoffSeconds)
        } catch {
          continuation.finish()
          return
        }
      }
    }
    continuation.finish()
  }

  private static func dispatchFrame(
    eventName: String?,
    dataLines: [String],
    groupId: ExpenseGroup.ID,
    expectedTokenGeneration: UInt64,
    environment: LiveAPIEnvironment,
    continuation: AsyncStream<GroupEvent>.Continuation
  ) async -> Bool {
    guard let eventName else { return false }
    guard await environment.tokenStore.currentGeneration() == expectedTokenGeneration else {
      return true
    }
    switch eventName {
    case "changed":
      let joined = dataLines.joined(separator: "\n")
      if let data = joined.data(using: .utf8),
        let decoded = try? JSONDecoder().decode(ChangedPayload.self, from: data)
      {
        continuation.yield(.changed(decoded.resources))
      }
      return false
    case "removed":
      await environment.snapshots.invalidateGroup(groupId.rawValue)
      continuation.yield(.removed)
      return true
    default:
      return false
    }
  }

  private static func sleepBackoff(_ seconds: inout UInt64) async throws {
    let wait = seconds
    seconds = min(seconds * 2, 30)
    try await Task.sleep(for: .seconds(wait))
  }
}
