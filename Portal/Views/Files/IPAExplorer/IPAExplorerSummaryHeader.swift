import SwiftUI

struct IPAExplorerSummaryHeader: View {
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

                    Text(summary.bundleId)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("\(summary.version) (\(summary.build))")
                        Spacer()
                        Text("iOS \(summary.minOS)+")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.clear)
            .cornerRadius(12)

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
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .cornerRadius(8)
    }
}
