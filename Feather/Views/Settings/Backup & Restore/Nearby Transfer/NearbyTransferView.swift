import SwiftUI
import NimbleViews

// MARK: - Nearby Transfer View
struct NearbyTransferView: View {
    @Environment(\.dismiss) var dismiss
    @State private var appearAnimation = false
    
    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        // Animated background glow
                        Circle()
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .scaleEffect(appearAnimation ? 1.2 : 0.8)

                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .pulseEffect(appearAnimation)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Text(.localized("Portal Transfer"))
                            .font(.system(.title, design: .rounded, weight: .bold))
                        
                        Text(.localized("Move your data between devices instantly using a secure, direct connection."))
                            .font(.system(.subheadline, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
            }
            
            // Quick Start Section
            Section {
                NavigationLink(destination: PairingView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "bolt.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Start New Transfer"))
                                .font(.system(.headline, design: .rounded))
                            Text(.localized("Send or receive data securely"))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.clear)
                        .padding(.horizontal, 8)
                )
            } header: {
                Text(.localized("Actions"))
            }
            
            // How It Works Section
            Section {
                featureCard(
                    icon: "lock.shield.fill",
                    iconColor: .green,
                    title: .localized("End-to-End Security"),
                    description: .localized("All transfers are encrypted and happen directly between your devices. Your data never leaves your local network.")
                )
                
                featureCard(
                    icon: "wifi.router.fill",
                    iconColor: .blue,
                    title: .localized("Direct Connection"),
                    description: .localized("Uses Multipeer Connectivity to establish a fast, direct link via Wi-Fi or Bluetooth without needing the internet.")
                )
                
                featureCard(
                    icon: "speedometer",
                    iconColor: .orange,
                    title: .localized("Lightning Fast"),
                    description: .localized("High-speed data transfer with real-time progress monitoring, speed reporting, and automatic error recovery.")
                )
            } header: {
                Text(.localized("Why Portal Transfer?"))
            }
            
            // Requirements Section
            Section {
                requirementRow(
                    icon: "network",
                    text: .localized("Same Network: Both devices must be on the same Wi-Fi or within Bluetooth range.")
                )
                
                requirementRow(
                    icon: "iphone.gen2",
                    text: .localized("App Version: Both devices should have the latest Portal version for best compatibility.")
                )
                
                requirementRow(
                    icon: "battery.100.bolt",
                    text: .localized("Power: Ensure sufficient battery or connect to power for large backup transfers.")
                )
            } header: {
                Text(.localized("Requirements"))
            }
            
            // About Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(.localized("Supported Data Types"))
                        .font(.system(.headline, design: .rounded))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        transferItemRow(icon: "checkmark.seal.fill", text: .localized("Certificates"), color: .blue)
                        transferItemRow(icon: "app.badge.fill", text: .localized("Signed Apps"), color: .green)
                        transferItemRow(icon: "square.and.arrow.down.fill", text: .localized("Imported"), color: .orange)
                        transferItemRow(icon: "globe.fill", text: .localized("Sources"), color: .purple)
                        transferItemRow(icon: "puzzlepiece.extension.fill", text: .localized("Frameworks"), color: .cyan)
                        transferItemRow(icon: "gearshape.fill", text: .localized("Settings"), color: .gray)
                    }
                }
                .padding(.vertical, 12)
            } header: {
                Text(.localized("Details"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func featureCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func requirementRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.system(size: 18))
                .frame(width: 24)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func transferItemRow(icon: String, text: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .bold))
            }
            
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.primary.opacity(0.8))

            Spacer()
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}
