import Foundation
import Security

enum PasswordChangerError: LocalizedError {
    case importFailed(OSStatus)
    case exportFailed(OSStatus)
    case noItemsFound
    case invalidData
    case notSupported

    var errorDescription: String? {
        switch self {
        case .importFailed(let status):
            return "Failed to import P12: \(status)"
        case .exportFailed(let status):
            return "Failed to export P12: \(status)"
        case .noItemsFound:
            return "No items found in P12"
        case .invalidData:
            return "Invalid P12 data"
        case .notSupported:
            return "This operation is not supported on this platform"
        }
    }
}

class PasswordChanger {
    /// Changes the password of a PKCS#12 (.p12) file.
    /// This operation is performed entirely in memory.
    static func changePassword(p12Data: Data, oldPassword: String, newPassword: String) throws -> Data {
        let importOptions: [String: Any] = [
            kSecImportExportPassphrase as String: oldPassword
        ]

        var rawItems: CFArray?
        let importStatus = SecPKCS12Import(p12Data as CFData, importOptions as CFDictionary, &rawItems)

        guard importStatus == errSecSuccess else {
            throw PasswordChangerError.importFailed(importStatus)
        }

        guard let items = rawItems as? [[String: Any]], !items.isEmpty else {
            throw PasswordChangerError.noItemsFound
        }

        // We want to export the identities and certificates found in the import
        var exportItems: [Any] = []
        for item in items {
            if let identity = item[kSecImportItemIdentity as String] {
                exportItems.append(identity)
            }
            if let certChain = item[kSecImportItemCertChain as String] as? [Any] {
                exportItems.append(contentsOf: certChain)
            }
        }

        if exportItems.isEmpty {
            throw PasswordChangerError.noItemsFound
        }

        #if os(macOS)
        var keyParams = SecItemImportExportKeyParameters()
        keyParams.version = UInt32(kSecKeyImportExportParamsVersion)

        // Use a pointer to the new password string
        let passwordCF = newPassword as CFString
        keyParams.passphrase = Unmanaged.passRetained(passwordCF)

        var exportedData: CFData?
        // Note: SecItemExport with kSecFormatPKCS12 requires SecIdentity or CFArray of items
        let exportStatus = SecItemExport(
            exportItems as CFArray,
            SecExternalFormat.formatPKCS12,
            [],
            &keyParams,
            &exportedData
        )

        // Release the retained CFString
        keyParams.passphrase?.release()

        guard exportStatus == errSecSuccess, let resultData = exportedData as Data? else {
            throw PasswordChangerError.exportFailed(exportStatus)
        }

        return resultData
        #else
        // On non-macOS platforms, SecItemExport for PKCS12 is not available in the public Security framework.
        throw PasswordChangerError.notSupported
        #endif
    }
}
