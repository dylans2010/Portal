import SwiftUI

// MARK: - Offline View
/// Displays when there is absolutely no WiFi or cellular data connection
struct OfflineView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.15),
                                Color.red.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.orange.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Title and message
            VStack(spacing: 12) {
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("You're not connected to the internet.\nPlease check your Wi-Fi or cellular data connection.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Connection type indicator
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: networkMonitor.connectionType.icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection Status")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(networkMonitor.connectionType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(networkMonitor.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal, 32)
            }
            
            // Troubleshooting tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Try:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                TroubleshootingTip(icon: "wifi", text: "Check your Wi-Fi connection")
                TroubleshootingTip(icon: "antenna.radiowaves.left.and.right", text: "Enable cellular data")
                TroubleshootingTip(icon: "airplane", text: "Disable Airplane Mode")
                TroubleshootingTip(icon: "arrow.clockwise", text: "Restart your device")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Retry connection info
            Text("Portal will automatically reconnect when internet is available.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            animateIcon = true
            AppLogManager.shared.warning("Offline view displayed - no internet connection available", category: "Network")
        }
    }
}

// MARK: - Troubleshooting Tip Row
struct TroubleshootingTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct OfflineView_Previews: PreviewProvider {
    static var previews: some View {
        OfflineView()
    }
}
#endif
