import SwiftUI
import NimbleViews
import Zip

// MARK: - Installation Options Splash Screen
struct InstallationOptionsSplashView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("Feather.serverMethod") private var serverMethod: Int = 0
    @AppStorage("Feather.useTunnel") private var useTunnel: Bool = false
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    // Connection Method Card
                    connectionMethodCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                    
                    // Server Settings
                    if !useTunnel {
                        serverSettingsCard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                    }
                    
                    // Tunnel Settings
                    if useTunnel {
                        tunnelSettingsCard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Installation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .cyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .cyan.opacity(0.4), radius: 16, x: 0, y: 8)
                
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 6) {
                Text("Installation Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Configure how apps are installed on your device")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var connectionMethodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("CONNECTION METHOD")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Toggle(isOn: $useTunnel) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: useTunnel ? [.green, .mint] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: useTunnel ? .green.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(useTunnel ? .white : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use Tunnel")
                            .font(.system(size: 16, weight: .medium))
                        Text("iDevice and pairing file method")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var serverSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("SERVER SETTINGS")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            ServerView()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var tunnelSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "cable.connector")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("TUNNEL SETTINGS")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            TunnelView()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - View
struct ConfigurationView: View {
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var isRandomAlertPresenting = false
    @State private var randomString = ""
    @State private var showInstallationOptions = false
    @AppStorage("Feather.compressionLevel") private var _compressionLevel: Int = ZipCompression.DefaultCompression.rawValue
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    
    var body: some View {
        List {
            // Installation Section
            Section {
                Button {
                    showInstallationOptions = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .cyan.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.down.app.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Installation Options")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Server, tunnel & connection settings")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                sectionHeader("Installation", icon: "arrow.down.circle.fill")
            }
            
            // Frameworks Section
            Section {
                NavigationLink {
                    DefaultFrameworksView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Default Frameworks")
                                .font(.system(size: 15))
                            Text("Auto-inject into all apps")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                sectionHeader("Injection", icon: "syringe.fill")
            }
            
            // Archive & Compression Section (moved from separate view)
            Section {
                Picker(selection: $_compressionLevel) {
                    ForEach(ZipCompression.allCases, id: \.rawValue) { level in
                        Text(level.label).tag(level.rawValue)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.indigo)
                            .frame(width: 24)
                        Text("Compression Level")
                            .font(.system(size: 15))
                    }
                }
                
                Toggle(isOn: $_useShareSheet) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("Show Sheet When Exporting")
                            .font(.system(size: 15))
                    }
                }
                .tint(.accentColor)
            } header: {
                sectionHeader("Archive & Compression", icon: "archivebox.fill")
            } footer: {
                Text("Toggling show sheet will present a share sheet after exporting to your files.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            // Signing Options
            SigningOptionsView(options: $optionsManager.options)
        }
        .navigationTitle("Signing Options")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section(optionsManager.options.ppqString) {
                        Button {
                            isRandomAlertPresenting = true
                        } label: {
                            Label("Change", systemImage: "pencil")
                        }
                        
                        Button {
                            UIPasteboard.general.string = optionsManager.options.ppqString
                            HapticsManager.shared.success()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                }
            }
        }
        .sheet(isPresented: $showInstallationOptions) {
            InstallationOptionsSplashView()
        }
        .alert("PPQ String", isPresented: $isRandomAlertPresenting) {
            TextField("String", text: $randomString)
            Button("Save") {
                if !randomString.isEmpty {
                    optionsManager.options.ppqString = randomString
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: optionsManager.options) { _ in
            optionsManager.saveOptions()
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
