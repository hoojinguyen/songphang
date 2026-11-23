import DesignSystem
import Domain
import Foundation

extension AccountModel {
  public func loadChatIdentities() async {
    guard let chatLinksRepository else { return }
    do throws(AppError) {
      let identities = try await chatLinksRepository.myIdentities()
      chatIdentities = .loaded(identities)
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .loaded = chatIdentities {
        telegramError = L10n.tr("common.saveError")
      } else {
        chatIdentities = .failed(error)
      }
    }
  }

  public func startTelegramPairing() async {
    guard let chatLinksRepository, !isStartingPairing, !isOffline else { return }
    isStartingPairing = true
    telegramError = nil
    pairingError = nil
    pairingCompleted = false
    pairingTerminalStatus = nil
    defer { isStartingPairing = false }
    do throws(AppError) {
      let started = try await chatLinksRepository.startTelegramPairing()
      startedPairing = started
      currentPairing = started.pairing
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if error == .rateLimited {
        telegramError = L10n.tr("login.tooMany")
      } else if case .api(_, 404) = error {
        telegramError = L10n.tr("telegram.linkInvalid")
      } else {
        telegramError = L10n.tr("common.saveError")
      }
    }
  }

  public func pollTelegramPairing() async {
    guard let chatLinksRepository,
      let pairingId = currentPairing?.id ?? startedPairing?.pairing.id,
      !pairingCompleted,
      pairingTerminalStatus == nil
    else { return }
    do throws(AppError) {
      let updated = try await chatLinksRepository.telegramPairing(id: pairingId)
      currentPairing = updated
      switch updated.status {
      case .completed:
        pairingCompleted = true
        await loadChatIdentities()
      case .cancelled, .expired:
        pairingTerminalStatus = .invalid
      case .pendingTelegram, .telegramConfirmed:
        break
      }
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .api(_, 404) = error {
        pairingTerminalStatus = .invalid
      }
    }
  }

  public func confirmTelegramPairing() async {
    guard let chatLinksRepository,
      let pairingId = currentPairing?.id ?? startedPairing?.pairing.id,
      !isSubmittingPairingAction,
      !isOffline
    else { return }
    isSubmittingPairingAction = true
    pairingError = nil
    defer { isSubmittingPairingAction = false }
    do throws(AppError) {
      try await chatLinksRepository.confirmTelegramPairing(id: pairingId)
      pairingCompleted = true
      await loadChatIdentities()
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .api(_, 409) = error {
        pairingTerminalStatus = .identityTaken
      } else if case .api(_, 400) = error {
        pairingTerminalStatus = .invalid
      } else if case .api(_, 404) = error {
        pairingTerminalStatus = .invalid
      } else {
        pairingError = L10n.tr("common.saveError")
      }
    }
  }

  public func cancelTelegramPairing() async {
    guard let chatLinksRepository,
      let pairingId = currentPairing?.id ?? startedPairing?.pairing.id,
      !isSubmittingPairingAction,
      !isOffline
    else { return }
    isSubmittingPairingAction = true
    pairingError = nil
    defer { isSubmittingPairingAction = false }
    do throws(AppError) {
      try await chatLinksRepository.cancelTelegramPairing(id: pairingId)
      pairingTerminalStatus = .invalid
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else if case .api(_, 404) = error {
        pairingTerminalStatus = .invalid
      } else {
        pairingError = L10n.tr("common.saveError")
      }
    }
  }

  public func resetTelegramPairing() {
    startedPairing = nil
    currentPairing = nil
    pairingCompleted = false
    pairingError = nil
    pairingTerminalStatus = nil
  }

  public func unlinkTelegram() async {
    guard let chatLinksRepository, !isUnlinkingTelegram, !isOffline else { return }
    isUnlinkingTelegram = true
    telegramError = nil
    defer { isUnlinkingTelegram = false }
    do throws(AppError) {
      try await chatLinksRepository.unlinkMyIdentity(platform: .telegram)
      if case .loaded(var list) = chatIdentities {
        list.removeAll { $0.platform == .telegram }
        chatIdentities = .loaded(list)
      }
      await loadChatIdentities()
    } catch {
      if error == .unauthorized {
        onSignedOut()
      } else {
        telegramError = L10n.tr("common.saveError")
      }
    }
  }
}
