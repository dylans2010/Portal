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
            NBList(.localized("Restore Backup")) {
                Section {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                                .ifAvailableiOS17SymbolPulse()
                        }

                        VStack(spacing: 8) {
                            Text("Backup Received")
                                .font(.system(.title3, design: .rounded, weight: .bold))

                            Text("Your data has been securely transferred. Select a restoration method to proceed.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } header: {
                    AppearanceSectionHeader(title: String.localized("Success"), icon: "checkmark.circle.fill")
                }

                Section {
                    restoreMethodCard(
                        title: "Merge With Existing",
                        subtitle: "Combine backup data with your current apps and settings. Perfect for incremental updates.",
                        icon: "arrow.triangle.merge",
                        color: .blue,
                        merge: true
                    )

                    restoreMethodCard(
                        title: "Clean Restore",
                        subtitle: "Erase all current data and replace it with the backup content. Useful for a fresh start.",
                        icon: "trash.fill",
                        color: .orange,
                        merge: false
                    )
                } header: {
                    AppearanceSectionHeader(title: String.localized("Choose Method"), icon: "arrow.down.doc.fill")
                } footer: {
                    Text("Warning: Clean Restore will permanently delete your current Portal database and files.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Restore Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        cleanupAndDismiss()
                    }
                }
            }
            .overlay {
                if isRestoring {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Restoring Data...")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(30)
                        .background(Color.clear)
                        .cornerRadius(24)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private func restoreMethodCard(title: String, subtitle: String, icon: String, color: Color, merge: Bool) -> some View {
        Button {
            handleRestore(merge: merge)
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func cleanupAndDismiss() {
        if let path = UserDefaults.standard.string(forKey: "pendingNearbyBackupRestore") {
            try? FileManager.default.removeItem(atPath: path)
            UserDefaults.standard.removeObject(forKey: "pendingNearbyBackupRestore")
        }
        dismiss()
    }

    private func handleRestore(merge: Bool) {
        guard let path = UserDefaults.standard.string(forKey: "pendingNearbyBackupRestore") else { return }
        let tempRestoreDir = URL(fileURLWithPath: path)
        selectedMergeMode = merge
        dismiss()
        if let callback = onConflictResolution {
            callback(tempRestoreDir)
        } else {
            performRestore(tempRestoreDir: tempRestoreDir, merge: merge)
        }
    }

    private func performRestore(tempRestoreDir: URL, merge: Bool) {
        isRestoring = true
        Task {
            let fileManager = FileManager.default
            do {
                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in fileManager.fileExists(atPath: tempRestoreDir.appendingPathComponent(marker).path) }
                let hasSettings = fileManager.fileExists(atPath: tempRestoreDir.appendingPathComponent("settings.plist").path)

                guard hasMarker && hasSettings else {
                    try? fileManager.removeItem(at: tempRestoreDir)
                    await MainActor.run {
                        isRestoring = false
                        UIAlertController.showAlertWithOk(title: .localized("Invalid Backup"), message: .localized("The backup data is corrupted."))
                    }
                    return
                }

                // Restore UserDefaults (Settings)
                let settingsURL = tempRestoreDir.appendingPathComponent("settings.plist")
                if fileManager.fileExists(atPath: settingsURL.path), let data = try? Data(contentsOf: settingsURL),
                   let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                   let bundleID = Bundle.main.bundleIdentifier {
                    if merge {
                        var currentDict = UserDefaults.standard.persistentDomain(forName: bundleID) ?? [:]
                        currentDict.merge(dict) { _, new in new }
                        UserDefaults.standard.setPersistentDomain(currentDict, forName: bundleID)
                    } else {
                        UserDefaults.standard.setPersistentDomain(dict, forName: bundleID)
                    }
                }

                // Restore Database (Core Data)
                if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                    let dbSourceDir = tempRestoreDir.appendingPathComponent("database")
                    let baseName = storeURL.lastPathComponent
                    let dbDestDir = storeURL.deletingLastPathComponent()
                    for f in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                        let src = dbSourceDir.appendingPathComponent(f)
                        let dest = dbDestDir.appendingPathComponent(f)
                        if fileManager.fileExists(atPath: src.path) {
                            if !merge { try? fileManager.removeItem(at: dest) }
                            try fileManager.copyItem(at: src, to: dest)
                        }
                    }
                }

                // Restore Application Files
                let documentsURL = Storage.shared.documentsURL
                let mappings = [
                    ("certificates", fileManager.certificates),
                    ("signed_apps", fileManager.signed),
                    ("imported_apps", fileManager.unsigned),
                    ("default_frameworks", documentsURL.appendingPathComponent("DefaultFrameworks")),
                    ("archives", fileManager.archives),
                    ("extra_files", documentsURL)
                ]

                for (srcName, destURL) in mappings {
                    let srcURL = tempRestoreDir.appendingPathComponent(srcName)
                    if fileManager.fileExists(atPath: srcURL.path) {
                        try? fileManager.createDirectory(at: destURL, withIntermediateDirectories: true)
                        let contents = (try? fileManager.contentsOfDirectory(at: srcURL, includingPropertiesForKeys: nil)) ?? []
                        for item in contents {
                            let dest = destURL.appendingPathComponent(item.lastPathComponent)
                            if !merge { try? fileManager.removeItem(at: dest) }
                            try? fileManager.copyItem(at: item, to: dest)
                        }
                    }
                }

                try? fileManager.removeItem(at: tempRestoreDir)
                UserDefaults.standard.removeObject(forKey: "pendingNearbyBackupRestore")

                await MainActor.run {
                    isRestoring = false
                    HapticsManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        UIApplication.shared.suspendAndReopen()
                    }
                }
            } catch {
                try? fileManager.removeItem(at: tempRestoreDir)
                await MainActor.run {
                    isRestoring = false
                    UIAlertController.showAlertWithOk(title: .localized("Restore Error"), message: error.localizedDescription)
                }
            }
        }
    }
}
