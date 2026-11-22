import Domain
import Foundation
import GeneratedAPI

enum BudgetMapping {
  static func mapBudget(_ dto: Components.Schemas.BudgetDto) -> GroupBudget {
    GroupBudget(
      period: BudgetPeriod(rawValue: dto.period.rawValue) ?? .month,
      amount: Money(Int64(dto.amount)),
      spent: Money(Int64(dto.spent)),
      state: BudgetState(code: dto.state.rawValue),
      periodStart: dto.periodStart,
      periodEnd: dto.periodEnd
    )
  }

  static func encodePutRequest(
    period: BudgetPeriod,
    amount: Money
  ) -> Components.Schemas.PutBudgetRequest {
    let encodedPeriod: Components.Schemas.PutBudgetRequest.periodPayload =
      switch period {
      case .month: .month
      case .total: .total
      }
    return Components.Schemas.PutBudgetRequest(
      amount: Int(amount.amount),
      period: encodedPeriod
    )
  }

  struct RawBudget: Codable, Sendable {
    let period: String
    let amount: Int64
    let spent: Int64
    let state: String
    let periodStart: String?
    let periodEnd: String?

    init(_ budget: GroupBudget) {
      self.period = budget.period.rawValue
      self.amount = budget.amount.amount
      self.spent = budget.spent.amount
      self.state = budget.state.code
      self.periodStart = budget.periodStart
      self.periodEnd = budget.periodEnd
    }

    func toDomain() -> GroupBudget {
      GroupBudget(
        period: BudgetPeriod(rawValue: period) ?? .month,
        amount: Money(amount),
        spent: Money(spent),
        state: BudgetState(code: state),
        periodStart: periodStart,
        periodEnd: periodEnd
      )
    }
  }

  private struct RawBudgetResponse: Codable, Sendable {
    let budget: RawBudget?
  }

  static func decodeResilientResponse(from data: Data) throws -> GroupBudget? {
    try JSONDecoder().decode(RawBudgetResponse.self, from: data).budget?.toDomain()
  }

  static func encodeSnapshot(_ budget: GroupBudget?) -> Data? {
    try? JSONEncoder().encode(RawBudgetResponse(budget: budget.map(RawBudget.init)))
  }
}
