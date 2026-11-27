public import Foundation

public final class ExtensionSharedStore: Sendable {
  public static let shared = ExtensionSharedStore()
  public static let widgetHideAmountsDefaultsKey = "sp.widget.hideAmounts"
  public static let defaultAppGroupIdentifier = "group.vn.songphang.app"

  private let appGroupIdentifier: String
  private let overrideRootURL: URL?

  public init(
    appGroupIdentifier: String? = nil,
    overrideRootURL: URL? = nil
  ) {
    self.appGroupIdentifier = appGroupIdentifier ?? Self.resolveAppGroupIdentifier()
    self.overrideRootURL = overrideRootURL
  }

  public static func resolveAppGroupIdentifier() -> String {
    if let raw = Bundle.main.infoDictionary?["AppGroupIdentifier"] as? String {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty, !trimmed.contains("$(") {
        return trimmed
      }
    }
    return defaultAppGroupIdentifier
  }

  public var sharedStateURL: URL? {
    if let overrideRootURL {
      return overrideRootURL
    }
    return FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
      .appending(path: "SharedState", directoryHint: .isDirectory)
  }

  // MARK: - Widget Snapshot & Preferences

  private struct WidgetPreferencesPayload: Codable {
    let hideAmounts: Bool
  }

  public func readWidgetSnapshot() -> WidgetSnapshot? {
    guard let url = sharedStateURL?.appending(path: "widget-snapshot.json") else {
      return nil
    }
    return readJSON(WidgetSnapshot.self, from: url)
  }

  public func writeWidgetSnapshot(_ snapshot: WidgetSnapshot) {
    guard let url = sharedStateURL?.appending(path: "widget-snapshot.json") else {
      return
    }
    writeJSON(snapshot, to: url)
  }

  public func readWidgetHideAmounts() -> Bool {
    if let url = sharedStateURL?.appending(path: "widget-preferences.json"),
      let prefs = readJSON(WidgetPreferencesPayload.self, from: url)
    {
      return prefs.hideAmounts
    }
    return UserDefaults.standard.bool(forKey: Self.widgetHideAmountsDefaultsKey)
  }

  public func writeWidgetHideAmounts(_ hideAmounts: Bool) {
    UserDefaults.standard.set(hideAmounts, forKey: Self.widgetHideAmountsDefaultsKey)
    if let prefsURL = sharedStateURL?.appending(path: "widget-preferences.json") {
      writeJSON(WidgetPreferencesPayload(hideAmounts: hideAmounts), to: prefsURL)
    }
    if var snapshot = readWidgetSnapshot() {
      snapshot.hideAmounts = hideAmounts
      snapshot.updatedAt = Date()
      writeWidgetSnapshot(snapshot)
    }
  }

  // MARK: - Share Groups

  public func readShareGroups() -> ShareGroupsSnapshot? {
    guard let url = sharedStateURL?.appending(path: "share-groups.json") else {
      return nil
    }
    return readJSON(ShareGroupsSnapshot.self, from: url)
  }

  public func writeShareGroups(_ snapshot: ShareGroupsSnapshot) {
    guard let url = sharedStateURL?.appending(path: "share-groups.json") else {
      return
    }
    writeJSON(snapshot, to: url)
  }

  // MARK: - Share Inbox

  public func shareInboxBatchDirectory(batchId: String) -> URL? {
    let safeId = sanitizeComponent(batchId)
    guard !safeId.isEmpty else { return nil }
    return sharedStateURL?
      .appending(path: "ShareInbox", directoryHint: .isDirectory)
      .appending(path: safeId, directoryHint: .isDirectory)
  }

  public func writeShareInboxManifest(_ manifest: ShareInboxManifest) -> Bool {
    guard let dir = shareInboxBatchDirectory(batchId: manifest.batchId) else {
      return false
    }
    return writeJSON(manifest, to: dir.appending(path: "manifest.json"))
  }

  public func readShareInboxManifest(batchId: String) -> ShareInboxManifest? {
    guard let dir = shareInboxBatchDirectory(batchId: batchId) else {
      return nil
    }
    let url = dir.appending(path: "manifest.json")
    return readJSON(ShareInboxManifest.self, from: url)
  }

  public func pendingShareInboxManifests(maxAge: TimeInterval = 24 * 60 * 60)
    -> [ShareInboxManifest]
  {
    pruneStaleShareInbox(maxAge: maxAge)
    guard
      let inboxRoot = sharedStateURL?.appending(path: "ShareInbox", directoryHint: .isDirectory),
      let entries = try? FileManager.default.contentsOfDirectory(
        at: inboxRoot,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    var manifests: [ShareInboxManifest] = []
    for entry in entries {
      let manifestURL = entry.appending(path: "manifest.json")
      if let manifest = readJSON(ShareInboxManifest.self, from: manifestURL) {
        manifests.append(manifest)
      }
    }
    return manifests.sorted { $0.createdAt > $1.createdAt }
  }

  public func removeShareInboxBatch(batchId: String) {
    guard let dir = shareInboxBatchDirectory(batchId: batchId) else {
      return
    }
    try? FileManager.default.removeItem(at: dir)
  }

  public func pruneStaleShareInbox(maxAge: TimeInterval = 24 * 60 * 60) {
    guard
      let inboxRoot = sharedStateURL?.appending(path: "ShareInbox", directoryHint: .isDirectory),
      let entries = try? FileManager.default.contentsOfDirectory(
        at: inboxRoot,
        includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return
    }

    let cutoff = Date().addingTimeInterval(-maxAge)
    for entry in entries {
      let manifestURL = entry.appending(path: "manifest.json")
      if let manifest = readJSON(ShareInboxManifest.self, from: manifestURL) {
        if manifest.createdAt < cutoff {
          try? FileManager.default.removeItem(at: entry)
        }
        continue
      }
      let values = try? entry.resourceValues(forKeys: [
        .creationDateKey, .contentModificationDateKey,
      ])
      let date = values?.contentModificationDate ?? values?.creationDate ?? Date.distantPast
      if date < cutoff {
        try? FileManager.default.removeItem(at: entry)
      }
    }
  }

  public func clearAll() {
    guard let root = sharedStateURL else { return }
    try? FileManager.default.removeItem(at: root)
  }

  // MARK: - Helpers

  private func readJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
    guard let data = try? Data(contentsOf: url) else {
      return nil
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(type, from: data)
  }

  @discardableResult
  private func writeJSON<T: Encodable>(_ value: T, to url: URL) -> Bool {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(value) else { return false }

    let fm = FileManager.default
    let parent = url.deletingLastPathComponent()
    do {
      try fm.createDirectory(at: parent, withIntermediateDirectories: true)
      if let root = sharedStateURL {
        excludeFromBackup(root)
      }
      excludeFromBackup(parent)
      try data.write(
        to: url,
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
      excludeFromBackup(url)
      return true
    } catch {
      return false
    }
  }

  private func excludeFromBackup(_ url: URL) {
    var mutableURL = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? mutableURL.setResourceValues(values)
  }

  private func sanitizeComponent(_ raw: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    return String(raw.unicodeScalars.filter { allowed.contains($0) })
  }
}
