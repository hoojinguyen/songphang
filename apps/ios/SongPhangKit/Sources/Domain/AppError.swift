public enum AppError: Error, Sendable, Equatable {
  case offline
  case unauthorized
  case upgradeRequired
  case conflict
  case rateLimited
  case api(code: String, status: Int)
  case unexpected
}
