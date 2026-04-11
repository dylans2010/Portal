import Foundation
import ZIPFoundation
import CryptoKit

// MARK: - Backup Payload
/// Manages the collection and packaging of device data into a ZIP archive.
struct BackupPayload {
    static let mirrorFilename = "PortalMirror.zip"
    static let markerFilename = "PORTAL_MIRROR_MARKER.txt"

    // MARK: - Instance Storage

    private let zipData: Data

    /// Zips the contents of `backupDirectory` into an in-memory payload.
    init(backupDirectory: URL) throws {
        let fileManager = FileManager.default
        let tempZip = fileManager.temporaryDirectory
            .appendingPathComponent("BackupPayload_\(UUID().uuidString).zip")
        defer { try? fileManager.removeItem(at: tempZip) }
        try fileManager.zipItem(at: backupDirectory, to: tempZip, shouldKeepParent: false)
        self.zipData = try Data(contentsOf: tempZip)
    }

    private init(zipData: Data) {
        self.zipData = zipData
    }

    // MARK: - Encryption / Decryption

    /// Encrypts the payload using AES-GCM with a SHA-256-derived key.
    func encrypted(with password: String) throws -> Data {
        let keyData = SHA256.hash(data: Data(password.utf8))
        let key = SymmetricKey(data: keyData)
        let sealed = try AES.GCM.seal(zipData, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "BackupPayload", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to produce sealed box data."])
        }
        return combined
    }

    /// Decrypts data previously produced by `encrypted(with:)`.
    static func decrypted(from data: Data, password: String) throws -> BackupPayload {
        let keyData = SHA256.hash(data: Data(password.utf8))
        let key = SymmetricKey(data: keyData)
        let box = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(box, using: key)
        return BackupPayload(zipData: decryptedData)
    }

    // MARK: - Extraction

    /// Unzips the payload into `directory`, creating it if necessary.
    func extract(to directory: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let tempZip = fileManager.temporaryDirectory
            .appendingPathComponent("BackupPayloadExtract_\(UUID().uuidString).zip")
        defer { try? fileManager.removeItem(at: tempZip) }
        try zipData.write(to: tempZip)
        try fileManager.unzipItem(at: tempZip, to: directory)
    }

    // MARK: - Static Factory

    /// Collects ALL relevant data from the device and packages it into a ZIP archive at the given URL.
    static func createFullMirror(at destinationURL: URL) async throws {
        let fileManager = FileManager.default
        let tempMirrorDir = fileManager.temporaryDirectory.appendingPathComponent("MirrorCollection_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempMirrorDir, withIntermediateDirectories: true)

        // 1. Certificates
        let certsDir = fileManager.certificates
        if fileManager.fileExists(atPath: certsDir.path) {
            try? fileManager.copyItem(at: certsDir, to: tempMirrorDir.appendingPathComponent("certificates"))
        }

        // 2. Signed Apps
        let signedDir = fileManager.signed
        if fileManager.fileExists(atPath: signedDir.path) {
            try? fileManager.copyItem(at: signedDir, to: tempMirrorDir.appendingPathComponent("signed_apps"))
        }

        // 3. Imported Apps
        let unsignedDir = fileManager.unsigned
        if fileManager.fileExists(atPath: unsignedDir.path) {
            try? fileManager.copyItem(at: unsignedDir, to: tempMirrorDir.appendingPathComponent("imported_apps"))
        }
        
        // 4. Default Frameworks
        let frameworksDir = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
        if fileManager.fileExists(atPath: frameworksDir.path) {
            try? fileManager.copyItem(at: frameworksDir, to: tempMirrorDir.appendingPathComponent("default_frameworks"))
        }

        // 5. Archives
        let archivesDir = fileManager.archives
        if fileManager.fileExists(atPath: archivesDir.path) {
            try? fileManager.copyItem(at: archivesDir, to: tempMirrorDir.appendingPathComponent("archives"))
        }
        
        // 6. Database (Core Data)
        if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
            let dbSourceDir = storeURL.deletingLastPathComponent()
            let dbDestDir = tempMirrorDir.appendingPathComponent("database")
            try fileManager.createDirectory(at: dbDestDir, withIntermediateDirectories: true)

            let baseName = storeURL.lastPathComponent
            for suffix in ["", "-shm", "-wal"] {
                let fileURL = dbSourceDir.appendingPathComponent(baseName + suffix)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try? fileManager.copyItem(at: fileURL, to: dbDestDir.appendingPathComponent(baseName + suffix))
                }
            }
        }
        
        // 7. Settings (Standard & App Group)
        let settingsDir = tempMirrorDir.appendingPathComponent("settings")
        try fileManager.createDirectory(at: settingsDir, withIntermediateDirectories: true)
        
        // Standard
        let standardDefaults = UserDefaults.standard.dictionaryRepresentation()
        let filteredStandard = standardDefaults.filter { key, _ in
            !key.hasPrefix("NS") && !key.hasPrefix("Apple") && !key.hasPrefix("AK") && !key.hasPrefix("WebKit")
        }
        if let standardData = try? PropertyListSerialization.data(fromPropertyList: filteredStandard, format: .xml, options: 0) {
            try? standardData.write(to: settingsDir.appendingPathComponent("standard_settings.plist"))
        }
        
        // App Group
        if let userDefaults = UserDefaults(suiteName: Storage.appGroupID) {
            let groupDefaults = userDefaults.dictionaryRepresentation()
            let filteredGroup = groupDefaults.filter { key, _ in
                !key.hasPrefix("NS") && !key.hasPrefix("Apple") && !key.hasPrefix("AK") && !key.hasPrefix("WebKit")
            }
            if let groupData = try? PropertyListSerialization.data(fromPropertyList: filteredGroup, format: .xml, options: 0) {
                try? groupData.write(to: settingsDir.appendingPathComponent("settings.plist"))
            }
        }

        // 8. Sources
        let sources = Storage.shared.getSources()
        let sourcesData = sources.compactMap { source -> [String: String]? in
            guard let urlString = source.sourceURL?.absoluteString,
                  let name = source.name,
                  let identifier = source.identifier else { return nil }
            return ["url": urlString, "name": name, "identifier": identifier]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: sourcesData) {
            try? jsonData.write(to: tempMirrorDir.appendingPathComponent("sources.json"))
        }
        
        // 9. Marker file
        let markerContent = "PORTAL_MIRROR_v2.0_\(Date().timeIntervalSince1970)"
        try? markerContent.write(to: tempMirrorDir.appendingPathComponent(markerFilename), atomically: true, encoding: .utf8)

        // 10. ZIP it up
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.zipItem(at: tempMirrorDir, to: destinationURL, shouldKeepParent: false)
        
        // Cleanup
        try? fileManager.removeItem(at: tempMirrorDir)
    }
}
