import DesignSystem
import Domain
import SwiftUI
import UIKit

struct TelegramPairingSheetView: View {
  @Bindable var model: AccountModel
  let email: String
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @State private var copiedCommand = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(L10n.tr("ios.common.close")) {
            model.resetTelegramPairing()
            dismiss()
          }
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
        }
      }
    }
    .task(id: model.currentPairing?.id) {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(2))
        if Task.isCancelled { break }
        guard let pairing = model.currentPairing,
          pairing.status == .pendingTelegram,
          !model.pairingCompleted,
          model.pairingTerminalStatus == nil
        else { break }
        await model.pollTelegramPairing()
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    if model.pairingCompleted {
      Text(L10n.tr("telegram.linkDone"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      SPButton(L10n.tr("ios.common.close"), variant: .primary, isFullWidth: true) {
        model.resetTelegramPairing()
        dismiss()
      }
    } else if let terminal = model.pairingTerminalStatus {
      Text(
        terminal == .identityTaken
          ? L10n.tr("telegram.identityTaken") : L10n.tr("telegram.linkInvalid")
      )
      .font(Typography.sectionTitle)
      .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("telegram.startNewPairingButton"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: model.isOffline || model.isStartingPairing,
        isPending: model.isStartingPairing
      ) {
        copiedCommand = false
        Task { await model.startTelegramPairing() }
      }
    } else if let started = model.startedPairing, let pairing = model.currentPairing {
      let identity = formatTelegramIdentity(
        name: pairing.stagedPlatformName,
        userId: pairing.stagedPlatformUserId
      )
      if pairing.status == .telegramConfirmed {
        confirmStep(identity: identity)
      } else {
        privateStep(started: started, pairing: pairing, identity: identity)
      }
    } else if let pairingError = model.pairingError {
      Text(pairingError)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      SPButton(
        L10n.tr("common.retry"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: model.isOffline || model.isStartingPairing,
        isPending: model.isStartingPairing
      ) {
        Task { await model.startTelegramPairing() }
      }
    } else {
      LoadingSkeleton(rowCount: 2, rowHeight: 56)
    }
  }

  @ViewBuilder
  private func confirmStep(identity: String) -> some View {
    Text(L10n.tr("telegram.confirmStepTitle"))
      .font(Typography.sectionTitle)
      .foregroundStyle(Tokens.ink)

    Text(L10n.t("telegram.confirmStepBody", ["telegramIdentity": identity, "email": email]))
      .font(Typography.subheadline)
      .foregroundStyle(Tokens.ink)

    SPButton(
      L10n.tr("telegram.finalConfirmButton"),
      variant: .primary,
      size: .lg,
      isFullWidth: true,
      isDisabled: model.isOffline || model.isSubmittingPairingAction,
      isPending: model.isSubmittingPairingAction
    ) {
      Task { await model.confirmTelegramPairing() }
    }

    SPButton(
      L10n.tr("telegram.cancelPairingButton"),
      variant: .surface,
      size: .md,
      isFullWidth: true,
      isDisabled: model.isOffline || model.isSubmittingPairingAction
    ) {
      Task { await model.cancelTelegramPairing() }
    }

    if let pairingError = model.pairingError {
      Text(pairingError)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }
  }

  @ViewBuilder
  private func privateStep(
    started: StartedTelegramPairing,
    pairing: TelegramPairing,
    identity: String
  ) -> some View {
    Text(L10n.tr("telegram.privateStepTitle"))
      .font(Typography.sectionTitle)
      .foregroundStyle(Tokens.ink)

    if let botUsername = pairing.botUsername, !botUsername.isEmpty {
      Text(L10n.t("telegram.privateStepHint", ["bot": botUsername]))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.muted)

      if let rawDeepLink = started.deepLinkUrl,
        let deepLinkURL = URL(string: rawDeepLink),
        let scheme = deepLinkURL.scheme?.lowercased(),
        scheme == "https" || scheme == "tg"
      {
        SPButton(
          L10n.t("telegram.openTelegramButton", ["bot": botUsername]),
          variant: .primary,
          size: .lg,
          isFullWidth: true
        ) {
          openURL(deepLinkURL)
        }
      }
    } else {
      Text(L10n.tr("telegram.privateStepHintNoBot"))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.muted)
    }

    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 12) {
        Text(started.startCommand)
          .font(.system(.subheadline, design: .monospaced).weight(.bold))
          .foregroundStyle(Tokens.ink)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)

        Button {
          UIPasteboard.general.string = started.startCommand
          copiedCommand = true
        } label: {
          Text(copiedCommand ? L10n.tr("telegram.copied") : L10n.tr("telegram.copy"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Tokens.surface, in: Capsule())
        }
      }
      Text(L10n.tr("telegram.codeTtl"))
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
    }
    .padding(16)
    .background(Tokens.sunken)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

    Text(
      pairing.stagedPlatformUserId != nil
        ? L10n.t("telegram.stagedWaitingConfirm", ["telegramIdentity": identity])
        : L10n.tr("telegram.waitingForTelegram")
    )
    .font(Typography.subheadlineBold)
    .foregroundStyle(Tokens.ink)

    SPButton(
      L10n.tr("telegram.cancelPairingButton"),
      variant: .surface,
      size: .md,
      isFullWidth: true,
      isDisabled: model.isOffline || model.isSubmittingPairingAction
    ) {
      Task { await model.cancelTelegramPairing() }
    }

    if let pairingError = model.pairingError {
      Text(pairingError)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }
  }

  private func formatTelegramIdentity(name: String?, userId: String?) -> String {
    if let name, !name.isEmpty, let userId, !userId.isEmpty {
      return "\(name) (ID #\(userId))"
    }
    if let userId, !userId.isEmpty {
      return "ID #\(userId)"
    }
    return L10n.tr("telegram.accountTitle")
  }
}
