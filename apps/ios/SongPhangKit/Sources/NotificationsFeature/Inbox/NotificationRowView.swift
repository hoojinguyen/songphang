import DesignSystem
public import Domain
public import SwiftUI

public struct NotificationRowView: View {
  public let notification: AppNotification
  public let onSelect: (AppNotification) -> Void

  public init(
    notification: AppNotification,
    onSelect: @escaping (AppNotification) -> Void
  ) {
    self.notification = notification
    self.onSelect = onSelect
  }

  public var body: some View {
    Button(action: { onSelect(notification) }) {
      VStack(alignment: .leading, spacing: 4) {
        Text(NotificationFormatter.formatText(notification))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .multilineTextAlignment(.leading)

        let subtitle: String = {
          let time = NotificationFormatter.formatDateTime(notification.createdAt)
          if notification.groupName.isEmpty {
            return time
          } else {
            return "\(notification.groupName) · \(time)"
          }
        }()

        Text(subtitle)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(notification.read ? Tokens.surface : Tokens.sunken)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
