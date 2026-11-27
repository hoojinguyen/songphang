import Domain
import Foundation
import Security

actor TokenStore {
  enum TokenReadResult: Sendable, Equatable {
    case token(String)
    case notFound
    case transientFailure(OSStatus)
  }

  struct TokenSnapshot: Sendable, Equatable {
    let result: TokenReadResult
    let generation: UInt64

    var token: String? {
      if case .token(let t) = result { return t }
      return nil
    }

    var isDefinitivelyNotFound: Bool {
      result == .notFound
    }
  }

  private let service: String
  private let account: String
  private var accessGroup: String?
  private let extensionSharedStore: ExtensionSharedStore
  private static let tombstoneKey = "sp.session.tombstoned"
  private var cachedToken: String?
  private var hasLoaded = false
  private var generation: UInt64 = 0

  init(
    service: String = "vn.songphang.app.session",
    account: String = "bearer-token",
    accessGroup: String? = TokenStore.defaultAccessGroup(),
    extensionSharedStore: ExtensionSharedStore = .shared
  ) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
    self.extensionSharedStore = extensionSharedStore
  }

  static func defaultAccessGroup() -> String? {
    guard let raw = Bundle.main.infoDictionary?["KeychainAccessGroup"] as? String else {
      return nil
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.contains("$(") else {
      return nil
    }
    return trimmed
  }

  func currentGeneration() -> UInt64 {
    generation
  }

  func readSnapshot() async -> TokenSnapshot {
    let res = await readResult()
    return TokenSnapshot(result: res, generation: generation)
  }

  func read() async -> String? {
    await readSnapshot().token
  }

  private func baseQuery(usingAccessGroup group: String?) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    if let group, !group.isEmpty {
      query[kSecAttrAccessGroup as String] = group
    }
    return query
  }

  private func copyMatching(usingAccessGroup group: String?) -> (status: OSStatus, item: CFTypeRef?)
  {
    var query = baseQuery(usingAccessGroup: group)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    return (status, item)
  }

  private func deleteItem(usingAccessGroup group: String?) -> OSStatus {
    SecItemDelete(baseQuery(usingAccessGroup: group) as CFDictionary)
  }

  private func writeItem(data: Data, usingAccessGroup group: String?) -> OSStatus {
    let searchQuery = baseQuery(usingAccessGroup: group)
    let updateAttributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    var status = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)
    if status == errSecItemNotFound {
      var addQuery = searchQuery
      addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      addQuery[kSecValueData as String] = data
      status = SecItemAdd(addQuery as CFDictionary, nil)
    }
    return status
  }

  private func readResult() async -> TokenReadResult {
    if hasLoaded {
      if let token = cachedToken {
        return .token(token)
      } else {
        return .notFound
      }
    }

    if UserDefaults.standard.bool(forKey: Self.tombstoneKey) {
      let targetGroup = accessGroup ?? Self.defaultAccessGroup()
      let sharedStatus: OSStatus =
        if let group = targetGroup {
          deleteItem(usingAccessGroup: group)
        } else {
          errSecItemNotFound
        }
      let legacyStatus = deleteItem(usingAccessGroup: nil)
      let sharedOk =
        sharedStatus == errSecSuccess
        || sharedStatus == errSecItemNotFound
      let legacyOk = legacyStatus == errSecSuccess || legacyStatus == errSecItemNotFound
      if sharedOk && legacyOk {
        UserDefaults.standard.removeObject(forKey: Self.tombstoneKey)
      }
      hasLoaded = true
      cachedToken = nil
      return .notFound
    }

    let initialGeneration = generation
    var activeGroup = accessGroup
    var match = copyMatching(usingAccessGroup: activeGroup)
    var retries = 0
    while (match.status == errSecInteractionNotAllowed || match.status == errSecAuthFailed)
      && retries < 3
    {
      try? await Task.sleep(for: .milliseconds(20))
      if hasLoaded || generation != initialGeneration {
        if let token = cachedToken {
          return .token(token)
        }
        return .notFound
      }
      retries += 1
      match = copyMatching(usingAccessGroup: activeGroup)
    }

    if match.status == errSecMissingEntitlement, activeGroup != nil {
      // Simulator builds with CODE_SIGNING_ALLOWED=NO omit keychain-access-groups entitlement.
      accessGroup = nil
      activeGroup = nil
      match = copyMatching(usingAccessGroup: nil)
    }

    if match.status == errSecItemNotFound, let group = activeGroup {
      let legacyMatch = copyMatching(usingAccessGroup: nil)
      if legacyMatch.status == errSecSuccess,
        let legacyData = legacyMatch.item as? Data,
        let legacyToken = String(data: legacyData, encoding: .utf8),
        !legacyToken.isEmpty
      {
        let migrateStatus = writeItem(data: legacyData, usingAccessGroup: group)
        if migrateStatus == errSecSuccess {
          _ = deleteItem(usingAccessGroup: nil)
        } else if migrateStatus == errSecMissingEntitlement {
          accessGroup = nil
        }
        hasLoaded = true
        cachedToken = legacyToken
        return .token(legacyToken)
      }
    }

    guard match.status == errSecSuccess else {
      if match.status == errSecItemNotFound {
        hasLoaded = true
        cachedToken = nil
        return .notFound
      }
      return .transientFailure(match.status)
    }
    guard let data = match.item as? Data,
      let token = String(data: data, encoding: .utf8),
      !token.isEmpty
    else {
      hasLoaded = true
      cachedToken = nil
      return .notFound
    }
    hasLoaded = true
    cachedToken = token
    return .token(token)
  }

  @discardableResult
  func write(_ token: String) throws(AppError) -> UInt64 {
    guard let data = token.data(using: .utf8), !data.isEmpty else {
      throw .unexpected
    }
    var status = writeItem(data: data, usingAccessGroup: accessGroup)
    if status == errSecMissingEntitlement, accessGroup != nil {
      accessGroup = nil
      status = writeItem(data: data, usingAccessGroup: nil)
    } else if status == errSecSuccess, accessGroup != nil {
      _ = deleteItem(usingAccessGroup: nil)
    }
    guard status == errSecSuccess else {
      throw .unexpected
    }
    UserDefaults.standard.removeObject(forKey: Self.tombstoneKey)
    cachedToken = token
    hasLoaded = true
    generation &+= 1
    return generation
  }

  @discardableResult
  func clear() -> UInt64 {
    UserDefaults.standard.set(true, forKey: Self.tombstoneKey)
    let targetGroup = accessGroup ?? Self.defaultAccessGroup()
    let sharedStatus: OSStatus =
      if let group = targetGroup {
        deleteItem(usingAccessGroup: group)
      } else {
        errSecItemNotFound
      }
    let legacyStatus = deleteItem(usingAccessGroup: nil)
    cachedToken = nil
    hasLoaded = true
    let sharedOk =
      sharedStatus == errSecSuccess
      || sharedStatus == errSecItemNotFound
    let legacyOk = legacyStatus == errSecSuccess || legacyStatus == errSecItemNotFound
    if sharedOk && legacyOk {
      UserDefaults.standard.removeObject(forKey: Self.tombstoneKey)
    }
    extensionSharedStore.clearAll()
    generation &+= 1
    return generation
  }

  func clearIfGeneration(_ expected: UInt64) -> UInt64? {
    guard generation == expected else {
      return nil
    }
    return clear()
  }
}
