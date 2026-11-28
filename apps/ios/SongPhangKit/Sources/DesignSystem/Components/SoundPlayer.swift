import AVFAudio
import Foundation

#if DEBUG
  import os
#endif

public enum SoundEffect: String, CaseIterable, Sendable {
  case coin
  case ting
  case chord
}

@MainActor
public final class SoundPlayer {
  public static let shared = SoundPlayer()

  #if DEBUG
    private let logger = Logger(subsystem: "vn.songphang.app", category: "Sound")
  #endif

  private let engine = AudioEngine()

  private init() {
    preloadAll()
  }

  public func preloadAll() {
    Task {
      await engine.preloadAll()
    }
  }

  public func play(_ effect: SoundEffect) {
    guard FeedbackSettings.isSoundEnabled else {
      #if DEBUG
        logger.notice(
          "SoundPlayer suppressed (sound off) effect=\(effect.rawValue, privacy: .public)")
      #endif
      return
    }
    Task {
      await engine.play(effect)
    }
  }
}

private actor AudioEngine {
  #if DEBUG
    private let logger = Logger(subsystem: "vn.songphang.app", category: "Sound")
  #endif

  private var didConfigureSession = false
  private var players: [SoundEffect: AVAudioPlayer] = [:]

  func preloadAll() {
    configureSessionIfNeeded()
    for effect in SoundEffect.allCases where players[effect] == nil {
      _ = loadPlayerIfNeeded(for: effect)
    }
  }

  func play(_ effect: SoundEffect) {
    configureSessionIfNeeded()
    guard let player = loadPlayerIfNeeded(for: effect) else {
      #if DEBUG
        logger.error("SoundPlayer missing resource effect=\(effect.rawValue, privacy: .public)")
      #endif
      return
    }
    if player.isPlaying {
      player.stop()
    }
    player.currentTime = 0
    let started = player.play()
    #if DEBUG
      logger.notice(
        "SoundPlayer played effect=\(effect.rawValue, privacy: .public) started=\(started, privacy: .public)"
      )
    #endif
  }

  private func loadPlayerIfNeeded(for effect: SoundEffect) -> AVAudioPlayer? {
    if let existing = players[effect] {
      return existing
    }
    guard let url = Self.resourceURL(for: effect) else { return nil }
    guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
    player.prepareToPlay()
    players[effect] = player
    return player
  }

  private func configureSessionIfNeeded() {
    guard !didConfigureSession else { return }
    didConfigureSession = true
    // Category .ambient silences automatically with the hardware Ring/Silent switch
    // and mixes with background audio without interrupting music.
    try? AVAudioSession.sharedInstance().setCategory(.ambient)
  }

  private static func resourceURL(for effect: SoundEffect) -> URL? {
    Bundle.module.url(forResource: effect.rawValue, withExtension: "caf", subdirectory: "Sounds")
      ?? Bundle.module.url(forResource: effect.rawValue, withExtension: "caf", subdirectory: nil)
  }
}
