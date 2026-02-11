import Foundation
import CoreData
import SwiftUI

final class RestorationManager {
    static let shared = RestorationManager()

    private let fileManager = FileManager.default
    private let pendingRestoreKey = "Feather.pendingRestore"

    private init() {}

    var isRestorePending: Bool {
        UserDefaults.standard.bool(forKey: pendingRestoreKey)
    }

    func applyPendingRestore() {
        guard isRestorePending else { return }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pendingDir = documentsURL.appendingPathComponent("PendingRestore")
        let extractedDir = pendingDir.appendingPathComponent("extracted")

        guard fileManager.fileExists(atPath: extractedDir.path) else {
            UserDefaults.standard.removeObject(forKey: pendingRestoreKey)
            return
        }

        AppLogManager.shared.info("Applying pending backup restoration...", category: "Restoration")

        do {
            // 1. Restore Database (Core Data)
            // We do this BEFORE loading the persistent container if possible
            let dbSourceDir = extractedDir.appendingPathComponent("database")
            if fileManager.fileExists(atPath: dbSourceDir.path) {
                // Get the default store URL without initializing the whole stack
                let container = NSPersistentContainer(name: "Feather")
                guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }

                let baseName = storeURL.lastPathComponent
                let dbDestDir = storeURL.deletingLastPathComponent()

                try? fileManager.createDirectory(at: dbDestDir, withIntermediateDirectories: true)

                for f in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                    let src = dbSourceDir.appendingPathComponent(f)
                    let dest = dbDestDir.appendingPathComponent(f)
                    if fileManager.fileExists(atPath: src.path) {
                        try? fileManager.removeItem(at: dest)
                        try fileManager.copyItem(at: src, to: dest)
                    }
                }
            }

            // 2. Restore Settings (UserDefaults)
            let settingsURL = extractedDir.appendingPathComponent("settings.plist")
            if fileManager.fileExists(atPath: settingsURL.path),
               let data = try? Data(contentsOf: settingsURL),
               let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.setPersistentDomain(dict, forName: bundleID)
                }
            }

            let standardSettingsURL = extractedDir.appendingPathComponent("standard_settings.plist")
            if fileManager.fileExists(atPath: standardSettingsURL.path),
               let data = try? Data(contentsOf: standardSettingsURL),
               let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                // For standard UserDefaults, we merge keys to avoid losing the pendingRestore flag during the process
                // though it's cleared at the end anyway.
                for (key, value) in dict {
                    if key != pendingRestoreKey {
                        UserDefaults.standard.set(value, forKey: key)
                    }
                }
            }

            // 3. Restore Files
            let categories = [
                "certificates": fileManager.certificates,
                "signed_apps": fileManager.signed,
                "imported_apps": fileManager.unsigned,
                "archives": fileManager.archives,
                "default_frameworks": documentsURL.appendingPathComponent("DefaultFrameworks")
            ]

            for (subDir, destURL) in categories {
                let srcURL = extractedDir.appendingPathComponent(subDir)
                if fileManager.fileExists(atPath: srcURL.path) {
                    try? fileManager.removeItem(at: destURL)
                    try? fileManager.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try fileManager.copyItem(at: srcURL, to: destURL)
                }
            }

            // 4. Extra Files
            let extraSourceDir = extractedDir.appendingPathComponent("extra_files")
            if fileManager.fileExists(atPath: extraSourceDir.path) {
                let contents = (try? fileManager.contentsOfDirectory(at: extraSourceDir, includingPropertiesForKeys: nil)) ?? []
                for file in contents {
                    let dest = documentsURL.appendingPathComponent(file.lastPathComponent)
                    try? fileManager.removeItem(at: dest)
                    try fileManager.copyItem(at: file, to: dest)
                }
            }

            AppLogManager.shared.success("Pending restoration applied successfully.", category: "Restoration")

        } catch {
            AppLogManager.shared.error("Failed to apply pending restoration: \(error.localizedDescription)", category: "Restoration")
        }

        // Final Cleanup
        try? fileManager.removeItem(at: pendingDir)
        UserDefaults.standard.removeObject(forKey: pendingRestoreKey)
        UserDefaults.standard.synchronize()
    }
}
