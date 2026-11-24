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
  private static let tombstoneKey = "sp.session.tombstoned"
  private var cachedToken: String?
  private var hasLoaded = false
  private var generation: UInt64 = 0

  init(
    service: String = "vn.songphang.app.session",
    account: String = "bearer-token"
  ) {
    self.service = service
    self.account = account
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

  private func readResult() async -> TokenReadResult {
    if hasLoaded {
      if let token = cachedToken {
        return .token(token)
      } else {
        return .notFound
      }
    }
    if UserDefaults.standard.bool(forKey: Self.tombstoneKey) {
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
      ]
      let status = SecItemDelete(query as CFDictionary)
      if status == errSecSuccess || status == errSecItemNotFound {
        UserDefaults.standard.removeObject(forKey: Self.tombstoneKey)
      }
      hasLoaded = true
      cachedToken = nil
      return .notFound
    }

    let initialGeneration = generation
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    var status = SecItemCopyMatching(query as CFDictionary, &item)
    var retries = 0
    while (status == errSecInteractionNotAllowed || status == errSecAuthFailed) && retries < 3 {
      try? await Task.sleep(for: .milliseconds(20))
      if hasLoaded || generation != initialGeneration {
        if let token = cachedToken {
          return .token(token)
        }
        return .notFound
      }
      retries += 1
      status = SecItemCopyMatching(query as CFDictionary, &item)
    }
    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        hasLoaded = true
        cachedToken = nil
        return .notFound
      }
      return .transientFailure(status)
    }
    guard let data = item as? Data,
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
    let searchQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
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
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    cachedToken = nil
    hasLoaded = true
    if status == errSecSuccess || status == errSecItemNotFound {
      UserDefaults.standard.removeObject(forKey: Self.tombstoneKey)
    }
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
