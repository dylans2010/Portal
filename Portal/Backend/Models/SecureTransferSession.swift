import Foundation

struct SecureTransferSession: Codable {
    let sessionID: UUID
    let createdAt: Date
    let transferMethod: String // "Nearby", "Remote", "Manual", etc.
    let remoteDeviceName: String
    let encryptionType: String
    let sessionFingerprint: String
    var isActive: Bool
    let expirationDate: Date?

    // Optional compatibility with legacy fields if needed by other parts of the app
    var udid: String {
        return sessionID.uuidString
    }
}
