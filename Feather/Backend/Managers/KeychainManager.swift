import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.feather.portal"
    
    private init() {}
    
    enum KeychainKey: String {
        case openRouterAPIKey = "openrouter_api_key"
    }
    
    enum KeychainError: Error, LocalizedError {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .duplicateEntry:
                return "Duplicate Keychain Entry"
            case .unknown(let status):
                return "Keychain Error: \(status)"
            case .itemNotFound:
                return "Item not found in keychain"
            case .invalidData:
                return "Invalid Data Format"
            }
        }
    }
    
    func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func retrieve(for key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    func exists(for key: KeychainKey) -> Bool {
        do {
            _ = try retrieve(for: key)
            return true
        } catch {
            return false
        }
    }
}
