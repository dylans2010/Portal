import SwiftUI
import IDeviceSwift

// MARK: - Compact Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // App icon - fully visible
            FRAppIconView(app: app, size: 48)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Status label with symbol
            statusLabel
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Status Label
    @ViewBuilder
    private var statusLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(app.name ?? "App")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 6) {
                if viewModel.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Installed Successfully")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                } else if case .broken = viewModel.status {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.red)
                    Text("Installation Failed")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.accentColor)
                    Text(viewModel.statusLabel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
