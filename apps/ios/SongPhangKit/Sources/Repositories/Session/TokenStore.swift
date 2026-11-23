import Domain
import Foundation
import Security

actor TokenStore {
  struct TokenSnapshot: Sendable, Equatable {
    let token: String?
    let generation: UInt64
  }

  private let service: String
  private let account: String
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

  func readSnapshot() -> TokenSnapshot {
    TokenSnapshot(token: read(), generation: generation)
  }

  func read() -> String? {
    if hasLoaded {
      return cachedToken
    }
    hasLoaded = true
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess,
      let data = item as? Data,
      let token = String(data: data, encoding: .utf8),
      !token.isEmpty
    else {
      cachedToken = nil
      return nil
    }
    cachedToken = token
    return token
  }

  @discardableResult
  func write(_ token: String) throws(AppError) -> UInt64 {
    guard let data = token.data(using: .utf8), !data.isEmpty else {
      throw .unexpected
    }
    let deleteQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(deleteQuery as CFDictionary)

    let addQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData as String: data,
    ]
    let status = SecItemAdd(addQuery as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw .unexpected
    }
    cachedToken = token
    hasLoaded = true
    generation &+= 1
    return generation
  }

  @discardableResult
  func clear() -> UInt64 {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
    cachedToken = nil
    hasLoaded = true
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
