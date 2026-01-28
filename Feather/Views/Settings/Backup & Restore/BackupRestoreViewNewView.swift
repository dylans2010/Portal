import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

/// A simplified and focused view for managing app backups and restorations.
/// This view reuses the core logic provided by `BackupRestoreManager`.
struct BackupRestoreViewNewView: View {
    // MARK: - Properties
    @StateObject private var manager = BackupRestoreManager.shared
    @Environment(\.dismiss) private var dismiss

    // State for Backup flow
    @State private var isBackupOptionsPresented = false
    @State private var backupOptions = BackupOptions()
    @State private var backupDocument: BackupDocument?
    @State private var showExporter = false

    // State for Restore flow
    @State private var showImporter = false
    @State private var showRestoreDialog = false
    @State private var pendingRestoreURL: URL?

    // Feedback State
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var successMessage = ""

    // MARK: - Body
    var body: some View {
        NBList(.localized("Backup & Restore")) {
            // Header Section
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)

                        Image(systemName: "arrow.up.arrow.down.doc.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text(.localized("Backup & Restore"))
                            .font(.title.bold())

                        Text(.localized("Securely backup your certificates, apps, and settings. You can restore them at any time to recover your data."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Actions Section
            Section {
                Button {
                    isBackupOptionsPresented = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("Create Backup"))
                                    .font(.headline)
                                Text(.localized("Export your data to a secure file"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                Button {
                    showImporter = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("Import Backup"))
                                    .font(.headline)
                                Text(.localized("Restore data from a previous backup"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            } header: {
                Text(.localized("Manage Data"))
            } footer: {
                Text(.localized("Backups are saved as encrypted .zip files and can be stored in iCloud or locally."))
            }
        }
        // MARK: - Sheets & Modals
        .sheet(isPresented: $isBackupOptionsPresented) {
            BackupOptionsView(options: $backupOptions) {
                isBackupOptionsPresented = false
                handleCreateBackup()
            }
        }
        // Native File Exporter for saving the backup
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .zip,
            defaultFilename: "PortalBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
        ) { result in
            switch result {
            case .success(let url):
                AppLogManager.shared.success("Backup exported to: \(url.path)", category: "Backup")
                successMessage = String.localized("Backup saved successfully.")
                showSuccessAlert = true
                HapticsManager.shared.success()
            case .failure(let error):
                errorMessage = error.localizedDescription
                HapticsManager.shared.error()
            }

            // Cleanup temporary zip file
            if let tempURL = backupDocument?.url {
                try? FileManager.default.removeItem(at: tempURL)
            }
            backupDocument = nil
        }
        // Native File Importer for selecting a backup
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImportPicked(result: result)
        }
        // Confirmation for restoration as it requires app restart
        .alert(.localized("Restart Required"), isPresented: $showRestoreDialog) {
            Button(.localized("Cancel"), role: .cancel) { pendingRestoreURL = nil }
            Button(.localized("Proceed"), role: .destructive) {
                if let url = pendingRestoreURL {
                    handlePerformRestore(from: url)
                }
            }
        } message: {
            Text(.localized("Portal must restart to apply the restored data. Do you want to continue?"))
        }
        // Feedback Alerts
        .alert(.localized("Success"), isPresented: $showSuccessAlert) {
            Button(.localized("OK")) { }
        } message: {
            Text(successMessage)
        }
        .alert(.localized("Error"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(.localized("OK")) { }
        } message: {
            Text(errorMessage ?? "")
        }
        // Loading Overlay during restoration
        .overlay {
            if manager.isRestoring {
                RestoreLoadingOverlay(progress: manager.restoreProgress)
            }
        }
    }

    // MARK: - Helper Functions

    /// Triggers the backup creation logic via the Manager
    private func handleCreateBackup() {
        Task {
            do {
                let url = try await manager.prepareBackup(with: backupOptions)
                await MainActor.run {
                    self.backupDocument = BackupDocument(url: url)
                    self.showExporter = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Handles the file picked from the system importer
    private func handleImportPicked(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = String.localized("Permission denied for the selected file.")
                return
            }

            // Best practice: Copy to temporary directory for stable access
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                url.stopAccessingSecurityScopedResource()

                self.pendingRestoreURL = tempURL
                self.showRestoreDialog = true
            } catch {
                url.stopAccessingSecurityScopedResource()
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// Executes the restoration process
    private func handlePerformRestore(from url: URL) {
        Task {
            do {
                // Validate before restoration
                let isValid = try await manager.verifyBackup(at: url)
                if isValid {
                    try await manager.performRestore(from: url, restart: true)
                } else {
                    await MainActor.run {
                        errorMessage = String.localized("The selected file is not a valid Portal backup.")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }

            // Cleanup the temporary copy
            try? FileManager.default.removeItem(at: url)
        }
    }
}
