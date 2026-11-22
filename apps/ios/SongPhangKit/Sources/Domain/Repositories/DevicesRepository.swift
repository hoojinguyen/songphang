public enum PushRegistrationEnvironment: String, Sendable, Hashable {
  case sandbox
  case production
}

public protocol DevicesRepository: Sendable {
  func registerDevice(
    token: String,
    environment: PushRegistrationEnvironment
  ) async throws(AppError) -> String

  func removeDevice(id: String) async throws(AppError)

  func updateHidePushContent(_ hideContent: Bool) async throws(AppError) -> Bool
}
