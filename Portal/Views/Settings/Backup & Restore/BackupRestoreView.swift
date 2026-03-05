import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData

// MARK: - Backup Options
struct BackupOptions {
    var includeCertificates: Bool = true
    var includeSignedApps: Bool = true
    var includeImportedApps: Bool = true
    var includeSources: Bool = true
    var includeDefaultFrameworks: Bool = true
    var includeArchives: Bool = true
    var usePassword: Bool = true
    var snapshotType: String = "full"
}

// MARK: - View
struct BackupRestoreView: View {
    @Environment(\.dismiss) var dismiss

    // UI State
    @State private var isImportIPAPresented = false
    @State private var isVerifyFilePickerPresented = false
    @State private var isBackupOptionsPresented = false
    @State private var showExporter = false
    @State private var showInvalidBackupError = false

    // Logic State
    @State private var backupOptions = BackupOptions()
    @State private var backupDocument: BackupDocument?
    @State private var isVerifying = false
    @State private var isRestoring = false
    @State private var isPreparingBackup = false
    @State private var isShowingPairingStatus = false
    @State private var showSecureTransfer = false

    @AppStorage("feature_advancedBackupTools") var advancedBackupTools = false
    @AppStorage("feature_newBackupOptions") var newBackupOptions = false
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @ObservedObject private var advancedManager = BackupAdvancedManager.shared

    // MARK: Body
    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    BackupRestoreHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if newBackupOptions {
                _healthStatusSection
            }
            _nearbyTransferSection
            _advancedToolsSection
        }
        .navigationTitle(.localized("Backup & Restore"))
        .sheet(isPresented: $isBackupOptionsPresented) {
            BackupOptionsView(
                options: $backupOptions,
                isPreparing: isPreparingBackup,
                onConfirm: {
                    handleCreateBackup()
                }
            )
        }
        .sheet(isPresented: $isImportIPAPresented) {
            FileImporterRepresentableView(
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false,
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    handleRestoreBackup(at: url)
                }
            )
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $isVerifyFilePickerPresented,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleVerifyBackup(at: url)
                }
            case .failure(let error):
                AppLogManager.shared.error("Failed to pick backup file for verification: \(error.localizedDescription)", category: "Backup & Restore", errorCode: .BACKUP_FAILED)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .zip,
            defaultFilename: "PortalBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
        ) { result in
            switch result {
            case .success(let url):
                AppLogManager.shared.success("Backup exported successfully to: \(url.path)", category: "Backup & Restore")
                HapticsManager.shared.success()
            case .failure(let error):
                AppLogManager.shared.error("Failed to export backup: \(error.localizedDescription)", category: "Backup & Restore", errorCode: .BACKUP_FAILED)
                HapticsManager.shared.error()
            }
            // Clean up the temporary zip file after export attempt
            if let tempURL = backupDocument?.url {
                try? FileManager.default.removeItem(at: tempURL)
            }
            backupDocument = nil
        }
        .alert(.localized("Invalid Backup File"), isPresented: $showInvalidBackupError) {
            Button(.localized("OK"), role: .cancel) { }
        } message: {
            Text(.localized("Not a valid Backup file because Portal couldn't find the internal checker inside this uploaded file. Please upload an actual .zip file of a backup."))
        }
        .sheet(isPresented: $isShowingPairingStatus) {
            NavigationStack {
                SecureSessionStatusView {
                    showSecureTransfer = true
                }
                .navigationDestination(isPresented: $showSecureTransfer) {
                    TransferSetupView()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .overlay { _statusOverlays }
        .onAppear {
            if newBackupOptions {
                advancedManager.loadAndRefresh()
            }
        }
    }

    @ViewBuilder
    private var _healthStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("Backup Health"))
                            .font(.headline)
                        Text(advancedManager.chainIntegrityStatus == "Intact" ? .localized("All snapshots are consistent") : .localized("Broken snapshot chain detected"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(advancedManager.healthScore > 80 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: CGFloat(advancedManager.healthScore) / 100.0)
                            .stroke(advancedManager.healthScore > 80 ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        Text("\(advancedManager.healthScore)")
                            .font(.system(size: 12, weight: .bold))
                    }
                }

                Divider()

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text(.localized("Last Backup"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let last = advancedManager.lastBackupTime {
                            Text(last, style: .date)
                                .font(.caption.bold())
                        } else {
                            Text(.localized("Never"))
                                .font(.caption.bold())
                        }
                    }

                    VStack(alignment: .leading) {
                        Text(.localized("Expiring Certs"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(advancedManager.expiringCertsCount)")
                            .font(.caption.bold())
                            .foregroundStyle(advancedManager.expiringCertsCount > 0 ? .orange : .primary)
                    }

                    VStack(alignment: .leading) {
                        Text(.localized("Integrity"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(advancedManager.chainIntegrityStatus)
                            .font(.caption.bold())
                            .foregroundStyle(advancedManager.chainIntegrityStatus == "Intact" ? .green : .red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var _nearbyTransferSection: some View {
        Section {
            NavigationLink(destination: TransferSetupView()) {
                Label(.localized("Secure Transfer"), systemImage: "network.badge.shield.half.filled")
                    .foregroundStyle(.purple)
            }

            NavigationLink(destination: SelfBackupRestoreView()) {
                Label(.localized("Self Backup"), systemImage: "externaldrive.fill")
                    .foregroundStyle(.green)
            }
        } header: {
            Text(.localized("Nearby Transfer"))
        }
    }

    @ViewBuilder
    private var _advancedToolsSection: some View {
        if advancedBackupTools {
            Section {
                Button {
                    handleExportFullDatabase()
                } label: {
                    Label(.localized("Export Full Database"), systemImage: "cylinder.split.1x2.fill")
                }

                Button {
                    isVerifyFilePickerPresented = true
                } label: {
                    Label(.localized("Verify Backup Integrity"), systemImage: "shield.checkerboard")
                }

                Button {
                    handleClearCaches()
                } label: {
                    Label(.localized("Clear All Caches"), systemImage: "trash.fill")
                }

                Button {
                    handleResetSettings()
                } label: {
                    Label(.localized("Reset All Settings"), systemImage: "arrow.counterclockwise.circle.fill")
                }

                Button {
                    handleExportLogs()
                } label: {
                    Label(.localized("Export Application Logs"), systemImage: "doc.text.fill")
                }

                Button {
                    handleRebuildIconCache()
                } label: {
                    Label(.localized("Rebuild Icon Cache"), systemImage: "sparkles")
                }

                Button {
                    handleViewPairingStatus()
                } label: {
                    Label(.localized("View Secure Session Status"), systemImage: "link.circle.fill")
                }
            } header: {
                Text(.localized("Advanced Tools"))
            }
        }
    }

    @ViewBuilder
    private var _statusOverlays: some View {
        if isVerifying {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Verifying...")
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(Color.clear)
                .cornerRadius(16)
            }
        }

        if isRestoring {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Restoring...")
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(Color.clear)
                .cornerRadius(16)
            }
        }

        if isPreparingBackup {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Preparing Backup...")
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(Color.clear)
                .cornerRadius(16)
            }
        }
    }

    private func handleRestoreBackup(at url: URL) {
        isRestoring = true
        Task {
            let tempRestoreDir = FileManager.default.temporaryDirectory.appendingPathComponent("Restore_\(UUID().uuidString)")

            do {
                try FileManager.default.createDirectory(at: tempRestoreDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: url, to: tempRestoreDir)

                // 1. Validate Backup
                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in
                    FileManager.default.fileExists(atPath: tempRestoreDir.appendingPathComponent(marker).path)
                }
                let hasSettings = FileManager.default.fileExists(atPath: tempRestoreDir.appendingPathComponent("settings.plist").path)

                guard hasMarker && hasSettings else {
                    try? FileManager.default.removeItem(at: tempRestoreDir)
                    await MainActor.run {
                        isRestoring = false
                        showInvalidBackupError = true
                    }
                    return
                }

                // 2. Restore UserDefaults (App Group)
                let settingsURL = tempRestoreDir.appendingPathComponent("settings.plist")
                if FileManager.default.fileExists(atPath: settingsURL.path) {
                    if let data = try? Data(contentsOf: settingsURL),
                       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        if let userDefaults = UserDefaults(suiteName: Storage.appGroupID) {
                            for (key, value) in dict {
                                userDefaults.set(value, forKey: key)
                            }
                            userDefaults.synchronize()
                        }
                    }
                }

                // 2a. Restore UserDefaults (Standard)
                let standardURL = tempRestoreDir.appendingPathComponent("standard_settings.plist")
                if FileManager.default.fileExists(atPath: standardURL.path) {
                    if let data = try? Data(contentsOf: standardURL),
                       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        let standardDefaults = UserDefaults.standard
                        for (key, value) in dict {
                            standardDefaults.set(value, forKey: key)
                        }
                        standardDefaults.synchronize()
                    }
                }

                // 3. Restore Database (Core Data)
                let dbSourceDir = tempRestoreDir.appendingPathComponent("database")
                if FileManager.default.fileExists(atPath: dbSourceDir.path) {
                    if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                        let baseName = storeURL.lastPathComponent
                        let dbDestDir = storeURL.deletingLastPathComponent()
                        for f in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                            let src = dbSourceDir.appendingPathComponent(f)
                            let dest = dbDestDir.appendingPathComponent(f)
                            if FileManager.default.fileExists(atPath: src.path) {
                                try? FileManager.default.removeItem(at: dest)
                                try FileManager.default.copyItem(at: src, to: dest)
                            }
                        }
                    }
                }

                // 4. Restore Application Files
                let documentsURL = Storage.shared.documentsURL

                // 4a. Certificates
                let certsSourceDir = tempRestoreDir.appendingPathComponent("certificates")
                if FileManager.default.fileExists(atPath: certsSourceDir.path) {
                    let certsDestDir = FileManager.default.certificates
                    try? FileManager.default.createDirectory(at: certsDestDir, withIntermediateDirectories: true)

                    let contents = (try? FileManager.default.contentsOfDirectory(at: certsSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        // Skip any hidden files or metadata
                        if file.lastPathComponent.contains(".json") { continue }

                        let dest = certsDestDir.appendingPathComponent(file.lastPathComponent)
                        try? FileManager.default.removeItem(at: dest)
                        try FileManager.default.copyItem(at: file, to: dest)
                    }
                }

                // 4b. Signed Apps - Handle both old (IPA-only) and new (Directory) formats
                let signedSourceDir = tempRestoreDir.appendingPathComponent("signed_apps")
                if FileManager.default.fileExists(atPath: signedSourceDir.path) {
                    let signedDestDir = FileManager.default.signed
                    try? FileManager.default.createDirectory(at: signedDestDir, withIntermediateDirectories: true)

                    let contents = (try? FileManager.default.contentsOfDirectory(at: signedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for fileURL in contents {
                        let name = fileURL.lastPathComponent
                        if name.contains(".json") { continue }

                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                            if isDir.boolValue {
                                // New format: Full directory
                                let dest = signedDestDir.appendingPathComponent(name)
                                try? FileManager.default.removeItem(at: dest)
                                try FileManager.default.copyItem(at: fileURL, to: dest)
                            } else if fileURL.pathExtension.lowercased() == "ipa" {
                                // Old format: Single IPA file
                                let uuid = name.replacingOccurrences(of: ".ipa", with: "")
                                let destFolder = signedDestDir.appendingPathComponent(uuid)
                                try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
                                let destFile = destFolder.appendingPathComponent("ipa")
                                try? FileManager.default.removeItem(at: destFile)
                                try FileManager.default.copyItem(at: fileURL, to: destFile)
                            }
                        }
                    }
                }

                // 4c. Imported (Unsigned) Apps - Handle both old (IPA-only) and new (Directory) formats
                let importedSourceDir = tempRestoreDir.appendingPathComponent("imported_apps")
                if FileManager.default.fileExists(atPath: importedSourceDir.path) {
                    let importedDestDir = FileManager.default.unsigned
                    try? FileManager.default.createDirectory(at: importedDestDir, withIntermediateDirectories: true)

                    let contents = (try? FileManager.default.contentsOfDirectory(at: importedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for fileURL in contents {
                        let name = fileURL.lastPathComponent
                        if name.contains(".json") { continue }

                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                            if isDir.boolValue {
                                // New format: Full directory
                                let dest = importedDestDir.appendingPathComponent(name)
                                try? FileManager.default.removeItem(at: dest)
                                try FileManager.default.copyItem(at: fileURL, to: dest)
                            } else if fileURL.pathExtension.lowercased() == "ipa" {
                                // Old format: Single IPA file
                                let uuid = name.replacingOccurrences(of: ".ipa", with: "")
                                let destFolder = importedDestDir.appendingPathComponent(uuid)
                                try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
                                let destFile = destFolder.appendingPathComponent("ipa")
                                try? FileManager.default.removeItem(at: destFile)
                                try FileManager.default.copyItem(at: fileURL, to: destFile)
                            }
                        }
                    }
                }

                // 4d. Default Frameworks
                let frameworksSourceDir = tempRestoreDir.appendingPathComponent("default_frameworks")
                if FileManager.default.fileExists(atPath: frameworksSourceDir.path) {
                    let frameworksDestDir = documentsURL.appendingPathComponent("DefaultFrameworks") // Simplified path
                    try? FileManager.default.createDirectory(at: frameworksDestDir, withIntermediateDirectories: true)

                    let contents = (try? FileManager.default.contentsOfDirectory(at: frameworksSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = frameworksDestDir.appendingPathComponent(file.lastPathComponent)
                        try? FileManager.default.removeItem(at: destFile)
                        try FileManager.default.copyItem(at: file, to: destFile)
                    }
                }

                // 4e. Archives
                let archivesSourceDir = tempRestoreDir.appendingPathComponent("archives")
                if FileManager.default.fileExists(atPath: archivesSourceDir.path) {
                    let archivesDestDir = FileManager.default.archives
                    try? FileManager.default.createDirectory(at: archivesDestDir, withIntermediateDirectories: true)

                    let contents = (try? FileManager.default.contentsOfDirectory(at: archivesSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = archivesDestDir.appendingPathComponent(file.lastPathComponent)
                        try? FileManager.default.removeItem(at: destFile)
                        try FileManager.default.copyItem(at: file, to: destFile)
                    }
                }

                // 4f. Root Documents Files (Pairing, SSL certs)
                let extraSourceDir = tempRestoreDir.appendingPathComponent("extra_files")
                if FileManager.default.fileExists(atPath: extraSourceDir.path) {
                    let contents = (try? FileManager.default.contentsOfDirectory(at: extraSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = documentsURL.appendingPathComponent(file.lastPathComponent)
                        try? FileManager.default.removeItem(at: destFile)
                        try FileManager.default.copyItem(at: file, to: destFile)
                    }
                }

                try? FileManager.default.removeItem(at: tempRestoreDir)

                await MainActor.run {
                    isRestoring = false
                    HapticsManager.shared.success()

                    // Restart app after a brief delay to apply all changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        UIApplication.shared.suspendAndReopen()
                    }
                }

            } catch {
                try? FileManager.default.removeItem(at: tempRestoreDir)
                await MainActor.run {
                    isRestoring = false
                    UIAlertController.showAlertWithOk(title: .localized("Restore Error"), message: .localized("Failed to restore backup: \(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - Info Card View
    @ViewBuilder
    private func infoCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 4)
    }

    // MARK: - Advanced Tools Functions
    private func handleVerifyBackup(at url: URL) {
        isVerifying = true
        Task {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: url, to: tempDir)

                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in
                    FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(marker).path)
                }
                let hasSettings = FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("settings.plist").path)

                try? FileManager.default.removeItem(at: tempDir)

                await MainActor.run {
                    isVerifying = false
                    if hasMarker && hasSettings {
                        UIAlertController.showAlertWithOk(title: .localized("Verification Successful"), message: .localized("This backup file is valid and can be restored."))
                    } else {
                        showInvalidBackupError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to verify backup: \(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - Advanced Tools Functions
    private func handleClearCaches() {
        let tempDir = NSTemporaryDirectory()
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path

        var count = 0

        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(atPath: tempDir)
            for file in tempFiles {
                try? FileManager.default.removeItem(atPath: (tempDir as NSString).appendingPathComponent(file))
                count += 1
            }

            if let cacheDir = cacheDir {
                let cacheFiles = try FileManager.default.contentsOfDirectory(atPath: cacheDir)
                for file in cacheFiles {
                    try? FileManager.default.removeItem(atPath: (cacheDir as NSString).appendingPathComponent(file))
                    count += 1
                }
            }

            AppLogManager.shared.success("Cleared \(count) Cache Items", category: "Advanced Tools")
            UIAlertController.showAlertWithOk(title: "Caches Cleared", message: "Successfully removed \(count) temporary files and cached items.")
        } catch {
            AppLogManager.shared.error("Failed to clear caches: \(error.localizedDescription)", category: "Advanced Tools", errorCode: .FILE_OP_FAILED)
        }
    }

    private func handleResetSettings() {
        let alert = UIAlertController(title: "Reset All Settings", message: "Are you sure you want to reset all app settings? This will clear all preferences and restart the app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.suspendAndReopen()
            }
        })
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }

    private func handleExportLogs() {
        let logs = AppLogManager.shared.exportLogs()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Feather_Logs_\(Date().timeIntervalSince1970).txt")
        do {
            try logs.write(to: tempURL, atomically: true, encoding: .utf8)
            UIActivityViewController.show(activityItems: [tempURL])
        } catch {
            AppLogManager.shared.error("Failed to export logs: \(error.localizedDescription)", category: "Advanced Tools", errorCode: .BACKUP_FAILED)
        }
    }

    private func handleRebuildIconCache() {
        isPreparingBackup = true
        Task {
            // Logic to clear icon cache using correct directory URLs
            let signedDir = FileManager.default.signed
            let importedDir = FileManager.default.unsigned

            for dir in [signedDir, importedDir] {
                if let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        let name = fileURL.lastPathComponent
                        if name == "icon.png" || name.contains("tinted_icon") || name.contains("AppIcon") {
                            try? FileManager.default.removeItem(at: fileURL)
                        }
                    }
                }
            }

            await MainActor.run {
                isPreparingBackup = false
                UIAlertController.showAlertWithOk(title: .localized("Icon Cache Rebuilt"), message: .localized("Icons will be regenerated on next view."))
                HapticsManager.shared.success()
            }
        }
    }

    private func handleViewPairingStatus() {
        isShowingPairingStatus = true
    }

    private func handleExportFullDatabase() {
        guard let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url else {
            UIAlertController.showAlertWithOk(title: "Error", message: "Could not find database location")
            return
        }

        isPreparingBackup = true
        Task {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalDatabaseBackup_\(Date().timeIntervalSince1970).zip")

            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                let baseName = storeURL.lastPathComponent
                let directory = storeURL.deletingLastPathComponent()
                for fileName in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                    let fileURL = directory.appendingPathComponent(fileName)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.copyItem(at: fileURL, to: tempDir.appendingPathComponent(fileName))
                    }
                }

                try FileManager.default.zipItem(at: tempDir, to: zipURL, shouldKeepParent: false)
                try? FileManager.default.removeItem(at: tempDir)

                await MainActor.run {
                    isPreparingBackup = false
                    backupDocument = BackupDocument(url: zipURL)
                    showExporter = true
                }
            } catch {
                await MainActor.run {
                    isPreparingBackup = false
                    UIAlertController.showAlertWithOk(title: "Error", message: "Failed to export database: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Backup Functions
    private func handleCreateBackup() {
        isPreparingBackup = true
        Task {
            if let url = await prepareBackup(with: backupOptions) {
                await MainActor.run {
                    isPreparingBackup = false
                    backupDocument = BackupDocument(url: url)
                    showExporter = true
                    isBackupOptionsPresented = false
                }
            } else {
                await MainActor.run {
                    isPreparingBackup = false
                    isBackupOptionsPresented = false
                }
            }
        }
    }

    private func prepareBackup(with options: BackupOptions) async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("Backup_\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // 1. Certificates
            if options.includeCertificates {
                let certificatesDir = tempDir.appendingPathComponent("certificates")
                try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)

                let src = FileManager.default.certificates
                if FileManager.default.fileExists(atPath: src.path) {
                    for file in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.copyItem(at: file, to: certificatesDir.appendingPathComponent(file.lastPathComponent))
                    }
                }

                // Also include metadata for easier restoration/viewing
                let certificates = Storage.shared.getAllCertificates()
                var certMetadata: [[String: Any]] = []
                for cert in certificates {
                    guard let uuid = cert.uuid else { continue }
                    var metadata: [String: Any] = ["uuid": uuid]
                    if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
                        metadata["name"] = provisionData.Name
                        if let teamID = provisionData.TeamIdentifier.first { metadata["teamID"] = teamID }
                        metadata["teamName"] = provisionData.TeamName
                    }
                    if let date = cert.date { metadata["date"] = date.timeIntervalSince1970 }
                    metadata["ppQCheck"] = cert.ppQCheck
                    if let password = cert.password { metadata["password"] = password }
                    certMetadata.append(metadata)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: certMetadata)
                try jsonData.write(to: tempDir.appendingPathComponent("certificates_metadata.json"))
            }

            // 2. Sources
            if options.includeSources {
                let sources = Storage.shared.getSources()
                let sourcesData = sources.compactMap { source -> [String: String]? in
                    guard let urlString = source.sourceURL?.absoluteString,
                          let name = source.name,
                          let identifier = source.identifier else { return nil }
                    return ["url": urlString, "name": name, "identifier": identifier]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: sourcesData)
                try jsonData.write(to: tempDir.appendingPathComponent("sources.json"))
            }

            // 3. Signed Apps
            if options.includeSignedApps {
                let signedAppsDir = tempDir.appendingPathComponent("signed_apps")
                try? FileManager.default.createDirectory(at: signedAppsDir, withIntermediateDirectories: true)

                let src = FileManager.default.signed
                if FileManager.default.fileExists(atPath: src.path) {
                    let folders = (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? []
                    for folder in folders {
                        try? FileManager.default.copyItem(at: folder, to: signedAppsDir.appendingPathComponent(folder.lastPathComponent))
                    }
                }

                // Metadata for easier identification
                let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
                let appsData = signedApps.compactMap { app -> [String: String]? in
                    guard let uuid = app.uuid else { return nil }
                    return ["uuid": uuid, "name": app.name ?? "", "identifier": app.identifier ?? "", "version": app.version ?? ""]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("signed_apps_metadata.json"))
            }

            // 4. Imported (Unsigned) Apps
            if options.includeImportedApps {
                let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
                try? FileManager.default.createDirectory(at: importedAppsDir, withIntermediateDirectories: true)

                let src = FileManager.default.unsigned
                if FileManager.default.fileExists(atPath: src.path) {
                    let folders = (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? []
                    for folder in folders {
                        try? FileManager.default.copyItem(at: folder, to: importedAppsDir.appendingPathComponent(folder.lastPathComponent))
                    }
                }

                // Metadata for easier identification
                let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
                let appsData = importedApps.compactMap { app -> [String: String]? in
                    guard let uuid = app.uuid else { return nil }
                    return ["uuid": uuid, "name": app.name ?? "", "identifier": app.identifier ?? "", "version": app.version ?? ""]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("imported_apps_metadata.json"))
            }

            // 5. Default Frameworks
            if options.includeDefaultFrameworks {
                let dest = tempDir.appendingPathComponent("default_frameworks")
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)

                let src = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
                if FileManager.default.fileExists(atPath: src.path) {
                    for file in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }

            // 6. Archives
            if options.includeArchives {
                let dest = tempDir.appendingPathComponent("archives")
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let src = FileManager.default.archives
                if FileManager.default.fileExists(atPath: src.path) {
                    for file in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }

            // 7. Extra Files (Always) - Copy all plists, certs, and logs from root
            let extraDir = tempDir.appendingPathComponent("extra_files")
            try? FileManager.default.createDirectory(at: extraDir, withIntermediateDirectories: true)
            let rootFiles = (try? FileManager.default.contentsOfDirectory(at: Storage.shared.documentsURL, includingPropertiesForKeys: nil)) ?? []
            for fileURL in rootFiles {
                let ext = fileURL.pathExtension.lowercased()
                let name = fileURL.lastPathComponent
                let importantExtensions = ["plist", "pem", "crt", "txt", "json", "log"]
                let importantNames = ["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"]

                if importantExtensions.contains(ext) || importantNames.contains(name) {
                    // Skip database files here as they are handled in step 8
                    if ext == "sqlite" || name.contains("-shm") || name.contains("-wal") { continue }
                    try? FileManager.default.copyItem(at: fileURL, to: extraDir.appendingPathComponent(name))
                }
            }

            // 8. Database (Always)
            let dbDir = tempDir.appendingPathComponent("database")
            try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
            if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                let dir = storeURL.deletingLastPathComponent()
                for f in [storeURL.lastPathComponent, "\(storeURL.lastPathComponent)-shm", "\(storeURL.lastPathComponent)-wal"] {
                    let url = dir.appendingPathComponent(f)
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.copyItem(at: url, to: dbDir.appendingPathComponent(f))
                    }
                }
            }

            // 9. Settings (Standard)
            let defaults = UserDefaults.standard.dictionaryRepresentation()
            let filtered = defaults.filter { k, _ in
                !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") &&
                !k.hasPrefix("WebKit") && !k.hasPrefix("CPU") && !k.hasPrefix("metal")
            }
            let data = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
            try data.write(to: tempDir.appendingPathComponent("standard_settings.plist"))

            // 9a. Settings (App Group)
            if let userDefaults = UserDefaults(suiteName: Storage.appGroupID) {
                let settingsDict = userDefaults.dictionaryRepresentation()
                let filteredSettings = settingsDict.filter { key, _ in
                    !key.hasPrefix("NS") && !key.hasPrefix("Apple") && !key.hasPrefix("AK") && !key.hasPrefix("WebKit") && !key.hasPrefix("CPU") && !key.hasPrefix("metal")
                }
                let settingsPlist = try PropertyListSerialization.data(fromPropertyList: filteredSettings, format: .xml, options: 0)
                try settingsPlist.write(to: tempDir.appendingPathComponent("settings.plist"))
            }

            // 10. Zip
            let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalBackup_\(UUID().uuidString).zip")
            try "PORTAL_BACKUP_v1.0_\(Date().timeIntervalSince1970)".write(to: tempDir.appendingPathComponent("PORTAL_BACKUP_MARKER.txt"), atomically: true, encoding: .utf8)
            try FileManager.default.zipItem(at: tempDir, to: finalURL, shouldKeepParent: false)
            try? FileManager.default.removeItem(at: tempDir)
            return finalURL
        } catch {
            await MainActor.run { UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to prepare backup: \(error.localizedDescription)")) }
            return nil
        }
    }

}

// MARK: - BackupDocument
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { throw CocoaError(.fileReadUnknown) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { return try FileWrapper(url: url) }
}

// MARK: - BackupOptionsView
struct BackupOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var options: BackupOptions
    var isPreparing: Bool = false
    let onConfirm: () -> Void
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $options.includeCertificates) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Certificates"))
                                Text(.localized("Signing certificates and profiles")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue) }
                    }

                    Toggle(isOn: $options.includeSignedApps) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Signed Apps"))
                                Text(.localized("Apps signed with your certificates")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "app.badge.fill").foregroundStyle(.green) }
                    }

                    Toggle(isOn: $options.includeImportedApps) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Imported Apps"))
                                Text(.localized("Unsigned apps imported from files")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "square.and.arrow.down.fill").foregroundStyle(.orange) }
                    }

                    Toggle(isOn: $options.includeSources) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Sources"))
                                Text(.localized("Configured app repositories")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "globe.fill").foregroundStyle(.purple) }
                    }

                    Toggle(isOn: $options.includeDefaultFrameworks) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Default Frameworks"))
                                Text(.localized("Automatically injected dylibs")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "puzzlepiece.extension.fill").foregroundStyle(.cyan) }
                    }

                    Toggle(isOn: $options.includeArchives) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(.localized("Archives"))
                                Text(.localized("Saved app archives")).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "archivebox.fill").foregroundStyle(.indigo) }
                    }

                    if UserDefaults.standard.bool(forKey: "feature_newBackupOptions") {
                        Picker(.localized("Snapshot Type"), selection: $options.snapshotType) {
                            Text(.localized("Full")).tag("full")
                            Text(.localized("Incremental")).tag("incremental")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                    }

                } header: {
                    Text(.localized("Backup Content"))
                }

                if options.includeSignedApps || options.includeImportedApps {
                    Section {
                        Label {
                            Text(.localized("If you include Signed and Imported Apps, this backup will be large."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }

                Section {
                    Button { onConfirm() } label: {
                        HStack {
                            if isPreparing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(isPreparing ? .localized("Preparing...") : .localized("Create Portal Backup"))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isPreparing ? Color.gray : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isPreparing)
                }
            }
            .navigationTitle(.localized("Backup Options"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
            }
        }
    }
}
