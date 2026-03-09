import Foundation
import ZsignSwift

enum PasswordChangerError: LocalizedError {
    case importFailed(Int)
    case exportFailed(Int)
    case noItemsFound
    case invalidData
    case notSupported
    case authFailed
    case decodeFailed
    case invalidParam
    case keyMismatch

    var errorDescription: String? {
        switch self {
        case .importFailed(let code):
            return "Failed to import P12 (error \(code))"
        case .exportFailed(let code):
            return "Failed to export P12 (error \(code))"
        case .noItemsFound:
            return "No identities found in the P12 file"
        case .invalidData:
            return "Invalid P12 data"
        case .notSupported:
            return "This operation is not supported on this platform"
        case .authFailed:
            return "Incorrect password or unsupported encryption algorithm"
        case .decodeFailed:
            return "The file could not be decoded. It may be malformed or not a valid PKCS#12 file"
        case .invalidParam:
            return "Invalid PKCS#12 file or parameters"
        case .keyMismatch:
            return "Private key does not match the certificate in the P12 file"
        }
    }
}

class PasswordChanger {
    /// Changes the password of a PKCS#12 (.p12) file entirely in memory.
    /// Compatible with iOS and macOS via OpenSSL.
    static func changePassword(p12Data: Data, oldPassword: String, newPassword: String) throws -> Data {
        // Trim whitespace and newline characters; never pass nil — empty string is valid for passwordless P12 files
        let trimmedOldPassword = oldPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            return try Zsign.changeP12Password(
                data: p12Data,
                oldPassword: trimmedOldPassword,
                newPassword: trimmedNewPassword
            )
        } catch {
            let nsError = error as NSError
            switch nsError.code {
            case -2:
                throw PasswordChangerError.decodeFailed
            case -3:
                throw PasswordChangerError.authFailed
            case -4:
                throw PasswordChangerError.noItemsFound
            case -5:
                throw PasswordChangerError.keyMismatch
            case -6, -7:
                throw PasswordChangerError.exportFailed(nsError.code)
            default:
                throw PasswordChangerError.importFailed(nsError.code)
            }
        }
    }
}
