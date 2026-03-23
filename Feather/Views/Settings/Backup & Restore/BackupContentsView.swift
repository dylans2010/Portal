import SwiftUI
import ZIPFoundation
import CryptoKit

struct BackupContentsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let backupURL: URL
    let isEncrypted: Bool
    let backupID: UUID?

    @State private var isLoading = true
    @State private var certificates: [CertMetadata] = []
    @State private var sources: [SourceMetadata] = []
    @State private var signedApps: [AppMetadata] = []
    @State private var importedApps: [AppMetadata] = []
    @State private var frameworks: [String] = []
    @State private var archives: [String] = []
    @State private var errorMessage: String?
    @State private var backupMetadata: BackupMetadataInfo?

    @State private var showDiffViewer = false
    @State private var showRestoreSimulation = false
    @AppStorage("feature_newBackupOptions") var newBackupOptions = false

    struct CertMetadata: Codable, Identifiable {
        var id: String { uuid }
        let uuid: String
        let name: String?
        let teamName: String?
        let teamID: String?
        let date: TimeInterval?
        let ppQCheck: Bool
    }

    struct SourceMetadata: Codable, Identifiable {
        var id: String { url }
        let url: String
        let name: String
    }

    struct AppMetadata: Codable, Identifiable {
        var id: String { uuid }
        let uuid: String
        let name: String
        let identifier: String
        let version: String
    }

    struct BackupMetadataInfo: Codable {
        let backupID: String?
        let backupDate: TimeInterval?
        let backupDateString: String?
        let deviceModel: String?
        let systemVersion: String?
        let appVersion: String?
        let appBuildNumber: String?
        let includedData: [String]?
        let backupFormatVersion: String?
        let snapshotType: String?
        let isIncremental: Bool?
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cert.name ?? "Unknown Certificate")
                                            .font(.headline)

                                        HStack(spacing: 8) {
                                            if let teamID = cert.teamID {
                                                Text(teamID)
                                                    .font(.caption.monospaced())
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1), in: Capsule())
                                            }

                                            if let team = cert.teamName {
                                                Text(team).font(.caption).foregroundStyle(.secondary)
                                            }
                                        }

                                        HStack(spacing: 12) {
                                            if let date = cert.date {
                                                Label(Date(timeIntervalSince1970: date).formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                            }

                                            if cert.ppQCheck {
                                                Label("PPQ Protected", systemImage: "shield.checkered")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
                            ForEach(frameworks, id: \.self) { framework in
                                Label(framework, systemImage: "puzzlepiece.extension.fill")
                                    .foregroundStyle(.cyan)
                            }
                        } header: {
                            headerView(title: "Default Frameworks", icon: "puzzlepiece.extension.fill", color: .cyan)
                        }
                    }

                    if !archives.isEmpty {
                        Section {
                            ForEach(archives, id: \.self) { archive in
                                Label(archive, systemImage: "archivebox.fill")
                                    .foregroundStyle(.indigo)
                            }
                        } header: {
                            headerView(title: "Archives", icon: "archivebox.fill", color: .indigo)
                        }
                    }

                    if !sources.isEmpty {
                        Section {
                            DisclosureGroup {
                                ForEach(sources) { source in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.name).font(.subheadline.bold())
                                        Text(source.url).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            } label: {
                                headerView(title: "Sources (\(sources.count))", icon: "globe", color: .purple)
                            }
                        }
                    }

                    if let info = backupMetadata {
                        Section {
                            if let dateString = info.backupDateString {
                                metadataRow(label: "Created", value: dateString, icon: "calendar", color: .blue)
                            } else if let dateTS = info.backupDate {
                                metadataRow(label: "Created", value: Date(timeIntervalSince1970: dateTS).formatted(date: .abbreviated, time: .shortened), icon: "calendar", color: .blue)
                            }
                            if let device = info.deviceModel {
                                metadataRow(label: "Device", value: device, icon: "iphone", color: .gray)
                            }
                            if let ios = info.systemVersion {
                                metadataRow(label: "iOS Version", value: ios, icon: "apple.logo", color: .primary)
                            }
                            if let version = info.appVersion, let build = info.appBuildNumber {
                                metadataRow(label: "App Version", value: "\(version) (\(build))", icon: "app.badge", color: .accentColor)
                            }
                            if let format = info.backupFormatVersion {
                                metadataRow(label: "Backup Format", value: "v\(format)", icon: "doc.badge.gearshape", color: .orange)
                            }
                            if let type = info.snapshotType {
                                metadataRow(label: "Snapshot Type", value: type.capitalized, icon: "camera.viewfinder", color: .purple)
                            }
                            if let id = info.backupID {
                                metadataRow(label: "Backup ID", value: id, icon: "number", color: .secondary)
                                    .font(.system(.caption, design: .monospaced))
                            }
                            if let included = info.includedData, !included.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label {
                                        Text("Included Data")
                                            .font(.headline)
                                    } icon: {
                                        Image(systemName: "checklist")
                                            .foregroundStyle(.teal)
                                    }
                                    FlowTagsView(tags: included)
                                        .padding(.top, 4)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            headerView(title: "Backup Info", icon: "info.circle.fill", color: .teal)
                        }
                    }

                    if certificates.isEmpty && signedApps.isEmpty && importedApps.isEmpty && frameworks.isEmpty && archives.isEmpty && backupMetadata == nil {
                        Section {
                            Text("No recognizable metadata found in this backup.")
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
        metadata["sources"] = sources.map { ["url": $0.url, "name": $0.name] }
        metadata["signed_apps"] = signedApps.map { ["uuid": $0.uuid, "name": $0.name] }
        metadata["imported_apps"] = importedApps.map { ["uuid": $0.uuid, "name": $0.name] }
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

    private func metadataRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
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

            // Support both new plain ZIP backups and legacy encrypted backups
            if let decrypted = try? decryptData(fileData, with: nil) {
                zipData = decrypted
            } else {
                zipData = fileData
            }

            let tempZipURL = tempDir.appendingPathComponent("backup.zip")
            try zipData.write(to: tempZipURL)

            try FileManager.default.unzipItem(at: tempZipURL, to: tempDir)

            // Load Metadata Info
            let metadataInfoURL = tempDir.appendingPathComponent("metadataInfo.json")
            if let data = try? Data(contentsOf: metadataInfoURL) {
                backupMetadata = try? JSONDecoder().decode(BackupMetadataInfo.self, from: data)
            }

            // Load Certificates
            let certsURL = tempDir.appendingPathComponent("certificates_metadata.json")
            if let data = try? Data(contentsOf: certsURL) {
                certificates = (try? JSONDecoder().decode([CertMetadata].self, from: data)) ?? []
            }

            // Load Sources
            let sourcesURL = tempDir.appendingPathComponent("sources.json")
            if let data = try? Data(contentsOf: sourcesURL) {
                sources = (try? JSONDecoder().decode([SourceMetadata].self, from: data)) ?? []
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

            // Load Frameworks
            let frameworksDir = tempDir.appendingPathComponent("default_frameworks")
            if let items = try? FileManager.default.contentsOfDirectory(atPath: frameworksDir.path) {
                frameworks = items.filter { !$0.hasPrefix(".") }
            }

            // Load Archives
            let archivesDir = tempDir.appendingPathComponent("archives")
            if let items = try? FileManager.default.contentsOfDirectory(atPath: archivesDir.path) {
                archives = items.filter { !$0.hasPrefix(".") }
            }

            try? FileManager.default.removeItem(at: tempDir)
            isLoading = false

        } catch {
            errorMessage = "Failed to read backup: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Flow Tags View

private struct FlowTagsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.12))
                    .foregroundStyle(Color.teal)
                    .clipShape(Capsule())
            }
        }
    }
}
