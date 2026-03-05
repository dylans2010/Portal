import SwiftUI

struct BackupRestoreHeaderView: View {
    // MARK: - Body
    var body: some View {
        headerCard
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            backupIcon

            // Title
            Text(.localized("Backup & Restore"))
                .font(.title2).bold()
                .foregroundStyle(Color.accentColor)

            Text(.localized("Protect your Portal data by creating Backups files or restoring from previous backup sessions."))
                .font(.subheadline)
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var backupIcon: some View {
        ZStack {
            Color.accentColor.opacity(0.15)

            Image(systemName: "externaldrive.fill.badge.timemachine")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

#Preview {
    BackupRestoreHeaderView()
        .padding()
}
