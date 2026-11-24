public import Domain
public import Foundation

public struct EditableReceiptItem: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var name: String
  public var amountText: String
  public var memberIds: [Member.ID]

  public init(
    id: UUID = UUID(),
    name: String,
    amountText: String,
    memberIds: [Member.ID]
  ) {
    self.id = id
    self.name = name
    self.amountText = amountText
    self.memberIds = memberIds
  }
}

public struct EditableReceiptExtra: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var kind: ReceiptExtraKind
  public var label: String
  public var amountText: String

  public init(
    id: UUID = UUID(),
    kind: ReceiptExtraKind,
    label: String,
    amountText: String
  ) {
    self.id = id
    self.kind = kind
    self.label = label
    self.amountText = amountText
  }
}

public struct ItemsSplitDraft: Sendable, Equatable {
  public static let maxItems = 60
  public static let maxExtras = 6
  public static let maxItemMembers = 20

  public var items: [EditableReceiptItem]
  public var extras: [EditableReceiptExtra]
  public var selectedItemId: UUID

  public init(
    items: [EditableReceiptItem] = [],
    extras: [EditableReceiptExtra] = [],
    selectedItemId: UUID? = nil
  ) {
    self.items = items
    self.extras = extras
    self.selectedItemId = selectedItemId ?? items.first?.id ?? UUID()
  }

  public init(
    initialSplit: SplitSpec?, fallbackTitle: String, totalAmount: Money, members: [Member]
  ) {
    if case .items(let specItems, let specExtras) = initialSplit {
      let mappedItems = specItems.map {
        EditableReceiptItem(
          name: $0.name,
          amountText: String($0.amount.amount),
          memberIds: $0.memberIds
        )
      }
      let mappedExtras = specExtras.map {
        EditableReceiptExtra(
          kind: $0.kind,
          label: $0.label,
          amountText: String($0.amount.amount)
        )
      }
      self.items = mappedItems
      self.extras = mappedExtras
      self.selectedItemId = mappedItems.first?.id ?? UUID()
    } else {
      let defaultMemberIds =
        members.count <= Self.maxItemMembers ? members.map(\.id) : []
      let item = EditableReceiptItem(
        name: fallbackTitle,
        amountText: totalAmount.isPositive ? String(totalAmount.amount) : "0",
        memberIds: defaultMemberIds
      )
      self.items = [item]
      self.extras = []
      self.selectedItemId = item.id
    }
  }

  public init(scan: ReceiptScan, fallbackTitle: String) {
    let merchant = scan.reading?.merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = (merchant?.isEmpty == false) ? (merchant ?? fallbackTitle) : fallbackTitle
    if let reading = scan.reading, !reading.items.isEmpty {
      self.items = reading.items.map {
        EditableReceiptItem(
          name: $0.name,
          amountText: String($0.amount.amount),
          memberIds: []
        )
      }
      self.extras = reading.extras.map {
        EditableReceiptExtra(
          kind: $0.kind,
          label: $0.label,
          amountText: String($0.amount.amount)
        )
      }
    } else {
      let amountValue = scan.reading?.total?.amount ?? 0
      self.items = [
        EditableReceiptItem(
          name: title,
          amountText: String(amountValue),
          memberIds: []
        )
      ]
      self.extras = []
    }
    self.selectedItemId = self.items.first?.id ?? UUID()
  }

  public var selectedItem: EditableReceiptItem? {
    items.first(where: { $0.id == selectedItemId }) ?? items.first
  }

  public var unassignedCount: Int {
    items.filter { $0.memberIds.isEmpty }.count
  }

  public var isExtrasFull: Bool {
    extras.count >= Self.maxExtras
  }

  public mutating func addItem() {
    guard items.count < Self.maxItems else { return }
    let created = EditableReceiptItem(name: "", amountText: "0", memberIds: [])
    items.append(created)
    selectedItemId = created.id
  }

  public mutating func removeItem(id: UUID) {
    guard items.count > 1 else { return }
    items.removeAll { $0.id == id }
    if selectedItemId == id {
      selectedItemId = items.first?.id ?? UUID()
    }
  }

  public mutating func toggleMemberOnSelected(_ memberId: Member.ID) {
    guard let idx = items.firstIndex(where: { $0.id == (selectedItem?.id ?? selectedItemId) })
    else {
      return
    }
    if let existingIdx = items[idx].memberIds.firstIndex(of: memberId) {
      items[idx].memberIds.remove(at: existingIdx)
    } else if items[idx].memberIds.count < Self.maxItemMembers {
      items[idx].memberIds.append(memberId)
    }
  }

  public mutating func splitRemainingEqual(among people: [Member]) {
    let ids = people.map(\.id)
    guard !ids.isEmpty, ids.count <= Self.maxItemMembers else { return }
    for idx in items.indices where items[idx].memberIds.isEmpty {
      items[idx].memberIds = ids
    }
  }

  public mutating func addExtra() {
    guard extras.count < Self.maxExtras else { return }
    extras.append(EditableReceiptExtra(kind: .other, label: "", amountText: "0"))
  }

  public mutating func removeExtra(id: UUID) {
    extras.removeAll { $0.id == id }
  }

  public mutating func addAdjustmentExtra(kind: ReceiptExtraKind, label: String, amount: Money) {
    guard extras.count < Self.maxExtras else { return }
    extras.append(EditableReceiptExtra(kind: kind, label: label, amountText: String(amount.amount)))
  }

  public func buildPayload() -> (items: [SplitSpec.ItemEntry], extras: [SplitSpec.ItemsExtra])? {
    guard !items.isEmpty, items.count <= Self.maxItems, extras.count <= Self.maxExtras else {
      return nil
    }
    var builtItems: [SplitSpec.ItemEntry] = []
    for item in items {
      let name = String(item.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
      guard !name.isEmpty,
        let amount = Self.parseNonnegativeAmount(item.amountText),
        item.memberIds.count <= Self.maxItemMembers
      else {
        return nil
      }
      builtItems.append(SplitSpec.ItemEntry(name: name, amount: amount, memberIds: item.memberIds))
    }

    var builtExtras: [SplitSpec.ItemsExtra] = []
    for extra in extras {
      guard let amount = Self.parseNonnegativeAmount(extra.amountText) else {
        return nil
      }
      let label = String(extra.label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
      builtExtras.append(SplitSpec.ItemsExtra(kind: extra.kind, label: label, amount: amount))
    }

    return (builtItems, builtExtras)
  }

  public static func parseNonnegativeAmount(_ text: String) -> Money? {
    let digits = text.filter { $0.isWholeNumber && $0.isASCII }
    guard !digits.isEmpty else { return nil }
    guard let value = Int64(digits), value >= 0, value <= 999_999_999_999 else {
      return nil
    }
    return Money(value)
  }
}
