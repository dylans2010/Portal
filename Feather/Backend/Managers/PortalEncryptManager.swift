import Foundation
import CryptoKit
import OSLog

/// Manager responsible for protecting .portalcert files and their extracted contents
final class PortalEncryptManager {
    static let shared = PortalEncryptManager()

    private let _fileManager = FileManager.default

    /// Obfuscated extension for encrypted portal cert files
    static let encryptedExtension = "portaldata"

    private init() {}

    // MARK: - Protection

    /// Encrypts and obfuscates P12 and Provision files into a single bundle
    /// - Parameters:
    ///   - p12: URL to the plain P12 file
    ///   - provision: URL to the plain mobileprovision file
    ///   - destination: Directory where the encrypted bundle should be stored
    func protectPortalCertFiles(p12: URL, provision: URL, destination: URL) throws {
        AppLogManager.shared.info("Protecting portal certificate files at: \(destination.path)", category: "Security")

        // 1. Read files
        let p12Data = try Data(contentsOf: p12)
        let provisionData = try Data(contentsOf: provision)

        // 2. Bundle them
        let bundle: [String: Data] = [
            "p12": p12Data,
            "provision": provisionData
        ]

        let bundleData = try JSONEncoder().encode(bundle)

        // 3. Encrypt
        let key = try _getEncryptionKey()
        let sealedBox = try AES.GCM.seal(bundleData, using: key)

        guard let encryptedData = sealedBox.combined else {
            AppLogManager.shared.error("Failed to combine encrypted data", category: "Security")
            throw PortalEncryptError.encryptionFailed
        }

        // 4. Write to destination with obfuscated name
        try _fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let encryptedURL = destination.appendingPathComponent("data.\(Self.encryptedExtension)")

        // Security check: ensure file doesn't exist or remove it first
        if _fileManager.fileExists(atPath: encryptedURL.path) {
            try _fileManager.removeItem(at: encryptedURL)
        }

        try encryptedData.write(to: encryptedURL, options: .atomic)

        // 5. Cleanup plain files if they are in the destination directory
        if p12.deletingLastPathComponent().path == destination.path {
            try? _fileManager.removeItem(at: p12)
        }
        if provision.deletingLastPathComponent().path == destination.path {
            try? _fileManager.removeItem(at: provision)
        }

        AppLogManager.shared.success("Portal certificate files protected successfully", category: "Security")
    }

    // MARK: - Decryption

    /// Decrypts the protected bundle into plain Data
    /// - Parameter directory: Directory containing the .portaldata file
    /// - Returns: Tuple of decrypted P12 and Provision data
    func getDecryptedFiles(from directory: URL) throws -> (p12: Data, provision: Data) {
        let encryptedURL = directory.appendingPathComponent("data.\(Self.encryptedExtension)")

        guard _fileManager.fileExists(atPath: encryptedURL.path) else {
            AppLogManager.shared.error("Protected file not found at: \(encryptedURL.path)", category: "Security")
            throw PortalEncryptError.protectedFileNotFound
        }

        let encryptedData = try Data(contentsOf: encryptedURL)
        let key = try _getEncryptionKey()

        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        let bundle = try JSONDecoder().decode([String: Data].self, from: decryptedData)

        guard let p12 = bundle["p12"], let provision = bundle["provision"] else {
            AppLogManager.shared.error("Decrypted bundle is missing expected files", category: "Security")
            throw PortalEncryptError.decryptionFailed
        }

        return (p12, provision)
    }

    /// Provides temporary access to plain files for a specific operation
    /// - Parameters:
    ///   - directory: Directory containing the .portaldata file
    ///   - perform: Closure that uses the temporary plain files
    func withDecryptedFiles<T>(from directory: URL, perform: (URL, URL) async throws -> T) async throws -> T {
        AppLogManager.shared.debug("Creating temporary plain files for operation", category: "Security")

        let (p12Data, provisionData) = try getDecryptedFiles(from: directory)

        let tempDir = _fileManager.temporaryDirectory.appendingPathComponent("portal-secure-\(UUID().uuidString)")
        try _fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let p12URL = tempDir.appendingPathComponent("cert.p12")
        let provisionURL = tempDir.appendingPathComponent("profile.mobileprovision")

        try p12Data.write(to: p12URL)
        try provisionData.write(to: provisionURL)

        defer {
            // Secure cleanup
            try? _fileManager.removeItem(at: tempDir)
            AppLogManager.shared.debug("Temporary plain files cleaned up", category: "Security")
        }

        return try await perform(p12URL, provisionURL)
    }

    // MARK: - Private Helpers

    /// Retrieves or generates a persistent encryption key from the Keychain
    private func _getEncryptionKey() throws -> SymmetricKey {
        let tag = "dev.feather.portalcert.encryption.key".data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data {
            return SymmetricKey(data: data)
        } else if status == errSecItemNotFound {
            // Generate and save new key
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrApplicationTag as String: tag,
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                AppLogManager.shared.error("Failed to save encryption key to Keychain: \(addStatus)", category: "Security")
                throw PortalEncryptError.keyStorageFailed
            }

            return newKey
        } else {
            AppLogManager.shared.error("Keychain error: \(status)", category: "Security")
            throw PortalEncryptError.keyRetrievalFailed
        }
    }
}

// MARK: - Error Types

enum PortalEncryptError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case protectedFileNotFound
    case keyStorageFailed
    case keyRetrievalFailed

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt certificate data."
        case .decryptionFailed: return "Failed to decrypt certificate data."
        case .protectedFileNotFound: return "Protected certificate file not found."
        case .keyStorageFailed: return "Failed to securely store encryption key."
        case .keyRetrievalFailed: return "Failed to retrieve encryption key."
        }
    }
}
