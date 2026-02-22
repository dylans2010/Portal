import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CryptoKit

struct BackupContentsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingDocumentPicker = false
    @State private var isAnalyzing = false
    @State private var backupData: BackupDetails?
    @State private var errorMessage: String?
    @State private var appearAnimation = false
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var pendingBackupURL: URL?

    struct BackupDetails {
        let name: String
        let size: Int64
        let date: Date
        let certificates: [String]
        let signedApps: [String]
        let importedApps: [String]
        let sources: [SourceInfo]
        let hasFrameworks: Bool
        let hasArchives: Bool
        let hasSettings: Bool

        struct SourceInfo: Identifiable {
            let id = UUID()
            let name: String
            let url: String
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let data = backupData {
                    Section {
                        headerCard(data: data)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    Section {
                        if !data.certificates.isEmpty {
                            contentRow(title: "Certificates", count: data.certificates.count, icon: "checkmark.seal.fill", color: .blue, items: data.certificates)
                        }
                        if !data.signedApps.isEmpty {
                            contentRow(title: "Signed Apps", count: data.signedApps.count, icon: "app.badge.fill", color: .green, items: data.signedApps)
                        }
                        if !data.importedApps.isEmpty {
                            contentRow(title: "Imported Apps", count: data.importedApps.count, icon: "square.and.arrow.down.fill", color: .orange, items: data.importedApps)
                        }
                        if !data.sources.isEmpty {
                            contentRow(title: "Sources", count: data.sources.count, icon: "globe.fill", color: .purple, items: data.sources.map { $0.name })
                        }
                    } header: {
                        Text("Contents")
                    }

                    Section {
                        statusRow(title: "Default Frameworks", active: data.hasFrameworks, icon: "puzzlepiece.extension.fill", color: .cyan)
                        statusRow(title: "Archives", active: data.hasArchives, icon: "archivebox.fill", color: .indigo)
                        statusRow(title: "Settings", active: data.hasSettings, icon: "gearshape.fill", color: .gray)
                    } header: {
                        Text("System Data")
                    }

                    Section {
                        Button(role: .destructive) {
                            backupData = nil
                        } label: {
                            Label("Clear View", systemImage: "trash")
                        }
                    }
                } else if isAnalyzing {
                    Section {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing Backup...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        VStack(spacing: 24) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .pulseEffect(true)

                            VStack(spacing: 8) {
                                Text("No Backup Selected")
                                    .font(.title2.bold())

                                Text("Upload a .backup file to view its contents without restoring.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }

                            Button {
                                showingDocumentPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Select Backup File")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Backup Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                if backupData != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showingDocumentPicker = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                if let backupType = UTType(filenameExtension: "backup") {
                    FileImporterRepresentableView(
                        allowedContentTypes: [backupType],
                        allowsMultipleSelection: false,
                        onDocumentsPicked: { urls in
                            guard let url = urls.first else { return }
                            checkEncryption(at: url)
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Enter Backup Password", isPresented: $showingPasswordPrompt) {
                SecureField("Password", text: $passwordInput)
                    .textContentType(.password)
                Button("Cancel", role: .cancel) {
                    passwordInput = ""
                    pendingBackupURL = nil
                }
                Button("View") {
                    if let url = pendingBackupURL {
                        analyzeBackup(at: url, password: passwordInput)
                    }
                    passwordInput = ""
                }
            } message: {
                Text("This backup is encrypted. Please enter the password to view its contents.")
            }
        }
        .onAppear {
            withAnimation { appearAnimation = true }
        }
    }

    private func headerCard(data: BackupDetails) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "archivebox.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 4) {
                Text(data.name)
                    .font(.title3.bold())

                HStack(spacing: 12) {
                    Label(data.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Text("•")
                    Label(ByteCountFormatter.string(fromByteCount: data.size, countStyle: .file), systemImage: "internaldrive")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private func contentRow(title: String, count: Int, icon: String, color: Color, items: [String]) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(color.opacity(0.5))
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.vertical, 8)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(color))
            }
        }
    }

    private func statusRow(title: String, active: Bool, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.body)

            Spacer()

            Image(systemName: active ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(active ? .green : .secondary.opacity(0.3))
        }
        .padding(.vertical, 4)
    }

    private func checkEncryption(at url: URL) {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let fileData = try Data(contentsOf: url)
            let v2Header = "PORTAL_V2".data(using: .utf8)!
            let v1Header = "PORTAL_ENC".data(using: .utf8)!

            if fileData.starts(with: v2Header) || fileData.starts(with: v1Header) {
                pendingBackupURL = url
                showingPasswordPrompt = true
            } else {
                analyzeBackup(at: url)
            }
        } catch {
            errorMessage = "Failed to read backup file: \(error.localizedDescription)"
        }
    }

    private func analyzeBackup(at url: URL, password: String? = nil) {
        isAnalyzing = true
        backupData = nil
        errorMessage = nil

        Task {
            do {
                let isSecurityScoped = url.startAccessingSecurityScopedResource()
                defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }

                let fileManager = FileManager.default
                let tempDir = fileManager.temporaryDirectory.appendingPathComponent("BackupAnalysis_\(UUID().uuidString)")
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                defer { try? fileManager.removeItem(at: tempDir) }

                let fileData = try Data(contentsOf: url)
                let dataToUnzip: Data

                if let pwd = password {
                    let v2Header = "PORTAL_V2".data(using: .utf8)!
                    let decryptionPassword = pwd.isEmpty ? "PortalLocalBackup2026" : pwd
                    let key = SymmetricKey(data: SHA256.hash(data: decryptionPassword.data(using: .utf8)!))

                    if fileData.starts(with: v2Header) {
                        let sealedBox = try AES.GCM.SealedBox(combined: fileData.suffix(from: v2Header.count))
                        dataToUnzip = try AES.GCM.open(sealedBox, using: key)
                    } else {
                        // V1 or legacy - skipping for brevity in analysis view but could be added
                        dataToUnzip = fileData
                    }
                } else {
                    dataToUnzip = fileData
                }

                let tempZip = tempDir.appendingPathComponent("backup.zip")
                try dataToUnzip.write(to: tempZip)

                let extractDir = tempDir.appendingPathComponent("extract")
                try fileManager.unzipItem(at: tempZip, to: extractDir)

                // Read contents
                let certificates = (try? fileManager.contentsOfDirectory(at: extractDir.appendingPathComponent("certificates"), includingPropertiesForKeys: nil))?.map { $0.lastPathComponent } ?? []
                let signedApps = (try? fileManager.contentsOfDirectory(at: extractDir.appendingPathComponent("signed_apps"), includingPropertiesForKeys: nil))?.map { $0.lastPathComponent } ?? []
                let importedApps = (try? fileManager.contentsOfDirectory(at: extractDir.appendingPathComponent("imported_apps"), includingPropertiesForKeys: nil))?.map { $0.lastPathComponent } ?? []

                var sources: [BackupDetails.SourceInfo] = []
                let sourcesFile = extractDir.appendingPathComponent("sources.json")
                if let sourcesData = try? Data(contentsOf: sourcesFile),
                   let sourcesArray = try? JSONSerialization.jsonObject(with: sourcesData) as? [[String: String]] {
                    sources = sourcesArray.compactMap { dict in
                        guard let name = dict["name"], let url = dict["url"] else { return nil }
                        return BackupDetails.SourceInfo(name: name, url: url)
                    }
                }

                let hasFrameworks = fileManager.fileExists(atPath: extractDir.appendingPathComponent("default_frameworks").path)
                let hasArchives = fileManager.fileExists(atPath: extractDir.appendingPathComponent("archives").path)
                let hasSettings = fileManager.fileExists(atPath: extractDir.appendingPathComponent("settings.plist").path) ||
                                 fileManager.fileExists(atPath: extractDir.appendingPathComponent("standard_settings.plist").path)

                let attributes = try fileManager.attributesOfItem(atPath: url.path)

                await MainActor.run {
                    self.backupData = BackupDetails(
                        name: url.deletingPathExtension().lastPathComponent,
                        size: attributes[.size] as? Int64 ?? 0,
                        date: attributes[.creationDate] as? Date ?? Date(),
                        certificates: certificates,
                        signedApps: signedApps,
                        importedApps: importedApps,
                        sources: sources,
                        hasFrameworks: hasFrameworks,
                        hasArchives: hasArchives,
                        hasSettings: hasSettings
                    )
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to analyze backup: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}
