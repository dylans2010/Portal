import SwiftUI

struct IPAExplorerSummaryHeader: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let summary: IPAExplorerViewModel.IPASummary
    let isModified: Bool
    let isValid: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if let icon = summary.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "app.fill").font(.largeTitle).foregroundStyle(.gray))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .themedText(.primary)

                    Text(summary.bundleId)
                        .font(.subheadline)
                        .themedText(.secondary)

                    HStack {
                        Text("\(summary.version) (\(summary.build))")
                        Spacer()
                        Text("iOS \(summary.minOS)+")
                    }
                    .font(.caption)
                    .themedText(.secondary)
                }
            }
            .padding()
            .themedCard()

            HStack {
                StatusBadge(
                    title: isValid && !isModified ? .localized("Ready for Signing") : (isModified ? .localized("Modified") : .localized("Incomplete")),
                    icon: isValid && !isModified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    color: isValid && !isModified ? .green : .orange
                )

                Spacer()

                if summary.isSigned {
                    StatusBadge(title: .localized("Signed"), icon: "signature", color: .blue)
                } else {
                    StatusBadge(title: .localized("Unsigned"), icon: "xmark.shield", color: .gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
                .themedText(.badge)
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: themeManager.resolvedColors.badgeBackground))
        .cornerRadius(8)
    }
}
