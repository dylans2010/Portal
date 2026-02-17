import SwiftUI
import NimbleViews

struct QuickActionsSheetView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NBNavigationView(.localized("Quick Actions")) {
            ScrollView {
                VStack(spacing: 20) {
                    // Signer Tools
                    SectionHeader(title: "Signer Tools")

                    VStack(spacing: 12) {
                        QuickActionRow(
                            icon: "signature",
                            title: "Sign an App",
                            subtitle: "Select and sign an imported IPA",
                            color: .blue
                        ) {
                            dismiss()
                            NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.library)
                        }

                        QuickActionRow(
                            icon: "plus.app.fill",
                            title: "Add & Sign IPA",
                            subtitle: "Import and sign automatically",
                            color: .green
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://add-and-sign")!)
                        }
                    }

                    // Management
                    SectionHeader(title: "Management")

                    VStack(spacing: 12) {
                        QuickActionRow(
                            icon: "plus.circle.fill",
                            title: "Add Source",
                            subtitle: "Add a new repository",
                            color: .orange
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://add-source")!)
                        }

                        QuickActionRow(
                            icon: "checkmark.seal.fill",
                            title: "Add Certificate",
                            subtitle: "Import P12 and Provisioning",
                            color: .purple
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://add-certificate")!)
                        }
                    }

                    // Maintenance
                    SectionHeader(title: "Maintenance")

                    VStack(spacing: 12) {
                        QuickActionRow(
                            icon: "trash.fill",
                            title: "Clear Caches",
                            subtitle: "Free up disk space",
                            color: .red
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://clear-caches")!)
                        }

                        QuickActionRow(
                            icon: "doc.text.fill",
                            title: "Export Logs",
                            subtitle: "Share diagnostic information",
                            color: .gray
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://export-logs")!)
                        }

                        QuickActionRow(
                            icon: "app.badge.fill",
                            title: "Rebuild Icon Cache",
                            subtitle: "Fix broken app icons",
                            color: .cyan
                        ) {
                            dismiss()
                            UIApplication.shared.open(URL(string: "portal://rebuild-icon-cache")!)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            Spacer()
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
