import SwiftUI
import NimbleViews

// MARK: - Restore Options View
struct RestoreOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isRestoring = false
    @State private var selectedMergeMode: Bool? = nil

    var onConflictResolution: ((URL) -> Void)? = nil
    var onHealthCheck: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            NBList(.localized("Restore Options")) {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Backup Received Successfully")
                            .font(.headline)

                        Text("Choose how to restore the backup")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } header: {
                    AppearanceSectionHeader(title: String.localized("Status"), icon: "checkmark.shield.fill")
                }

                Section {
                    Button {
                        handleRestore(merge: true)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.triangle.merge")
                                    .foregroundStyle(.blue)
                                Text("Merge With Existing Data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            Text("Keep existing data and add backup contents. Conflicts will be resolved automatically using the Auto Fix tool.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    Button {
                        handleRestore(merge: false)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(.orange)
                                Text("Replace All Data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            Text("Remove existing data and restore from backup. This will overwrite all your current settings and apps. Be careful on what you choose.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Restore Method"), icon: "arrow.down.doc.fill")
                }
            }
            .navigationTitle("Restore Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Clean up the pending backup
                        if let path = UserDefaults.standard.string(forKey: "pendingNearbyBackupRestore") {
                            try? FileManager.default.removeItem(atPath: path)
                            UserDefaults.standard.removeObject(forKey: "pendingNearbyBackupRestore")
                        }
                        dismiss()
                    }
                }
            }
            .overlay {
                if isRestoring {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Restoring")
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    private func handleRestore(merge: Bool) {
        guard let path = UserDefaults.standard.string(forKey: "pendingNearbyBackupRestore") else { return }
        let tempRestoreDir = URL(fileURLWithPath: path)

        selectedMergeMode = merge

        // First check for conflicts
        dismiss()

        // Trigger conflict resolver if callback exists
        if let callback = onConflictResolution {
            callback(tempRestoreDir)
        } else {
            // Fallback to direct restore (for backward compatibility)
            performRestore(tempRestoreDir: tempRestoreDir, merge: merge)
        }
    }

    private func performRestore(tempRestoreDir: URL, merge: Bool) {
        isRestoring = true

        Task {
            // Reuse the exact restore logic from BackupRestoreView
            let fileManager = FileManager.default

            do {
                // 1. Validate Backup
                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in
                    fileManager.fileExists(atPath: tempRestoreDir.appendingPathComponent(marker).path)
                }
                let hasSettings = fileManager.fileExists(atPath: tempRestoreDir.appendingPathComponent("settings.plist").path)

                guard hasMarker && hasSettings else {
                    try? fileManager.removeItem(at: tempRestoreDir)
                    await MainActor.run {
                        isRestoring = false
                        UIAlertController.showAlertWithOk(
                            title: .localized("Invalid Backup"),
                            message: .localized("The received backup is invalid or corrupted. Please run Nearby Share again or try manuallly.")
                        )
                    }
                    return
                }

                // 2. Restore UserDefaults (Settings)
                let settingsURL = tempRestoreDir.appendingPathComponent("settings.plist")
                if fileManager.fileExists(atPath: settingsURL.path) {
                    if let data = try? Data(contentsOf: settingsURL),
                       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        if let bundleID = Bundle.main.bundleIdentifier {
                            if merge {
                                // Merge settings
                                var currentDict = UserDefaults.standard.persistentDomain(forName: bundleID) ?? [:]
                                currentDict.merge(dict) { _, new in new }
                                UserDefaults.standard.setPersistentDomain(currentDict, forName: bundleID)
                            } else {
                                // Replace settings
                                UserDefaults.standard.setPersistentDomain(dict, forName: bundleID)
                            }
                        }
                    }
                }

                // 3. Restore Database (Core Data)
                let dbSourceDir = tempRestoreDir.appendingPathComponent("database")
                if fileManager.fileExists(atPath: dbSourceDir.path) {
                    if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                        let baseName = storeURL.lastPathComponent
                        let dbDestDir = storeURL.deletingLastPathComponent()
                        for f in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                            let src = dbSourceDir.appendingPathComponent(f)
                            let dest = dbDestDir.appendingPathComponent(f)
                            if fileManager.fileExists(atPath: src.path) {
                                if !merge {
                                    try? fileManager.removeItem(at: dest)
                                }
                                try fileManager.copyItem(at: src, to: dest)
                            }
                        }
                    }
                }

                // 4. Restore Application Files
                let documentsURL = Storage.shared.documentsURL

                // 4a. Certificates
                let certsSourceDir = tempRestoreDir.appendingPathComponent("certificates")
                if fileManager.fileExists(atPath: certsSourceDir.path) {
                    let certsDestDir = fileManager.certificates
                    try? fileManager.createDirectory(at: certsDestDir, withIntermediateDirectories: true)

                    let contents = (try? fileManager.contentsOfDirectory(at: certsSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        if file.lastPathComponent.contains(".json") { continue }

                        let dest = certsDestDir.appendingPathComponent(file.lastPathComponent)
                        if !merge {
                            try? fileManager.removeItem(at: dest)
                        }
                        try fileManager.copyItem(at: file, to: dest)
                    }
                }

                // 4b. Signed Apps
                let signedSourceDir = tempRestoreDir.appendingPathComponent("signed_apps")
                if fileManager.fileExists(atPath: signedSourceDir.path) {
                    let signedDestDir = fileManager.signed
                    try? fileManager.createDirectory(at: signedDestDir, withIntermediateDirectories: true)

                    let contents = (try? fileManager.contentsOfDirectory(at: signedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for fileURL in contents {
                        let name = fileURL.lastPathComponent
                        if name.contains(".json") { continue }

                        var isDir: ObjCBool = false
                        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                            if isDir.boolValue {
                                let dest = signedDestDir.appendingPathComponent(name)
                                if !merge {
                                    try? fileManager.removeItem(at: dest)
                                }
                                try fileManager.copyItem(at: fileURL, to: dest)
                            } else if fileURL.pathExtension.lowercased() == "ipa" {
                                let uuid = name.replacingOccurrences(of: ".ipa", with: "")
                                let destFolder = signedDestDir.appendingPathComponent(uuid)
                                try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
                                let destFile = destFolder.appendingPathComponent("ipa")
                                if !merge {
                                    try? fileManager.removeItem(at: destFile)
                                }
                                try fileManager.copyItem(at: fileURL, to: destFile)
                            }
                        }
                    }
                }

                // 4c. Imported Apps
                let importedSourceDir = tempRestoreDir.appendingPathComponent("imported_apps")
                if fileManager.fileExists(atPath: importedSourceDir.path) {
                    let importedDestDir = fileManager.unsigned
                    try? fileManager.createDirectory(at: importedDestDir, withIntermediateDirectories: true)

                    let contents = (try? fileManager.contentsOfDirectory(at: importedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for fileURL in contents {
                        let name = fileURL.lastPathComponent
                        if name.contains(".json") { continue }

                        var isDir: ObjCBool = false
                        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                            if isDir.boolValue {
                                let dest = importedDestDir.appendingPathComponent(name)
                                if !merge {
                                    try? fileManager.removeItem(at: dest)
                                }
                                try fileManager.copyItem(at: fileURL, to: dest)
                            } else if fileURL.pathExtension.lowercased() == "ipa" {
                                let uuid = name.replacingOccurrences(of: ".ipa", with: "")
                                let destFolder = importedDestDir.appendingPathComponent(uuid)
                                try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
                                let destFile = destFolder.appendingPathComponent("ipa")
                                if !merge {
                                    try? fileManager.removeItem(at: destFile)
                                }
                                try fileManager.copyItem(at: fileURL, to: destFile)
                            }
                        }
                    }
                }

                // 4d. Default Frameworks
                let frameworksSourceDir = tempRestoreDir.appendingPathComponent("default_frameworks")
                if fileManager.fileExists(atPath: frameworksSourceDir.path) {
                    let frameworksDestDir = documentsURL.appendingPathComponent("DefaultFrameworks")
                    try? fileManager.createDirectory(at: frameworksDestDir, withIntermediateDirectories: true)

                    let contents = (try? fileManager.contentsOfDirectory(at: frameworksSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = frameworksDestDir.appendingPathComponent(file.lastPathComponent)
                        if !merge {
                            try? fileManager.removeItem(at: destFile)
                        }
                        try fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 4e. Archives
                let archivesSourceDir = tempRestoreDir.appendingPathComponent("archives")
                if fileManager.fileExists(atPath: archivesSourceDir.path) {
                    let archivesDestDir = fileManager.archives
                    try? fileManager.createDirectory(at: archivesDestDir, withIntermediateDirectories: true)

                    let contents = (try? fileManager.contentsOfDirectory(at: archivesSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = archivesDestDir.appendingPathComponent(file.lastPathComponent)
                        if !merge {
                            try? fileManager.removeItem(at: destFile)
                        }
                        try fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 4f. Root Documents Files
                let extraSourceDir = tempRestoreDir.appendingPathComponent("extra_files")
                if fileManager.fileExists(atPath: extraSourceDir.path) {
                    let contents = (try? fileManager.contentsOfDirectory(at: extraSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = documentsURL.appendingPathComponent(file.lastPathComponent)
                        if !merge {
                            try? fileManager.removeItem(at: destFile)
                        }
                        try fileManager.copyItem(at: file, to: destFile)
                    }
                }

                try? fileManager.removeItem(at: tempRestoreDir)
                UserDefaults.standard.removeObject(forKey: "pendingNearbyBackupRestore")

                await MainActor.run {
                    isRestoring = false
                    HapticsManager.shared.success()

                    // Restart app after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        UIApplication.shared.suspendAndReopen()
                    }
                }

            } catch {
                try? fileManager.removeItem(at: tempRestoreDir)
                await MainActor.run {
                    isRestoring = false
                    UIAlertController.showAlertWithOk(
                        title: .localized("Restore Error"),
                        message: .localized("Failed to restore backup: \(error.localizedDescription)")
                    )
                }
            }
        }
    }
}
