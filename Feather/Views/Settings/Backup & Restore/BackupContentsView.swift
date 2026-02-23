import SwiftUI
import ZIPFoundation
import CryptoKit

struct BackupContentsView: View {
    @Environment(\.dismiss) private var dismiss
    let backupURL: URL
    let isEncrypted: Bool
    let backupID: UUID?

    @State private var isLoading = true
    @State private var certificates: [CertMetadata] = []
    @State private var sources: [SourceMetadata] = []
    @State private var signedApps: [AppMetadata] = []
    @State private var importedApps: [AppMetadata] = []
    @State private var archives: [ArchiveMetadata] = []
    @State private var frameworks: [FrameworkMetadata] = []
    @State private var errorMessage: String?

    @State private var showDiffViewer = false
    @State private var showRestoreSimulation = false
    @AppStorage("feature_newBackupOptions") var newBackupOptions = false

    struct CertMetadata: Codable, Identifiable {
        var id: String { uuid }
        let uuid: String
        let name: String?
        let teamName: String?
        let ppQCheck: Bool
    }

    struct AppMetadata: Codable, Identifiable {
        var id: String { uuid }
        let uuid: String
        let name: String
        let identifier: String
        let version: String
    }

    struct ArchiveMetadata: Codable, Identifiable {
        var id: String { name }
        let name: String
        let size: Int64
    }

    struct FrameworkMetadata: Codable, Identifiable {
        var id: String { name }
        let name: String
    }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Analyzing Backup...")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                } else {
                    if !certificates.isEmpty {
                        Section {
                            ForEach(certificates) { cert in
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(cert.name ?? "Unknown Certificate")
                                            .font(.headline)
                                        if let team = cert.teamName {
                                            Text(team).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                } icon: {
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue)
                                }
                            }
                        } header: {
                            headerView(title: "Certificates", icon: "checkmark.seal.fill", color: .blue)
                        }
                    }

                    if !signedApps.isEmpty {
                        Section {
                            ForEach(signedApps) { app in
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(app.name).font(.headline)
                                        Text("\(app.identifier) • \(app.version)").font(.caption).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "app.badge.fill").foregroundStyle(.green)
                                }
                            }
                        } header: {
                            headerView(title: "Signed Apps", icon: "app.badge.fill", color: .green)
                        }
                    }

                    if !importedApps.isEmpty {
                        Section {
                            ForEach(importedApps) { app in
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(app.name).font(.headline)
                                        Text("\(app.identifier) • \(app.version)").font(.caption).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "square.and.arrow.down.fill").foregroundStyle(.orange)
                                }
                            }
                        } header: {
                            headerView(title: "Imported Apps", icon: "square.and.arrow.down.fill", color: .orange)
                        }
                    }

                    if !frameworks.isEmpty {
                        Section {
                            ForEach(frameworks) { framework in
                                Label {
                                    Text(framework.name).font(.headline)
                                } icon: {
                                    Image(systemName: "square.stack.3d.up.fill").foregroundStyle(.purple)
                                }
                            }
                        } header: {
                            headerView(title: "Default Frameworks", icon: "square.stack.3d.up.fill", color: .purple)
                        }
                    }

                    if !archives.isEmpty {
                        Section {
                            ForEach(archives) { archive in
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(archive.name).font(.headline)
                                        Text(ByteCountFormatter.string(fromByteCount: archive.size, countStyle: .file)).font(.caption).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "archivebox.fill").foregroundStyle(.brown)
                                }
                            }
                        } header: {
                            headerView(title: "Archives", icon: "archivebox.fill", color: .brown)
                        }
                    }

                    if certificates.isEmpty && signedApps.isEmpty && importedApps.isEmpty && frameworks.isEmpty && archives.isEmpty {
                        Section {
                            Text("No recognizable metadata found in backup.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Backup Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if newBackupOptions && !isLoading && errorMessage == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                showDiffViewer = true
                            } label: {
                                Label("View Differences", systemImage: "arrow.left.arrow.right")
                            }

                            Button {
                                showRestoreSimulation = true
                            } label: {
                                Label("Simulate Restore", systemImage: "play.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showDiffViewer) {
                BackupDiffView(snapshotID: backupID?.uuidString ?? "", backupMetadata: collectedMetadata)
            }
            .sheet(isPresented: $showRestoreSimulation) {
                RestoreSimulationView(snapshotID: backupID?.uuidString ?? "", backupMetadata: collectedMetadata)
            }
            .task {
                await loadContents()
            }
        }
    }

    private var collectedMetadata: [String: Any] {
        var metadata: [String: Any] = [:]
        metadata["certificates"] = certificates.map { ["uuid": $0.uuid, "name": $0.name ?? ""] }
        metadata["signed_apps"] = signedApps.map { ["uuid": $0.uuid, "name": $0.name] }
        metadata["imported_apps"] = importedApps.map { ["uuid": $0.uuid, "name": $0.name] }
        metadata["archives"] = archives.map { ["name": $0.name, "size": $0.size] }
        metadata["frameworks"] = frameworks.map { ["name": $0.name] }
        metadata["profiles"] = [] // Simplified
        metadata["settings"] = ["status": "present"] // Simplified
        return metadata
    }

    private func headerView(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(color)
        .padding(.vertical, 8)
    }

    private func decryptData(_ encryptedData: Data, with customPassword: String? = nil) throws -> Data {
        let password = "PortalLocalBackup2026"
        let decryptionPassword = customPassword ?? password
        let key = SymmetricKey(data: SHA256.hash(data: decryptionPassword.data(using: .utf8)!))

        // Check for binary magic header (v2)
        let v2Header = "PORTAL_V2".data(using: .utf8)!
        if encryptedData.starts(with: v2Header) {
            let dataToDecrypt = encryptedData.suffix(from: v2Header.count)
            let sealedBox = try AES.GCM.SealedBox(combined: dataToDecrypt)
            return try AES.GCM.open(sealedBox, using: key)
        }

        // Fallback to legacy JSON format (v1)
        var dataToDecrypt = encryptedData
        let v1Header = "PORTAL_ENC".data(using: .utf8)!
        if encryptedData.starts(with: v1Header) {
            dataToDecrypt = encryptedData.suffix(from: v1Header.count)
        }

        struct SimplePayload: Codable {
            let version: String
            let timestamp: TimeInterval
            let data: Data
        }

        let sealedBox = try AES.GCM.SealedBox(combined: dataToDecrypt)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        let decoder = JSONDecoder()
        let payload = try decoder.decode(SimplePayload.self, from: decryptedData)
        return payload.data
    }

    private func loadContents() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("BackupContents_\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Access security scoped resource
            let isSecurityScoped = backupURL.startAccessingSecurityScopedResource()
            defer { if isSecurityScoped { backupURL.stopAccessingSecurityScopedResource() } }

            let fileData = try Data(contentsOf: backupURL)
            let zipData: Data

            if isEncrypted {
                // Try to get password from Keychain
                var backupPassword: String? = nil
                if let id = backupID {
                    backupPassword = try? KeychainManager.shared.retrieve(account: "backup_\(id.uuidString)")
                }

                zipData = try decryptData(fileData, with: backupPassword)
            } else {
                // Check if it's an old encrypted style or already a ZIP
                if let decrypted = try? decryptData(fileData, with: nil) {
                    zipData = decrypted
                } else {
                    zipData = fileData
                }
            }

            let tempZipURL = tempDir.appendingPathComponent("backup.zip")
            try zipData.write(to: tempZipURL)

            try FileManager.default.unzipItem(at: tempZipURL, to: tempDir)

            // Load Certificates
            let certsURL = tempDir.appendingPathComponent("certificates_metadata.json")
            if let data = try? Data(contentsOf: certsURL) {
                certificates = (try? JSONDecoder().decode([CertMetadata].self, from: data)) ?? []
            }

            // Load Signed Apps
            let signedURL = tempDir.appendingPathComponent("signed_apps_metadata.json")
            if let data = try? Data(contentsOf: signedURL) {
                signedApps = (try? JSONDecoder().decode([AppMetadata].self, from: data)) ?? []
            }

            // Load Imported Apps
            let importedURL = tempDir.appendingPathComponent("imported_apps_metadata.json")
            if let data = try? Data(contentsOf: importedURL) {
                importedApps = (try? JSONDecoder().decode([AppMetadata].self, from: data)) ?? []
            }

            // Load Archives
            let archivesDir = tempDir.appendingPathComponent("archives")
            if let contents = try? FileManager.default.contentsOfDirectory(at: archivesDir, includingPropertiesForKeys: [.fileSizeKey]) {
                archives = contents.map { url in
                    let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let size = attr?[.size] as? Int64 ?? 0
                    return ArchiveMetadata(name: url.lastPathComponent, size: size)
                }
            }

            // Load Frameworks
            let frameworksURL = tempDir.appendingPathComponent("frameworks.json")
            if let data = try? Data(contentsOf: frameworksURL) {
                frameworks = (try? JSONDecoder().decode([FrameworkMetadata].self, from: data)) ?? []
            }

            try? FileManager.default.removeItem(at: tempDir)
            isLoading = false

        } catch {
            errorMessage = "Failed to read backup: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
