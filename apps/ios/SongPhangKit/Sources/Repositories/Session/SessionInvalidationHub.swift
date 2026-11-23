import Foundation
import os

final class SessionInvalidationHub: Sendable {
  private let continuations = OSAllocatedUnfairLock<[UUID: AsyncStream<UInt64>.Continuation]>(
    initialState: [:]
  )

  func makeStream() -> AsyncStream<UInt64> {
    let id = UUID()
    return AsyncStream { continuation in
      self.continuations.withLock { $0[id] = continuation }
      continuation.onTermination = { [weak self] _ in
        _ = self?.continuations.withLock { $0.removeValue(forKey: id) }
      }
    }
  }

  func broadcast(_ generation: UInt64) {
    let active = continuations.withLock { Array($0.values) }
    for continuation in active {
      continuation.yield(generation)
    }
  }
}
