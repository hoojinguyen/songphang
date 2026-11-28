import DesignSystem
import Domain
import SwiftUI
import UIKit

struct TelegramGroupCardView: View {
  @Bindable var model: GroupSettingsModel
  let isDisabled: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("telegram.settingsTitle"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      switch model.groupChatLinks {
      case .loading:
        LoadingSkeleton(rowCount: 1, rowHeight: 56)

      case .failed:
        LoadError {
          Task { await model.reloadChatLinks() }
        }

      case .loaded(let data):
        let botUsername = model.generatedLinkCode?.botUsername ?? data.botUsername ?? ""
        Text(L10n.t("telegram.settingsHint", ["bot": botUsername]))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)

        SPButton(
          L10n.tr("telegram.generateCode"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: isDisabled || model.isPerformingTelegramAction,
          isPending: model.isPerformingTelegramAction
        ) {
          Task { await model.generateTelegramLinkCode() }
        }

        if let code = model.generatedLinkCode {
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
              Text(code.command)
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(Tokens.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

              CopyButton(
                value: code.command,
                label: L10n.tr("telegram.copy")
              )
            }
            Text(L10n.tr("telegram.codeTtl"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
          .padding(14)
          .background(Tokens.sunken)
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }

        if !data.chatLinks.isEmpty {
          VStack(spacing: 8) {
            ForEach(data.chatLinks) { link in
              HStack(spacing: 12) {
                Text(link.chatId)
                  .font(.system(.caption, design: .monospaced))
                  .foregroundStyle(Tokens.ink)
                  .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                  Task { await model.unlinkGroupChat(link.id) }
                } label: {
                  Text(L10n.tr("telegram.unlink"))
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Tokens.surface, in: Capsule())
                }
                .disabled(isDisabled || model.isPerformingTelegramAction)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Tokens.bg)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
          }
        }

        if let error = model.telegramError {
          Text(
            error == .api(code: "FORBIDDEN", status: 403)
              ? L10n.tr("common.forbidden") : L10n.tr("common.saveError")
          )
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}
