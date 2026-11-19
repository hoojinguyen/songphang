import Foundation
import os

final class SessionInvalidationHub: Sendable {
  private let continuations = OSAllocatedUnfairLock<[UUID: AsyncStream<Void>.Continuation]>(
    initialState: [:]
  )

  func makeStream() -> AsyncStream<Void> {
    let id = UUID()
    return AsyncStream { continuation in
      self.continuations.withLock { $0[id] = continuation }
      continuation.onTermination = { [weak self] _ in
        _ = self?.continuations.withLock { $0.removeValue(forKey: id) }
      }
    }
  }

  func broadcast() {
    let active = continuations.withLock { Array($0.values) }
    for continuation in active {
      continuation.yield(())
    }
  }
}
