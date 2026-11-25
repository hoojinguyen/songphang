import Domain
import Foundation
import GeneratedAPI

enum LiveMemberBreakdownsMapping {
  static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func encodeQuery(
    _ cycleId: BreakdownCycleSelection
  )
    -> Operations.get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_balances_sol_breakdowns
    .Input.Query.cycleIdPayload
  {
    switch cycleId {
    case .auto: return .init(value1: .auto)
    case .current: return .init(value2: .current)
    case .cycle(let id): return .init(value3: id.rawValue)
    }
  }

  static func mapResult(
    _ dto: Components.Schemas.MemberBreakdownsResponse
  ) -> MemberBreakdownsResult {
    MemberBreakdownsResult(
      hasClosedCycles: dto.hasClosedCycles,
      resolvedFocus: mapResolvedFocus(dto.resolvedFocus),
      breakdowns: dto.breakdowns.map(mapBreakdown)
    )
  }

  static func mapResolvedFocus(
    _ dto: Components.Schemas.MemberBreakdownsResolvedFocus
  ) -> MemberBreakdownsResolvedFocus {
    MemberBreakdownsResolvedFocus(
      kind: MemberBreakdownsResolvedFocus.Kind(code: dto.kind.rawValue),
      cycleId: dto.cycleId.map(SettlementCycle.ID.init),
      label: dto.label
    )
  }

  static func mapBreakdown(
    _ dto: Components.Schemas.MemberDebtBreakdownDto
  ) -> MemberDebtBreakdown {
    MemberDebtBreakdown(
      memberId: Member.ID(dto.memberId),
      memberName: dto.memberName,
      shape: MemberShape(code: dto.shape.rawValue),
      color: MemberColor(code: dto.color.rawValue),
      carryOverBalance: Money(Int64(dto.carryOverBalance)),
      focusExpenseDelta: Money(Int64(dto.focusExpenseDelta)),
      focusTransferDelta: Money(Int64(dto.focusTransferDelta)),
      postCycleDelta: Money(Int64(dto.postCycleDelta)),
      netBalance: Money(Int64(dto.netBalance)),
      lines: dto.lines.map(mapLine)
    )
  }

  private static func mapLine(
    _ dto: Components.Schemas.MemberBreakdownLineDto
  ) -> MemberBreakdownLine {
    MemberBreakdownLine(
      transactionId: LedgerTransaction.ID(dto.transactionId),
      type: TransactionType(code: dto._type.rawValue),
      description: dto.description,
      occurredAt: formatISO(dto.occurredAt),
      totalAmount: Money(Int64(dto.totalAmount)),
      payerSummary: dto.payerSummary,
      memberPaid: Money(Int64(dto.memberPaid)),
      memberShare: Money(Int64(dto.memberShare)),
      delta: Money(Int64(dto.delta)),
      isPostCloseoutTransfer: dto.isPostCloseoutTransfer
    )
  }
}
