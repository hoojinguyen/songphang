public enum AppError: Error, Sendable, Equatable {
  case offline
  case unauthorized
  case upgradeRequired
  case conflict
  case groupArchived
  case rateLimited
  case reminderTooSoon(nextAt: String)
  case api(code: String, status: Int)
  case unexpected
}
