import Foundation
import SwiftUI

// MARK: - Save Device Storage Manager
final class SaveDeviceStorage: ObservableObject {
    static let shared = SaveDeviceStorage()

    @AppStorage("Feather.saveDataToDevice") var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                ensureDeviceID()
                if migrateData(toAppGroup: true) {
                    ToastManager.shared.show("💾 Data migrated to App Group successfully!", type: .success)
                } else {
                    ToastManager.shared.show("⚠️ Migration to App Group failed. Some data might be missing.", type: .error)
                }
            } else {
                if migrateData(toAppGroup: false) {
                    ToastManager.shared.show("📦 Data restored to local storage.", type: .info)
                } else {
                    ToastManager.shared.show("⚠️ Restoring data to local storage failed.", type: .error)
                }
            }
        }
    }

    private init() {
        if isEnabled {
            ensureDeviceID()
        }
    }

    /// Ensures that a unique device ID exists in the system-level storage
    func ensureDeviceID() {
        if getDeviceID() == nil {
            // Use hardware ID if possible, otherwise persistent UUID
            let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

            // Save to App Group UserDefaults for "system level" persistence
            if let groupDefaults = UserDefaults(suiteName: Storage.appGroupID) {
                groupDefaults.set(newID, forKey: "portal_device_id")
                AppLogManager.shared.success("Generated and saved new Portal Device ID to App Group: \(newID)", category: "Storage")
            }

            // Also try to save to Keychain as a backup
            do {
                try KeychainManager.shared.save(newID, for: .portalDeviceID)
            } catch {
                AppLogManager.shared.error("Failed to save Portal Device ID to Keychain: \(error.localizedDescription)", category: "Storage")
            }
        }
    }

    /// Migrates data between local container and App Group
    @discardableResult
    internal func migrateData(toAppGroup: Bool) -> Bool {
        let fileManager = FileManager.default
        let localDocuments = URL.documentsDirectory
        let appGroupID = Storage.appGroupID
        var success = true

        guard let groupContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            AppLogManager.shared.error("App Group container not found during migration", category: "Storage")
            return false
        }

        let groupDocuments = groupContainer.appendingPathComponent("Documents", isDirectory: true)

        let sourceDocs = toAppGroup ? localDocuments : groupDocuments
        let targetDocs = toAppGroup ? groupDocuments : localDocuments

        // Ensure target parent exists
        try? fileManager.createDirectory(at: targetDocs, withIntermediateDirectories: true)

        // Migrate Documents
        do {
            let items = try fileManager.contentsOfDirectory(at: sourceDocs, includingPropertiesForKeys: nil)
            for item in items {
                let targetItem = targetDocs.appendingPathComponent(item.lastPathComponent)
                if !fileManager.fileExists(atPath: targetItem.path) {
                    try fileManager.moveItem(at: item, to: targetItem)
                }
            }
            AppLogManager.shared.success("Migrated documents to \(toAppGroup ? "App Group" : "Local")", category: "Storage")
        } catch {
            AppLogManager.shared.error("Failed to migrate documents: \(error.localizedDescription)", category: "Storage")
            success = false
        }

        // Migrate Core Data
        let dbName = "Feather"
        let localSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sourceDBDir = toAppGroup ? localSupport : groupContainer
        let targetDBDir = toAppGroup ? groupContainer : localSupport

        let extensions = ["sqlite", "sqlite-shm", "sqlite-wal"]
        for ext in extensions {
            let sourceFile = sourceDBDir.appendingPathComponent("\(dbName).\(ext)")
            let targetFile = targetDBDir.appendingPathComponent("\(dbName).\(ext)")

            if fileManager.fileExists(atPath: sourceFile.path) {
                do {
                    if fileManager.fileExists(atPath: targetFile.path) {
                        try fileManager.removeItem(at: targetFile)
                    }
                    try fileManager.moveItem(at: sourceFile, to: targetFile)
                    AppLogManager.shared.success("Migrated \(dbName).\(ext) to \(toAppGroup ? "App Group" : "Local")", category: "Storage")
                } catch {
                    AppLogManager.shared.error("Failed to migrate \(dbName).\(ext): \(error.localizedDescription)", category: "Storage")
                    success = false
                }
            }
        }

        return success
    }

    /// Retrieves the unique device ID from the storage
    func getDeviceID() -> String? {
        // Try App Group UserDefaults first
        if let groupDefaults = UserDefaults(suiteName: Storage.appGroupID),
           let id = groupDefaults.string(forKey: "portal_device_id") {
            return id
        }

        // Fallback to Keychain
        do {
            return try KeychainManager.shared.retrieve(for: .portalDeviceID)
        } catch {
            return nil
        }
    }
}
