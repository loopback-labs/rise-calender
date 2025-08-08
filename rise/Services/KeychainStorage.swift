import Foundation
import Security

final class KeychainStorage {
  static let shared = KeychainStorage()
  private init() {}

  // Cache to avoid repeated Keychain access
  private var cache: [String: Data] = [:]
  private let cacheQueue = DispatchQueue(label: "keychain.cache", attributes: .concurrent)

  func set(data: Data, forKey key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "rise.app",
      kSecAttrAccount as String: key,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]

    // Update cache first
    cacheQueue.async(flags: .barrier) {
      self.cache[key] = data
    }

    SecItemDelete(query as CFDictionary)

    var attributes = query
    attributes[kSecValueData as String] = data

    let status = SecItemAdd(attributes as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }

  func data(forKey key: String) throws -> Data? {
    // Check cache first
    if let cachedData = cacheQueue.sync(execute: { cache[key] }) {
      return cachedData
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "rise.app",
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    if let data = item as? Data {
      // Cache the result
      cacheQueue.async(flags: .barrier) {
        self.cache[key] = data
      }
      return data
    }

    return nil
  }

  func remove(forKey key: String) throws {
    // Remove from cache first
    cacheQueue.async(flags: .barrier) {
      self.cache.removeValue(forKey: key)
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "rise.app",
      kSecAttrAccount as String: key,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }

  // Preload all tokens to reduce Keychain prompts
  func preloadTokens(forKeys keys: [String]) {
    for key in keys {
      _ = try? data(forKey: key)
    }
  }

  // Clear cache when needed
  func clearCache() {
    cacheQueue.async(flags: .barrier) {
      self.cache.removeAll()
    }
  }
}
