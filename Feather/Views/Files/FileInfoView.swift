import SwiftUI
import NimbleViews

// MARK: - FileInfoView
struct FileInfoView: View {
    let file: FileItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NBNavigationView(.localized("File Info"), displayMode: .inline) {
            ZStack {
                // Modern background
                LinearGradient(
                    colors: [
                        file.iconColor.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    // File icon and name header
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    file.iconColor.opacity(0.15),
                                                    file.iconColor.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: file.icon)
                                        .font(.system(size: 36))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [file.iconColor, file.iconColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .shadow(color: file.iconColor.opacity(0.25), radius: 8, x: 0, y: 4)
                                
                                VStack(spacing: 4) {
                                    Text(file.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(file.isDirectory ? .localized("Folder") : file.url.pathExtension.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(file.iconColor.opacity(0.12))
                                        )
                                }
                            }
                            .padding(.vertical, 10)
                            Spacer()
                        }
                    }
                    
                    Section {
                        InfoRow(label: .localized("Name"), value: file.name, icon: "tag.fill")
                        if !file.isDirectory {
                            InfoRow(label: .localized("Type"), value: file.url.pathExtension.uppercased(), icon: "doc.fill")
                        }
                        if let size = file.size {
                            InfoRow(label: .localized("Size"), value: size, icon: "externaldrive.fill")
                        }
                    } header: {
                        Label(.localized("General"), systemImage: "info.circle.fill")
                    }
                    
                    Section {
                        InfoRow(label: .localized("Path"), value: file.url.path, icon: "folder.fill", copyable: true)
                        if let modDate = file.modificationDate {
                            InfoRow(label: .localized("Modified"), value: formatDate(modDate), icon: "clock.fill")
                        }
                    } header: {
                        Label(.localized("Details"), systemImage: "list.bullet.rectangle")
                    }
                    
                    Section {
                        Button {
                            UIPasteboard.general.string = file.url.path
                            HapticsManager.shared.success()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text(.localized("Copy Path"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Label(.localized("Actions"), systemImage: "hand.tap.fill")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var copyable: Bool = false
    @State private var copied = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                Text(value)
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            if copyable {
                Button {
                    UIPasteboard.general.string = value
                    copied = true
                    HapticsManager.shared.success()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(copied ? .green : .blue)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
