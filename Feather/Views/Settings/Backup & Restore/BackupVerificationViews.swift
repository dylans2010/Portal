import SwiftUI

// MARK: - Backup Verification Results View

struct BackupVerificationResultsView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let entries: [BackupVerificationEntry]
    let isVerifying: Bool
    let lastVerified: Date?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if isVerifying {
                Section {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Verifying backups…")
                            .font(.subheadline)
                    }
                }
            }

            if !entries.isEmpty {
                Section {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.backupName)
                                    .font(.headline)
                                Spacer()
                                statusBadge(for: entry.status)
                            }

                            Text(entry.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let checksum = entry.fileChecksum {
                                HStack(spacing: 4) {
                                    Text("SHA-256:")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(String(checksum.prefix(24)) + "…")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            if let sig = entry.sessionSignature {
                                HStack(spacing: 4) {
                                    Text("Signature:")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(String(sig.prefix(24)) + "…")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Text(entry.verifiedAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Results")
                } footer: {
                    let verified = entries.filter { $0.status == .verified }.count
                    Text("\(verified) of \(entries.count) backups verified successfully.")
                }
            } else if !isVerifying {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Verification Results")
                            .font(.headline)
                        Text("Run a verification from the Backup & Restore screen to check your backups.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }

            if let date = lastVerified {
                Section {
                    HStack {
                        Text("Last Verification")
                        Spacer()
                        Text(date, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Verification Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for status: BackupVerificationStatus) -> some View {
        let (text, color, icon): (String, Color, String) = {
            switch status {
            case .verified:
                return ("Verified", .green, "checkmark.circle.fill")
            case .failed:
                return ("Failed", .red, "xmark.circle.fill")
            case .noSession:
                return ("No Session", .orange, "exclamationmark.triangle.fill")
            case .tampered:
                return ("Tampered", .red, "exclamationmark.shield.fill")
            }
        }()

        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
    }
}

// MARK: - Backup Chain Validation View

struct BackupChainValidationView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let validation: BackupChainValidation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chain Status")
                            .font(.headline)
                        Text(validation.isChainIntact ? "All chain links are intact" : "Broken chain links detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: validation.isChainIntact ? "link.circle.fill" : "link.badge.plus")
                        .font(.title2)
                        .foregroundStyle(validation.isChainIntact ? .green : .red)
                }
                .padding(.vertical, 4)
            }

            Section {
                chainStatRow(label: "Total Backups", value: "\(validation.totalBackups)", icon: "archivebox.fill", color: .blue)
                chainStatRow(label: "Full Backups", value: "\(validation.fullBackups)", icon: "doc.fill", color: .indigo)
                chainStatRow(label: "Incremental Backups", value: "\(validation.incrementalBackups)", icon: "doc.on.doc.fill", color: .teal)
                chainStatRow(label: "Valid Chain Links", value: "\(validation.validChainLinks)", icon: "checkmark.circle.fill", color: .green)
                chainStatRow(label: "Broken Links", value: "\(validation.brokenLinks)", icon: "xmark.circle.fill", color: validation.brokenLinks > 0 ? .red : .secondary)
            } header: {
                Text("Chain Statistics")
            }

            if !validation.orphanedBackups.isEmpty {
                Section {
                    ForEach(validation.orphanedBackups) { backup in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backup.name)
                                .font(.subheadline.weight(.semibold))
                            if let parentID = backup.parentSnapshotID {
                                HStack(spacing: 4) {
                                    Text("Missing parent:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(parentID)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Orphaned Backups")
                } footer: {
                    Text("These incremental backups reference parent snapshots that no longer exist. Consider creating a new full backup.")
                }
            }
        }
        .navigationTitle("Chain Validation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func chainStatRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}
