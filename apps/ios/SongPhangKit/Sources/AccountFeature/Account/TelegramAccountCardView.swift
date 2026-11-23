import DesignSystem
import Domain
import SwiftUI

struct TelegramAccountCardView: View {
  @Bindable var model: AccountModel
  let email: String
  let emailVerified: Bool
  @State private var isShowingPairingSheet = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.tr("telegram.accountTitle"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      switch model.chatIdentities {
      case .loading:
        LoadingSkeleton(rowCount: 1, rowHeight: 48)
      case .failed:
        LoadError {
          Task { await model.loadChatIdentities() }
        }
      case .loaded(let identities):
        if identities.contains(where: { $0.platform == .telegram }) {
          Text(L10n.t("telegram.accountLinked", ["name": L10n.tr("telegram.accountTitle")]))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)

          SPButton(
            L10n.tr("telegram.unlink"),
            variant: .surface,
            size: .md,
            isFullWidth: true,
            isDisabled: model.isOffline || model.isUnlinkingTelegram,
            isPending: model.isUnlinkingTelegram
          ) {
            Task { await model.unlinkTelegram() }
          }
        } else if emailVerified {
          Text(L10n.tr("telegram.startPairingHint"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.muted)

          SPButton(
            L10n.tr("telegram.startPairingButton"),
            variant: .primary,
            size: .md,
            isFullWidth: true,
            isDisabled: model.isOffline || model.isStartingPairing,
            isPending: model.isStartingPairing
          ) {
            Task {
              await model.startTelegramPairing()
              if model.startedPairing != nil {
                isShowingPairingSheet = true
              }
            }
          }
        } else {
          Text(L10n.tr("verify.banner"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.muted)
        }
      }

      if let telegramError = model.telegramError {
        Text(telegramError)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .sheet(isPresented: $isShowingPairingSheet) {
      TelegramPairingSheetView(model: model, email: email)
    }
  }
}
