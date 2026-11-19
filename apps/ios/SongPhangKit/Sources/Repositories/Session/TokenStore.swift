import Domain
import Foundation
import Security

actor TokenStore {
  private let service: String
  private let account: String
  private var cachedToken: String?
  private var hasLoaded = false

  init(
    service: String = "vn.songphang.app.session",
    account: String = "bearer-token"
  ) {
    self.service = service
    self.account = account
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

  func write(_ token: String) throws(AppError) {
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
  }

  func clear() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
    cachedToken = nil
    hasLoaded = true
  }
}
