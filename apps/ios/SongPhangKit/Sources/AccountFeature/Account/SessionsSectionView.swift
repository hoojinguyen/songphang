import DesignSystem
import Domain
import SwiftUI

struct SessionsSectionView: View {
  let sessions: Loadable<[UserSession]>
  let revokingSessionId: UserSession.ID?
  let revokeError: String?
  let isOffline: Bool
  let onRetry: () -> Void
  let onRevoke: (UserSession) -> Void

  var body: some View {
    switch sessions {
    case .loading:
      LoadingSkeleton(rowCount: 2, rowHeight: 56)

    case .failed:
      LoadError(onRetry: onRetry)

    case .loaded(let list):
      VStack(alignment: .leading, spacing: 16) {
        Text(L10n.tr("account.sessionsTitle"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        VStack(alignment: .leading, spacing: 12) {
          ForEach(list) { session in
            sessionRow(session)
          }
        }

        if let revokeError {
          Text(revokeError)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
  }

  private func sessionRow(_ session: UserSession) -> some View {
    let label = clientLabel(for: session.client)
    let title = session.deviceName ?? label
    let subtitle =
      session.current
      ? "\(label) · \(L10n.tr("account.currentDevice"))"
      : label

    return HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(subtitle)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
      Spacer(minLength: 8)
      SPButton(
        L10n.tr("common.logout"),
        variant: .surface,
        isDisabled: revokingSessionId != nil,
        isOfflineBlocked: isOffline,
        isPending: revokingSessionId == session.id
      ) {
        onRevoke(session)
      }
      .fixedSize(horizontal: true, vertical: false)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Tokens.bg)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private func clientLabel(for client: UserSession.Client) -> String {
    switch client {
    case .ios:
      return L10n.tr("account.clientIos")
    case .android:
      return L10n.tr("account.clientAndroid")
    case .web:
      return L10n.tr("account.clientWeb")
    case .unknown(let raw):
      return raw
    }
  }
}
