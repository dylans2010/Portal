import SwiftUI

// MARK: - Transfer Progress View
struct TransferProgressView: View {
    @ObservedObject var service: NearbyTransferService
    let onCancel: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Main Status Visualization
                mainStatusView
                    .padding(.top, 20)
                
                // Detailed Info Section
                if case .transferring(let progress, let bytesTransferred, let totalBytes, let speed) = service.state {
                    modernTransferDetails(
                        progress: progress,
                        bytesTransferred: bytesTransferred,
                        totalBytes: totalBytes,
                        speed: speed
                    )
                } else {
                    staticStatusInfo
                }
                
                // Action Buttons
                actionButtons
                    .padding(.bottom, 30)
            }
            .padding(24)
        }
        .background(Color.clear.ignoresSafeArea())
    }
    
    // MARK: - Main Status View
    @ViewBuilder
    private var mainStatusView: some View {
        switch service.state {
        case .idle:
            modernStatusCard(icon: "antenna.radiowaves.left.and.right", title: "Ready", subtitle: "Establishing connection...", color: .blue)
        case .discovering:
            modernStatusCard(icon: "magnifyingglass", title: "Searching", subtitle: "Finding nearby devices...", color: .purple, isSearching: true)
        case .connecting:
            modernStatusCard(icon: "wifi", title: "Connecting", subtitle: service.currentItem.isEmpty ? "Securing link..." : service.currentItem, color: .orange, isConnecting: true)
        case .transferring(let progress, _, _, _):
            modernProgressCircle(progress: progress)
        case .completed:
            modernStatusCard(icon: "checkmark.seal.fill", title: "Success", subtitle: "Data transferred successfully!", color: .green)
        case .failed(let error):
            modernStatusCard(icon: "exclamationmark.triangle.fill", title: "Error", subtitle: error.localizedDescription, color: .red)
        }
    }

    // MARK: - Modern Progress Circle
    @ViewBuilder
    private func modernProgressCircle(progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: 16)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .shadow(color: .blue.opacity(0.3), radius: 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("Complete")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Modern Transfer Details
    @ViewBuilder
    private func modernTransferDetails(progress: Double, bytesTransferred: Int64, totalBytes: Int64, speed: Double) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                infoCard(icon: "arrow.up.arrow.down", label: "Progress", value: "\(formatBytes(bytesTransferred)) / \(formatBytes(totalBytes))", color: .blue)
                infoCard(icon: "speedometer", label: "Speed", value: formatSpeed(speed), color: .green)
            }

            HStack(spacing: 16) {
                if totalBytes > 0 && speed > 0 {
                    let remaining = Double(totalBytes - bytesTransferred) / speed
                    infoCard(icon: "clock.fill", label: "Remaining", value: formatTime(remaining), color: .orange)
                }

                if !service.currentItem.isEmpty {
                    infoCard(icon: "doc.fill", label: "Current", value: service.currentItem, color: .purple)
                }
            }
        }
    }
    
    @ViewBuilder
    private var staticStatusInfo: some View {
        if !service.currentItem.isEmpty {
            infoCard(icon: "info.circle.fill", label: "Status", value: service.currentItem, color: .blue)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Modern Status Card
    @ViewBuilder
    private func modernStatusCard(icon: String, title: String, subtitle: String, color: Color, isSearching: Bool = false, isConnecting: Bool = false) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 110, height: 110)
                
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if isSearching || isConnecting {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }
    
    // MARK: - Info Card
    @ViewBuilder
    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if case .transferring = service.state {
                actionButton(title: "Cancel Transfer", icon: "xmark", color: .red, action: onCancel)
            } else if service.canRetry {
                actionButton(title: "Retry Transfer", icon: "arrow.clockwise", color: .blue, action: onRetry)
            }
        }
    }
    
    @ViewBuilder
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
    
    // MARK: - Helpers
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(secs)s"
    }
}
