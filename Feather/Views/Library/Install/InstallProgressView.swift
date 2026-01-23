import SwiftUI
import IDeviceSwift

// MARK: - Compact Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon - simple, no effects
            FRAppIconView(app: app)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Status label with symbol
            statusLabel
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Status Label
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 6) {
            if viewModel.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.green)
                Text("Installed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.green)
            } else if case .broken = viewModel.status {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.red)
                Text("Failed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                Text(viewModel.statusLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
