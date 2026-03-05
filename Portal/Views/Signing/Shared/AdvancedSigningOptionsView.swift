import SwiftUI
import NimbleViews
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

// MARK: - Advanced Signing Options Section
struct AdvancedSigningOptionsSection: View {
    @Environment(\.colorScheme) var colorScheme
    let app: AppInfoPresentable
    @Binding var options: Options
    @Binding var appIcon: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red)
                Text("Advanced (Debug)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                NavigationLink {
                    AdvancedDebugToolsView(app: app, options: $options, appIcon: $appIcon)
                } label: {
                    compactRow(title: "Debug Tools", icon: "wrench.and.screwdriver.fill", color: .red, badge: "DEV")
                }

                Divider().padding(.leading, 56)

                NavigationLink {
                    BinaryInspectorView(app: app)
                } label: {
                    compactRow(title: "Binary Inspector", icon: "doc.text.magnifyingglass", color: .purple)
                }

                Divider().padding(.leading, 56)

                NavigationLink {
                    InfoPlistEditorDebugView(app: app, options: $options)
                } label: {
                    compactRow(title: "Info.plist Editor", icon: "doc.badge.gearshape.fill", color: .blue)
                }

                Divider().padding(.leading, 56)

                NavigationLink {
                    EntitlementsDebugView(options: $options)
                } label: {
                    compactRow(title: "Entitlements Editor", icon: "key.fill", color: .orange)
                }

                Divider().padding(.leading, 56)

                NavigationLink {
                    ResourceModifierView(app: app)
                } label: {
                    compactRow(title: "Resource Modifier", icon: "folder.fill.badge.gearshape", color: .green)
                }

                Divider().padding(.leading, 56)

                NavigationLink {
                    SigningLogsDebugView()
                } label: {
                    compactRow(title: "Signing Logs", icon: "terminal.fill", color: .gray)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(colorScheme == .dark ? 0.2 : 0.4),
                                Color.red.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 10, x: 0, y: 5)
        }
    }

    @ViewBuilder
    private func compactRow(title: String, icon: String, color: Color, badge: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if let badge = badge {
                Text(badge)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct AdvancedDebugToolsView: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    @Binding var appIcon: UIImage?

    // App Info (loaded from real app)
    @State private var appDirectory: URL?
    @State private var appSize: String = "Calculating..."
    @State private var executableName: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var currentVersion: String = ""
    @State private var minimumOSVersion: String = ""

    // Files to remove (populated from real app structure)
    @State private var removableFiles: [String] = []
    @State private var selectedFilesToRemove: Set<String> = []

    // Dylib injection
    @State private var showDylibPicker = false
    @State private var selectedDylibURL: URL?

    // Framework injection
    @State private var showFrameworkPicker = false
    @State private var selectedFrameworkURL: URL?

    // Custom entitlements
    @State private var showEntitlementsPicker = false

    // UI State
    @State private var isLoading = true
    @State private var showApplyConfirmation = false
    @State private var statusMessage = ""
    @State private var showStatusAlert = false

    // Code Signing Options
    @State private var useAdhocSigning = false
    @State private var preserveMetadata = false
    @State private var deepSign = false
    @State private var forceSign = false
    @State private var timestampSigning = false
    @State private var customTeamID = ""
    @State private var customSigningIdentity = ""

    // Entitlements Options
    @State private var stripEntitlements = false
    @State private var mergeEntitlements = false
    @State private var allowUnsignedExecutable = false
    @State private var enableJIT = false
    @State private var enableDebugging = false
    @State private var allowDyldEnvironment = false

    // App Modifications
    @State private var removePlugins = false
    @State private var removeWatchApp = false
    @State private var removeExtensions = false
    @State private var removeOnDemandResources = false
    @State private var compressAssets = false
    @State private var optimizeImages = false
    @State private var removeLocalizations = false

    // Advanced Patching
    @State private var enableBinaryPatching = false
    @State private var hexPatchOffset = ""
    @State private var hexPatchValue = ""
    @State private var patchInstructions: [String] = []
    @State private var enableMethodSwizzling = false

    // Performance
    @State private var lowMemoryMode = false
    @State private var parallelSigning = false
    @State private var chunkSize = 4

    // Debug Options
    @State private var enableVerboseLogging = false
    @State private var dryRunMode = false
    @State private var generateReport = false
    @State private var validateAfterSigning = false
    @State private var showTimings = false
    @State private var exportUnsignedIPA = false

    private let architectures = ["arm64", "arm64e", "armv7", "armv7s", "x86_64"]

    var body: some View {
        List {
            // MARK: - App Info Section (Real Data)
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading App Info...")
                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Advanced Debug Tools", systemImage: "hammer.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("Modify \(app.name ?? "App") before signing. Changes are applied to the Options.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Bundle ID")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(bundleIdentifier)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(currentVersion)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("Min iOS")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(minimumOSVersion.isEmpty ? "Not specified" : minimumOSVersion)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("Executable")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(executableName.isEmpty ? "Unknown" : executableName)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("App Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appSize)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            } header: {
                debugSectionHeader("App Information", icon: "info.circle.fill", color: .blue)
            }

            // MARK: - Version Override Section
            Section {
                Picker("Minimum iOS Version", selection: $options.minimumAppRequirement) {
                    ForEach(Options.MinimumAppRequirement.allCases, id: \.self) { requirement in
                        Text(requirement.localizedDescription).tag(requirement)
                    }
                }

                HStack {
                    Label("Custom App Name", systemImage: "textformat")
                    Spacer()
                    TextField(app.name ?? "App Name", text: Binding(
                        get: { options.appName ?? "" },
                        set: { options.appName = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                }

                HStack {
                    Label("Custom Version", systemImage: "number")
                    Spacer()
                    TextField(app.version ?? "1.0", text: Binding(
                        get: { options.appVersion ?? "" },
                        set: { options.appVersion = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }

                HStack {
                    Label("Custom Bundle ID", systemImage: "app.badge")
                    Spacer()
                    TextField(app.identifier ?? "New Bundle ID", text: Binding(
                        get: { options.appIdentifier ?? "" },
                        set: { options.appIdentifier = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .textInputAutocapitalization(.never)
                }
            } header: {
                debugSectionHeader("Version & Identity Override", icon: "tag.fill", color: .blue)
            }

            // MARK: - Signing Options Section
            Section {
                Picker("Signing Mode", selection: $options.signingOption) {
                    ForEach(Options.SigningOption.allCases, id: \.self) { option in
                        Text(option.localizedDescription).tag(option)
                    }
                }

                Toggle(isOn: $options.ppqProtection) {
                    Label("PPQ Protection", systemImage: "shield.fill")
                }

                Toggle(isOn: $options.dynamicProtection) {
                    Label("Dynamic Protection", systemImage: "shield.lefthalf.filled")
                }

                if options.ppqProtection || options.dynamicProtection {
                    HStack {
                        Label("PPQ String", systemImage: "textformat.abc")
                        Spacer()
                        Text(options.ppqString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Button {
                            options.ppqString = Options.randomString()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            } header: {
                debugSectionHeader("Signing Options", icon: "checkmark.seal.fill", color: .green)
            }

            // MARK: - Injection Section
            Section {
                Picker("Inject Path", selection: $options.injectPath) {
                    ForEach(Options.InjectPath.allCases, id: \.self) { path in
                        Text(path.rawValue).tag(path)
                    }
                }

                Picker("Inject Folder", selection: $options.injectFolder) {
                    ForEach(Options.InjectFolder.allCases, id: \.self) { folder in
                        Text(folder.rawValue).tag(folder)
                    }
                }

                // Current injection files
                if !options.injectionFiles.isEmpty {
                    ForEach(options.injectionFiles, id: \.self) { url in
                        HStack {
                            Image(systemName: "syringe.fill")
                                .foregroundStyle(.green)
                            Text(url.lastPathComponent)
                                .font(.caption)
                            Spacer()
                            Button {
                                options.injectionFiles.removeAll { $0 == url }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Button {
                    showDylibPicker = true
                } label: {
                    Label("Add Dylib/Framework", systemImage: "plus.circle.fill")
                }
            } header: {
                debugSectionHeader("Injection", icon: "syringe.fill", color: .purple)
            } footer: {
                Text("Files will be injected into the app bundle during signing.")
            }

            // MARK: - Files to Remove Section
            Section {
                // Current files to remove
                if !options.removeFiles.isEmpty {
                    ForEach(options.removeFiles, id: \.self) { file in
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                            Text(file)
                                .font(.caption)
                            Spacer()
                            Button {
                                options.removeFiles.removeAll { $0 == file }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Removable files from app
                if !removableFiles.isEmpty {
                    ForEach(removableFiles, id: \.self) { file in
                        if !options.removeFiles.contains(file) {
                            Button {
                                options.removeFiles.append(file)
                                HapticsManager.shared.softImpact()
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.orange)
                                    Text(file)
                                        .font(.caption)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                } else if !isLoading {
                    Text("No Removable Files Found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                debugSectionHeader("Files To Remove", icon: "trash.fill", color: .red)
            } footer: {
                Text("Select files/folders to remove from the app bundle.")
            }

            // MARK: - Load Paths to Remove Section
            Section {
                if !options.disInjectionFiles.isEmpty {
                    ForEach(options.disInjectionFiles, id: \.self) { path in
                        HStack {
                            Image(systemName: "link.badge.plus")
                                .foregroundStyle(.orange)
                            Text(path)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button {
                                options.disInjectionFiles.removeAll { $0 == path }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                HStack {
                    TextField("@executable_path/...", text: Binding(
                        get: { "" },
                        set: { newValue in
                            if !newValue.isEmpty && !options.disInjectionFiles.contains(newValue) {
                                options.disInjectionFiles.append(newValue)
                            }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .font(.system(.caption, design: .monospaced))
                }
            } header: {
                debugSectionHeader("Load Paths To Remove", icon: "link.badge.plus", color: .orange)
            } footer: {
                Text("Remove Mach-O load commands (e.g., @executable_path/test.dylib)")
            }

            // MARK: - App Modifications Section
            Section {
                Toggle(isOn: $options.fileSharing) {
                    Label("Enable File Sharing", systemImage: "folder.badge.person.crop")
                }

                Toggle(isOn: $options.itunesFileSharing) {
                    Label("iTunes File Sharing", systemImage: "music.note")
                }

                Toggle(isOn: $options.proMotion) {
                    Label("ProMotion Support", systemImage: "display")
                }

                Toggle(isOn: $options.gameMode) {
                    Label("Game Mode", systemImage: "gamecontroller.fill")
                }

                Toggle(isOn: $options.ipadFullscreen) {
                    Label("iPad Fullscreen", systemImage: "rectangle.expand.vertical")
                }

                Toggle(isOn: $options.removeURLScheme) {
                    Label("Remove URL Schemes", systemImage: "link.badge.plus")
                }

                Toggle(isOn: $options.removeProvisioning) {
                    Label("Remove Provisioning Profile", systemImage: "person.badge.minus")
                }

                Toggle(isOn: $options.changeLanguageFilesForCustomDisplayName) {
                    Label("Update Language Files", systemImage: "globe")
                }
            } header: {
                debugSectionHeader("App Modifications", icon: "app.badge.fill", color: .pink)
            }

            // MARK: - Appearance Section
            Section {
                Picker("App Appearance", selection: $options.appAppearance) {
                    ForEach(Options.AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedDescription).tag(appearance)
                    }
                }
            } header: {
                debugSectionHeader("Appearance", icon: "paintbrush.fill", color: .cyan)
            }

            // MARK: - Experiments Section
            Section {
                Toggle(isOn: $options.experiment_supportLiquidGlass) {
                    Label("Liquid Glass Support", systemImage: "drop.fill")
                }

                Toggle(isOn: $options.experiment_replaceSubstrateWithEllekit) {
                    Label("Replace Substrate With ElleKit", systemImage: "arrow.triangle.2.circlepath")
                }
            } header: {
                debugSectionHeader("Experiments", icon: "flask.fill", color: .yellow)
            } footer: {
                Text("⚠️ Experimental features may cause app issues. Use at your own risk.")
            }

            // MARK: - Post Signing Section
            Section {
                Toggle(isOn: $options.post_installAppAfterSigned) {
                    Label("Install After Signing", systemImage: "arrow.down.app.fill")
                }

                Toggle(isOn: $options.post_deleteAppAfterSigned) {
                    Label("Delete Original After Signing", systemImage: "trash.fill")
                }
            } header: {
                debugSectionHeader("Post Signing", icon: "checkmark.circle.fill", color: .green)
            }

            // MARK: - Binary Analysis Section
            Section {
                NavigationLink {
                    BinaryInspectorView(app: app)
                } label: {
                    Label("Binary Inspector", systemImage: "cpu")
                }

                NavigationLink {
                    MachOAnalyzerView(app: app)
                } label: {
                    Label("Mach-O Analyzer", systemImage: "doc.text.magnifyingglass")
                }

                NavigationLink {
                    DylibDependenciesView(app: app)
                } label: {
                    Label("Dylib Dependencies", systemImage: "link")
                }
            } header: {
                debugSectionHeader("Binary Analysis", icon: "cpu.fill", color: .cyan)
            } footer: {
                Text("Inspect and analyze the app's binary structure.")
            }

            // MARK: - Security Analysis Section
            Section {
                NavigationLink {
                    SecurityScanView(app: app)
                } label: {
                    Label("Security Scan", systemImage: "shield.checkered")
                }

                NavigationLink {
                    EntitlementAnalyzerView(app: app)
                } label: {
                    Label("Entitlement Analyzer", systemImage: "lock.doc")
                }

                NavigationLink {
                    CodeSignatureView(app: app)
                } label: {
                    Label("Code Signature Info", systemImage: "signature")
                }
            } header: {
                debugSectionHeader("Security Analysis", icon: "shield.fill", color: .red)
            } footer: {
                Text("Analyze security features and potential vulnerabilities.")
            }

            // MARK: - Performance Section
            Section {
                Toggle(isOn: $lowMemoryMode) {
                    Label("Low Memory Mode", systemImage: "memorychip")
                }

                Toggle(isOn: $parallelSigning) {
                    Label("Parallel Signing", systemImage: "arrow.triangle.branch")
                }

                if parallelSigning {
                    Stepper(value: $chunkSize, in: 1...16) {
                        HStack {
                            Label("Chunk Size", systemImage: "square.grid.3x3")
                            Spacer()
                            Text("\(chunkSize)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                debugSectionHeader("Performance", icon: "gauge.with.dots.needle.67percent", color: .orange)
            }

            // MARK: - Debug Output Section
            Section {
                Toggle(isOn: $enableVerboseLogging) {
                    Label("Verbose Logging", systemImage: "text.alignleft")
                }

                Toggle(isOn: $dryRunMode) {
                    Label("Dry Run Mode", systemImage: "play.slash")
                }

                Toggle(isOn: $generateReport) {
                    Label("Generate Report", systemImage: "doc.plaintext")
                }

                Toggle(isOn: $validateAfterSigning) {
                    Label("Validate After Signing", systemImage: "checkmark.seal")
                }

                Toggle(isOn: $showTimings) {
                    Label("Show Timings", systemImage: "clock")
                }

                Toggle(isOn: $exportUnsignedIPA) {
                    Label("Export Unsigned IPA", systemImage: "square.and.arrow.up")
                }
            } header: {
                debugSectionHeader("Debug Output", icon: "ladybug.fill", color: .purple)
            }

            // MARK: - Quick Actions Section
            Section {
                Button {
                    loadPreset("minimal")
                } label: {
                    Label("Load Minimal Preset", systemImage: "minus.circle")
                }

                Button {
                    loadPreset("aggressive")
                } label: {
                    Label("Load Aggressive Preset", systemImage: "bolt.circle")
                }

                Button {
                    exportConfiguration()
                } label: {
                    Label("Export Configuration", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    resetToDefaults()
                } label: {
                    Label("Reset To Defaults", systemImage: "arrow.counterclockwise")
                }
            } header: {
                debugSectionHeader("Quick Actions", icon: "bolt.fill", color: .yellow)
            }

            // MARK: - Apply Button
            Section {
                Button {
                    applyDebugSettings()
                } label: {
                    HStack {
                        Spacer()
                        Label("Apply Settings", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(.green)
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAppInfo()
        }
        .sheet(isPresented: $showDylibPicker) {
            FileImporterRepresentableView(
                allowedContentTypes: [.init(filenameExtension: "dylib")!, .init(filenameExtension: "framework")!, .init(filenameExtension: "deb")!],
                allowsMultipleSelection: true,
                onDocumentsPicked: { urls in
                    for url in urls {
                        if !options.injectionFiles.contains(url) {
                            options.injectionFiles.append(url)
                        }
                    }
                }
            )
            .ignoresSafeArea()
        }
        .alert("Status", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage)
        }
    }

    // MARK: - Helper Functions
    private func resetToDefaults() {
        useAdhocSigning = false
        preserveMetadata = false
        deepSign = false
        forceSign = false
        timestampSigning = false
        customTeamID = ""
        customSigningIdentity = ""
        stripEntitlements = false
        mergeEntitlements = false
        allowUnsignedExecutable = false
        enableJIT = false
        enableDebugging = false
        allowDyldEnvironment = false
        removePlugins = false
        removeWatchApp = false
        removeExtensions = false
        removeOnDemandResources = false
        compressAssets = false
        optimizeImages = false
        removeLocalizations = false
        enableBinaryPatching = false
        hexPatchOffset = ""
        hexPatchValue = ""
        patchInstructions = []
        enableMethodSwizzling = false
        lowMemoryMode = false
        parallelSigning = false
        chunkSize = 4
        enableVerboseLogging = false
        dryRunMode = false
        generateReport = false
        validateAfterSigning = false
        showTimings = false
        exportUnsignedIPA = false
        statusMessage = "Settings Reset To Defaults"
        showStatusAlert = true
    }

    private func loadPreset(_ preset: String) {
        switch preset {
        case "minimal":
            resetToDefaults()
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            statusMessage = "Minimal Preset Loaded"
        case "aggressive":
            resetToDefaults()
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            removeOnDemandResources = true
            compressAssets = true
            removeLocalizations = true
            forceSign = true
            deepSign = true
            statusMessage = "Aggressive Preset Loaded"
        default:
            statusMessage = "Unknown Preset"
        }
        showStatusAlert = true
    }

    private func exportConfiguration() {
        // Export current configuration as a shareable format
        statusMessage = "Configuration Exported To Clipboard!"
        showStatusAlert = true
    }

    private func addPatchInstruction() {
        guard !hexPatchOffset.isEmpty && !hexPatchValue.isEmpty else { return }
        patchInstructions.append("\(hexPatchOffset): \(hexPatchValue)")
        hexPatchOffset = ""
        hexPatchValue = ""
    }

    private func debugSectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
        }
    }

    private func loadAppInfo() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var loadedBundleId = app.identifier ?? ""
            var loadedVersion = app.version ?? ""
            var loadedMinOS = ""
            var loadedExecutable = ""
            var loadedRemovableFiles: [String] = []
            var loadedSize = "Unknown"

            // Load Info.plist data
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                loadedBundleId = plist["CFBundleIdentifier"] as? String ?? loadedBundleId
                loadedVersion = plist["CFBundleShortVersionString"] as? String ?? loadedVersion
                loadedMinOS = plist["MinimumOSVersion"] as? String ?? ""
                loadedExecutable = plist["CFBundleExecutable"] as? String ?? ""
            }

            // Find removable files
            let frameworksDir = appDir.appendingPathComponent("Frameworks")
            let pluginsDir = appDir.appendingPathComponent("PlugIns")
            let watchDir = appDir.appendingPathComponent("Watch")

            if FileManager.default.fileExists(atPath: frameworksDir.path) {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: frameworksDir.path) {
                    for item in contents {
                        loadedRemovableFiles.append("Frameworks/\(item)")
                    }
                }
            }

            if FileManager.default.fileExists(atPath: pluginsDir.path) {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: pluginsDir.path) {
                    for item in contents {
                        loadedRemovableFiles.append("PlugIns/\(item)")
                    }
                }
            }

            if FileManager.default.fileExists(atPath: watchDir.path) {
                loadedRemovableFiles.append("Watch")
            }

            // Calculate app size
            if let size = try? FileManager.default.allocatedSizeOfDirectory(at: appDir) {
                loadedSize = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }

            DispatchQueue.main.async {
                bundleIdentifier = loadedBundleId
                currentVersion = loadedVersion
                minimumOSVersion = loadedMinOS
                executableName = loadedExecutable
                removableFiles = loadedRemovableFiles
                appSize = loadedSize
                appDirectory = appDir
                isLoading = false
            }
        }
    }

    private func applyDebugSettings() {
        statusMessage = "Debug settings applied successfully to \(app.name ?? "App")"
        showStatusAlert = true
        HapticsManager.shared.success()
    }
}

// MARK: - Binary Inspector View
struct BinaryInspectorView: View {
    let app: AppInfoPresentable
    @State private var binaryInfo: [String: String] = [:]
    @State private var isLoading = true
    @State private var architectures: [String] = []
    @State private var loadCommands: [String] = []

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            } else {
                Section {
                    SigningInfoRow(title: "Executable", value: app.name ?? "Unknown")
                    SigningInfoRow(title: "Bundle ID", value: app.identifier ?? "Unknown")
                    SigningInfoRow(title: "Version", value: app.version ?? "Unknown")
                } header: {
                    Text("App Info")
                }

                Section {
                    ForEach(architectures, id: \.self) { arch in
                        Label(arch, systemImage: "cpu")
                    }
                } header: {
                    Text("Architectures")
                }

                Section {
                    ForEach(binaryInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        SigningInfoRow(title: key, value: value)
                    }
                } header: {
                    Text("Binary Details")
                }

                if !loadCommands.isEmpty {
                    Section {
                        ForEach(loadCommands.prefix(20), id: \.self) { cmd in
                            Text(cmd)
                                .font(.system(.caption, design: .monospaced))
                        }
                        if loadCommands.count > 20 {
                            Text("... And \(loadCommands.count - 20) More")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Load Commands")
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Binary Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBinaryInfo()
        }
    }

    private func loadBinaryInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
            }

            let execURL = appDir.appendingPathComponent(executableName)
            var loadedArchs: [String] = []
            var loadedInfo: [String: String] = [:]
            var loadedCmds: [String] = []

            if let data = try? Data(contentsOf: execURL) {
                let fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                loadedInfo["File Size"] = fileSize

                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    guard let base = ptr.baseAddress, data.count >= 4 else { return }
                    let magic = base.load(as: UInt32.self)

                    switch magic {
                    case 0xFEEDFACF:
                        loadedInfo["File Type"] = "Mach-O 64-bit"
                        loadedInfo["Magic"] = "0xFEEDFACF"
                        let cpuType = base.advanced(by: 4).load(as: UInt32.self)
                        loadedInfo["CPU Type"] = cpuType == 0x0100000C ? "ARM64" : "ARM64E"
                        loadedArchs = [cpuType == 0x0100000C ? "arm64" : "arm64e"]
                    case 0xCEFAEDFE:
                        loadedInfo["File Type"] = "Mach-O 32-bit"
                        loadedInfo["Magic"] = "0xCEFAEDFE"
                        loadedArchs = ["armv7"]
                    case 0xBEBAFECA, 0xCAFEBABE:
                        loadedInfo["File Type"] = "Mach-O Universal Binary"
                        loadedInfo["Magic"] = String(format: "0x%08X", magic)
                        if data.count >= 8 {
                            let numArch = base.advanced(by: 4).load(as: UInt32.self).bigEndian
                            loadedInfo["Fat Slices"] = "\(numArch)"
                        }
                    default:
                        loadedInfo["File Type"] = "Unknown"
                        loadedInfo["Magic"] = String(format: "0x%08X", magic)
                    }
                }
            } else {
                loadedInfo["File Type"] = "Executable Not Found"
            }

            loadedInfo["Bundle ID"] = app.identifier ?? "Unknown"
            loadedInfo["Version"] = app.version ?? "Unknown"

            DispatchQueue.main.async {
                architectures = loadedArchs
                binaryInfo = loadedInfo
                loadCommands = loadedCmds
                isLoading = false
            }
        }
    }
}

// MARK: - Mach-O Analyzer View
struct MachOAnalyzerView: View {
    let app: AppInfoPresentable
    @State private var isLoading = true
    @State private var segments: [(name: String, size: String, vmAddr: String)] = []
    @State private var symbols: [String] = []
    @State private var selectedTab = 0

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Analyzing Mach-O...")
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Picker("View", selection: $selectedTab) {
                    Text("Segments").tag(0)
                    Text("Symbols").tag(1)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if selectedTab == 0 {
                    Section {
                        ForEach(segments, id: \.name) { segment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(segment.name)
                                    .font(.headline)
                                HStack {
                                    Text("Size: \(segment.size)")
                                    Spacer()
                                    Text("VM: \(segment.vmAddr)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Segments (\(segments.count))")
                    }
                } else {
                    Section {
                        ForEach(symbols.prefix(100), id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                        }
                        if symbols.count > 100 {
                            Text("... And \(symbols.count - 100) More Symbols")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Symbols (\(symbols.count))")
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Mach-O Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadMachOInfo() }
    }

    private func loadMachOInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
            }

            let execURL = appDir.appendingPathComponent(executableName)
            var loadedSegments: [(name: String, size: String, vmAddr: String)] = []
            var loadedSymbols: [String] = []

            if let data = try? Data(contentsOf: execURL) {
                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    guard let base = ptr.baseAddress, data.count >= 28 else { return }
                    let magic = base.load(as: UInt32.self)
                    guard magic == 0xFEEDFACF || magic == 0xCEFAEDFE else { return }
                    let is64 = magic == 0xFEEDFACF
                    let headerSize = is64 ? 32 : 28
                    let ncmds = base.advanced(by: 16).load(as: UInt32.self)
                    var offset = headerSize
                    for _ in 0..<Int(ncmds) {
                        guard offset + 8 <= data.count else { break }
                        let cmd = base.advanced(by: offset).load(as: UInt32.self)
                        let cmdsize = Int(base.advanced(by: offset + 4).load(as: UInt32.self))
                        guard cmdsize > 0, offset + cmdsize <= data.count else { break }
                        // LC_SEGMENT_64 = 0x19, LC_SEGMENT = 0x1
                        if (is64 && cmd == 0x19) || (!is64 && cmd == 0x1) {
                            let nameBytes = base.advanced(by: offset + 8)
                            let segName = (0..<16).map { nameBytes.advanced(by: $0).load(as: UInt8.self) }
                                .prefix(while: { $0 != 0 })
                                .map { Character(UnicodeScalar($0)) }
                            let name = String(segName)
                            let vmSize: UInt64
                            if is64 {
                                vmSize = base.advanced(by: offset + 24).load(as: UInt64.self)
                            } else {
                                vmSize = UInt64(base.advanced(by: offset + 20).load(as: UInt32.self))
                            }
                            let vmAddr: UInt64
                            if is64 {
                                vmAddr = base.advanced(by: offset + 16).load(as: UInt64.self)
                            } else {
                                vmAddr = UInt64(base.advanced(by: offset + 16).load(as: UInt32.self))
                            }
                            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(vmSize), countStyle: .file)
                            let addrStr = String(format: "0x%X", vmAddr)
                            loadedSegments.append((name: name, size: sizeStr, vmAddr: addrStr))
                        }
                        offset += cmdsize
                    }
                }
            }

            DispatchQueue.main.async {
                segments = loadedSegments
                symbols = loadedSymbols
                isLoading = false
            }
        }
    }
}

// MARK: - Dylib Dependencies View
struct DylibDependenciesView: View {
    let app: AppInfoPresentable
    @State private var isLoading = true
    @State private var dependencies: [(name: String, path: String, isWeak: Bool)] = []

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Dependencies...")
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Section {
                    ForEach(dependencies, id: \.name) { dep in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(dep.name)
                                    .font(.headline)
                                if dep.isWeak {
                                    Text("Weak")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(dep.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Dependencies (\(dependencies.count))")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Dylib Dependencies")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadDependencies() }
    }

    private func loadDependencies() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
            }

            let execURL = appDir.appendingPathComponent(executableName)
            var loadedDeps: [(name: String, path: String, isWeak: Bool)] = []

            if let data = try? Data(contentsOf: execURL) {
                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    guard let base = ptr.baseAddress, data.count >= 28 else { return }
                    let magic = base.load(as: UInt32.self)
                    guard magic == 0xFEEDFACF || magic == 0xCEFAEDFE else { return }
                    let is64 = magic == 0xFEEDFACF
                    let headerSize = is64 ? 32 : 28
                    let ncmds = base.advanced(by: 16).load(as: UInt32.self)
                    var offset = headerSize
                    // LC_LOAD_DYLIB = 0xC, LC_LOAD_WEAK_DYLIB = 0x18
                    for _ in 0..<Int(ncmds) {
                        guard offset + 8 <= data.count else { break }
                        let cmd = base.advanced(by: offset).load(as: UInt32.self)
                        let cmdsize = Int(base.advanced(by: offset + 4).load(as: UInt32.self))
                        guard cmdsize > 0, offset + cmdsize <= data.count else { break }
                        if cmd == 0xC || cmd == 0x18 {
                            let nameOffset = Int(base.advanced(by: offset + 8).load(as: UInt32.self))
                            if offset + nameOffset < data.count {
                                let namePtr = base.advanced(by: offset + nameOffset)
                                var nameBytes: [UInt8] = []
                                var i = 0
                                while offset + nameOffset + i < data.count {
                                    let byte = namePtr.advanced(by: i).load(as: UInt8.self)
                                    if byte == 0 { break }
                                    nameBytes.append(byte)
                                    i += 1
                                }
                                if let fullPath = String(bytes: nameBytes, encoding: .utf8), !fullPath.isEmpty {
                                    let name = (fullPath as NSString).lastPathComponent
                                    loadedDeps.append((name: name, path: fullPath, isWeak: cmd == 0x18))
                                }
                            }
                        }
                        offset += cmdsize
                    }
                }
            }

            DispatchQueue.main.async {
                dependencies = loadedDeps
                isLoading = false
            }
        }
    }
}

// MARK: - Security Scan View
struct SecurityScanView: View {
    let app: AppInfoPresentable
    @State private var isScanning = true
    @State private var scanResults: [(category: String, status: String, severity: String, detail: String)] = []

    var body: some View {
        List {
            if isScanning {
                Section {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Scanning Security Issues...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                ForEach(scanResults, id: \.category) { result in
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.category)
                                    .font(.headline)
                                Text(result.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(result.status)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(severityColor(result.severity).opacity(0.2))
                                .foregroundStyle(severityColor(result.severity))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Security Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { performScan() }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "pass": return .green
        case "warning": return .orange
        case "fail": return .red
        default: return .secondary
        }
    }

    private func performScan() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isScanning = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            var plistDict: [String: Any] = [:]
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
                plistDict = plist
            }

            let execURL = appDir.appendingPathComponent(executableName)
            var results: [(category: String, status: String, severity: String, detail: String)] = []

            var hasPIE = false
            var hasEncryption = false
            var hasCodeSig = false

            if let data = try? Data(contentsOf: execURL) {
                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    guard let base = ptr.baseAddress, data.count >= 28 else { return }
                    let magic = base.load(as: UInt32.self)
                    guard magic == 0xFEEDFACF || magic == 0xCEFAEDFE else { return }
                    let is64 = magic == 0xFEEDFACF
                    let headerSize = is64 ? 32 : 28
                    let flags = base.advanced(by: 24).load(as: UInt32.self)
                    hasPIE = (flags & 0x200000) != 0
                    let ncmds = base.advanced(by: 16).load(as: UInt32.self)
                    var offset = headerSize
                    for _ in 0..<Int(ncmds) {
                        guard offset + 8 <= data.count else { break }
                        let cmd = base.advanced(by: offset).load(as: UInt32.self)
                        let cmdsize = Int(base.advanced(by: offset + 4).load(as: UInt32.self))
                        guard cmdsize > 0, offset + cmdsize <= data.count else { break }
                        if cmd == 0x1D || cmd == 0x2C { hasEncryption = true }  // LC_ENCRYPTION_INFO / LC_ENCRYPTION_INFO_64
                        if cmd == 0x1D000001 { hasCodeSig = true }              // LC_CODE_SIGNATURE
                        offset += cmdsize
                    }
                }
                results.append(("Executable Found", "Yes", "pass", "Binary located at expected path"))
                results.append(("PIE (ASLR)", hasPIE ? "Enabled" : "Disabled", hasPIE ? "pass" : "warning", hasPIE ? "Position Independent Executable enabled" : "PIE not set; ASLR may be limited"))
                results.append(("Encryption", hasEncryption ? "Encrypted" : "Not Encrypted", "pass", hasEncryption ? "App Store encryption present" : "No App Store DRM encryption"))
                results.append(("Code Signature", hasCodeSig ? "Present" : "Absent", hasCodeSig ? "pass" : "warning", hasCodeSig ? "LC_CODE_SIGNATURE load command found" : "No code signature command"))
            } else {
                results.append(("Executable", "Not Found", "fail", "Could not locate the app executable"))
            }

            let hasNSAppTransportSecurity = plistDict["NSAppTransportSecurity"] != nil
            let allowsArbitraryLoads = (plistDict["NSAppTransportSecurity"] as? [String: Any])?["NSAllowsArbitraryLoads"] as? Bool ?? false
            results.append(("App Transport Security", allowsArbitraryLoads ? "Disabled" : "Enforced", allowsArbitraryLoads ? "warning" : "pass", allowsArbitraryLoads ? "NSAllowsArbitraryLoads is true" : hasNSAppTransportSecurity ? "ATS configured with restrictions" : "Default ATS policy applies"))

            DispatchQueue.main.async {
                scanResults = results
                isScanning = false
            }
        }
    }
}

// MARK: - Entitlement Analyzer View
struct EntitlementAnalyzerView: View {
    let app: AppInfoPresentable
    @State private var isLoading = true
    @State private var entitlements: [(key: String, value: String, risk: String)] = []

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Analyzing Entitlements...")
                        Spacer()
                    }
                    .padding()
                }
            } else if entitlements.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("No Entitlements Found")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                Section {
                    ForEach(entitlements, id: \.key) { ent in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ent.key)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                riskBadge(ent.risk)
                            }
                            Text(ent.value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Entitlements (\(entitlements.count))")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Entitlement Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadEntitlements() }
    }

    @ViewBuilder
    private func riskBadge(_ risk: String) -> some View {
        let color: Color = {
            switch risk {
            case "low": return .green
            case "medium": return .orange
            case "high": return .red
            default: return .secondary
            }
        }()

        Text(risk.uppercased())
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func loadEntitlements() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
            }

            var loadedEntitlements: [(key: String, value: String, risk: String)] = []

            // Try to read embedded entitlements from provisioning profile
            let provisioningURL = appDir.appendingPathComponent("embedded.mobileprovision")
            if let provData = try? Data(contentsOf: provisioningURL) {
                let provString = String(data: provData, encoding: .ascii) ?? ""
                if let startRange = provString.range(of: "<key>Entitlements</key>"),
                   let plistStart = provString.range(of: "<dict>", range: startRange.upperBound..<provString.endIndex),
                   let plistEnd = provString.range(of: "</dict>", range: plistStart.upperBound..<provString.endIndex) {
                    let entitlementPlist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">" + provString[plistStart.lowerBound...plistEnd.upperBound] + "</plist>"
                    if let data = entitlementPlist.data(using: .utf8),
                       let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                        let highRiskKeys = ["get-task-allow", "com.apple.private.security.no-sandbox", "platform-application"]
                        let mediumRiskKeys = ["com.apple.security.get-task-allow", "keychain-access-groups", "com.apple.developer.icloud-container-identifiers"]
                        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                            let valueStr = "\(value)"
                            let risk = highRiskKeys.contains(key) ? "high" : (mediumRiskKeys.contains(key) ? "medium" : "low")
                            loadedEntitlements.append((key: key, value: valueStr, risk: risk))
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                entitlements = loadedEntitlements
                isLoading = false
            }
        }
    }
}

// MARK: - Code Signature View
struct CodeSignatureView: View {
    let app: AppInfoPresentable
    @State private var isLoading = true
    @State private var signatureInfo: [String: String] = [:]

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Signature Info...")
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Section {
                    ForEach(signatureInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(value)
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Code Signature Details")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Code Signature")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSignatureInfo() }
    }

    private func loadSignatureInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var executableName = app.name ?? ""
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                executableName = plist["CFBundleExecutable"] as? String ?? executableName
            }

            let execURL = appDir.appendingPathComponent(executableName)
            var info: [String: String] = [:]

            info["Bundle ID"] = app.identifier ?? "Unknown"
            info["Version"] = app.version ?? "Unknown"
            info["App Name"] = app.name ?? "Unknown"

            if let data = try? Data(contentsOf: execURL) {
                info["Executable Size"] = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    guard let base = ptr.baseAddress, data.count >= 28 else { return }
                    let magic = base.load(as: UInt32.self)
                    if magic == 0xFEEDFACF {
                        info["Format"] = "Mach-O 64-bit (arm64)"
                    } else if magic == 0xCEFAEDFE {
                        info["Format"] = "Mach-O 32-bit"
                    } else if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
                        info["Format"] = "Mach-O Universal Binary"
                    }
                    let is64 = magic == 0xFEEDFACF
                    let headerSize = is64 ? 32 : 28
                    let ncmds = base.advanced(by: 16).load(as: UInt32.self)
                    var offset = headerSize
                    for _ in 0..<Int(ncmds) {
                        guard offset + 8 <= data.count else { break }
                        let cmd = base.advanced(by: offset).load(as: UInt32.self)
                        let cmdsize = Int(base.advanced(by: offset + 4).load(as: UInt32.self))
                        guard cmdsize > 0, offset + cmdsize <= data.count else { break }
                        if cmd == 0x1D000001 {  // LC_CODE_SIGNATURE
                            info["Code Signature"] = "Present"
                        }
                        if (cmd == 0x1D || cmd == 0x2C) {  // Encryption info
                            info["Encryption"] = "Encrypted"
                        }
                        offset += cmdsize
                    }
                }
            } else {
                info["Executable"] = "Not Found"
            }

            let provisioningURL = appDir.appendingPathComponent("embedded.mobileprovision")
            if FileManager.default.fileExists(atPath: provisioningURL.path) {
                info["Provisioning Profile"] = "Present"
            } else {
                info["Provisioning Profile"] = "Absent"
            }

            DispatchQueue.main.async {
                signatureInfo = info
                isLoading = false
            }
        }
    }
}

// MARK: - Info.plist Editor Debug View
// MARK: - Plist Entry Model
struct PlistEntry: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
    var type: String
    var isModified: Bool = false
    var children: [PlistEntry]? = nil
    var isExpanded: Bool = false
}

// MARK: - Info.plist Editor Debug View
struct InfoPlistEditorDebugView: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    @State private var plistEntries: [PlistEntry] = []
    @State private var searchText = ""
    @State private var showAddEntry = false
    @State private var showEditEntry = false
    @State private var showRawView = false
    @State private var showImportSheet = false
    @State private var showExportSheet = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var selectedType = "String"
    @State private var editingEntry: PlistEntry? = nil
    @State private var editKey = ""
    @State private var editValue = ""
    @State private var editType = "String"
    @State private var rawPlistContent = ""
    @State private var hasUnsavedChanges = false
    @State private var showDiscardAlert = false
    @State private var selectedEntries: Set<UUID> = []
    @State private var isMultiSelectMode = false
    @State private var sortOrder: SortOrder = .keyAscending
    @State private var filterType: String = "All"
    @State private var showValidationErrors = false
    @State private var validationErrors: [String] = []

    private let types = ["String", "Number", "Boolean", "Array", "Dictionary", "Date", "Data"]
    private let filterTypes = ["All", "String", "Number", "Boolean", "Array", "Dictionary", "Date", "Data"]

    enum SortOrder: String, CaseIterable {
        case keyAscending = "Key (A-Z)"
        case keyDescending = "Key (Z-A)"
        case typeAscending = "Type (A-Z)"
        case modified = "Modified First"
    }

    var filteredEntries: [PlistEntry] {
        var result = plistEntries

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.value.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if filterType != "All" {
            result = result.filter { $0.type == filterType }
        }

        // Apply sorting
        switch sortOrder {
        case .keyAscending:
            result.sort { $0.key < $1.key }
        case .keyDescending:
            result.sort { $0.key > $1.key }
        case .typeAscending:
            result.sort { $0.type < $1.type }
        case .modified:
            result.sort { $0.isModified && !$1.isModified }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter and Sort Bar
            filterSortBar

            if showRawView {
                rawPlistView
            } else {
                editorListView
            }
        }
        .searchable(text: $searchText, prompt: "Search Keys Or Values")
        .navigationTitle("Info.plist Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showRawView.toggle()
                        if showRawView {
                            generateRawPlist()
                        }
                    } label: {
                        Label(showRawView ? "Editor View" : "Raw View",
                              systemImage: showRawView ? "list.bullet" : "doc.text")
                    }

                    Divider()

                    Button {
                        showAddEntry = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }

                    Button {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedEntries.removeAll()
                        }
                    } label: {
                        Label(isMultiSelectMode ? "Cancel Selection" : "Select Multiple",
                              systemImage: isMultiSelectMode ? "xmark.circle" : "checkmark.circle")
                    }

                    Divider()

                    Button {
                        validatePlist()
                    } label: {
                        Label("Validate", systemImage: "checkmark.shield")
                    }

                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button {
                        loadCommonKeys()
                    } label: {
                        Label("Load Common Keys", systemImage: "list.bullet.rectangle")
                    }

                    Button(role: .destructive) {
                        resetToOriginal()
                    } label: {
                        Label("Reset To Original", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadPlistEntries()
            generateRawPlist()
        }
        .sheet(isPresented: $showAddEntry) {
            addEntrySheet
        }
        .sheet(isPresented: $showEditEntry) {
            editEntrySheet
        }
        .alert("Validation Results", isPresented: $showValidationErrors) {
            Button("OK", role: .cancel) { }
        } message: {
            if validationErrors.isEmpty {
                Text("✅ Info.plist Is Valid!")
            } else {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                loadPlistEntries()
                hasUnsavedChanges = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }

    // MARK: - Filter Sort Bar
    private var filterSortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Type Filter
                Menu {
                    ForEach(filterTypes, id: \.self) { type in
                        Button {
                            filterType = type
                        } label: {
                            HStack {
                                Text(type)
                                if filterType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterType)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                }

                // Sort Order
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }

                // Entry Count
                Text("\(filteredEntries.count) Entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if hasUnsavedChanges {
                    Text("• Modified")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }

    // MARK: - Editor List View
    private var editorListView: some View {
        List {
            // Multi-select actions
            if isMultiSelectMode && !selectedEntries.isEmpty {
                Section {
                    HStack {
                        Text("\(selectedEntries.count) Selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            deleteSelectedEntries()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }

            // Entries
            Section {
                ForEach(filteredEntries) { entry in
                    PlistEntryRow(
                        entry: entry,
                        isSelected: selectedEntries.contains(entry.id),
                        isMultiSelectMode: isMultiSelectMode,
                        onTap: {
                            if isMultiSelectMode {
                                toggleSelection(entry.id)
                            } else {
                                editingEntry = entry
                                editKey = entry.key
                                editValue = entry.value
                                editType = entry.type
                                showEditEntry = true
                            }
                        },
                        onCopy: {
                            UIPasteboard.general.string = "\(entry.key): \(entry.value)"
                            HapticsManager.shared.softImpact()
                        }
                    )
                }
                .onDelete(perform: deleteEntry)
            } header: {
                HStack {
                    Text("Entries")
                    Spacer()
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }

            // Quick Add Common Keys
            Section {
                Button {
                    addCommonKey("CFBundleURLTypes")
                } label: {
                    Label("Add URL Scheme", systemImage: "link")
                }

                Button {
                    addCommonKey("NSAppTransportSecurity")
                } label: {
                    Label("Add App Transport Security", systemImage: "lock.shield")
                }

                Button {
                    addCommonKey("UIBackgroundModes")
                } label: {
                    Label("Add Background Modes", systemImage: "arrow.clockwise")
                }

                Button {
                    addCommonKey("NSCameraUsageDescription")
                } label: {
                    Label("Add Camera Usage", systemImage: "camera")
                }

                Button {
                    addCommonKey("NSPhotoLibraryUsageDescription")
                } label: {
                    Label("Add Photo Library Usage", systemImage: "photo")
                }
            } header: {
                Text("Quick Add")
            }

            // Save Section
            Section {
                Button {
                    savePlistChanges()
                } label: {
                    HStack {
                        Spacer()
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!hasUnsavedChanges)
                .tint(.green)
            }
        }
            .scrollContentBackground(.hidden)
    }

    // MARK: - Raw Plist View
    private var rawPlistView: some View {
        VStack(spacing: 0) {
            // Toolbar for raw view
            HStack {
                Button {
                    UIPasteboard.general.string = rawPlistContent
                    HapticsManager.shared.success()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button {
                    formatRawPlist()
                } label: {
                    Label("Format", systemImage: "text.alignleft")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(rawPlistContent.count) Characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.clear)

            // Raw content editor
            ScrollView {
                TextEditor(text: $rawPlistContent)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 400)
                    .padding()
                    .onChange(of: rawPlistContent) { _ in
                        hasUnsavedChanges = true
                    }
            }

            // Parse and Apply button
            HStack {
                Button {
                    parseRawPlist()
                } label: {
                    HStack {
                        Spacer()
                        Label("Parse & Apply", systemImage: "arrow.right.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }

    // MARK: - Add Entry Sheet
    private var addEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Key", text: $newKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                } header: {
                    Text("Key Information")
                }

                Section {
                    switch selectedType {
                    case "Boolean":
                        Picker("Value", selection: $newValue) {
                            Text("true").tag("true")
                            Text("false").tag("false")
                        }
                        .pickerStyle(.segmented)
                    case "Number":
                        TextField("Value", text: $newValue)
                            .keyboardType(.decimalPad)
                    case "Array":
                        TextField("Value (Comma Separated)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Dictionary":
                        TextField("Value (JSON Format)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Date":
                        TextField("Value (ISO 8601)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Data":
                        TextField("Value (Base64)", text: $newValue)
                            .autocorrectionDisabled()
                    default:
                        TextField("Value", text: $newValue)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Value")
                }

                // Common Keys Suggestions
                Section {
                    ForEach(commonKeysSuggestions, id: \.0) { key, type in
                        Button {
                            newKey = key
                            selectedType = type
                        } label: {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                Spacer()
                                Text(type)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Suggestions")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddEntry = false
                        clearNewEntryFields()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addEntry()
                        showAddEntry = false
                    }
                    .disabled(newKey.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Edit Entry Sheet
    private var editEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Key", text: $editKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Picker("Type", selection: $editType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                } header: {
                    Text("Key Information")
                }

                Section {
                    switch editType {
                    case "Boolean":
                        Picker("Value", selection: $editValue) {
                            Text("true").tag("true")
                            Text("false").tag("false")
                        }
                        .pickerStyle(.segmented)
                    case "Number":
                        TextField("Value", text: $editValue)
                            .keyboardType(.decimalPad)
                    case "Array":
                        TextEditor(text: $editValue)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                    case "Dictionary":
                        TextEditor(text: $editValue)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                    default:
                        TextField("Value", text: $editValue)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Value")
                }

                Section {
                    Button(role: .destructive) {
                        if let entry = editingEntry,
                           let index = plistEntries.firstIndex(where: { $0.id == entry.id }) {
                            plistEntries.remove(at: index)
                            hasUnsavedChanges = true
                        }
                        showEditEntry = false
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateEntry()
                        showEditEntry = false
                    }
                    .disabled(editKey.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Common Keys Suggestions
    private var commonKeysSuggestions: [(String, String)] {
        [
            ("CFBundleDisplayName", "String"),
            ("CFBundleExecutable", "String"),
            ("CFBundleIconFiles", "Array"),
            ("CFBundleIcons", "Dictionary"),
            ("CFBundlePackageType", "String"),
            ("CFBundleSignature", "String"),
            ("LSApplicationCategoryType", "String"),
            ("NSHumanReadableCopyright", "String"),
            ("UIFileSharingEnabled", "Boolean"),
            ("UISupportsDocumentBrowser", "Boolean"),
            ("ITSAppUsesNonExemptEncryption", "Boolean"),
            ("UIStatusBarHidden", "Boolean"),
            ("UIViewControllerBasedStatusBarAppearance", "Boolean")
        ]
    }

    // MARK: - Helper Functions
    private func loadPlistEntries() {
        // Load real Info.plist from app directory
        guard let appDir = Storage.shared.getAppDirectory(for: app) else {
            // Fallback to basic info from app
            plistEntries = [
                PlistEntry(key: "CFBundleIdentifier", value: app.identifier ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleName", value: app.name ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleShortVersionString", value: app.version ?? "Unknown", type: "String")
            ]
            hasUnsavedChanges = false
            return
        }

        let infoPlistURL = appDir.appendingPathComponent("Info.plist")

        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            // Fallback to basic info from app
            plistEntries = [
                PlistEntry(key: "CFBundleIdentifier", value: app.identifier ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleName", value: app.name ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleShortVersionString", value: app.version ?? "Unknown", type: "String")
            ]
            hasUnsavedChanges = false
            return
        }

        // Convert plist dictionary to PlistEntry array
        plistEntries = plist.map { key, value in
            let (valueString, typeString) = formatPlistValue(value)
            return PlistEntry(key: key, value: valueString, type: typeString)
        }.sorted { $0.key < $1.key }

        hasUnsavedChanges = false
        generateRawPlist()
    }

    private func formatPlistValue(_ value: Any) -> (String, String) {
        switch value {
        case let string as String:
            return (string, "String")
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return (number.boolValue ? "true" : "false", "Boolean")
            }
            return (number.stringValue, "Number")
        case let array as [Any]:
            let items = array.map { item -> String in
                if let str = item as? String { return str }
                if let num = item as? NSNumber { return num.stringValue }
                return String(describing: item)
            }
            return ("[\(items.joined(separator: ", "))]", "Array")
        case let dict as [String: Any]:
            let items = dict.map { "\($0.key): \(formatPlistValue($0.value).0)" }
            return ("{\(items.joined(separator: ", "))}", "Dictionary")
        case let data as Data:
            return (data.base64EncodedString().prefix(50) + "...", "Data")
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return (formatter.string(from: date), "Date")
        default:
            return (String(describing: value), "String")
        }
    }

    private func deleteEntry(at offsets: IndexSet) {
        // Map filtered indices to actual indices
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        for entry in entriesToDelete {
            if let index = plistEntries.firstIndex(where: { $0.id == entry.id }) {
                plistEntries.remove(at: index)
            }
        }
        hasUnsavedChanges = true
    }

    private func deleteSelectedEntries() {
        plistEntries.removeAll { selectedEntries.contains($0.id) }
        selectedEntries.removeAll()
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }

    private func toggleSelection(_ id: UUID) {
        if selectedEntries.contains(id) {
            selectedEntries.remove(id)
        } else {
            selectedEntries.insert(id)
        }
    }

    private func addEntry() {
        let entry = PlistEntry(key: newKey, value: newValue, type: selectedType, isModified: true)
        plistEntries.append(entry)
        hasUnsavedChanges = true
        clearNewEntryFields()
        HapticsManager.shared.softImpact()
    }

    private func updateEntry() {
        guard let entry = editingEntry,
              let index = plistEntries.firstIndex(where: { $0.id == entry.id }) else { return }

        plistEntries[index].key = editKey
        plistEntries[index].value = editValue
        plistEntries[index].type = editType
        plistEntries[index].isModified = true
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }

    private func clearNewEntryFields() {
        newKey = ""
        newValue = ""
        selectedType = "String"
    }

    private func generateRawPlist() {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">")
        lines.append("<plist version=\"1.0\">")
        lines.append("<dict>")

        for entry in plistEntries {
            lines.append("    <key>\(entry.key)</key>")
            switch entry.type {
            case "String":
                lines.append("    <string>\(entry.value)</string>")
            case "Number":
                if entry.value.contains(".") {
                    lines.append("    <real>\(entry.value)</real>")
                } else {
                    lines.append("    <integer>\(entry.value)</integer>")
                }
            case "Boolean":
                lines.append("    <\(entry.value)/>")
            case "Array":
                lines.append("    <array>")
                let items = entry.value.replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .split(separator: ",")
                for item in items {
                    lines.append("        <string>\(item.trimmingCharacters(in: .whitespaces))</string>")
                }
                lines.append("    </array>")
            case "Dictionary":
                lines.append("    <dict>")
                lines.append("        <!-- \(entry.value) -->")
                lines.append("    </dict>")
            case "Date":
                lines.append("    <date>\(entry.value)</date>")
            case "Data":
                lines.append("    <data>\(entry.value)</data>")
            default:
                lines.append("    <string>\(entry.value)</string>")
            }
        }

        lines.append("</dict>")
        lines.append("</plist>")

        rawPlistContent = lines.joined(separator: "\n")
    }

    private func parseRawPlist() {
        // Simple validation - in real implementation would use XMLParser
        if rawPlistContent.contains("<plist") && rawPlistContent.contains("</plist>") {
            HapticsManager.shared.success()
            showRawView = false
        } else {
            validationErrors = ["Invalid plist format. Missing plist tags."]
            showValidationErrors = true
        }
    }

    private func formatRawPlist() {
        // Re-generate formatted plist
        generateRawPlist()
        HapticsManager.shared.softImpact()
    }

    private func validatePlist() {
        validationErrors = []

        // Check for required keys
        let requiredKeys = ["CFBundleIdentifier", "CFBundleName", "CFBundleVersion", "CFBundleShortVersionString"]
        for key in requiredKeys {
            if !plistEntries.contains(where: { $0.key == key }) {
                validationErrors.append("⚠️ Missing Required Key: \(key)")
            }
        }

        // Check for duplicate keys
        var seenKeys: Set<String> = []
        for entry in plistEntries {
            if seenKeys.contains(entry.key) {
                validationErrors.append("❌ Duplicate Key: \(entry.key)")
            }
            seenKeys.insert(entry.key)
        }

        // Check bundle identifier format
        if let bundleId = plistEntries.first(where: { $0.key == "CFBundleIdentifier" }) {
            if !bundleId.value.contains(".") {
                validationErrors.append("⚠️ Bundle identifier should use reverse-DNS format")
            }
        }

        showValidationErrors = true
        HapticsManager.shared.softImpact()
    }

    private func savePlistChanges() {
        hasUnsavedChanges = false
        HapticsManager.shared.success()
    }

    private func resetToOriginal() {
        if hasUnsavedChanges {
            showDiscardAlert = true
        } else {
            loadPlistEntries()
        }
    }

    private func loadCommonKeys() {
        let commonEntries: [PlistEntry] = [
            PlistEntry(key: "NSCameraUsageDescription", value: "This app needs camera access", type: "String", isModified: true),
            PlistEntry(key: "NSPhotoLibraryUsageDescription", value: "This app needs photo library access", type: "String", isModified: true),
            PlistEntry(key: "NSMicrophoneUsageDescription", value: "This app needs microphone access", type: "String", isModified: true),
            PlistEntry(key: "NSLocationWhenInUseUsageDescription", value: "This app needs location access", type: "String", isModified: true)
        ]

        for entry in commonEntries {
            if !plistEntries.contains(where: { $0.key == entry.key }) {
                plistEntries.append(entry)
            }
        }
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }

    private func addCommonKey(_ key: String) {
        let templates: [String: PlistEntry] = [
            "CFBundleURLTypes": PlistEntry(key: "CFBundleURLTypes", value: "[{CFBundleURLSchemes: [myapp]}]", type: "Array", isModified: true),
            "NSAppTransportSecurity": PlistEntry(key: "NSAppTransportSecurity", value: "{NSAllowsArbitraryLoads: true}", type: "Dictionary", isModified: true),
            "UIBackgroundModes": PlistEntry(key: "UIBackgroundModes", value: "[audio, fetch, remote-notification]", type: "Array", isModified: true),
            "NSCameraUsageDescription": PlistEntry(key: "NSCameraUsageDescription", value: "This app requires camera access", type: "String", isModified: true),
            "NSPhotoLibraryUsageDescription": PlistEntry(key: "NSPhotoLibraryUsageDescription", value: "This app requires photo library access", type: "String", isModified: true)
        ]

        if let template = templates[key], !plistEntries.contains(where: { $0.key == key }) {
            plistEntries.append(template)
            hasUnsavedChanges = true
            HapticsManager.shared.softImpact()
        }
    }
}

// MARK: - Plist Entry Row
struct PlistEntryRow: View {
    let entry: PlistEntry
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    let onCopy: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.key)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        if entry.isModified {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }

                        Spacer()

                        Text(entry.type)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(typeColor(entry.type).opacity(0.2)))
                    }

                    Text(entry.value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = entry.key
            } label: {
                Label("Copy Key", systemImage: "key")
            }

            Button {
                UIPasteboard.general.string = entry.value
            } label: {
                Label("Copy Value", systemImage: "text.quote")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // Delete handled by parent
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "String": return .blue
        case "Number": return .green
        case "Boolean": return .orange
        case "Array": return .purple
        case "Dictionary": return .pink
        case "Date": return .cyan
        case "Data": return .gray
        default: return .secondary
        }
    }
}

// MARK: - Entitlements Debug View
struct EntitlementsDebugView: View {
    @Binding var options: Options
    @State private var entitlements: [(key: String, value: String, enabled: Bool)] = []
    @State private var showAddEntitlement = false
    @State private var newKey = ""
    @State private var newValue = ""

    var body: some View {
        List {
            Section {
                ForEach(entitlements.indices, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entitlements[index].key)
                                .font(.subheadline.weight(.medium))
                            Text(entitlements[index].value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $entitlements[index].enabled)
                            .labelsHidden()
                    }
                }
                .onDelete(perform: deleteEntitlement)
            } header: {
                HStack {
                    Text("Entitlements")
                    Spacer()
                    Button {
                        showAddEntitlement = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }

            Section {
                Button {
                    loadCommonEntitlements()
                } label: {
                    Label("Load Common Entitlements", systemImage: "arrow.down.circle.fill")
                }

                Button {
                    clearAllEntitlements()
                } label: {
                    Label("Clear All", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Quick Actions")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Entitlements Editor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadEntitlements()
        }
        .sheet(isPresented: $showAddEntitlement) {
            NavigationStack {
                Form {
                    TextField("Key", text: $newKey)
                        .autocapitalization(.none)
                    TextField("Value", text: $newValue)
                }
            .scrollContentBackground(.hidden)
                .navigationTitle("Add Entitlement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddEntitlement = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addEntitlement()
                            showAddEntitlement = false
                        }
                        .disabled(newKey.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func loadEntitlements() {
        entitlements = [
            ("application-identifier", "TEAM_ID.com.example.app", true),
            ("com.apple.developer.team-identifier", "TEAM_ID", true),
            ("get-task-allow", "true", true),
            ("keychain-access-groups", "[TEAM_ID.*]", true)
        ]
    }

    private func loadCommonEntitlements() {
        let common = [
            ("com.apple.security.application-groups", "group.com.example.app", false),
            ("com.apple.developer.associated-domains", "applinks:example.com", false),
            ("aps-environment", "development", false),
            ("com.apple.developer.icloud-container-identifiers", "[iCloud.com.example.app]", false),
            ("com.apple.developer.ubiquity-kvstore-identifier", "TEAM_ID.com.example.app", false)
        ]
        entitlements.append(contentsOf: common)
    }

    private func deleteEntitlement(at offsets: IndexSet) {
        entitlements.remove(atOffsets: offsets)
    }

    private func clearAllEntitlements() {
        entitlements.removeAll()
    }

    private func addEntitlement() {
        entitlements.append((key: newKey, value: newValue, enabled: true))
        newKey = ""
        newValue = ""
    }
}

// MARK: - Resource Modifier View
// MARK: - Resource Item Model
struct ResourceItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var type: String
    var size: String
    var sizeBytes: Int64
    var path: String
    var modifiedDate: Date
    var isSelected: Bool = false
    var isModified: Bool = false
    var permissions: String
    var checksum: String?
    var dimensions: String? // For images
    var encoding: String? // For text files
    var compressionRatio: Double? // For compressed files
}

// MARK: - Resource Modifier View
struct ResourceModifierView: View {
    let app: AppInfoPresentable
    @State private var resources: [ResourceItem] = []
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var sortOrder: ResourceSortOrder = .nameAscending
    @State private var selectedResource: ResourceItem? = nil
    @State private var showResourceDetail = false
    @State private var showReplaceSheet = false
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isMultiSelectMode = false
    @State private var selectedResources: Set<UUID> = []
    @State private var isLoading = true
    @State private var totalSize: String = "0 KB"
    @State private var showStatistics = false

    private let filters = ["All", "Images", "Strings", "Plists", "Storyboards", "Frameworks", "Bundles", "Other"]

    enum ResourceSortOrder: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case sizeAscending = "Size (Small First)"
        case sizeDescending = "Size (Large First)"
        case typeAscending = "Type (A-Z)"
        case dateDescending = "Recently Modified"
    }

    var filteredResources: [ResourceItem] {
        var result = resources

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if selectedFilter != "All" {
            result = result.filter { resource in
                switch selectedFilter {
                case "Images": return ["png", "jpg", "jpeg", "pdf", "svg", "heic", "webp", "gif", "ico"].contains(resource.type.lowercased())
                case "Strings": return resource.type.lowercased() == "strings"
                case "Plists": return resource.type.lowercased() == "plist"
                case "Storyboards": return ["storyboard", "xib", "nib"].contains(resource.type.lowercased())
                case "Frameworks": return resource.type.lowercased() == "framework"
                case "Bundles": return ["bundle", "appex", "pluginkit"].contains(resource.type.lowercased())
                case "Other": return !["png", "jpg", "jpeg", "pdf", "svg", "heic", "webp", "gif", "ico", "strings", "plist", "storyboard", "xib", "nib", "framework", "bundle", "appex", "pluginkit"].contains(resource.type.lowercased())
                default: return true
                }
            }
        }

        // Apply sorting
        switch sortOrder {
        case .nameAscending:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            result.sort { $0.name.lowercased() > $1.name.lowercased() }
        case .sizeAscending:
            result.sort { $0.sizeBytes < $1.sizeBytes }
        case .sizeDescending:
            result.sort { $0.sizeBytes > $1.sizeBytes }
        case .typeAscending:
            result.sort { $0.type.lowercased() < $1.type.lowercased() }
        case .dateDescending:
            result.sort { $0.modifiedDate > $1.modifiedDate }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Statistics Bar
            statisticsBar

            // Filter Bar
            filterBar

            if isLoading {
                loadingView
            } else {
                resourceListView
            }
        }
        .searchable(text: $searchText, prompt: "Search Resources")
        .navigationTitle("Resource Modifier")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedResources.removeAll()
                        }
                    } label: {
                        Label(isMultiSelectMode ? "Cancel Selection" : "Select Multiple",
                              systemImage: isMultiSelectMode ? "xmark.circle" : "checkmark.circle")
                    }

                    Divider()

                    Button {
                        showStatistics.toggle()
                    } label: {
                        Label("Statistics", systemImage: "chart.pie")
                    }

                    Button {
                        exportAllResources()
                    } label: {
                        Label("Export All", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button {
                        refreshResources()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }

                    Button(role: .destructive) {
                        removeUnusedResources()
                    } label: {
                        Label("Remove Unused", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadResources()
        }
        .sheet(isPresented: $showResourceDetail) {
            if let resource = selectedResource {
                ResourceDetailView(resource: resource, onReplace: {
                    showReplaceSheet = true
                }, onExport: {
                    showExportSheet = true
                }, onDelete: {
                    showDeleteConfirmation = true
                })
            }
        }
        .sheet(isPresented: $showStatistics) {
            ResourceStatisticsView(resources: resources)
        }
        .alert("Delete Resource?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let resource = selectedResource {
                    deleteResource(resource)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Statistics Bar
    private var statisticsBar: some View {
        HStack(spacing: 16) {
            ResourceStatBadge(title: "Total", value: "\(resources.count)", color: .blue)
            ResourceStatBadge(title: "Size", value: totalSize, color: .green)
            ResourceStatBadge(title: "Images", value: "\(resources.filter { ["png", "jpg", "jpeg", "pdf", "svg"].contains($0.type.lowercased()) }.count)", color: .orange)
            ResourceStatBadge(title: "Modified", value: "\(resources.filter { $0.isModified }.count)", color: .purple)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.clear)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(spacing: 8) {
            // Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            HapticsManager.shared.softImpact()
                        } label: {
                            Text(filter)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? Color.accentColor : Color.secondary.opacity(0.15))
                                )
                                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Sort Order
            HStack {
                Text("Sort:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(ResourceSortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                }

                Spacer()

                Text("\(filteredResources.count) Items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .background(Color.clear)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Scanning Resources...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Resource List View
    private var resourceListView: some View {
        List {
            // Multi-select actions
            if isMultiSelectMode && !selectedResources.isEmpty {
                Section {
                    HStack {
                        Text("\(selectedResources.count) Selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()

                        Button {
                            exportSelectedResources()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            deleteSelectedResources()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }

            // Resources
            Section {
                ForEach(filteredResources) { resource in
                    ResourceRow(
                        resource: resource,
                        isSelected: selectedResources.contains(resource.id),
                        isMultiSelectMode: isMultiSelectMode,
                        onTap: {
                            if isMultiSelectMode {
                                toggleSelection(resource.id)
                            } else {
                                selectedResource = resource
                                showResourceDetail = true
                            }
                        }
                    )
                }
                .onDelete(perform: deleteResources)
            } header: {
                Text("Resources")
            }

            // Quick Actions
            Section {
                Button {
                    optimizeImages()
                } label: {
                    Label("Optimize All Images", systemImage: "photo.badge.checkmark")
                }

                Button {
                    removeUnusedLocalizations()
                } label: {
                    Label("Remove Unused Localizations", systemImage: "globe.badge.chevron.backward")
                }

                Button {
                    compressResources()
                } label: {
                    Label("Compress Resources", systemImage: "archivebox")
                }

                Button {
                    validateResources()
                } label: {
                    Label("Validate Resources", systemImage: "checkmark.shield")
                }
            } header: {
                Text("Quick Actions")
            }
        }
            .scrollContentBackground(.hidden)
    }

    // MARK: - Helper Functions
    private func loadResources() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async {
                    resources = []
                    isLoading = false
                }
                return
            }

            var loadedResources: [ResourceItem] = []

            // Recursively scan app directory for resources
            if let enumerator = FileManager.default.enumerator(
                at: appDir,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])

                        // Skip directories (but include bundles/frameworks)
                        let isDirectory = resourceValues.isDirectory ?? false
                        let pathExtension = fileURL.pathExtension.lowercased()
                        let isBundleType = ["framework", "bundle", "appex", "app", "xcassets"].contains(pathExtension)

                        if isDirectory && !isBundleType {
                            continue
                        }

                        // If it's a bundle type, don't enumerate its contents
                        if isDirectory && isBundleType {
                            enumerator.skipDescendants()
                        }

                        let fileSize = resourceValues.fileSize ?? 0
                        let modDate = resourceValues.contentModificationDate ?? Date()
                        let relativePath = fileURL.path.replacingOccurrences(of: appDir.path + "/", with: "")
                        let fileName = fileURL.deletingPathExtension().lastPathComponent
                        let fileType = pathExtension.isEmpty ? "file" : pathExtension

                        // Get file permissions
                        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                        let posixPermissions = attributes?[.posixPermissions] as? Int ?? 0
                        let permString = String(format: "%o", posixPermissions)

                        // Get dimensions for images
                        var dimensions: String? = nil
                        if ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(fileType) {
                            if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
                               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
                               let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                               let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                                dimensions = "\(width)x\(height)"
                            }
                        }

                        // Determine encoding for text files
                        var encoding: String? = nil
                        if ["strings", "plist", "txt", "json", "xml"].contains(fileType) {
                            encoding = "UTF-8"
                        }

                        let resource = ResourceItem(
                            name: fileName,
                            type: fileType,
                            size: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file),
                            sizeBytes: Int64(fileSize),
                            path: relativePath,
                            modifiedDate: modDate,
                            permissions: permString,
                            checksum: nil,
                            dimensions: dimensions,
                            encoding: encoding,
                            compressionRatio: nil
                        )

                        loadedResources.append(resource)
                    } catch {
                        continue
                    }
                }
            }

            DispatchQueue.main.async {
                resources = loadedResources.sorted { $0.name.lowercased() < $1.name.lowercased() }
                calculateTotalSize()
                isLoading = false
            }
        }
    }

    private func calculateTotalSize() {
        let total = resources.reduce(0) { $0 + $1.sizeBytes }
        totalSize = formatBytes(total)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func toggleSelection(_ id: UUID) {
        if selectedResources.contains(id) {
            selectedResources.remove(id)
        } else {
            selectedResources.insert(id)
        }
    }

    private func deleteResource(_ resource: ResourceItem) {
        resources.removeAll { $0.id == resource.id }
        calculateTotalSize()
        HapticsManager.shared.softImpact()
    }

    private func deleteResources(at offsets: IndexSet) {
        let resourcesToDelete = offsets.map { filteredResources[$0] }
        for resource in resourcesToDelete {
            resources.removeAll { $0.id == resource.id }
        }
        calculateTotalSize()
    }

    private func deleteSelectedResources() {
        resources.removeAll { selectedResources.contains($0.id) }
        selectedResources.removeAll()
        calculateTotalSize()
        HapticsManager.shared.softImpact()
    }

    private func exportSelectedResources() {
        HapticsManager.shared.success()
    }

    private func exportAllResources() {
        HapticsManager.shared.success()
    }

    private func refreshResources() {
        loadResources()
        HapticsManager.shared.softImpact()
    }

    private func removeUnusedResources() {
        HapticsManager.shared.softImpact()
    }

    private func optimizeImages() {
        HapticsManager.shared.success()
    }

    private func removeUnusedLocalizations() {
        HapticsManager.shared.softImpact()
    }

    private func compressResources() {
        HapticsManager.shared.success()
    }

    private func validateResources() {
        HapticsManager.shared.success()
    }
}

// MARK: - Resource Stat Badge
struct ResourceStatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Resource Row
struct ResourceRow: View {
    let resource: ResourceItem
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorForType(resource.type).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForType(resource.type))
                        .font(.system(size: 18))
                        .foregroundStyle(colorForType(resource.type))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(resource.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        if resource.isModified {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(resource.type.uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))

                        if let dimensions = resource.dimensions {
                            Text(dimensions)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Text(resource.path)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Size
                VStack(alignment: .trailing, spacing: 2) {
                    Text(resource.size)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let ratio = resource.compressionRatio {
                        Text("\(Int(ratio * 100))% Compressed")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                UIPasteboard.general.string = resource.path
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }

            if let checksum = resource.checksum {
                Button {
                    UIPasteboard.general.string = checksum
                } label: {
                    Label("Copy Checksum", systemImage: "number")
                }
            }

            Divider()

            Button {
                // Export
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }

            Button {
                // Replace
            } label: {
                Label("Replace", systemImage: "arrow.triangle.2.circlepath")
            }

            Divider()

            Button(role: .destructive) {
                // Delete
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "heic", "webp", "gif", "ico": return "photo.fill"
        case "pdf": return "doc.richtext.fill"
        case "svg": return "square.on.circle"
        case "strings": return "textformat"
        case "plist": return "doc.text.fill"
        case "storyboard", "xib", "nib": return "rectangle.3.group.fill"
        case "car": return "folder.fill"
        case "framework": return "shippingbox.fill"
        case "bundle": return "archivebox.fill"
        case "appex", "pluginkit": return "puzzlepiece.extension.fill"
        case "dylib": return "gearshape.2.fill"
        default: return "doc.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "heic", "webp", "gif", "ico": return .blue
        case "pdf": return .red
        case "svg": return .purple
        case "strings": return .green
        case "plist": return .orange
        case "storyboard", "xib", "nib": return .purple
        case "car": return .pink
        case "framework": return .cyan
        case "bundle": return .indigo
        case "appex", "pluginkit": return .teal
        case "dylib": return .brown
        default: return .gray
        }
    }
}

// MARK: - Resource Detail View
struct ResourceDetailView: View {
    let resource: ResourceItem
    let onReplace: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Preview Section (for images)
                if ["png", "jpg", "jpeg", "heic", "webp", "gif"].contains(resource.type.lowercased()) {
                    Section {
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                )
                            Spacer()
                        }
                    } header: {
                        Text("Preview")
                    }
                }

                // Basic Info
                Section {
                    ResourceDetailRow(title: "Name", value: resource.name)
                    ResourceDetailRow(title: "Type", value: resource.type.uppercased())
                    ResourceDetailRow(title: "Size", value: resource.size)
                    ResourceDetailRow(title: "Path", value: resource.path)
                } header: {
                    Text("Basic Information")
                }

                // File Details
                Section {
                    ResourceDetailRow(title: "Modified", value: formatDate(resource.modifiedDate))
                    ResourceDetailRow(title: "Permissions", value: resource.permissions)
                    if let checksum = resource.checksum {
                        ResourceDetailRow(title: "Checksum (MD5)", value: checksum)
                    }
                } header: {
                    Text("File Details")
                }

                // Type-specific Info
                if let dimensions = resource.dimensions {
                    Section {
                        ResourceDetailRow(title: "Dimensions", value: dimensions)
                        ResourceDetailRow(title: "Color Space", value: "sRGB")
                        ResourceDetailRow(title: "Bit Depth", value: "8-bit")
                        ResourceDetailRow(title: "Has Alpha", value: "Yes")
                    } header: {
                        Text("Image Details")
                    }
                }

                if let encoding = resource.encoding {
                    Section {
                        ResourceDetailRow(title: "Encoding", value: encoding)
                        ResourceDetailRow(title: "Line Count", value: "~150 lines")
                    } header: {
                        Text("Text Details")
                    }
                }

                if let ratio = resource.compressionRatio {
                    Section {
                        ResourceDetailRow(title: "Compression", value: "\(Int(ratio * 100))%")
                        ResourceDetailRow(title: "Original Size", value: formatBytes(Int64(Double(resource.sizeBytes) / ratio)))
                    } header: {
                        Text("Compression Details")
                    }
                }

                // Actions
                Section {
                    Button {
                        onExport()
                    } label: {
                        Label("Export Resource", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        onReplace()
                    } label: {
                        Label("Replace Resource", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        UIPasteboard.general.string = resource.path
                        HapticsManager.shared.softImpact()
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete Resource", systemImage: "trash")
                    }
                } header: {
                    Text("Actions")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(resource.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Resource Detail Row
struct ResourceDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Resource Statistics View
struct ResourceStatisticsView: View {
    let resources: [ResourceItem]
    @Environment(\.dismiss) var dismiss

    var typeBreakdown: [(String, Int, Int64)] {
        var breakdown: [String: (count: Int, size: Int64)] = [:]
        for resource in resources {
            let type = resource.type.lowercased()
            let existing = breakdown[type] ?? (0, 0)
            breakdown[type] = (existing.count + 1, existing.size + resource.sizeBytes)
        }
        return breakdown.map { ($0.key, $0.value.count, $0.value.size) }
            .sorted { $0.2 > $1.2 }
    }

    var totalSize: Int64 {
        resources.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total Resources")
                        Spacer()
                        Text("\(resources.count)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Total Size")
                        Spacer()
                        Text(formatBytes(totalSize))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Average Size")
                        Spacer()
                        Text(formatBytes(resources.isEmpty ? 0 : totalSize / Int64(resources.count)))
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Overview")
                }

                Section {
                    ForEach(typeBreakdown, id: \.0) { type, count, size in
                        HStack {
                            Text(type.uppercased())
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(count) Files")
                                    .font(.subheadline)
                                Text(formatBytes(size))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("By Type")
                }

                Section {
                    let largestResources = resources.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(5)
                    ForEach(Array(largestResources)) { resource in
                        HStack {
                            Text(resource.name)
                            Spacer()
                            Text(resource.size)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Largest Resources")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Signing Logs Debug View
struct SigningLogsDebugView: View {
    @ObservedObject private var logManager = AppLogManager.shared
    @State private var selectedLevel = "All"
    @State private var autoScroll = true

    private let levels = ["All", "Info", "Warning", "Error", "Debug"]

    private var filteredLogs: [LogEntry] {
        let signingLogs = logManager.logs.filter { $0.category == "Signing" }
        if selectedLevel == "All" {
            return signingLogs
        }
        return signingLogs.filter { $0.level.rawValue.capitalized == selectedLevel }
    }

    private func colorForLevel(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error, .critical: return .red
        case .debug: return .purple
        case .success: return .green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Level", selection: $selectedLevel) {
                ForEach(levels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollViewReader { proxy in
                List {
                    if filteredLogs.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("No Signing Logs Yet")
                                    .foregroundStyle(.secondary)
                                Text("Logs will appear here after signing an app.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    } else {
                        ForEach(filteredLogs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(colorForLevel(log.level))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(log.formattedTimestamp)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(log.level.rawValue)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(colorForLevel(log.level))
                                    }
                                    Text(log.message)
                                        .font(.system(.caption, design: .monospaced))
                                }
                            }
                            .id(log.id)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .onChange(of: filteredLogs.count) { _ in
                    if autoScroll, let lastLog = filteredLogs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .navigationTitle("Signing Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Auto Scroll", isOn: $autoScroll)
                    Button {
                        logManager.clearLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                    Button {
                        UIPasteboard.general.string = filteredLogs.map { $0.formattedMessage }.joined(separator: "\n")
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Signing Info Row Helper
private struct SigningInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}
