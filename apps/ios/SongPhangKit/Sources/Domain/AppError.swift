public enum AppError: Error, Sendable, Equatable {
  case offline
  case unauthorized
  case upgradeRequired
  case conflict
  case groupArchived
  case cycleEmpty
  case cycleNotLatest
  case householdMemberConflict
  case householdRepresentativeActiveRequired
  case recurringMemberInactive
  case rateLimited
  case reminderTooSoon(nextAt: String)
  case api(code: String, status: Int)
  case unexpected
}
