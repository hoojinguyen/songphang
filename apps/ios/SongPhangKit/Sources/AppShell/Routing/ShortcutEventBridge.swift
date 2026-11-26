public import Domain
import Foundation

@MainActor
public final class ShortcutEventBridge {
  public enum ShortcutKind: String, Sendable, Hashable {
    case quickEntry = "vn.songphang.app.shortcut.quick-entry"
    case expenseNew = "vn.songphang.app.shortcut.expense-new"
    case balances = "vn.songphang.app.shortcut.balances"
  }

  public struct Payload: Sendable, Hashable {
    public let kind: ShortcutKind
    public let groupId: ExpenseGroup.ID

    public init(kind: ShortcutKind, groupId: ExpenseGroup.ID) {
      self.kind = kind
      self.groupId = groupId
    }
  }

  public static let shared = ShortcutEventBridge()

  public var onShortcutReceived: ((Payload) -> Void)? {
    didSet {
      flushPendingIfReady()
    }
  }

  private var pendingPayload: Payload?

  private init() {}

  public func didTriggerShortcut(type: String, userInfo: [String: Any]?) {
    guard let kind = ShortcutKind(rawValue: type),
      let rawGroupId = userInfo?["groupId"] as? String,
      UUID(uuidString: rawGroupId) != nil
    else {
      return
    }
    let payload = Payload(kind: kind, groupId: ExpenseGroup.ID(rawGroupId))
    if let onShortcutReceived {
      pendingPayload = nil
      onShortcutReceived(payload)
    } else {
      pendingPayload = payload
    }
  }

  public func consumePending() -> Payload? {
    let next = pendingPayload
    pendingPayload = nil
    return next
  }

  private func flushPendingIfReady() {
    guard let onShortcutReceived, let pendingPayload else { return }
    self.pendingPayload = nil
    onShortcutReceived(pendingPayload)
  }
}
