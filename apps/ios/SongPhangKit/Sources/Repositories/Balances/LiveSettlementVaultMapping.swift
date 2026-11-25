import Domain
import Foundation
import GeneratedAPI

enum LiveSettlementVaultMapping {
  static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapPaymentChannel(_ dto: Components.Schemas.PaymentChannel?) -> PaymentChannel? {
    dto.map { PaymentChannel(code: $0.rawValue) }
  }

  static func encodePaymentChannel(_ channel: PaymentChannel?) -> Components.Schemas.PaymentChannel?
  {
    guard let channel else { return nil }
    switch channel {
    case .bank: return .bank
    case .momo: return .momo
    case .zalopay: return .zalopay
    case .cash: return .cash
    case .unknown: return nil
    }
  }

  static func encodeFilter(
    _ filter: SettlementVaultFilter
  ) -> Components.Schemas.SettlementVaultFilter {
    switch filter {
    case .all: return .all
    case .pending: return .pending
    case .confirmed: return .confirmed
    case .withProof: return .with_proof
    }
  }

  static func encodeCycleQuery(
    _ cycleId: TransactionCycleFilter?
  )
    -> Operations.get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_vault
    .Input.Query.cycleIdPayload?
  {
    guard let cycleId else { return nil }
    switch cycleId {
    case .current: return .init(value1: .current)
    case .cycle(let id): return .init(value2: id.rawValue)
    }
  }

  static func mapPage(_ dto: Components.Schemas.SettlementVaultResponse) -> SettlementVaultPage {
    SettlementVaultPage(
      items: dto.items.map(mapItem),
      summary: SettlementVaultSummary(
        pendingCount: dto.summary.pendingCount,
        confirmedCount: dto.summary.confirmedCount,
        confirmedTotalAmount: Money(Int64(dto.summary.confirmedTotalAmount)),
        proofCount: dto.summary.proofCount
      ),
      nextCursor: dto.nextCursor
    )
  }

  private static func mapItem(
    _ dto: Components.Schemas.SettlementVaultItemDto
  ) -> SettlementVaultItem {
    SettlementVaultItem(
      id: dto.id,
      kind: SettlementVaultItem.Kind(code: dto.kind.rawValue),
      status: SettlementRequestStatus(code: dto.status.rawValue),
      transactionId: dto.transactionId.map(LedgerTransaction.ID.init),
      settlementRequestId: dto.settlementRequestId,
      fromMemberId: Member.ID(dto.fromMemberId),
      toMemberId: Member.ID(dto.toMemberId),
      amount: Money(Int64(dto.amount)),
      channel: mapPaymentChannel(dto.channel),
      note: dto.note,
      description: dto.description,
      attachments: dto.attachments.map(ReceiptMapping.mapAttachment),
      createdBy: dto.createdBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      resolvedBy: dto.resolvedBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      occurredAt: formatISO(dto.occurredAt),
      resolvedAt: dto.resolvedAt.map(formatISO),
      cycleId: dto.cycleId.map(SettlementCycle.ID.init)
    )
  }
}
