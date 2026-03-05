import Foundation
import Combine

class SecureTransferSessionManager: ObservableObject {
    static let shared = SecureTransferSessionManager()

    @Published var currentSession: SecureTransferSession?

    private let sessionFileName = "secureTransferSession.plist"

    private var sessionFileURL: URL {
        return URL.documentsDirectory.appendingPathComponent(sessionFileName)
    }

    private init() {
        self.currentSession = loadSession()
    }

    func sessionExists() -> Bool {
        return FileManager.default.fileExists(atPath: sessionFileURL.path)
    }

    func saveSession(_ session: SecureTransferSession) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(session)
            try data.write(to: sessionFileURL, options: .atomic)

            DispatchQueue.main.async {
                self.currentSession = session
            }

            AppLogManager.shared.success("Secure transfer session saved: \(session.remoteDeviceName)", category: "Session")
        } catch {
            AppLogManager.shared.error("Failed to save secure transfer session: \(error.localizedDescription)", category: "Session")
        }
    }

    func loadSession() -> SecureTransferSession? {
        guard sessionExists() else {
            return nil
        }

        do {
            let data = try Data(contentsOf: sessionFileURL)
            let decoder = PropertyListDecoder()
            let session = try decoder.decode(SecureTransferSession.self, from: data)
            return session
        } catch {
            AppLogManager.shared.error("Failed to load secure transfer session: \(error.localizedDescription)", category: "Session")
            return nil
        }
    }

    func refreshSession() {
        self.currentSession = loadSession()
    }

    func deactivateSession() {
        if var session = loadSession() {
            session.isActive = false
            saveSession(session)
            AppLogManager.shared.info("Secure transfer session deactivated", category: "Session")
        }
    }

    func deleteSession() {
        do {
            if sessionExists() {
                try FileManager.default.removeItem(at: sessionFileURL)
                DispatchQueue.main.async {
                    self.currentSession = nil
                }
                AppLogManager.shared.info("Secure transfer session deleted", category: "Session")
            }
        } catch {
            AppLogManager.shared.error("Failed to delete secure transfer session: \(error.localizedDescription)", category: "Session")
        }
    }

    func isSessionActive() -> Bool {
        guard let session = loadSession() else { return false }
        return isSessionValid(session)
    }

    func isSessionValid(_ session: SecureTransferSession) -> Bool {
        guard session.isActive else { return false }
        return !validateExpiration(session)
    }

    func validateExpiration(_ session: SecureTransferSession) -> Bool {
        if let expirationDate = session.expirationDate {
            return expirationDate < Date()
        }
        return false
    }

    func recordSessionAuthenticated(
        sessionID: UUID = UUID(),
        createdAt: Date = Date(),
        method: String,
        remoteDeviceName: String,
        encryptionType: String = "AES-256",
        sessionFingerprint: String? = nil,
        isActive: Bool = true
    ) {
        let fingerprint = sessionFingerprint ?? String(UUID().uuidString.prefix(8)).uppercased()
        let session = SecureTransferSession(
            sessionID: sessionID,
            createdAt: createdAt,
            transferMethod: method,
            remoteDeviceName: remoteDeviceName,
            encryptionType: encryptionType,
            sessionFingerprint: fingerprint,
            isActive: isActive,
            expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        saveSession(session)
    }
}
