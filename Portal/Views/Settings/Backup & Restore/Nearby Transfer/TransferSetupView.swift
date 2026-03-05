import SwiftUI
import NimbleViews

// MARK: - Transfer Setup View
struct TransferSetupView: View {
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Header Section
            if showHeaderViews {
                Section {
                    TransferSetupHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            
            // Quick Start Section
            Section {
                NavigationLink(destination: PairingView()) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Start New Transfer"))
                                .font(.headline)
                            Text(.localized("Send or receive a backup securely."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.blue)
                    }
                }
            } header: {
                Text(.localized("Actions"))
            }
            
            // How It Works Section
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("End-to-End Security"))
                            .font(.headline)
                        Text(.localized("All transfers are encrypted and happen directly between your devices."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                }
                
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Direct Connection"))
                            .font(.headline)
                        Text(.localized("Uses Multipeer Connectivity to establish a fast, direct link via Wi-Fi or Bluetooth."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "wifi.router.fill")
                        .foregroundStyle(.blue)
                }
                
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Lightning Fast"))
                            .font(.headline)
                        Text(.localized("High-speed data transfer with real-time progress monitoring."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "speedometer")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text(.localized("Why Secure Transfer?"))
            }
            
            // Requirements Section
            Section {
                Label(.localized("Same Network: Both devices must be on the same Wi-Fi or within Bluetooth range."), systemImage: "network")
                Label(.localized("App Version: Both devices should have the latest Portal version."), systemImage: "iphone.gen2")
                Label(.localized("Power: Ensure sufficient battery for large transfers."), systemImage: "battery.100.bolt")
            } header: {
                Text(.localized("Requirements"))
            }
            
            // About Section
            Section {
                ForEach([
                    ("checkmark.seal.fill", "Certificates", Color.blue),
                    ("app.badge.fill", "Signed Apps", Color.green),
                    ("square.and.arrow.down.fill", "Imported", Color.orange),
                    ("globe.fill", "Sources", Color.purple),
                    ("puzzlepiece.extension.fill", "Frameworks", Color.cyan),
                    ("gearshape.fill", "Settings", Color.gray)
                ], id: \.1) { icon, name, color in
                    Label(name, systemImage: icon)
                        .foregroundStyle(color)
                }
            } header: {
                Text(.localized("Supported Data Types"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
