import Foundation
import OpenAPIRuntime
import os

final class LockedDataBox: Sendable {
  private let state = OSAllocatedUnfairLock<Data?>(initialState: nil)

  func store(_ data: Data) {
    state.withLock { $0 = data }
  }

  func read() -> Data? {
    state.withLock { $0 }
  }
}

enum ResponseBodyCapture {
  @TaskLocal static var box: LockedDataBox?

  static func isDecodingFailure(_ error: any Error) -> Bool {
    if error is DecodingError {
      return true
    }
    if let clientError = error as? ClientError {
      return isDecodingFailure(clientError.underlyingError)
    }
    return false
  }

  static func withCapture<T: Sendable>(
    _ operation: () async throws -> T,
    fallback: (Data) throws -> T
  ) async throws -> T {
    let captureBox = LockedDataBox()
    do {
      return try await Self.$box.withValue(captureBox) {
        try await operation()
      }
    } catch {
      if isDecodingFailure(error), let raw = captureBox.read() {
        return try fallback(raw)
      }
      throw error
    }
  }
}
