import SwiftUI
import NimbleViews
import Zip

// MARK: - Modern Installation Options View
struct InstallationOptionsSplashView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("Feather.serverMethod") private var serverMethod: Int = 0
    @State private var appearAnimation = false
    @State private var floatingAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                modernBackground
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                        
                        // Server Settings Card
                        serverSettingsCard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                        
                        // Info Card
                        infoCard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                    }
                    .padding(20)
                }
            }
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
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }
    
    private var modernBackground: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.15), Color.cyan.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? -20 : 20, y: floatingAnimation ? -15 : 15)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.15)
            }
            .ignoresSafeArea()
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
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .cyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .cyan.opacity(0.4), radius: 16, x: 0, y: 8)
                
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 6) {
                Text("Installation Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Configure how apps are installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var serverSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("SERVER SETTINGS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            
            ServerView()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("About Installation")
                    .font(.subheadline.weight(.semibold))
                Text("Apps are installed using a local server that communicates with iOS. Choose the method that works best for your network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Modern Configuration View
struct ConfigurationView: View {
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var isRandomAlertPresenting = false
    @State private var randomString = ""
    @State private var showInstallationOptions = false
    @AppStorage("Feather.compressionLevel") private var _compressionLevel: Int = ZipCompression.DefaultCompression.rawValue
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick Actions Card
                quickActionsCard
                
                // Signing Options Card
                signingOptionsCard
                
                // Archive Options Card
                archiveOptionsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Signing Options")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section(optionsManager.options.ppqString) {
                        Button {
                            isRandomAlertPresenting = true
                        } label: {
                            Label("Change PPQ String", systemImage: "pencil")
                        }
                        
                        Button {
                            UIPasteboard.general.string = optionsManager.options.ppqString
                            HapticsManager.shared.success()
                        } label: {
                            Label("Copy PPQ String", systemImage: "doc.on.doc")
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
    
    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        VStack(spacing: 0) {
            configSectionHeader("Quick Actions", icon: "bolt.fill", color: .yellow)
            
            VStack(spacing: 0) {
                // Installation Options
                Button {
                    showInstallationOptions = true
                } label: {
                    configRow(
                        icon: "arrow.down.app.fill",
                        iconColor: .cyan,
                        title: "Installation Options",
                        subtitle: "Server & connection settings",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                
                Divider().padding(.leading, 60)
                
                // Default Frameworks
                NavigationLink {
                    DefaultFrameworksView()
                } label: {
                    configRow(
                        icon: "puzzlepiece.extension.fill",
                        iconColor: .purple,
                        title: "Default Frameworks",
                        subtitle: "Auto inject into all apps",
                        showChevron: true
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Signing Options Card
    private var signingOptionsCard: some View {
        VStack(spacing: 0) {
            configSectionHeader("Signing Options", icon: "signature", color: .blue)
            
            // Embed SigningOptionsView content in modern style
            ModernSigningOptionsCard(options: $optionsManager.options)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Archive Options Card
    private var archiveOptionsCard: some View {
        VStack(spacing: 0) {
            configSectionHeader("Archive & Compression", icon: "archivebox.fill", color: .indigo)
            
            VStack(spacing: 0) {
                // Compression Level
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.indigo)
                    }
                    
                    Text("Compression")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                    
                    Picker("", selection: $_compressionLevel) {
                        ForEach(ZipCompression.allCases, id: \.rawValue) { level in
                            Text(level.label).tag(level.rawValue)
                        }
                    }
                    .labelsHidden()
                    .tint(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().padding(.leading, 60)
                
                // Share Sheet Toggle
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share Sheet")
                            .font(.subheadline.weight(.medium))
                        Text("Show after exporting")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $_useShareSheet)
                        .labelsHidden()
                        .tint(.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Helper Views
    private func configSectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    private func configRow(icon: String, iconColor: Color, title: String, subtitle: String?, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Modern Signing Options Card
struct ModernSigningOptionsCard: View {
    @Binding var options: Options
    @State private var showPPQInfo = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    
    private var hasCertificateWithPPQCheck: Bool {
        let certificates = Storage.shared.getAllCertificates()
        return certificates.contains { $0.ppQCheck }
    }
    
    private var isEnterpriseCertificate: Bool {
        certificateExperience == "Enterprise"
    }
    
    private var isPPQProtectionForced: Bool {
        isEnterpriseCertificate || hasCertificateWithPPQCheck
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Protection Toggle
            optionToggleRow(
                icon: "shield.checkered",
                iconColor: .blue,
                title: "PPQ Protection",
                subtitle: isPPQProtectionForced ? "Required for your certificate" : "Protect against revocation",
                isOn: Binding(
                    get: { isPPQProtectionForced ? true : options.ppqProtection },
                    set: { if !isPPQProtectionForced || $0 { options.ppqProtection = $0 } }
                ),
                disabled: isPPQProtectionForced
            )
            
            Divider().padding(.leading, 60)
            
            // Signing Type Picker
            optionPickerRow(
                icon: "signature",
                iconColor: .purple,
                title: "Signing Type",
                selection: $options.signingOption,
                values: Options.SigningOption.allCases
            )
            
            Divider().padding(.leading, 60)
            
            // App Appearance
            optionPickerRow(
                icon: "paintpalette.fill",
                iconColor: .pink,
                title: "Appearance",
                selection: $options.appAppearance,
                values: Options.AppAppearance.allCases
            )
            
            Divider().padding(.leading, 60)
            
            // File Sharing
            optionToggleRow(
                icon: "folder.fill.badge.person.crop",
                iconColor: .orange,
                title: "File Sharing",
                subtitle: nil,
                isOn: $options.fileSharing
            )
            
            Divider().padding(.leading, 60)
            
            // Pro Motion
            optionToggleRow(
                icon: "gauge.with.dots.needle.67percent",
                iconColor: .green,
                title: "Pro Motion",
                subtitle: nil,
                isOn: $options.proMotion
            )
            
            Divider().padding(.leading, 60)
            
            // Install After Signing
            optionToggleRow(
                icon: "arrow.down.circle.fill",
                iconColor: .cyan,
                title: "Install After Signing",
                subtitle: nil,
                isOn: $options.post_installAppAfterSigned
            )
            
            Divider().padding(.leading, 60)
            
            // Delete After Signing
            optionToggleRow(
                icon: "trash.fill",
                iconColor: .red,
                title: "Delete After Signing",
                subtitle: nil,
                isOn: $options.post_deleteAppAfterSigned
            )
        }
        .onAppear {
            if isPPQProtectionForced && !options.ppqProtection {
                options.ppqProtection = true
            }
        }
    }
    
    private func optionToggleRow(icon: String, iconColor: Color, title: String, subtitle: String?, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.accentColor)
                .disabled(disabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func optionPickerRow<T: Hashable & LocalizedDescribable>(icon: String, iconColor: Color, title: String, selection: Binding<T>, values: [T]) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            Text(title)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value.localizedDescription).tag(value)
                }
            }
            .labelsHidden()
            .tint(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
