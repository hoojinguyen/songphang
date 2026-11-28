import Foundation
public import SwiftUI

public struct NotificationBellButton: View {
  @ScaledMetric(relativeTo: .title3) private var scaledSize: CGFloat = 44
  public let unreadCount: Int
  public let onOpen: () -> Void

  public init(unreadCount: Int, onOpen: @escaping () -> Void) {
    self.unreadCount = unreadCount
    self.onOpen = onOpen
  }

  public var body: some View {
    let circleSize = max(44, scaledSize)
    Button(action: onOpen) {
      ZStack(alignment: .topTrailing) {
        Image(systemName: "bell")
          .spIconFont(size: 20, weight: .semibold, relativeTo: .title3)
          .foregroundStyle(Tokens.ink)
          .frame(width: circleSize, height: circleSize)
          .background(Tokens.surface)
          .clipShape(Circle())

        if unreadCount > 0 {
          Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
            .font(Typography.microBold)
            .foregroundStyle(Tokens.onAccent)
            .padding(.horizontal, 4)
            .frame(minWidth: 18, minHeight: 18)
            .background(Tokens.coral)
            .clipShape(Capsule())
            .offset(x: 2, y: -2)
            .accessibilityHidden(true)
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
