#if DEBUG
  public import Domain
  public import Foundation
  import UIKit

  extension FakeWorld {
    public nonisolated static let sampleAttachmentId = Attachment.ID(
      "00000000-0000-7000-8000-000000000901"
    )
    public nonisolated static let sampleReceiptScanId = ReceiptScan.ID(
      "00000000-0000-7000-8000-000000000902"
    )

    public nonisolated static func sampleReceiptScan() -> ReceiptScan {
      ReceiptScan(
        id: sampleReceiptScanId,
        attachmentId: sampleAttachmentId,
        status: .done,
        reading: ReceiptReading(
          merchant: "Lẩu gà lá é Đà Lạt",
          occurredOn: "2026-11-16",
          items: [
            ReceiptItem(name: "Lẩu gà lá é", quantity: 1, amount: Money(280_000)),
            ReceiptItem(name: "Nước suối", quantity: 2, amount: Money(40_000)),
          ],
          extras: [
            ReceiptExtra(kind: .service, label: "Phí dịch vụ", amount: Money(20_000))
          ],
          total: Money(340_000)
        ),
        computed: Money(340_000),
        flags: [],
        errorCode: nil,
        createdAt: "2026-11-16T12:00:00.000Z"
      )
    }

    public func uploadAttachment(
      groupId: ExpenseGroup.ID,
      data: Data,
      filename _: String,
      contentType: String
    ) async throws(AppError) -> Attachment {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      let id = Attachment.ID(UUID().uuidString.lowercased())
      let attachment = Attachment(
        id: id,
        contentType: contentType,
        byteSize: data.count,
        transactionId: nil,
        createdAt: "2026-11-16T15:00:00.000Z"
      )
      var byGroup = attachmentsByGroup[groupId] ?? [:]
      byGroup[id] = attachment
      attachmentsByGroup[groupId] = byGroup
      attachmentDataById[id] = data
      return attachment
    }

    public func attachmentContent(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID
    ) async throws(AppError) -> Data {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let data = attachmentDataById[attachmentId] {
        return data
      }
      if attachmentId == Self.sampleAttachmentId {
        return Self.sampleReceiptPlaceholderData()
      }
      throw .api(code: "NOT_FOUND", status: 404)
    }

    public func deleteAttachment(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      attachmentsByGroup[groupId]?[attachmentId] = nil
      attachmentDataById[attachmentId] = nil
    }

    public func startReceiptScan(
      groupId: ExpenseGroup.ID,
      attachmentId: Attachment.ID,
      key: IdempotencyKey
    ) async throws(AppError) -> ReceiptScan {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      seenIdempotencyKeys.insert(key)
      let scanId = ReceiptScan.ID(UUID().uuidString.lowercased())
      let base = Self.sampleReceiptScan()
      let created = ReceiptScan(
        id: scanId,
        attachmentId: attachmentId,
        status: .done,
        reading: base.reading,
        computed: base.computed,
        flags: base.flags,
        errorCode: nil,
        createdAt: base.createdAt
      )
      scansById[scanId] = created
      return created
    }

    public func receiptScan(
      groupId: ExpenseGroup.ID,
      id: ReceiptScan.ID
    ) async throws(AppError) -> ReceiptScan {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let stored = scansById[id] {
        return stored
      }
      if id == Self.sampleReceiptScanId {
        return Self.sampleReceiptScan()
      }
      throw .api(code: "NOT_FOUND", status: 404)
    }

    public func previewItems(
      groupId: ExpenseGroup.ID,
      items: [SplitSpec.ItemEntry],
      extras: [SplitSpec.ItemsExtra],
      targetTotal: Money?
    ) async throws(AppError) -> ItemsPreview {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      _ = group
      let itemTotal = items.reduce(Int64(0)) { $0 + $1.amount.amount }
      let extraTotal = extras.reduce(Int64(0)) { sum, extra in
        sum + (extra.kind == .discount ? -extra.amount.amount : extra.amount.amount)
      }
      let computed = Money(itemTotal + extraTotal)
      var issues: [ItemsSplitIssue] = []
      for (idx, item) in items.enumerated() where item.memberIds.isEmpty {
        issues.append(ItemsSplitIssue(code: .itemUnassigned, itemIndex: idx))
      }
      if computed.amount <= 0 {
        issues.append(ItemsSplitIssue(code: .invalidTotal, itemIndex: nil))
      }
      let adjustment: TargetAdjustment? =
        if let targetTotal, targetTotal.amount != computed.amount {
          if targetTotal.amount > computed.amount {
            TargetAdjustment(kind: .other, amount: Money(targetTotal.amount - computed.amount))
          } else {
            TargetAdjustment(kind: .discount, amount: Money(computed.amount - targetTotal.amount))
          }
        } else {
          nil
        }
      let shares: [MemberAmount]
      if issues.isEmpty, computed == Money(340_000) {
        shares = [
          MemberAmount(memberId: TripScenario.minhId, amount: Money(170_000)),
          MemberAmount(memberId: TripScenario.lanId, amount: Money(170_000)),
        ]
      } else if issues.isEmpty,
        let firstMember = membersByGroup[groupId]?.first(where: { $0.kind == .person })
      {
        shares = [MemberAmount(memberId: firstMember.id, amount: computed)]
      } else {
        shares = []
      }
      return ItemsPreview(
        computedAmount: computed,
        shares: shares,
        issues: issues,
        targetAdjustment: adjustment
      )
    }

    private nonisolated static func sampleReceiptPlaceholderData() -> Data {
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 160))
      let image = renderer.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 120, height: 160))
        UIColor.systemGray4.setFill()
        ctx.fill(CGRect(x: 16, y: 20, width: 88, height: 12))
        ctx.fill(CGRect(x: 16, y: 44, width: 72, height: 10))
        ctx.fill(CGRect(x: 16, y: 66, width: 80, height: 10))
      }
      return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
  }
#endif
