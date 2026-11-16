public enum Loadable<Value: Sendable>: Sendable {
  case loading
  case loaded(Value)
  case failed(AppError)

  public var value: Value? {
    if case .loaded(let value) = self {
      return value
    }
    return nil
  }
}

extension Loadable: Equatable where Value: Equatable {}
