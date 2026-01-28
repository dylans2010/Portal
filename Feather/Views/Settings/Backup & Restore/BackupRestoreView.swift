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
}

// MARK: - View
struct BackupRestoreView: View {
    @Environment(\.dismiss) var dismiss

    // UI State
    @State private var isRestoreFilePickerPresented = false
    @State private var isVerifyFilePickerPresented = false
    @State private var isBackupOptionsPresented = false
    @State private var showExporter = false
    @State private var showRestoreDialog = false
    @State private var showInvalidBackupError = false

    // Logic State
    @State private var backupOptions = BackupOptions()
    @State private var backupDocument: BackupDocument?
    @State private var pendingRestoreURL: URL?
    @State private var isRestoring = false
    @State private var isVerifying = false
    @State private var isPreparingBackup = false
    @State private var restoreProgress: Double = 0.0

    @AppStorage("feature_advancedBackupTools") var advancedBackupTools = false

    // MARK: Body
    var body: some View {
        NBList(.localized("Backup & Restore")) {
            // Main View Header
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)

                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text(.localized("Backup & Restore"))
                            .font(.title2.bold())
                        Text(.localized("Keep your data safe by creating backups or restoring from a previous one."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Modernized Header Card
            Section {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Backup Card
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 72, height: 72)

                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 6) {
                                Text(.localized("Backup"))
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                Text(.localized("Save your data"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                isBackupOptionsPresented = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(.localized("Create"))
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )
                        )

                        // Restore Card
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 72, height: 72)

                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 6) {
                                Text(.localized("Restore"))
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                Text(.localized("Load a backup"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                isRestoreFilePickerPresented = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(.localized("Import"))
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .listRowBackground(Color.clear)

            // Advanced Tools Section
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
                } header: {
                    AppearanceSectionHeader(title: String.localized("Advanced Tools"), icon: "wrench.and.screwdriver.fill")
                }
            }

            // Information sections with modern cards
            Section {
                infoCard(
                    icon: "checkmark.shield.fill",
                    iconColor: .blue,
                    title: .localized("What's Included"),
                    description: .localized("Backups can include certificates, provisioning profiles, signed apps, imported apps, sources, and all app settings.")
                )

                infoCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: .localized("Important"),
                    description: .localized("Restoring requires the app to restart. Certificate restoration preserves files for manual re-import if needed.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("About Backups (Beta)"), icon: "info.circle.fill")
            }
        }
        .sheet(isPresented: $isBackupOptionsPresented) {
            BackupOptionsView(
                options: $backupOptions,
                onConfirm: {
                    isBackupOptionsPresented = false
                    handleCreateBackup()
                }
            )
        }
        .fileImporter(
            isPresented: $isRestoreFilePickerPresented,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let url):
                pendingRestoreURL = url
                showRestoreDialog = true
            case .failure(let error):
                AppLogManager.shared.error("Failed to pick backup file: \(error.localizedDescription)", category: "Backup & Restore")
            }
        }
        .fileImporter(
            isPresented: $isVerifyFilePickerPresented,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let url):
                handleVerifyBackup(at: url)
            case .failure(let error):
                AppLogManager.shared.error("Failed to pick backup file for verification: \(error.localizedDescription)", category: "Backup & Restore")
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
                AppLogManager.shared.error("Failed to export backup: \(error.localizedDescription)", category: "Backup & Restore")
                HapticsManager.shared.error()
            }
            // Clean up the temporary zip file after export attempt
            if let tempURL = backupDocument?.url {
                try? FileManager.default.removeItem(at: tempURL)
            }
            backupDocument = nil
        }
        .alert(.localized("Restart Required"), isPresented: $showRestoreDialog) {
            Button(.localized("No"), role: .cancel) {
                if let url = pendingRestoreURL {
                    // Mark for deferred restore
                    UserDefaults.standard.set(url.path, forKey: "pendingRestorePath")
                    pendingRestoreURL = nil
                }
            }
            Button(.localized("Yes")) {
                if let url = pendingRestoreURL {
                    handlePerformRestore(from: url, restart: true)
                }
            }
        } message: {
            Text(.localized("Portal has to restart in order to apply this backup, do you want to proceed?"))
        }
        .alert(.localized("Invalid Backup File"), isPresented: $showInvalidBackupError) {
            Button(.localized("OK"), role: .cancel) { }
        } message: {
            Text(.localized("Not a valid Backup file because Portal couldn't find the checker inside the file. Please upload an actual .zip file of a backup."))
        }
        .overlay {
            if isRestoring {
                RestoreLoadingOverlay(progress: restoreProgress)
            }

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
                    .background(.ultraThinMaterial)
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
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Info Card View
    @ViewBuilder
    private func infoCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
                }
            } else {
                await MainActor.run {
                    isPreparingBackup = false
                }
            }
        }
    }

    private func prepareBackup(with options: BackupOptions) async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // 1. Certificates
            if options.includeCertificates {
                let certificatesDir = tempDir.appendingPathComponent("certificates")
                try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
                let certificates = Storage.shared.getAllCertificates()
                var certMetadata: [[String: Any]] = []
                for cert in certificates {
                    if let uuid = cert.uuid {
                        var metadata: [String: Any] = ["uuid": uuid]
                        if let certURL = Storage.shared.getFile(.certificate, from: cert),
                           let certData = try? Data(contentsOf: certURL) {
                            try certData.write(to: certificatesDir.appendingPathComponent("\(uuid).p12"))
                            metadata["hasP12"] = true
                        }
                        if let provisionURL = Storage.shared.getFile(.provision, from: cert),
                           let provisionData = try? Data(contentsOf: provisionURL) {
                            try provisionData.write(to: certificatesDir.appendingPathComponent("\(uuid).mobileprovision"))
                            metadata["hasProvision"] = true
                        }
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
                let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
                var appsData: [[String: String]] = []
                for app in signedApps {
                    guard let uuid = app.uuid else { continue }
                    var data: [String: String] = ["uuid": uuid]
                    if let name = app.name { data["name"] = name }
                    if let identifier = app.identifier { data["identifier"] = identifier }
                    if let version = app.version { data["version"] = version }
                    if let ipaURL = FileManager.default.getPath(in: FileManager.default.signed(uuid), for: "ipa"),
                       FileManager.default.fileExists(atPath: ipaURL.path) {
                        try? FileManager.default.copyItem(at: ipaURL, to: signedAppsDir.appendingPathComponent("\(uuid).ipa"))
                        data["hasIPA"] = "true"
                    }
                    appsData.append(data)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("signed_apps.json"))
            }

            // 4. Imported Apps
            if options.includeImportedApps {
                let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
                try? FileManager.default.createDirectory(at: importedAppsDir, withIntermediateDirectories: true)
                let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
                var appsData: [[String: String]] = []
                for app in importedApps {
                    guard let uuid = app.uuid else { continue }
                    var data: [String: String] = ["uuid": uuid]
                    if let name = app.name { data["name"] = name }
                    if let identifier = app.identifier { data["identifier"] = identifier }
                    if let version = app.version { data["version"] = version }
                    if let ipaURL = FileManager.default.getPath(in: FileManager.default.unsigned(uuid), for: "ipa"),
                       FileManager.default.fileExists(atPath: ipaURL.path) {
                        try? FileManager.default.copyItem(at: ipaURL, to: importedAppsDir.appendingPathComponent("\(uuid).ipa"))
                        data["hasIPA"] = "true"
                    }
                    appsData.append(data)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("imported_apps.json"))
            }

            // 5. Default Frameworks
            if options.includeDefaultFrameworks {
                let dest = tempDir.appendingPathComponent("default_frameworks")
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let src = Storage.shared.documentsURL.appendingPathComponent("Feather/DefaultFrameworks")
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

            // 7. Extra Files (Always)
            let extraDir = tempDir.appendingPathComponent("extra_files")
            try? FileManager.default.createDirectory(at: extraDir, withIntermediateDirectories: true)
            for file in ["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"] {
                let url = Storage.shared.documentsURL.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.copyItem(at: url, to: extraDir.appendingPathComponent(file))
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

            // 9. Settings (Always)
            let defaults = UserDefaults.standard.dictionaryRepresentation()
            let filtered = defaults.filter { k, _ in
                !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") &&
                !k.hasPrefix("WebKit") && !k.hasPrefix("CPU") && !k.hasPrefix("metal")
            }
            let data = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
            try data.write(to: tempDir.appendingPathComponent("settings.plist"))

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

    private func handlePerformRestore(from url: URL, restart: Bool) {
        isRestoring = true
        restoreProgress = 0.0
        Task {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                await MainActor.run { withAnimation { restoreProgress = 0.1 } }
                try FileManager.default.unzipItem(at: url, to: tempDir)
                await MainActor.run { withAnimation { restoreProgress = 0.2 } }

                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { m in FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(m).path) }
                guard hasMarker, FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("settings.plist").path) else {
                    try? FileManager.default.removeItem(at: tempDir)
                    await MainActor.run { isRestoring = false; showInvalidBackupError = true }
                    return
                }

                await MainActor.run { withAnimation { restoreProgress = 0.3 } }

                // 1. Certificates
                if let data = try? Data(contentsOf: tempDir.appendingPathComponent("certificates_metadata.json")),
                   let metadata = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let certDir = Storage.shared.documentsURL.appendingPathComponent("certificates")
                    try? FileManager.default.createDirectory(at: certDir, withIntermediateDirectories: true)
                    for c in metadata {
                        guard let uuid = c["uuid"] as? String else { continue }
                        let p12 = tempDir.appendingPathComponent("certificates/\(uuid).p12")
                        let prov = tempDir.appendingPathComponent("certificates/\(uuid).mobileprovision")
                        if FileManager.default.fileExists(atPath: p12.path), FileManager.default.fileExists(atPath: prov.path) {
                            try? FileManager.default.copyItem(at: p12, to: certDir.appendingPathComponent("\(uuid).p12"))
                            try? FileManager.default.copyItem(at: prov, to: certDir.appendingPathComponent("\(uuid).mobileprovision"))
                            Storage.shared.addCertificate(uuid: uuid, password: c["password"] as? String, nickname: c["name"] as? String ?? "Restored", ppq: c["ppQCheck"] as? Bool ?? false, expiration: Date(timeIntervalSince1970: c["date"] as? Double ?? Date().timeIntervalSince1970), completion: { _ in })
                        }
                    }
                }
                await MainActor.run { withAnimation { restoreProgress = 0.5 } }

                // 2. Sources
                if let data = try? Data(contentsOf: tempDir.appendingPathComponent("sources.json")),
                   let sources = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                    for s in sources {
                        if let u = s["url"], let url = URL(string: u) {
                            Storage.shared.addSource(url, name: s["name"] ?? u, identifier: s["identifier"] ?? u, completion: { _ in })
                        }
                    }
                }
                await MainActor.run { withAnimation { restoreProgress = 0.6 } }

                // 3. Signed/Imported Apps
                for (file, dirName, method) in [("signed_apps.json", "signed", 1), ("imported_apps.json", "imported", 2)] {
                    if let data = try? Data(contentsOf: tempDir.appendingPathComponent(file)),
                       let apps = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                        let dest = method == 1 ? FileManager.default.signed : FileManager.default.unsigned
                        try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                        for a in apps {
                            guard let uuid = a["uuid"], a["hasIPA"] == "true" else { continue }
                            let src = tempDir.appendingPathComponent("\(dirName)_apps/\(uuid).ipa")
                            if FileManager.default.fileExists(atPath: src.path) {
                                let appDestDir = dest.appendingPathComponent(uuid)
                                try? FileManager.default.createDirectory(at: appDestDir, withIntermediateDirectories: true)
                                try? FileManager.default.copyItem(at: src, to: appDestDir.appendingPathComponent("app.ipa"))
                                if method == 1 { Storage.shared.addSigned(uuid: uuid, appName: a["name"] ?? "Unknown", appIdentifier: a["identifier"], appVersion: a["version"], completion: { _ in }) }
                                else { Storage.shared.addImported(uuid: uuid, appName: a["name"] ?? "Unknown", appIdentifier: a["identifier"], appVersion: a["version"], completion: { _ in }) }
                            }
                        }
                    }
                }
                await MainActor.run { withAnimation { restoreProgress = 0.8 } }

                // 4. Everything else
                let doc = Storage.shared.documentsURL
                for (s, d) in [("default_frameworks", "Feather/DefaultFrameworks"), ("archives", "Archives"), ("extra_files", "")] {
                    let src = tempDir.appendingPathComponent(s)
                    let dest = d.isEmpty ? doc : doc.appendingPathComponent(d)
                    if FileManager.default.fileExists(atPath: src.path) {
                        try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                        for f in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                            let du = dest.appendingPathComponent(f.lastPathComponent)
                            try? FileManager.default.removeItem(at: du); try? FileManager.default.copyItem(at: f, to: du)
                        }
                    }
                }

                if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                    let destDir = storeURL.deletingLastPathComponent()
                    let srcDir = tempDir.appendingPathComponent("database")
                    for f in (try? FileManager.default.contentsOfDirectory(at: srcDir, includingPropertiesForKeys: nil)) ?? [] {
                        let du = destDir.appendingPathComponent(f.lastPathComponent)
                        try? FileManager.default.removeItem(at: du); try? FileManager.default.copyItem(at: f, to: du)
                    }
                }

                await MainActor.run { withAnimation { restoreProgress = 0.9 } }

                // 5. Settings
                if let data = try? Data(contentsOf: tempDir.appendingPathComponent("settings.plist")),
                   let s = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    for (k, v) in s { if !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") { UserDefaults.standard.set(v, forKey: k) } }
                    UserDefaults.standard.synchronize()
                }

                await MainActor.run {
                    restoreProgress = 1.0; try? FileManager.default.removeItem(at: tempDir); isRestoring = false
                    if restart { UIAlertController.showAlertWithOk(title: .localized("Restore Complete"), message: .localized("The app will now restart.")) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { UIApplication.shared.suspendAndReopen() }
                    } } else { UIAlertController.showAlertWithOk(title: .localized("Success"), message: .localized("Backup restored successfully.")) }
                }
            } catch {
                await MainActor.run { isRestoring = false; UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to restore: \(error.localizedDescription)")) }
            }
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
    let onConfirm: () -> Void
    var body: some View {
        NavigationView {
            NBList(.localized("Backup Options")) {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                            Image(systemName: "square.and.arrow.up.fill").font(.system(size: 40, weight: .semibold)).foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        Text(.localized("What would you like in this Portal Backup?")).font(.title2.bold()).multilineTextAlignment(.center).padding(.horizontal)
                        Text(.localized("Select the data you want to include in your backup")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                    }.frame(maxWidth: .infinity).padding(.vertical, 20)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())

                Section {
                    backupOptionToggle(icon: "checkmark.seal.fill", iconColor: .blue, title: .localized("Certificates"), description: .localized("Your signing certificates and provisioning profiles"), isOn: $options.includeCertificates)
                    backupOptionToggle(icon: "app.badge.fill", iconColor: .green, title: .localized("Signed Apps"), description: .localized("Apps you have signed with your certificates"), isOn: $options.includeSignedApps)
                    backupOptionToggle(icon: "square.and.arrow.down.fill", iconColor: .orange, title: .localized("Imported Apps"), description: .localized("Apps imported from files or other sources"), isOn: $options.includeImportedApps)
                    backupOptionToggle(icon: "globe.fill", iconColor: .purple, title: .localized("Sources"), description: .localized("Your configured app sources and repositories"), isOn: $options.includeSources)
                    backupOptionToggle(icon: "puzzlepiece.extension.fill", iconColor: .cyan, title: .localized("Default Frameworks"), description: .localized("Your automatically injected frameworks (.dylib, .deb)"), isOn: $options.includeDefaultFrameworks)
                    backupOptionToggle(icon: "archivebox.fill", iconColor: .indigo, title: .localized("Archives"), description: .localized("Your saved app archives and backups"), isOn: $options.includeArchives)
                } header: { AppearanceSectionHeader(title: String.localized("Backup Content"), icon: "list.bullet.indent") }
                .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                if options.includeSignedApps || options.includeImportedApps {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 20)).foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("Large Backup Size")).font(.headline).foregroundStyle(.primary)
                                Text(.localized("If you include Signed and Imported Apps, this backup will be large.")).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }.padding(16).background(Color.orange.opacity(0.1)).cornerRadius(12)
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    Button { onConfirm() } label: {
                        HStack { Image(systemName: "checkmark.circle.fill"); Text(.localized("Create Backup")).font(.headline) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).foregroundStyle(.white).cornerRadius(12)
                    }.buttonStyle(.plain)
                    Button { dismiss() } label: { Text(.localized("Cancel")).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity) }.buttonStyle(.plain).padding(.top, 8)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
            }.navigationTitle(.localized("Backup Options")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(.secondary) } } }
        }
    }

    @ViewBuilder
    private func backupOptionToggle(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle(); HapticsManager.shared.softImpact() } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack { Circle().fill(iconColor.opacity(0.15)).frame(width: 44, height: 44); Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(iconColor) }
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline).foregroundStyle(.primary); Text(description).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle").font(.system(size: 24)).foregroundStyle(isOn.wrappedValue ? .blue : .gray.opacity(0.3))
            }.padding(16).background(.ultraThinMaterial).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isOn.wrappedValue ? iconColor.opacity(0.3) : Color.clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

// MARK: - RestoreLoadingOverlay
struct RestoreLoadingOverlay: View {
    let progress: Double
    @State private var rotation: Double = 0
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(Color.green.opacity(0.1)).frame(width: 100, height: 100)
                    Circle().stroke(Color.green.opacity(0.3), lineWidth: 4).frame(width: 100, height: 100).rotationEffect(.degrees(rotation))
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 50)).foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(spacing: 8) { Text("Restoring Backup").font(.title2.bold()); Text("Please wait while we restore your data...").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                VStack(spacing: 8) { ProgressView(value: progress).tint(.green); Text("\(Int(progress * 100))%").font(.caption).foregroundStyle(.secondary) }
            }.padding(32).background(.ultraThinMaterial).cornerRadius(24).padding(.horizontal, 40).shadow(color: .black.opacity(0.2), radius: 20)
        }.onAppear { withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { rotation = 360 } }
    }
}
