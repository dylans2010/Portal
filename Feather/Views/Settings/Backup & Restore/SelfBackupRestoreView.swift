import SwiftUI
import NimbleViews
import ZIPFoundation
import CryptoKit
import UniformTypeIdentifiers

// MARK: - Self Backup Restore View
struct SelfBackupRestoreView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SelfBackupRestoreViewModel()
    @State private var showingBackupOptions = false
    @State private var showingRestoreList = false
    @State private var backupOptions = BackupOptions()
    @State private var showingDocumentPicker = false
    @State private var showingRenameAlert = false
    @State private var backupToRename: LocalBackup?
    @State private var newBackupName = ""
    
    var body: some View {
        NBList(.localized("Self Backup & Restore")) {
            // Header Section
            Section {
                ZStack {
                    LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(.localized("Create and restore backups locally on your device."))
                            .font(.system(.subheadline, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Quick Actions Section
            Section {
                // Create Backup
                Button {
                    showingBackupOptions = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Create Backup"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(.localized("Save Your Current Data"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isCreatingBackup {
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 8)
                }
                .disabled(viewModel.isCreatingBackup || viewModel.isRestoring)
                
                // Restore Backup
                Button {
                    showingRestoreList = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Restore Backup"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(.localized("Load Previously Saved Data"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isRestoring {
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 8)
                }
                .disabled(viewModel.isCreatingBackup || viewModel.isRestoring || viewModel.localBackups.isEmpty)
                
                // Import Backup
                Button {
                    showingDocumentPicker = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Import Backup"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(.localized("Import Backup File"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .disabled(viewModel.isCreatingBackup || viewModel.isRestoring)
            } header: {
                AppearanceSectionHeader(title: String.localized("Quick Actions"), icon: "bolt.fill")
            }
            
            // Saved Backups Section
            if !viewModel.localBackups.isEmpty {
                Section {
                    ForEach(viewModel.localBackups) { backup in
                        backupRow(backup: backup)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteBackups(at: indexSet)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Saved Backups"), icon: "archivebox.fill")
                } footer: {
                    let count = viewModel.localBackups.count
                    let backupText = count == 1 ? "Backup" : "Backups"
                    return Text("\(count) \(backupText) • \(viewModel.totalBackupSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Current Operation Status
            if viewModel.isCreatingBackup || viewModel.isRestoring {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text(viewModel.currentOperation)
                                .font(.subheadline)
                        }
                        
                        if viewModel.operationProgress > 0 {
                            ProgressView(value: viewModel.operationProgress)
                                .progressViewStyle(.linear)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    AppearanceSectionHeader(title: String.localized("Status"), icon: "info.circle.fill")
                }
            }
            
            // Features Section
            Section {
                featureCard(
                    icon: "lock.shield.fill",
                    iconColor: .green,
                    title: .localized("Encrypted Storage"),
                    description: .localized("All backups are encrypted for security.")
                )
                
                featureCard(
                    icon: "internaldrive.fill",
                    iconColor: .blue,
                    title: .localized("Local Storage"),
                    description: .localized("Backups are stored locally on your device without any network transfer.")
                )
                
                featureCard(
                    icon: "clock.arrow.circlepath",
                    iconColor: .orange,
                    title: .localized("Quick Restore"),
                    description: .localized("Restore your data instantly from any saved backup.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Features"), icon: "star.fill")
            }
            
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.localized("Backups Include:"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    backupItemRow(icon: "checkmark.seal.fill", text: "Certificates & Profiles", color: .blue)
                    backupItemRow(icon: "app.badge.fill", text: "Signed Apps", color: .green)
                    backupItemRow(icon: "square.and.arrow.down.fill", text: "Imported Apps", color: .orange)
                    backupItemRow(icon: "globe.fill", text: "Sources", color: .purple)
                    backupItemRow(icon: "puzzlepiece.extension.fill", text: "Default Frameworks", color: .cyan)
                    backupItemRow(icon: "archivebox.fill", text: "Archives", color: .indigo)
                    backupItemRow(icon: "gearshape.fill", text: "Settings", color: .gray)
                }
                .padding(.vertical, 8)
            } header: {
                AppearanceSectionHeader(title: String.localized("What's Included"), icon: "list.bullet")
            }
        }
        .navigationTitle("Self Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBackupOptions) {
            BackupOptionsView(
                options: $backupOptions,
                isPreparing: viewModel.isCreatingBackup,
                onConfirm: {
                    Task {
                        await viewModel.createBackup(with: backupOptions)
                        showingBackupOptions = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingRestoreList) {
            let handleRestore: (LocalBackup) -> Void = { backup in
                showingRestoreList = false
                Task {
                    await viewModel.restoreBackup(backup)
                }
            }
            
            NavigationStack {
                Group {
                    if #available(iOS 17.0, *) {
                        ModernRestoreSelectionView(
                            backups: viewModel.localBackups,
                            onRestore: handleRestore
                        )
                    } else {
                        LegacyRestoreSelectionView(
                            backups: viewModel.localBackups,
                            onRestore: handleRestore
                        )
                    }
                }
                .navigationTitle("Select Backup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") {
                            showingRestoreList = false
                        }
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
                        Task {
                            await viewModel.importBackup(from: url)
                        }
                        showingDocumentPicker = false
                    }
                )
                .ignoresSafeArea()
            } else {
                Text("Error: Unable to create document picker")
                    .padding()
            }
        }
        .alert("Rename Backup", isPresented: $showingRenameAlert, presenting: backupToRename) { backup in
            TextField("Backup Name", text: $newBackupName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                viewModel.renameBackup(backup, to: newBackupName)
            }
        } message: { _ in
            Text("Enter a new name for this backup.")
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error)
        }
        .alert("Success", isPresented: $viewModel.showSuccess, presenting: viewModel.successMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .alert("Apply Backup", isPresented: $viewModel.showingApplyBackupPrompt, presenting: viewModel.backupToApply) { backup in
            Button("Apply Now") {
                Task {
                    await viewModel.restoreBackup(backup)
                }
            }
            Button("Later", role: .cancel) { }
        } message: { backup in
            Text("Do you want to apply '\(backup.name)' now? This will overwrite your current data and the app will need to restart.")
        }
        .alert("Restart Required", isPresented: $viewModel.showingRestartAlert) {
            Button("Restart Portal") {
                exit(0)
            }
        } message: {
            Text("Backup restored successfully! Portal needs to restart to apply all changes.")
        }
        .alert("Enter Backup Password", isPresented: $viewModel.showingPasswordPrompt) {
            SecureField("Password", text: $viewModel.passwordInput)
                .textContentType(.password)
                .keyboardType(.default)
            Button("Cancel", role: .cancel) {
                viewModel.onPasswordSubmit?("")
            }
            Button("OK") {
                viewModel.onPasswordSubmit?(viewModel.passwordInput)
                viewModel.passwordInput = ""
            }
        } message: {
            Text("This backup is encrypted. Please enter the password to import it.")
        }
        .alert("Export Backup", isPresented: $viewModel.showingExportPrompt) {
            Button("Yes, with Password (Don't)") {
                viewModel.onExportSubmit?(true)
            }
            Button("No, Decrypt First") {
                viewModel.onExportSubmit?(false)
            }
            Button("Cancel", role: .cancel) {
                viewModel.onExportSubmit?(nil)
            }
        } message: {
            Text("Do you want to export this backup with password protection? This will break the backup file, fix soon!")
        }
        .onAppear {
            viewModel.loadBackups()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func backupRow(backup: LocalBackup) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(backup.date, style: .date)
                    Text("•")
                    Text(backup.date, style: .time)
                    Text("•")
                    Text(backup.sizeString)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                backupToRename = backup
                newBackupName = backup.name
                showingRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                Task {
                    await viewModel.exportBackup(backup)
                }
            } label: {
                Label("Export As Backup", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive) {
                if let index = viewModel.localBackups.firstIndex(where: { $0.id == backup.id }) {
                    viewModel.deleteBackups(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func featureCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
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
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func backupItemRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Constants
private let kOTPExpirationSeconds = 300 // 5 minutes
private let kBackupMarkerContent = "PORTAL_SELF_BACKUP"
private let kBackupMarkerFilename = "PORTAL_BACKUP_MARKER.txt"

// MARK: - Local Backup Model
struct LocalBackup: Identifiable, Codable {
    let id: UUID
    var name: String
    let date: Date
    let size: Int64
    let path: String
    var isEncrypted: Bool?
    
    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Self Backup Restore View Model
@MainActor
class SelfBackupRestoreViewModel: ObservableObject {
    @Published var localBackups: [LocalBackup] = []
    @Published var isCreatingBackup = false
    @Published var isRestoring = false
    @Published var currentOperation = ""
    @Published var operationProgress: Double = 0
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var showingApplyBackupPrompt = false
    @Published var backupToApply: LocalBackup?
    @Published var showingRestartAlert = false

    @Published var showingPasswordPrompt = false
    @Published var passwordInput = ""
    var onPasswordSubmit: ((String) -> Void)?

    @Published var showingExportPrompt = false
    var onExportSubmit: ((Bool?) -> Void)?

    private let fileManager = FileManager.default
    private let backupsDirectory: URL
    private let password = "PortalLocalBackup2026"
    
    var totalBackupSize: String {
        let totalBytes = localBackups.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    init() {
        // Create backups directory in app's documents
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        backupsDirectory = documentsURL.appendingPathComponent("LocalBackups")
        
        try? fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
    }
    
    func loadBackups() {
        do {
            let metadataFile = backupsDirectory.appendingPathComponent("backups_metadata.json")
            if fileManager.fileExists(atPath: metadataFile.path) {
                let data = try Data(contentsOf: metadataFile)
                localBackups = try JSONDecoder().decode([LocalBackup].self, from: data)
                
                // Remove backups whose files no longer exist
                localBackups = localBackups.filter { backup in
                    fileManager.fileExists(atPath: backup.path)
                }
                
                saveMetadata()
            }
        } catch {
            AppLogManager.shared.error("Failed to load backups metadata: \(error.localizedDescription)", category: "Self Backup")
        }
    }
    
    func createBackup(with options: BackupOptions) async {
        isCreatingBackup = true
        currentOperation = "Preparing Backup"
        operationProgress = 0
        
        do {
            // Create temporary backup directory
            let backupID = UUID()
            let timestamp = Date()
            let tempBackupDir = fileManager.temporaryDirectory.appendingPathComponent("SelfBackup_\(backupID.uuidString)")
            try fileManager.createDirectory(at: tempBackupDir, withIntermediateDirectories: true)
            
            // Collect backup data (similar to BackupRestoreView logic)
            operationProgress = 0.1
            currentOperation = "Collecting Data"
            
            try await collectBackupData(to: tempBackupDir, options: options)
            
            operationProgress = 0.5
            currentOperation = "Creating Archive"
            
            // Create ZIP archive using a more robust manual approach
            let backupZipPath = backupsDirectory.appendingPathComponent("\(backupID.uuidString).zip")

            // Use a nested scope to ensure Archive is finalized before reading it back
            try await Task.detached { [weak self, tempBackupDir] in
                guard let self = self else { return }
                guard let archive = Archive(url: backupZipPath, accessMode: .create) else {
                    throw NSError(domain: "SelfBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create archive at \(backupZipPath.path)"])
                }

                // Add files individually for better error handling and recursion
                let fileManager = FileManager.default
                let enumerator = fileManager.enumerator(at: tempBackupDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                var filesToZip: [URL] = []
                while let fileURL = enumerator?.nextObject() as? URL {
                    filesToZip.append(fileURL)
                }

                for (index, fileURL) in filesToZip.enumerated() {
                    let progress = 0.5 + (Double(index) / Double(filesToZip.count)) * 0.3
                    let relativePath = fileURL.path.replacingOccurrences(of: tempBackupDir.path + "/", with: "")

                    await MainActor.run { [weak self] in
                        self?.operationProgress = progress
                        self?.currentOperation = "Zipping: \(relativePath)"
                    }

                    do {
                        try archive.addEntry(with: relativePath, relativeTo: tempBackupDir)
                    } catch {
                        AppLogManager.shared.error("Failed to add \(relativePath) to archive: \(error.localizedDescription)", category: "Self Backup")
                    }
                }
            }.value
            
            operationProgress = 0.8
            currentOperation = "Encrypting Backup"
            
            var backupPassword: String? = nil
            if options.usePassword {
                // Generate a random password
                let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                backupPassword = String((0..<12).map{ _ in letters.randomElement()! })

                // Save to Keychain
                try KeychainManager.shared.save(backupPassword!, account: "backup_\(backupID.uuidString)")
            }

            // Encrypt the backup - Avoid JSON overhead for large files
            let zipData = try Data(contentsOf: backupZipPath, options: .mappedIfSafe)
            let encryptedData = try encryptData(zipData, with: backupPassword)
            try encryptedData.write(to: backupZipPath)
            
            operationProgress = 0.9
            currentOperation = "Finalizing"
            
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: backupZipPath.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Create backup metadata
            let backup = LocalBackup(
                id: backupID,
                name: "Backup \(timestamp.formatted(date: .abbreviated, time: .shortened))",
                date: timestamp,
                size: fileSize,
                path: backupZipPath.path,
                isEncrypted: options.usePassword
            )
            
            localBackups.append(backup)
            localBackups.sort { $0.date > $1.date }
            
            saveMetadata()
            
            // Clean up temp directory
            try? fileManager.removeItem(at: tempBackupDir)
            
            operationProgress = 1.0
            currentOperation = "Backup Completed"
            
            if let password = backupPassword {
                successMessage = "Backup Created Successfully!\n\nBackup Password: \(password)\n\nPlease save this password to restore your backup on other devices."
            } else {
                successMessage = "Backup Created Successfully!"
            }
            showSuccess = true
            
        } catch {
            errorMessage = "Failed To Create Backup: \(error.localizedDescription)"
            showError = true
            AppLogManager.shared.error("Backup creation failed: \(error.localizedDescription)", category: "Self Backup")
        }
        
        isCreatingBackup = false
        operationProgress = 0
    }
    
    func restoreBackup(_ backup: LocalBackup) async {
        isRestoring = true
        currentOperation = "Loading Backup"
        operationProgress = 0
        
        do {
            guard fileManager.fileExists(atPath: backup.path) else {
                throw NSError(domain: "SelfBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Backup file not found."])
            }
            
            operationProgress = 0.1
            currentOperation = "Decrypting Backup"
            
            let fileData = try Data(contentsOf: URL(fileURLWithPath: backup.path))
            let decryptedData: Data

            if backup.isEncrypted == true {
                // Try Keychain first
                var backupPassword = try? KeychainManager.shared.retrieve(account: "backup_\(backup.id.uuidString)")

                // If not in Keychain, prompt
                if backupPassword == nil {
                    backupPassword = await promptForPassword()
                    guard let pwd = backupPassword, !pwd.isEmpty else {
                        isRestoring = false
                        return
                    }
                    // Save to Keychain for next time
                    try? KeychainManager.shared.save(pwd, account: "backup_\(backup.id.uuidString)")
                    backupPassword = pwd
                }

                decryptedData = try decryptData(fileData, with: backupPassword)
            } else {
                // Handle potentially old encrypted backups or plain ZIPs
                if fileData.starts(with: "PORTAL_ENC".data(using: .utf8)!) {
                    decryptedData = try decryptData(fileData, with: nil)
                } else {
                    // Try to decrypt with default password (old style)
                    if let decrypted = try? decryptData(fileData, with: nil) {
                        decryptedData = decrypted
                    } else {
                        // Plain ZIP
                        decryptedData = fileData
                    }
                }
            }
            
            operationProgress = 0.3
            currentOperation = "Extracting Backup"
            
            // Create temp directory for extraction
            let tempRestoreDir = fileManager.temporaryDirectory.appendingPathComponent("Restore_\(UUID().uuidString)")
            try fileManager.createDirectory(at: tempRestoreDir, withIntermediateDirectories: true)
            
            // Write decrypted data to temp file
            let tempZipFile = tempRestoreDir.appendingPathComponent("backup.zip")
            try decryptedData.write(to: tempZipFile)
            
            // Extract ZIP
            let extractedDir = tempRestoreDir.appendingPathComponent("extracted")
            try fileManager.unzipItem(at: tempZipFile, to: extractedDir)
            
            operationProgress = 0.5
            currentOperation = "Restoring Data..."
            
            // Restore the data
            try await restoreBackupData(from: extractedDir)
            
            operationProgress = 0.9
            currentOperation = "Cleaning Up..."
            
            // Clean up temp directory
            try? fileManager.removeItem(at: tempRestoreDir)
            
            operationProgress = 1.0
            currentOperation = "Restore Completed"
            
            showingRestartAlert = true
        } catch {
            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
            showError = true
            AppLogManager.shared.error("Backup restoration failed: \(error.localizedDescription)", category: "Self Backup")
        }
        
        isRestoring = false
        operationProgress = 0
    }
    
    func deleteBackups(at indexSet: IndexSet) {
        for index in indexSet {
            let backup = localBackups[index]
            try? fileManager.removeItem(atPath: backup.path)
        }
        localBackups.remove(atOffsets: indexSet)
        saveMetadata()
    }
    
    func renameBackup(_ backup: LocalBackup, to newName: String) {
        guard let index = localBackups.firstIndex(where: { $0.id == backup.id }) else { return }
        
        var updatedBackup = backup
        updatedBackup.name = newName
        localBackups[index] = updatedBackup
        saveMetadata()
    }
    
    func exportBackup(_ backup: LocalBackup) async {
        guard fileManager.fileExists(atPath: backup.path) else {
            errorMessage = "Backup File Not Found"
            showError = true
            return
        }
        
        let usePassword = await promptForExportEncryption()
        guard let usePassword = usePassword else { return }

        do {
            let sourceURL = URL(fileURLWithPath: backup.path)
            // Sanitize filename by removing invalid characters
            let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
            let sanitizedName = backup.name.components(separatedBy: invalidCharacters).joined(separator: "_")
            let fileName = "\(sanitizedName).backup"
            let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            if usePassword {
                // Just copy the already encrypted file
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            } else {
                // Decrypt first
                let fileData = try Data(contentsOf: sourceURL)
                let decryptedData: Data

                if backup.isEncrypted == true {
                    var backupPassword = try? KeychainManager.shared.retrieve(account: "backup_\(backup.id.uuidString)")
                    if backupPassword == nil {
                        backupPassword = await promptForPassword()
                        if backupPassword?.isEmpty == true { return }
                    }
                    decryptedData = try decryptData(fileData, with: backupPassword)
                } else {
                    // Check if it's an old encrypted style or already a ZIP
                    if let decrypted = try? decryptData(fileData, with: nil) {
                        decryptedData = decrypted
                    } else {
                        decryptedData = fileData
                    }
                }

                try decryptedData.write(to: destinationURL)
            }
            
            // Present share sheet
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [destinationURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var topVC = rootVC
                    while let presentedVC = topVC.presentedViewController {
                        topVC = presentedVC
                    }
                    topVC.present(activityVC, animated: true)
                }
            }
        } catch {
            errorMessage = "Failed to export backup: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func importBackup(from url: URL) async {
        do {
            // Access the security-scoped resource
            let isSecurityScoped = url.startAccessingSecurityScopedResource()
            defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }
            
            // Copy to backups directory
            let backupID = UUID()
            let destinationURL = backupsDirectory.appendingPathComponent("\(backupID.uuidString).zip")

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            
            // Check if encrypted
            let fileData = try Data(contentsOf: destinationURL)
            let header = "PORTAL_ENC".data(using: .utf8)!
            let isEncrypted = fileData.starts(with: header)

            var passwordToStore: String? = nil
            if isEncrypted {
                // Prompt for password
                let password = await promptForPassword()
                guard !password.isEmpty else {
                    try? fileManager.removeItem(at: destinationURL)
                    return
                }

                // Verify password
                do {
                    _ = try decryptData(fileData, with: password)
                    passwordToStore = password
                } catch {
                    try? fileManager.removeItem(at: destinationURL)
                    errorMessage = "Incorrect password for backup."
                    showError = true
                    return
                }
            }

            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Create backup metadata
            let fileName = url.deletingPathExtension().lastPathComponent
            // Sanitize filename by removing invalid characters
            let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
            let sanitizedName = fileName.components(separatedBy: invalidCharacters).joined(separator: "_")
            let backup = LocalBackup(
                id: backupID,
                name: sanitizedName.isEmpty ? "Imported Backup" : sanitizedName,
                date: Date(),
                size: fileSize,
                path: destinationURL.path,
                isEncrypted: isEncrypted
            )
            
            if let password = passwordToStore {
                try? KeychainManager.shared.save(password, account: "backup_\(backupID.uuidString)")
            }

            localBackups.append(backup)
            localBackups.sort { $0.date > $1.date }
            saveMetadata()
            
            backupToApply = backup
            showingApplyBackupPrompt = true
        } catch {
            errorMessage = "Failed to import backup: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func promptForPassword() async -> String {
        await withCheckedContinuation { continuation in
            onPasswordSubmit = { password in
                continuation.resume(returning: password)
            }
            showingPasswordPrompt = true
        }
    }

    private func promptForExportEncryption() async -> Bool? {
        await withCheckedContinuation { continuation in
            onExportSubmit = { useEncryption in
                continuation.resume(returning: useEncryption)
            }
            showingExportPrompt = true
        }
    }

    // MARK: - Private Helpers
    
    private func saveMetadata() {
        do {
            let metadataFile = backupsDirectory.appendingPathComponent("backups_metadata.json")
            let data = try JSONEncoder().encode(localBackups)
            try data.write(to: metadataFile)
        } catch {
            AppLogManager.shared.error("Failed to save backups metadata: \(error.localizedDescription)", category: "Self Backup")
        }
    }
    
    private func collectBackupData(to directory: URL, options: BackupOptions) async throws {
        // This implementation mirrors the prepareBackup logic from BackupRestoreView
        
        // Certificates
        if options.includeCertificates {
            let certsDir = directory.appendingPathComponent("certificates")
            try fileManager.createDirectory(at: certsDir, withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: fileManager.certificates.path) {
                let certFiles = try fileManager.contentsOfDirectory(at: fileManager.certificates, includingPropertiesForKeys: nil)
                for certFile in certFiles {
                    let destURL = certsDir.appendingPathComponent(certFile.lastPathComponent)
                    try? fileManager.copyItem(at: certFile, to: destURL)
                }
            }
        }
        
        // Signed Apps
        if options.includeSignedApps {
            let signedDir = directory.appendingPathComponent("signed_apps")
            try fileManager.createDirectory(at: signedDir, withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: fileManager.signed.path) {
                let signedApps = try fileManager.contentsOfDirectory(at: fileManager.signed, includingPropertiesForKeys: nil)
                for appDir in signedApps {
                    let destURL = signedDir.appendingPathComponent(appDir.lastPathComponent)
                    try? fileManager.copyItem(at: appDir, to: destURL)
                }
            }
        }
        
        // Imported Apps
        if options.includeImportedApps {
            let importedDir = directory.appendingPathComponent("imported_apps")
            try fileManager.createDirectory(at: importedDir, withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: fileManager.unsigned.path) {
                let importedApps = try fileManager.contentsOfDirectory(at: fileManager.unsigned, includingPropertiesForKeys: nil)
                for appFile in importedApps {
                    let destURL = importedDir.appendingPathComponent(appFile.lastPathComponent)
                    try? fileManager.copyItem(at: appFile, to: destURL)
                }
            }
        }
        
        // Sources
        if options.includeSources {
            let sources = Storage.shared.getSources()
            let sourcesData = sources.map { ["url": $0.sourceURL?.absoluteString ?? "", "name": $0.name ?? "", "id": $0.identifier ?? ""] }
            let sourcesJSON = try JSONSerialization.data(withJSONObject: sourcesData)
            try sourcesJSON.write(to: directory.appendingPathComponent("sources.json"))
        }
        
        // Default Frameworks
        if options.includeDefaultFrameworks {
            let frameworksDir = directory.appendingPathComponent("default_frameworks")
            let frameworksSource = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
            if fileManager.fileExists(atPath: frameworksSource.path) {
                try? fileManager.copyItem(at: frameworksSource, to: frameworksDir)
            }
        }
        
        // Archives
        if options.includeArchives {
            let archivesDir = directory.appendingPathComponent("archives")
            if fileManager.fileExists(atPath: fileManager.archives.path) {
                try? fileManager.copyItem(at: fileManager.archives, to: archivesDir)
            }
        }
        
        // Database
        let dbDir = directory.appendingPathComponent("database")
        try fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
        
        let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url
        if let storeURL = storeURL {
            try? fileManager.copyItem(at: storeURL, to: dbDir.appendingPathComponent(storeURL.lastPathComponent))
            
            // Copy WAL and SHM files if they exist
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            try? fileManager.copyItem(at: walURL, to: dbDir.appendingPathComponent(walURL.lastPathComponent))
            try? fileManager.copyItem(at: shmURL, to: dbDir.appendingPathComponent(shmURL.lastPathComponent))
        }
        
        // Settings (App Group)
        if let userDefaults = UserDefaults(suiteName: Storage.appGroupID) {
            let settingsDict = userDefaults.dictionaryRepresentation()
            let filteredSettings = settingsDict.filter { key, _ in
                !key.hasPrefix("NS") && !key.hasPrefix("Apple") && !key.hasPrefix("AK") && !key.hasPrefix("WebKit") && !key.hasPrefix("CPU") && !key.hasPrefix("metal")
            }
            let settingsPlist = try PropertyListSerialization.data(fromPropertyList: filteredSettings, format: .xml, options: 0)
            try settingsPlist.write(to: directory.appendingPathComponent("settings.plist"))
        }

        // Settings (Standard)
        let standardDefaults = UserDefaults.standard.dictionaryRepresentation()
        let filteredStandard = standardDefaults.filter { key, _ in
            !key.hasPrefix("NS") && !key.hasPrefix("Apple") && !key.hasPrefix("AK") && !key.hasPrefix("WebKit") && !key.hasPrefix("CPU") && !key.hasPrefix("metal")
        }
        let standardPlist = try PropertyListSerialization.data(fromPropertyList: filteredStandard, format: .xml, options: 0)
        try standardPlist.write(to: directory.appendingPathComponent("standard_settings.plist"))
        
        // Marker file
        try kBackupMarkerContent.write(to: directory.appendingPathComponent(kBackupMarkerFilename), atomically: true, encoding: .utf8)
    }
    
    private func restoreBackupData(from directory: URL) async throws {
        // Verify marker file
        let markerFile = directory.appendingPathComponent(kBackupMarkerFilename)
        guard fileManager.fileExists(atPath: markerFile.path) else {
            throw NSError(domain: "SelfBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Backup File"])
        }
        
        // Restore certificates
        let certsDir = directory.appendingPathComponent("certificates")
        if fileManager.fileExists(atPath: certsDir.path) {
            let certFiles = try fileManager.contentsOfDirectory(at: certsDir, includingPropertiesForKeys: nil)
            for certFile in certFiles {
                let destURL = fileManager.certificates.appendingPathComponent(certFile.lastPathComponent)
                try? fileManager.copyItem(at: certFile, to: destURL)
            }
        }
        
        // Restore signed apps
        let signedDir = directory.appendingPathComponent("signed_apps")
        if fileManager.fileExists(atPath: signedDir.path) {
            let signedApps = try fileManager.contentsOfDirectory(at: signedDir, includingPropertiesForKeys: nil)
            for appDir in signedApps {
                let destURL = fileManager.signed.appendingPathComponent(appDir.lastPathComponent)
                try? fileManager.copyItem(at: appDir, to: destURL)
            }
        }
        
        // Restore imported apps
        let importedDir = directory.appendingPathComponent("imported_apps")
        if fileManager.fileExists(atPath: importedDir.path) {
            let importedApps = try fileManager.contentsOfDirectory(at: importedDir, includingPropertiesForKeys: nil)
            for appFile in importedApps {
                let destURL = fileManager.unsigned.appendingPathComponent(appFile.lastPathComponent)
                try? fileManager.copyItem(at: appFile, to: destURL)
            }
        }
        
        // Restore sources (would need to import into Core Data)
        let sourcesFile = directory.appendingPathComponent("sources.json")
        if fileManager.fileExists(atPath: sourcesFile.path) {
            let sourcesData = try Data(contentsOf: sourcesFile)
            if let sourcesArray = try JSONSerialization.jsonObject(with: sourcesData) as? [[String: String]] {
                for sourceDict in sourcesArray {
                    if let urlString = sourceDict["url"], let name = sourceDict["name"], !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        Storage.shared.addSource(url, name: name, identifier: urlString, iconURL: nil, deferSave: true) { _ in }
                    }
                }
                Storage.shared.saveContext()
            }
        }
        
        // Restore default frameworks
        let frameworksDir = directory.appendingPathComponent("default_frameworks")
        if fileManager.fileExists(atPath: frameworksDir.path) {
            let destDir = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
            try? fileManager.removeItem(at: destDir)
            try? fileManager.copyItem(at: frameworksDir, to: destDir)
        }
        
        // Restore archives
        let archivesDir = directory.appendingPathComponent("archives")
        if fileManager.fileExists(atPath: archivesDir.path) {
            try? fileManager.removeItem(at: fileManager.archives)
            try? fileManager.copyItem(at: archivesDir, to: fileManager.archives)
        }
        
        // Restore settings (App Group)
        let settingsFile = directory.appendingPathComponent("settings.plist")
        if fileManager.fileExists(atPath: settingsFile.path) {
            let settingsData = try Data(contentsOf: settingsFile)
            if let settings = try PropertyListSerialization.propertyList(from: settingsData, format: nil) as? [String: Any] {
                if let userDefaults = UserDefaults(suiteName: Storage.appGroupID) {
                    for (key, value) in settings {
                        userDefaults.set(value, forKey: key)
                    }
                    userDefaults.synchronize()
                }
            }
        }

        // Restore settings (Standard)
        let standardFile = directory.appendingPathComponent("standard_settings.plist")
        if fileManager.fileExists(atPath: standardFile.path) {
            let standardData = try Data(contentsOf: standardFile)
            if let standardSettings = try PropertyListSerialization.propertyList(from: standardData, format: nil) as? [String: Any] {
                let standardDefaults = UserDefaults.standard
                for (key, value) in standardSettings {
                    standardDefaults.set(value, forKey: key)
                }
                standardDefaults.synchronize()
            }
        }
    }
    
    private func encryptData(_ data: Data, with customPassword: String? = nil) throws -> Data {
        let encryptionPassword = customPassword ?? password
        let key = SymmetricKey(data: SHA256.hash(data: encryptionPassword.data(using: .utf8)!))

        // Use direct binary format for better efficiency
        let sealedBox = try AES.GCM.seal(data, using: key)

        // Add a magic header to identify binary encrypted backups (v2)
        var combined = "PORTAL_V2".data(using: .utf8)!
        combined.append(sealedBox.combined!)
        return combined
    }
    
    private func decryptData(_ encryptedData: Data, with customPassword: String? = nil) throws -> Data {
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
}

// MARK: - Restore Selection View
struct RestoreSelectionView: View {
    let backups: [LocalBackup]
    let onRestore: (LocalBackup) -> Void
    
    var body: some View {
        List {
            ForEach(backups) { backup in
                Button {
                    onRestore(backup)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(backup.name)
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Text(backup.date, style: .date)
                            Text("•")
                            Text(backup.date, style: .time)
                            Text("•")
                            Text(backup.sizeString)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Modern Restore Selection View
@available(iOS 17.0, *)
struct ModernRestoreSelectionView: View {
    let backups: [LocalBackup]
    let onRestore: (LocalBackup) -> Void
    
    var body: some View {
        List {
            if backups.isEmpty {
                ContentUnavailableView(
                    "No Backups",
                    systemImage: "archivebox",
                    description: Text("Create a backup first before you can restore.")
                )
            } else {
                Section {
                    ForEach(backups) { backup in
                        Button {
                            onRestore(backup)
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "archivebox.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                        Text(backup.date, style: .date)
                                        Text("•")
                                        Text(backup.date, style: .time)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "internaldrive")
                                            .font(.caption2)
                                        Text(backup.sizeString)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Select A Backup To Restore")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
    }
}

// MARK: - Legacy Restore Selection View (iOS 16 compatibility)
struct LegacyRestoreSelectionView: View {
    let backups: [LocalBackup]
    let onRestore: (LocalBackup) -> Void
    
    var body: some View {
        List {
            if backups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No Backups")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Create a backup first before you can restore.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(backups) { backup in
                        Button {
                            onRestore(backup)
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "archivebox.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                        Text(backup.date, style: .date)
                                        Text("•")
                                        Text(backup.date, style: .time)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "internaldrive")
                                            .font(.caption2)
                                        Text(backup.sizeString)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Select A Backup To Restore")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
    }
}
