import Domain
import Foundation
import GeneratedAPI

enum ReceiptMapping {
  static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapAttachment(_ dto: Components.Schemas.AttachmentDto) -> Attachment {
    Attachment(
      id: Attachment.ID(dto.id),
      contentType: dto.contentType.rawValue,
      byteSize: dto.byteSize,
      transactionId: dto.transactionId.map(LedgerTransaction.ID.init),
      createdAt: formatISO(dto.createdAt)
    )
  }

  static func mapReceiptScan(_ dto: Components.Schemas.ReceiptScanDto) -> ReceiptScan {
    let reading: ReceiptReading? = dto.reading.map { r in
      ReceiptReading(
        merchant: r.merchant,
        occurredOn: r.occurredOn,
        items: r.items.map {
          ReceiptItem(name: $0.name, quantity: $0.quantity, amount: Money(Int64($0.amount)))
        },
        extras: r.extras.map {
          ReceiptExtra(
            kind: ReceiptExtraKind(code: $0.kind.rawValue),
            label: $0.label,
            amount: Money(Int64($0.amount))
          )
        },
        total: r.total.map { Money(Int64($0)) }
      )
    }
    return ReceiptScan(
      id: ReceiptScan.ID(dto.id),
      attachmentId: Attachment.ID(dto.attachmentId),
      status: ReceiptScanStatus(code: dto.status.rawValue),
      reading: reading,
      computed: dto.computed.map { Money(Int64($0)) },
      flags: dto.flags.map { ReceiptFlag(code: $0.rawValue) },
      errorCode: dto.errorCode,
      createdAt: formatISO(dto.createdAt)
    )
  }

  static func mapItemsPreview(_ dto: Components.Schemas.PreviewItemsResponse) -> ItemsPreview {
    let shares = (dto.shares ?? []).map {
      MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
    }
    let issues = dto.issues.map {
      ItemsSplitIssue(
        code: ItemsSplitIssueCode(code: $0.code.rawValue),
        itemIndex: $0.itemIndex
      )
    }
    let adjustment = dto.targetAdjustment.map {
      TargetAdjustment(
        kind: ReceiptExtraKind(code: $0.kind.rawValue),
        amount: Money(Int64($0.amount))
      )
    }
    return ItemsPreview(
      computedAmount: Money(Int64(dto.computedAmount)),
      shares: shares,
      issues: issues,
      targetAdjustment: adjustment
    )
  }

  static func encodeExtraKind(
    _ kind: ReceiptExtraKind
  ) -> Components.Schemas.PreviewItemsRequest.extrasPayloadPayload.kindPayload {
    switch kind {
    case .tax: return .tax
    case .service: return .service
    case .discount: return .discount
    case .other, .unknown: return .other
    }
  }

  // MARK: - Resilient fallback decoders

  struct RawAttachment: Codable, Sendable {
    let id: String
    let contentType: String
    let byteSize: Int
    let transactionId: String?
    let createdAt: String

    func toDomain() -> Attachment {
      Attachment(
        id: Attachment.ID(id),
        contentType: contentType,
        byteSize: byteSize,
        transactionId: transactionId.map(LedgerTransaction.ID.init),
        createdAt: createdAt
      )
    }

    init(attachment: Attachment) {
      self.id = attachment.id.rawValue
      self.contentType = attachment.contentType
      self.byteSize = attachment.byteSize
      self.transactionId = attachment.transactionId?.rawValue
      self.createdAt = attachment.createdAt
    }
  }

  private struct RawAttachmentResponse: Decodable {
    let attachment: RawAttachment
  }

  private struct RawReceiptReading: Decodable {
    struct RawItem: Decodable {
      let name: String
      let quantity: Int
      let amount: Int64
    }
    struct RawExtra: Decodable {
      let kind: String
      let label: String
      let amount: Int64
    }
    let merchant: String?
    let occurredOn: String?
    let items: [RawItem]
    let extras: [RawExtra]
    let total: Int64?
  }

  private struct RawReceiptScanResponse: Decodable {
    struct RawScan: Decodable {
      let id: String
      let attachmentId: String
      let status: String
      let reading: RawReceiptReading?
      let computed: Int64?
      let flags: [String]
      let errorCode: String?
      let createdAt: String
    }
    let scan: RawScan
  }

  static func decodeResilientAttachment(from data: Data) throws -> Attachment {
    try JSONDecoder().decode(RawAttachmentResponse.self, from: data).attachment.toDomain()
  }

  static func decodeResilientScan(from data: Data) throws -> ReceiptScan {
    let raw = try JSONDecoder().decode(RawReceiptScanResponse.self, from: data).scan
    let reading: ReceiptReading? = raw.reading.map { r in
      ReceiptReading(
        merchant: r.merchant,
        occurredOn: r.occurredOn,
        items: r.items.map {
          ReceiptItem(name: $0.name, quantity: $0.quantity, amount: Money($0.amount))
        },
        extras: r.extras.map {
          ReceiptExtra(
            kind: ReceiptExtraKind(code: $0.kind), label: $0.label, amount: Money($0.amount))
        },
        total: r.total.map(Money.init)
      )
    }
    return ReceiptScan(
      id: ReceiptScan.ID(raw.id),
      attachmentId: Attachment.ID(raw.attachmentId),
      status: ReceiptScanStatus(code: raw.status),
      reading: reading,
      computed: raw.computed.map(Money.init),
      flags: raw.flags.map { ReceiptFlag(code: $0) },
      errorCode: raw.errorCode,
      createdAt: raw.createdAt
    )
  }
}
