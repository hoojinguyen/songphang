import Foundation
public import SwiftUI

public struct NotificationBellButton: View {
  public let unreadCount: Int
  public let onOpen: () -> Void

  public init(unreadCount: Int, onOpen: @escaping () -> Void) {
    self.unreadCount = unreadCount
    self.onOpen = onOpen
  }

  public var body: some View {
    Button(action: onOpen) {
      ZStack(alignment: .topTrailing) {
        Image(systemName: "bell")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(Tokens.ink)
          .frame(width: 44, height: 44)
          .background(Tokens.surface)
          .clipShape(Circle())

        if unreadCount > 0 {
          Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 4)
            .frame(minWidth: 18, minHeight: 18)
            .background(Tokens.coral)
            .clipShape(Capsule())
            .offset(x: 2, y: -2)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      unreadCount > 0
        ? L10n.t("notifications.bellUnreadLabel", ["count": "\(unreadCount)"])
        : L10n.tr("notifications.title")
    )
  }
}
