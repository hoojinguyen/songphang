public import Foundation

public struct PushTapPayload: Sendable, Equatable {
  public let groupId: String?
  public let target: String?

  public init(groupId: String?, target: String?) {
    self.groupId = groupId
    self.target = target
  }
}

@MainActor
public final class PushEventBridge {
  public static let shared = PushEventBridge()

  private var pendingHexToken: String?
  private var pendingTap: PushTapPayload?

  public var onDeviceTokenRegistered: ((String) -> Void)? {
    didSet {
      if let handler = onDeviceTokenRegistered, let token = pendingHexToken {
        pendingHexToken = nil
        handler(token)
      }
    }
  }

  public var onPushTapReceived: ((PushTapPayload) -> Void)? {
    didSet {
      if let handler = onPushTapReceived, let tap = pendingTap {
        pendingTap = nil
        handler(tap)
      }
    }
  }

  private init() {}

  public func didRegisterDeviceToken(_ deviceToken: Data) {
    let hexToken = deviceToken.map { String(format: "%02x", $0) }.joined()
    if let handler = onDeviceTokenRegistered {
      handler(hexToken)
    } else {
      pendingHexToken = hexToken
    }
  }

  public func didReceiveTap(groupId: String?, target: String?) {
    let payload = PushTapPayload(groupId: groupId, target: target)
    if let handler = onPushTapReceived {
      handler(payload)
    } else {
      pendingTap = payload
    }
  }
}
