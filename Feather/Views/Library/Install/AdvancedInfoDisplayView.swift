import SwiftUI
import IDeviceSwift

struct AdvancedInfoDisplayView<Footer: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0

    @State private var _appSizeString: String = ""
    @State private var _autoScroll = true

    // Additional data
    @State private var _minIOS: String = "N/A"
    @State private var _buildNumber: String = "N/A"
    @State private var _deviceModel: String = UIDevice.current.model
    @State private var _osVersion: String = UIDevice.current.systemVersion
    @State private var _architecture: String = "arm64" // Default for modern iOS
    @State private var _freeDiskSpace: String = "Calculating..."

    @State private var _certPair: CertificatePair?
    @State private var _decodedCert: Certificate?

    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    @ObservedObject var appLogManager = AppLogManager.shared
    var installer: ServerInstaller?
    var installSource: InstallSource
    let footer: () -> Footer

    var onInstall: (() -> Void)?
    var onOpen: (() -> Void)?
    var onRetry: (() -> Void)?
    var onCancel: (() -> Void)?

    init(
        app: AppInfoPresentable,
        viewModel: InstallerStatusViewModel,
        installer: ServerInstaller? = nil,
        installSource: InstallSource = .userImported,
        onInstall: (() -> Void)? = nil,
        onOpen: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.app = app
        self.viewModel = viewModel
        self.installer = installer
        self.installSource = installSource
        self.onInstall = onInstall
        self.onOpen = onOpen
        self.onRetry = onRetry
        self.onCancel = onCancel
        self.footer = footer
    }

    var body: some View {
        NavigationStack {
            List {
                _headerSection()
                _progressSection()
                _deviceDiagnosticsSection()
                _ipaMetadataSection()
                _signingDetailsSection()
                _serverNetworkSection()
                _liveLogsSection()
                _actionSection()
            }
            .navigationTitle("Installation Diagnostics")
            .appWideHeaderTitle(displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onCancel?()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    footer()
                }
            }
            .onAppear {
                _computeAppSize()
                _loadExtendedAppInfo()
                _loadDeviceDiagnostics()
                _loadSigningInfo()
            }
            .safeAreaInset(edge: .bottom) {
                if _canShowInstallButton, let url = _installURL {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Install App", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.buttonBackgroundColor)
                    .foregroundStyle(themeManager.buttonTextColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(themeManager.appBackgroundColor.opacity(0.96))
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func _headerSection() -> some View {
        Section {
            HStack(spacing: 16) {
                FRAppIconView(app: app, size: 64)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name ?? "Unknown App")
                        .font(.headline)
                        .foregroundStyle(themeManager.primaryTextColor)
                    Text(app.identifier ?? "unknown.bundle.id")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)

                    Text("v\(app.version ?? "0.0") (\(_buildNumber))")
                        .font(.caption2)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func _progressSection() -> some View {
        Section("Installation Progress") {
            VStack(spacing: 12) {
                HStack {
                    Text(viewModel.statusLabel)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(.subheadline, design: .monospaced))
                }

                ProgressView(value: viewModel.overallProgress)
                    .tint(themeManager.accentColor)

                if _installationMethod == 1 {
                    VStack(spacing: 8) {
                        _progressMiniRow(label: "Packaging", progress: viewModel.packageProgress)
                        _progressMiniRow(label: "Uploading", progress: viewModel.uploadProgress)
                        _progressMiniRow(label: "Installing", progress: viewModel.installProgress)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func _deviceDiagnosticsSection() -> some View {
        Section("Device Diagnostics") {
            LabeledContent("Model", value: _deviceModel)
            LabeledContent("OS Version", value: _osVersion)
            LabeledContent("Architecture", value: _architecture)
            LabeledContent("Free Space", value: _freeDiskSpace)
        }
    }

    @ViewBuilder
    private func _ipaMetadataSection() -> some View {
        Section("IPA Metadata") {
            LabeledContent("Size", value: _appSizeString)
            LabeledContent("Min iOS", value: _minIOS)
            LabeledContent("Bundle ID", value: app.identifier ?? "N/A")
            LabeledContent("Version", value: app.version ?? "N/A")

            if let archiveURL = app.archiveURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source Path")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                    Text(archiveURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(themeManager.primaryTextColor)
                }
            }
        }
    }

    @ViewBuilder
    private func _signingDetailsSection() -> some View {
        Section("Signing Diagnostics") {
            if let cert = _certPair {
                LabeledContent("Certificate", value: cert.nickname ?? "N/A")
                if let decoded = _decodedCert {
                    LabeledContent("Team Name", value: decoded.TeamName)
                    LabeledContent("Team ID", value: decoded.TeamIdentifier.first ?? "N/A")
                    LabeledContent("Profile Name", value: decoded.Name)
                    LabeledContent("Expiration", value: decoded.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Profile UUID", value: decoded.UUID)
                }
            } else {
                Text("No signing information available")
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
        }
    }

    @ViewBuilder
    private func _serverNetworkSection() -> some View {
        Section("Network & Server") {
            LabeledContent("Install Method", value: _installationMethod == 1 ? "Direct (IDeviceSwift)" : "Server-based")

            if let installer = installer {
                LabeledContent("Port", value: "\(installer.port)")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Manifest URL")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                    Text(installer.plistEndpoint.absoluteString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(themeManager.primaryTextColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("IPA URL")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                    Text(installer.payloadEndpoint.absoluteString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(themeManager.primaryTextColor)
                }
            }
        }
    }

    @ViewBuilder
    private func _liveLogsSection() -> some View {
        Section {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(appLogManager.logs.suffix(100)) { log in
                                Text(log.formattedMessage)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(_logColor(for: log.level))
                                    .id(log.id)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 180)
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: appLogManager.logs.count) { _ in
                        if _autoScroll, let last = appLogManager.logs.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Live Installation Logs")
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        _autoScroll.toggle()
                    } label: {
                        Image(systemName: _autoScroll ? "lock.fill" : "lock.open.fill")
                    }

                    Button {
                        UIPasteboard.general.string = appLogManager.exportLogs()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
                .font(.caption)
                .textCase(nil)
            }
        }
    }

    @ViewBuilder
    private func _actionSection() -> some View {
        Section {
            if viewModel.isCompleted {
                if viewModel.isError {
                    Button {
                        onRetry?()
                    } label: {
                        Label("Retry Installation", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                onOpen?()
                            } label: {
                                Label("Open App", systemImage: "arrow.up.right.square")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                if let archiveURL = app.archiveURL {
                                    UIActivityViewController.show(activityItems: [archiveURL])
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(.horizontal, 12)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            } else if !viewModel.isInProgress {
                Button {
                    onInstall?()
                } label: {
                    Label("Start Installation", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("Install App button is pinned at the bottom.", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func _progressMiniRow(label: String, progress: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(themeManager.secondaryTextColor)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            ProgressView(value: progress)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                .tint(themeManager.accentColor)
        }
    }

    private func _logColor(for level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return themeManager.secondaryTextColor
        case .info: return themeManager.accentColor
        case .success: return themeManager.selectionColor
        case .warning: return themeManager.warningColor
        case .error, .critical: return themeManager.destructiveColor
        }
    }

    private var _installURL: URL? {
        guard let installer, let url = URL(string: installer.iTunesLink) else { return nil }
        return url
    }

    private var _canShowInstallButton: Bool {
        _installURL != nil && !viewModel.isError
    }

    private func _computeAppSize() {
        if let url = app.archiveURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    _appSizeString = _formatBytes(fileSize)
                }
            } catch {}
        }
    }

    private func _formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        else { return String(format: "%.1f MB", mb) }
    }

    private func _loadExtendedAppInfo() {
        if let bundleURL = Storage.shared.getAppDirectory(for: app),
           let infoDict = NSDictionary(contentsOf: bundleURL.appendingPathComponent("Info.plist")) {
            _minIOS = infoDict["MinimumOSVersion"] as? String ?? "N/A"
            _buildNumber = infoDict["CFBundleVersion"] as? String ?? "N/A"
        }
    }

    private func _loadDeviceDiagnostics() {
        let fileManager = FileManager.default
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            _freeDiskSpace = _formatBytes(UInt64(freeSize))
        }

        #if targetEnvironment(simulator)
        _architecture = "x86_64 / arm64 (Sim)"
        #else
        _architecture = "arm64"
        #endif
    }

    private func _loadSigningInfo() {
        _certPair = Storage.shared.getCertificate(from: app)
        if let cert = _certPair {
            _decodedCert = Storage.shared.getProvisionFileDecoded(for: cert)
        }
    }
}
