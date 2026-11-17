public enum GroupEvent: Sendable, Hashable {
  case changed([String])
  case removed
  case reconnected
}
