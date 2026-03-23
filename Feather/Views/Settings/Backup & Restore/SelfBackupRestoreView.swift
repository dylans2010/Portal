import SwiftUI
import NimbleViews
import ZIPFoundation
import CryptoKit
import UniformTypeIdentifiers

// MARK: - Self Backup Restore View
struct SelfBackupRestoreView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SelfBackupRestoreViewModel()
    @State private var showingBackupOptions = false
    @State private var showingRestoreList = false
    @State private var backupOptions = BackupOptions()
    @State private var showingDocumentPicker = false
    @State private var showingRenameAlert = false
    @State private var backupToRename: LocalBackup?
    @State private var newBackupName = ""
    @State private var showingSecureSessionSheet = false
    @State private var showingVerificationResults = false
    @State private var showingChainValidation = false
    @State private var chainValidation: BackupChainValidation?
    @AppStorage("feature_newBackupOptions") var newBackupOptions = false
    @ObservedObject private var advancedManager = BackupAdvancedManager.shared
    @ObservedObject private var secureBackupManager = SecureBackupSessionManager.shared
    @ObservedObject private var sessionManager = SecureTransferSessionManager.shared
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 72, height: 72)
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.top, 6)

                    Text(.localized("Create and restore backups locally on your device."))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                backupActionRow(
                    icon: "plus.circle.fill",
                    iconColor: .green,
                    title: .localized("Create Backup"),
                    subtitle: .localized("Save Your Current Data"),
                    action: { showingBackupOptions = true },
                    disabled: viewModel.isCreatingBackup || viewModel.isRestoring
                )

                backupActionRow(
                    icon: "arrow.counterclockwise.circle.fill",
                    iconColor: .blue,
                    title: .localized("Restore Backup"),
                    subtitle: .localized("Load Previously Saved Data"),
                    action: { showingRestoreList = true },
                    disabled: viewModel.isCreatingBackup || viewModel.isRestoring || viewModel.localBackups.isEmpty
                )

                backupActionRow(
                    icon: "folder.circle.fill",
                    iconColor: .purple,
                    title: .localized("Import Backup"),
                    subtitle: .localized("Import Backup File"),
                    action: { showingDocumentPicker = true },
                    disabled: viewModel.isCreatingBackup || viewModel.isRestoring
                )

                NavigationLink(destination: AutoBackupsView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "clock.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.orange)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Automatic Backups (Beta)"))
                                .font(.subheadline.weight(.semibold))
                            Text(.localized("Configure Schedule & Content"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(.localized("Quick Actions"))
            }

            if !viewModel.localBackups.isEmpty {
                Section {
                    ForEach(viewModel.localBackups) { backup in
                        NavigationLink(destination: BackupContentsView(
                            backupURL: URL(fileURLWithPath: backup.path),
                            isEncrypted: backup.isEncrypted ?? false,
                            backupID: backup.id
                        )) {
                            backupRow(backup: backup)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteBackups(at: indexSet)
                    }
                } header: {
                    Text(.localized("Saved Backups"))
                } footer: {
                    let count = viewModel.localBackups.count
                    let backupText = count == 1 ? "Backup" : "Backups"
                    return Text("\(count) \(backupText) \u{2022} \(viewModel.totalBackupSize)")
                }
            }

            if newBackupOptions {
                _storageUsageSection
                _advancedBackupSection
                _secureSessionSection
                _backupVerificationSection
            }

            if viewModel.isCreatingBackup || viewModel.isRestoring {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(viewModel.currentOperation)
                                .font(.subheadline.weight(.medium))
                        }

                        if viewModel.operationProgress > 0 {
                            ProgressView(value: viewModel.operationProgress)
                                .progressViewStyle(.linear)
                                .tint(.accentColor)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text(.localized("Status"))
                }
            }

            Section {
                featureInfoRow(icon: "arrow.triangle.2.circlepath.circle.fill", color: .green, title: .localized("Portable Format"), subtitle: .localized("Export and share backups between devices."))
                featureInfoRow(icon: "internaldrive.fill", color: .blue, title: .localized("Local Storage"), subtitle: .localized("Backups are stored locally on your device."))
            } header: {
                Text(.localized("Features"))
            }

            Section {
                includedItemRow(icon: "checkmark.seal.fill", color: .blue, title: "Certificates & Profiles")
                includedItemRow(icon: "app.fill", color: .green, title: "Signed Apps")
                includedItemRow(icon: "arrow.down.circle.fill", color: .orange, title: "Imported Apps")
                includedItemRow(icon: "globe", color: .purple, title: "Sources")
                includedItemRow(icon: "puzzlepiece.fill", color: .cyan, title: "Default Frameworks")
                includedItemRow(icon: "archivebox.fill", color: .indigo, title: "Archives")
                includedItemRow(icon: "gearshape.fill", color: .gray, title: "Settings")
            } header: {
                Text(.localized("What's Included"))
            }
        }
        .navigationTitle("Backup & Restore")
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
            Text("Do you want to apply '\(backup.name)' now? This will overwrite your current data and Portal will need to restart.")
        }
        .alert("Restart Required", isPresented: $viewModel.showingRestartAlert) {
            Button("Restart Portal") {
                exit(0)
            }
        } message: {
            Text("Backup restored successfully! Portal needs to restart to apply all changes.")
        }
        .onAppear {
            viewModel.loadBackups()
            advancedManager.refreshStats(backups: viewModel.localBackups)
            if newBackupOptions {
                secureBackupManager.refreshSessionBackupCount(backups: viewModel.localBackups)
            }
        }
        .sheet(isPresented: $showingSecureSessionSheet) {
            NavigationStack {
                SecureSessionStatusView(onStartTransfer: {
                    secureBackupManager.ensureSessionForBackup()
                    showingSecureSessionSheet = false
                })
            }
        }
        .sheet(isPresented: $showingVerificationResults) {
            NavigationStack {
                BackupVerificationResultsView(
                    entries: secureBackupManager.verificationLog,
                    isVerifying: secureBackupManager.isVerifying,
                    lastVerified: secureBackupManager.lastVerificationDate
                )
            }
        }
        .sheet(isPresented: $showingChainValidation) {
            if let validation = chainValidation {
                NavigationStack {
                    BackupChainValidationView(validation: validation)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var _storageUsageSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(.localized("Storage Usage"))
                        .font(.headline)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: advancedManager.usedStorage, countStyle: .file))
                        .font(.subheadline.bold())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * CGFloat(advancedManager.storagePercentage), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(String(format: "%.1f%% Consumed", advancedManager.storagePercentage * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(ByteCountFormatter.string(fromByteCount: advancedManager.availableStorage, countStyle: .file)) Available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(.localized("Backup Storage"))
        }
    }

    @ViewBuilder
    private var _advancedBackupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Snapshot Versioning"))
                            .font(.headline)
                        Text(.localized("Full and Incremental backups supported.")).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "clock.arrow.2.circlepath").foregroundStyle(.purple)
                }

                if let lastBackup = viewModel.localBackups.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("Latest Snapshot"))
                            .font(.caption.bold())
                        Text(lastBackup.snapshotID ?? lastBackup.id.uuidString)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)

                        if let type = lastBackup.snapshotType {
                            Text("Type: \(type.capitalized)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(.localized("Advanced Backup"))
        }
    }

    @ViewBuilder
    private var _secureSessionSection: some View {
        Section {
            // Session Status Summary
            if let session = sessionManager.currentSession {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: sessionManager.isSessionValid(session) ? "checkmark.shield.fill" : "xmark.shield.fill")
                                .foregroundStyle(sessionManager.isSessionValid(session) ? .green : .red)
                            Text(sessionManager.isSessionValid(session) ? "Session Active" : "Session Expired")
                                .font(.headline)
                        }

                        Text("Device: \(session.remoteDeviceName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Encryption: \(session.encryptionType)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Text("Fingerprint:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.sessionFingerprint)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        if secureBackupManager.sessionBackupCount > 0 {
                            Text("\(secureBackupManager.sessionBackupCount) backup(s) in this session")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer()

                    Button {
                        showingSecureSessionSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "shield.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text("No Secure Session")
                        .font(.headline)

                    Text("Create a secure session to enable backup signing, integrity verification, and session-based encryption.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        secureBackupManager.ensureSessionForBackup()
                    } label: {
                        Label("Create Session", systemImage: "plus.shield.checkmark.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // View Full Session Details
            Button {
                showingSecureSessionSheet = true
            } label: {
                Label {
                    Text("View Session Details")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "lock.doc")
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text(.localized("Secure Session"))
        } footer: {
            if sessionManager.currentSession != nil {
                Text("Backups created during an active session are signed with the session fingerprint for tamper detection.")
            }
        }
    }

    @ViewBuilder
    private var _backupVerificationSection: some View {
        Section {
            // Verify All Backups
            Button {
                Task {
                    await secureBackupManager.verifyAllBackups(viewModel.localBackups)
                    showingVerificationResults = true
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verify Backup Integrity")
                            .font(.headline)
                        Text("Check all backups against the current session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            .disabled(secureBackupManager.isVerifying || viewModel.localBackups.isEmpty)

            // Validate Backup Chain
            Button {
                chainValidation = secureBackupManager.validateBackupChain(viewModel.localBackups)
                showingChainValidation = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Validate Backup Chain")
                            .font(.headline)
                        Text("Verify incremental backup chain integrity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "link.badge.plus")
                        .foregroundStyle(.purple)
                }
            }
            .disabled(viewModel.localBackups.isEmpty)

            // Verification Status
            if let lastDate = secureBackupManager.lastVerificationDate {
                HStack {
                    Text("Last Verified")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lastDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Verified Backups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(secureBackupManager.verifiedBackupIDs.count) of \(viewModel.localBackups.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text(.localized("Backup Verification"))
        } footer: {
            Text("Integrity verification uses SHA-256 checksums and session-signed HMAC signatures to detect tampering.")
        }
    }

    @ViewBuilder
    private func backupActionRow(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(iconColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(disabled)
    }

    @ViewBuilder
    private func featureInfoRow(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func includedItemRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func backupRow(backup: LocalBackup) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(backup.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if backup.isAutomatic == true {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }

                    if newBackupOptions, let type = backup.snapshotType {
                        Text(type.prefix(1).uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(type == "full" ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                            .foregroundStyle(type == "full" ? .blue : .green)
                            .clipShape(Capsule())
                    }

                    if newBackupOptions && secureBackupManager.isBackupVerified(backup.id) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 6) {
                    Text(backup.date, style: .date)
                    Text("\u{2022}")
                    Text(backup.date, style: .time)
                    Text("\u{2022}")
                    Text(backup.sizeString)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            NavigationLink(destination: BackupContentsView(
                backupURL: URL(fileURLWithPath: backup.path),
                isEncrypted: backup.isEncrypted ?? false,
                backupID: backup.id
            )) {
                Label("View Backup Contents", systemImage: "eye")
            }

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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
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
        .padding(.vertical, 10)
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
    var isAutomatic: Bool?
    var snapshotID: String?
    var parentSnapshotID: String?
    var snapshotType: String?
    var changeSummary: String?
    
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

    private let fileManager = FileManager.default
    private let backupsDirectory: URL
    private let legacyPassword = "PortalLocalBackup2026"
    
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
            
            try await collectBackupData(to: tempBackupDir, options: options, backupID: backupID, timestamp: timestamp)
            
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
            
            operationProgress = 0.9
            currentOperation = "Finalizing"
            
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: backupZipPath.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Create backup metadata
            let parent = localBackups.first
            let changeSummary = BackupAdvancedManager.shared.generateChangeSummary(parent: parent, currentOptions: options)

            let backup = LocalBackup(
                id: backupID,
                name: "Backup \(timestamp.formatted(date: .abbreviated, time: .shortened))",
                date: timestamp,
                size: fileSize,
                path: backupZipPath.path,
                isEncrypted: false,
                snapshotID: backupID.uuidString,
                parentSnapshotID: parent?.snapshotID,
                snapshotType: options.snapshotType,
                changeSummary: changeSummary
            )
            
            localBackups.append(backup)
            localBackups.sort { $0.date > $1.date }
            
            saveMetadata()
            
            // Clean up temp directory
            try? fileManager.removeItem(at: tempBackupDir)
            
            operationProgress = 1.0
            currentOperation = "Backup Completed"
            
            successMessage = "Backup Created Successfully!"
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
            currentOperation = "Loading Backup"
            
            let fileData = try Data(contentsOf: URL(fileURLWithPath: backup.path))
            let decryptedData: Data

            // Handle both legacy encrypted backups and new plain ZIP backups
            if let decrypted = try? decryptData(fileData, with: nil) {
                decryptedData = decrypted
            } else {
                // Plain ZIP (new format)
                decryptedData = fileData
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

            // Decrypt legacy encrypted backups before export; plain ZIPs are exported as-is
            let fileData = try Data(contentsOf: sourceURL)
            if let decrypted = try? decryptData(fileData, with: nil) {
                try decrypted.write(to: destinationURL)
            } else {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
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
                isEncrypted: false
            )

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
    
    private func collectBackupData(to directory: URL, options: BackupOptions, backupID: UUID, timestamp: Date) async throws {
        // This implementation mirrors the prepareBackup logic from BackupRestoreView
        let isIncremental = options.snapshotType == "incremental"
        var currentManifest: [String: Int64] = [:] // relPath: size
        var parentManifest: [String: Int64] = [:]
        
        if isIncremental, let parent = localBackups.first {
            parentManifest = await BackupAdvancedManager.shared.loadManifest(from: URL(fileURLWithPath: parent.path))
        }

        // Certificates
        if options.includeCertificates {
            let certsDir = directory.appendingPathComponent("certificates")
            try fileManager.createDirectory(at: certsDir, withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: fileManager.certificates.path) {
                let certFiles = try fileManager.contentsOfDirectory(at: fileManager.certificates, includingPropertiesForKeys: [.fileSizeKey])
                for certFile in certFiles {
                    let relPath = "certificates/\(certFile.lastPathComponent)"
                    let size = Int64((try? certFile.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                    currentManifest[relPath] = size

                    if isIncremental && parentManifest[relPath] == size {
                        continue // Skip unchanged file
                    }

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
        
        // Manifest file
        let manifestData = try JSONSerialization.data(withJSONObject: currentManifest)
        try manifestData.write(to: directory.appendingPathComponent("manifest.json"))

        // Metadata Info file
        var includedDataTypes: [String] = ["database", "settings"]
        if options.includeCertificates { includedDataTypes.append("certificates") }
        if options.includeSignedApps { includedDataTypes.append("signedApps") }
        if options.includeImportedApps { includedDataTypes.append("importedApps") }
        if options.includeSources { includedDataTypes.append("sources") }
        if options.includeDefaultFrameworks { includedDataTypes.append("defaultFrameworks") }
        if options.includeArchives { includedDataTypes.append("archives") }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let isoFormatter = ISO8601DateFormatter()

        var metadataInfoDict: [String: Any] = [
            "backupID": backupID.uuidString,
            "backupDate": timestamp.timeIntervalSince1970,
            "backupDateString": isoFormatter.string(from: timestamp),
            "deviceModel": deviceModel,
            "systemVersion": systemVersion,
            "appVersion": appVersion,
            "appBuildNumber": buildNumber,
            "includedData": includedDataTypes,
            "backupFormatVersion": "3",  // v1: JSON+AES, v2: binary AES (PORTAL_V2), v3: plain ZIP with metadataInfo.json
            "snapshotType": options.snapshotType,
            "isIncremental": isIncremental
        ]

        // Embed secure session metadata if a session is active
        if let sessionMetadata = SecureBackupSessionManager.shared.createSessionMetadata(for: backupID) {
            metadataInfoDict["secureSession"] = sessionMetadata
        }

        let metadataInfoData = try JSONSerialization.data(withJSONObject: metadataInfoDict, options: [.prettyPrinted, .sortedKeys])
        try metadataInfoData.write(to: directory.appendingPathComponent("metadataInfo.json"))

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
    
    private func decryptData(_ encryptedData: Data, with customPassword: String? = nil) throws -> Data {
        let decryptionPassword = customPassword ?? legacyPassword
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
    @EnvironmentObject var themeManager: ThemeManager
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
            .scrollContentBackground(.hidden)
    }
}

// MARK: - Modern Restore Selection View
@available(iOS 17.0, *)
struct ModernRestoreSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
            .scrollContentBackground(.hidden)
    }
}

// MARK: - Legacy Restore Selection View (iOS 16 compatibility)
struct LegacyRestoreSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
            .scrollContentBackground(.hidden)
    }
}
