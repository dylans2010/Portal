import Foundation
import Security
import ZsignSwift

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
    /// Changes the password of a PKCS#12 (.p12) file using OpenSSL.
    /// This operation is performed entirely in memory.
    static func changePassword(p12Data: Data, oldPassword: String, newPassword: String) throws -> Data {
        do {
            return try Zsign.reencryptP12(p12Data: p12Data, oldPassword: oldPassword, newPassword: newPassword)
        } catch {
            // Rethrow as localized error if needed, or just let the NSError through
            throw error
        }
    }
}
