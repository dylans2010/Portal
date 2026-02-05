import SwiftUI
import NimbleViews

// MARK: - Nearby Transfer View
struct NearbyTransferView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        NBList(.localized("Nearby Transfer")) {
            // Modern Header Section with Animation
            Section {
                ZStack {
                    // Animated gradient background
                    LinearGradient(
                        colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 16) {
                        // Animated icon with pulse effect
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(isAnimating ? 1.2 : 1.0)
                                .opacity(isAnimating ? 0.0 : 0.5)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.pulse, options: .repeating)
                        }
                        
                        Text(.localized("Transfer backups wirelessly between devices"))
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    isAnimating = true
                }
            }
            
            // Modern Quick Start Section
            Section {
                NavigationLink(destination: PairingView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .symbolEffect(.bounce, options: .repeating.speed(0.5))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Start Transfer"))
                                .font(.headline.weight(.semibold))
                            Text(.localized("Send or receive a backup"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Quick Start"), icon: "bolt.fill")
            }
            
            // Modern Features Section
            Section {
                featureCard(
                    icon: "lock.shield.fill",
                    iconColor: .green,
                    title: .localized("Secure & Encrypted"),
                    description: .localized("All transfers are encrypted end-to-end using AES-256 encryption for maximum security.")
                )
                
                featureCard(
                    icon: "wifi",
                    iconColor: .blue,
                    title: .localized("No Internet Required"),
                    description: .localized("Transfer happens directly between devices using local Wi-Fi or Bluetooth.")
                )
                
                featureCard(
                    icon: "speedometer",
                    iconColor: .orange,
                    title: .localized("Fast & Reliable"),
                    description: .localized("Direct device-to-device transfer with real-time progress monitoring and speed reporting.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Features"), icon: "star.fill")
            }
            
            // Requirements Section
            Section {
                requirementRow(
                    icon: "network",
                    text: "Both devices must be on the same Wi-Fi network or within Bluetooth range"
                )
                
                requirementRow(
                    icon: "iphone.gen2",
                    text: "Both devices must have Portal installed"
                )
                
                requirementRow(
                    icon: "battery.100",
                    text: "Recommended to have sufficient battery or connect to power"
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Requirements"), icon: "checkmark.circle.fill")
            }
            
            // About Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.localized("What gets transferred?"))
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        transferItemRow(icon: "checkmark.seal.fill", text: "Certificates & Profiles", color: .blue)
                        transferItemRow(icon: "app.badge.fill", text: "Signed Apps", color: .green)
                        transferItemRow(icon: "square.and.arrow.down.fill", text: "Imported Apps", color: .orange)
                        transferItemRow(icon: "globe.fill", text: "Sources", color: .purple)
                        transferItemRow(icon: "puzzlepiece.extension.fill", text: "Default Frameworks", color: .cyan)
                        transferItemRow(icon: "archivebox.fill", text: "Archives", color: .indigo)
                        transferItemRow(icon: "gearshape.fill", text: "Settings", color: .gray)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                AppearanceSectionHeader(title: String.localized("About"), icon: "info.circle.fill")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Modern Helper Views
    
    @ViewBuilder
    private func featureCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func requirementRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func transferItemRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}
