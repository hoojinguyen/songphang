import Foundation

enum SnapshotKey: Hashable, Sendable {
  case me
  case groups
  case group(String)
  case members(String)
  case groupUsers(String)
  case categories(String)
  case budget(String)
  case feedFirstPage(String)
  case balances(String)
  case activityFirstPage(String)

  var groupId: String? {
    switch self {
    case .me, .groups:
      return nil
    case .group(let id),
      .members(let id),
      .groupUsers(let id),
      .categories(let id),
      .budget(let id),
      .feedFirstPage(let id),
      .balances(let id),
      .activityFirstPage(let id):
      return id
    }
  }

  var relativePath: String {
    switch self {
    case .me:
      return "me.json"
    case .groups:
      return "groups.json"
    case .group(let id):
      return "groups/\(Self.sanitize(id))/group.json"
    case .members(let id):
      return "groups/\(Self.sanitize(id))/members.json"
    case .groupUsers(let id):
      return "groups/\(Self.sanitize(id))/users.json"
    case .categories(let id):
      return "groups/\(Self.sanitize(id))/categories.json"
    case .budget(let id):
      return "groups/\(Self.sanitize(id))/budget.json"
    case .feedFirstPage(let id):
      return "groups/\(Self.sanitize(id))/feed.json"
    case .balances(let id):
      return "groups/\(Self.sanitize(id))/balances.json"
    case .activityFirstPage(let id):
      return "groups/\(Self.sanitize(id))/activity.json"
    }
  }

  static func sanitize(_ raw: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let filtered = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
    let value = String(filtered)
    return value.isEmpty ? "unknown" : value
  }
}

actor SnapshotStore {
  struct Scope: Equatable, Sendable {
    let userId: String
    let generation: UInt64
  }

  private let rootURL: URL
  private let maxRecentGroups: Int
  private var sessionGeneration: UInt64 = 0
  private var minAllowedTokenGeneration: UInt64 = 0
  private var activeScope: Scope?
  private var groupGenerations: [String: UInt64] = [:]
  private var memoryCache: [SnapshotKey: Data] = [:]
  private var recentGroupIds: [String] = []

  init(rootURL: URL? = nil, maxRecentGroups: Int = 20) {
    if let rootURL {
      self.rootURL = rootURL
    } else {
      let base =
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory
      self.rootURL = base.appending(path: "SongPhangSnapshots", directoryHint: .isDirectory)
    }
    self.maxRecentGroups = maxRecentGroups
  }

  func currentScope() -> Scope? {
    activeScope
  }

  func groupGeneration(for groupId: String) -> UInt64 {
    groupGenerations[groupId] ?? 0
  }

  @discardableResult
  func beginSession(userId: String, tokenGeneration: UInt64? = nil) -> Scope? {
    if let tokenGeneration {
      guard tokenGeneration >= minAllowedTokenGeneration else {
        return nil
      }
      if tokenGeneration > minAllowedTokenGeneration {
        minAllowedTokenGeneration = tokenGeneration
      }
    }
    if let current = activeScope, current.userId == userId {
      return current
    }
    sessionGeneration &+= 1
    let scope = Scope(userId: userId, generation: sessionGeneration)
    activeScope = scope
    memoryCache.removeAll()
    groupGenerations.removeAll()
    removeOtherUserDirectories(keeping: userId)
    recentGroupIds = loadRecentGroups(for: userId)
    return scope
  }

  func restoreLastUser<T: Sendable>(
    tokenGeneration: UInt64? = nil,
    decode: (Data) throws -> (userId: String, value: T)
  ) -> T? {
    if let tokenGeneration, tokenGeneration < minAllowedTokenGeneration {
      return nil
    }
    let fm = FileManager.default
    guard
      let entries = try? fm.contentsOfDirectory(
        at: rootURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return nil
    }
    let userDirs = entries.filter {
      (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
    guard userDirs.count == 1, let userDir = userDirs.first else {
      if userDirs.count > 1 {
        try? fm.removeItem(at: rootURL)
      }
      return nil
    }
    let meURL = userDir.appending(path: SnapshotKey.me.relativePath)
    guard let data = try? Data(contentsOf: meURL) else {
      return nil
    }
    do {
      let parsed = try decode(data)
      guard beginSession(userId: parsed.userId, tokenGeneration: tokenGeneration) != nil else {
        return nil
      }
      memoryCache[.me] = data
      return parsed.value
    } catch {
      try? fm.removeItem(at: meURL)
      return nil
    }
  }

  func read<T: Sendable>(_ key: SnapshotKey, decode: (Data) throws -> T) -> T? {
    guard let scope = activeScope else {
      return nil
    }
    if let cached = memoryCache[key] {
      do {
        return try decode(cached)
      } catch {
        memoryCache.removeValue(forKey: key)
        removeFile(for: key, userId: scope.userId)
        return nil
      }
    }
    let url = fileURL(for: key, userId: scope.userId)
    guard let data = try? Data(contentsOf: url) else {
      return nil
    }
    do {
      let decoded = try decode(data)
      memoryCache[key] = data
      return decoded
    } catch {
      try? FileManager.default.removeItem(at: url)
      return nil
    }
  }

  func writeData(
    _ data: Data,
    for key: SnapshotKey,
    scope: Scope,
    groupGeneration: UInt64? = nil
  ) {
    guard activeScope == scope else {
      return
    }
    if let groupId = key.groupId {
      let expected = self.groupGeneration(for: groupId)
      guard groupGeneration == nil || groupGeneration == expected else {
        return
      }
    }

    memoryCache[key] = data
    let url = fileURL(for: key, userId: scope.userId)
    writeProtected(data, to: url, userId: scope.userId)

    if let groupId = key.groupId {
      recordRecentGroup(groupId, userId: scope.userId)
    }
  }

  func writeEncoded<T: Encodable>(
    _ value: T,
    for key: SnapshotKey,
    scope: Scope,
    groupGeneration: UInt64? = nil
  ) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(value) else {
      return
    }
    writeData(data, for: key, scope: scope, groupGeneration: groupGeneration)
  }

  func invalidateGroup(_ groupId: String) {
    groupGenerations[groupId] = (groupGenerations[groupId] ?? 0) &+ 1
    memoryCache = memoryCache.filter { $0.key.groupId != groupId }
    if let userId = activeScope?.userId {
      let dir = groupDirectory(groupId: groupId, userId: userId)
      try? FileManager.default.removeItem(at: dir)
      recentGroupIds.removeAll { $0 == groupId }
      saveRecentGroups(for: userId)
    }
  }

  func reconcileGroups(keeping activeGroupIds: Set<String>, scope: Scope) {
    guard activeScope == scope else {
      return
    }
    var removedIds = Set<String>()
    for id in recentGroupIds where !activeGroupIds.contains(id) {
      removedIds.insert(id)
    }
    for key in memoryCache.keys {
      if let groupId = key.groupId, !activeGroupIds.contains(groupId) {
        removedIds.insert(groupId)
      }
    }
    for groupId in groupGenerations.keys where !activeGroupIds.contains(groupId) {
      removedIds.insert(groupId)
    }

    let fm = FileManager.default
    let groupsRoot = userDirectory(for: scope.userId).appending(
      path: "groups",
      directoryHint: .isDirectory
    )
    let sanitizedActive = Set(activeGroupIds.map(SnapshotKey.sanitize))
    if let dirs = try? fm.contentsOfDirectory(
      at: groupsRoot,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    ) {
      for dir in dirs where !sanitizedActive.contains(dir.lastPathComponent) {
        removedIds.insert(dir.lastPathComponent)
        try? fm.removeItem(at: dir)
      }
    }

    for groupId in removedIds {
      groupGenerations[groupId] = (groupGenerations[groupId] ?? 0) &+ 1
      memoryCache = memoryCache.filter { $0.key.groupId != groupId }
      let dir = groupDirectory(groupId: groupId, userId: scope.userId)
      try? fm.removeItem(at: dir)
    }

    recentGroupIds.removeAll { !activeGroupIds.contains($0) }
    saveRecentGroups(for: scope.userId)
  }

  func invalidateSession(atLeastTokenGeneration minGeneration: UInt64? = nil) {
    if let minGeneration, minGeneration > minAllowedTokenGeneration {
      minAllowedTokenGeneration = minGeneration
    }
    sessionGeneration &+= 1
    activeScope = nil
    groupGenerations.removeAll()
    memoryCache.removeAll()
    recentGroupIds.removeAll()
    try? FileManager.default.removeItem(at: rootURL)
  }

  // MARK: - Disk helpers

  private func userDirectory(for userId: String) -> URL {
    rootURL.appending(path: SnapshotKey.sanitize(userId), directoryHint: .isDirectory)
  }

  private func groupDirectory(groupId: String, userId: String) -> URL {
    userDirectory(for: userId)
      .appending(path: "groups", directoryHint: .isDirectory)
      .appending(path: SnapshotKey.sanitize(groupId), directoryHint: .isDirectory)
  }

  private func fileURL(for key: SnapshotKey, userId: String) -> URL {
    userDirectory(for: userId).appending(path: key.relativePath)
  }

  private func removeFile(for key: SnapshotKey, userId: String) {
    try? FileManager.default.removeItem(at: fileURL(for: key, userId: userId))
  }

  private func removeOtherUserDirectories(keeping userId: String) {
    let fm = FileManager.default
    let safeId = SnapshotKey.sanitize(userId)
    guard
      let entries = try? fm.contentsOfDirectory(
        at: rootURL,
        includingPropertiesForKeys: nil,
        options: []
      )
    else {
      return
    }
    for entry in entries where entry.lastPathComponent != safeId {
      try? fm.removeItem(at: entry)
    }
  }

  private func writeProtected(_ data: Data, to url: URL, userId: String) {
    let fm = FileManager.default
    let parent = url.deletingLastPathComponent()
    try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
    excludeFromBackup(rootURL)
    excludeFromBackup(userDirectory(for: userId))
    excludeFromBackup(parent)
    try? data.write(
      to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    excludeFromBackup(url)
  }

  private func excludeFromBackup(_ url: URL) {
    var mutableURL = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? mutableURL.setResourceValues(values)
  }

  private func recentGroupsURL(for userId: String) -> URL {
    userDirectory(for: userId).appending(path: "recent-groups.json")
  }

  private func loadRecentGroups(for userId: String) -> [String] {
    guard let data = try? Data(contentsOf: recentGroupsURL(for: userId)),
      let ids = try? JSONDecoder().decode([String].self, from: data)
    else {
      return []
    }
    return ids
  }

  private func saveRecentGroups(for userId: String) {
    guard let data = try? JSONEncoder().encode(recentGroupIds) else { return }
    writeProtected(data, to: recentGroupsURL(for: userId), userId: userId)
  }

  private func recordRecentGroup(_ groupId: String, userId: String) {
    recentGroupIds.removeAll { $0 == groupId }
    recentGroupIds.insert(groupId, at: 0)
    if recentGroupIds.count > maxRecentGroups {
      let evicted = recentGroupIds.suffix(from: maxRecentGroups)
      recentGroupIds = Array(recentGroupIds.prefix(maxRecentGroups))
      for oldGroupId in evicted {
        memoryCache = memoryCache.filter { $0.key.groupId != oldGroupId }
        try? FileManager.default.removeItem(
          at: groupDirectory(groupId: oldGroupId, userId: userId)
        )
      }
    }
    saveRecentGroups(for: userId)
  }
}
