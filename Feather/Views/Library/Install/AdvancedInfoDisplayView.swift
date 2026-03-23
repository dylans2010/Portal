import SwiftUI
import IDeviceSwift

struct AdvancedInfoDisplayView<Footer: View>: View {
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0

    @State private var _appeared = false
    @State private var _appSizeString: String = ""
    @State private var _logs: [LogEntry] = []
    @State private var _autoScroll = true
    @State private var _showInstallSheet = false

    // Collapsible states
    @State private var _isCoreInfoExpanded = true
    @State private var _isSourceMethodExpanded = true
    @State private var _isFilePathExpanded = false
    @State private var _isSigningExpanded = true
    @State private var _isLogsExpanded = true
    @State private var _isProgressExpanded = true
    @State private var _isPerformanceExpanded = false
    @State private var _isDebugExpanded = false

    // Additional data
    @State private var _minIOS: String = "N/A"
    @State private var _buildNumber: String = "N/A"

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
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    if !viewModel.isInProgress {
                        onCancel?()
                    }
                }

            VStack(spacing: 0) {
                _header()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            _coreAppInfoSection()
                            _installationSourceSection()
                            _progressStatusSection()
                            _liveLogsSection(proxy: proxy)
                            _signingDetailsSection()
                            _filePathSection()
                            _performanceMetricsSection()
                            _advancedDebugSection()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }

                _bottomActions()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.vertical, 40)
            .offset(y: _appeared ? 0 : 600)
        }
        .sheet(isPresented: $_showInstallSheet) {
            DetailedInstallInfoView(
                app: app,
                installer: installer,
                appSize: _appSizeString,
                minIOS: _minIOS,
                buildNumber: _buildNumber
            )
            .presentationDetents([.large])
        }
        .onAppear {
            _computeAppSize()
            _loadExtendedAppInfo()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                _appeared = true
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func _header() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Installation Diagnostics")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(viewModel.statusLabel)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(viewModel.statusColor)
            }
            Spacer()
            footer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color.primary.opacity(0.03))
    }

    @ViewBuilder
    private func _sectionHeader(title: String, systemImage: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation { isExpanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func _coreAppInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Core App Information", systemImage: "info.circle.fill", isExpanded: $_isCoreInfoExpanded)

            if _isCoreInfoExpanded {
                HStack(spacing: 16) {
                    FRAppIconView(app: app, size: 64)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name ?? "Unknown App")
                            .font(.headline)
                        Text(app.identifier ?? "unknown.bundle.id")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("v\(app.version ?? "0.0") (\(_buildNumber))")
                            Text("•")
                            Text(_appSizeString)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)

                        Text("Min iOS: \(_minIOS)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _installationSourceSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Installation Source & Method", systemImage: "shippingbox.fill", isExpanded: $_isSourceMethodExpanded)

            if _isSourceMethodExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    _infoRow(label: "Method", value: _installationMethod == 1 ? "Direct (IDeviceSwift)" : "Server-based")

                    if let installer = installer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Install Link")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(installer.iTunesLink)
                                    .font(.system(size: 10, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = installer.iTunesLink
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        _infoRow(label: "Server Port", value: "\(installer.port)")
                    }

                    _infoRow(label: "Signing", value: _installationMethod == 1 ? "Local" : "Remote/Server")
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _progressStatusSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Progress + Status System", systemImage: "gauge.with.needle.fill", isExpanded: $_isProgressExpanded)

            if _isProgressExpanded {
                VStack(spacing: 16) {
                    HStack {
                        Text(viewModel.statusLabel)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(Int(viewModel.overallProgress * 100))%")
                            .font(.system(.subheadline, design: .monospaced))
                    }

                    ProgressView(value: viewModel.overallProgress)
                        .tint(viewModel.statusColor)

                    if _installationMethod == 1 {
                        VStack(spacing: 8) {
                            _progressMiniRow(label: "Packaging", progress: viewModel.packageProgress)
                            _progressMiniRow(label: "Uploading", progress: viewModel.uploadProgress)
                            _progressMiniRow(label: "Installing", progress: viewModel.installProgress)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _liveLogsSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                _sectionHeader(title: "Live Installation Logs", systemImage: "terminal.fill", isExpanded: $_isLogsExpanded)
                Spacer()
                if _isLogsExpanded {
                    HStack(spacing: 12) {
                        Button {
                            _autoScroll.toggle()
                        } label: {
                            Image(systemName: _autoScroll ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 12))
                                .foregroundColor(_autoScroll ? .blue : .secondary)
                        }

                        Button {
                            UIPasteboard.general.string = appLogManager.exportLogs()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                        }
                    }
                }
            }

            if _isLogsExpanded {
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
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: appLogManager.logs.count) { _ in
                        if _autoScroll, let last = appLogManager.logs.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _signingDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Signing & Entitlements Details", systemImage: "key.fill", isExpanded: $_isSigningExpanded)

            if _isSigningExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    _infoRow(label: "Certificate", value: "Auto-selected")
                    _infoRow(label: "Entitlements", value: "Standard + Injected")
                    _infoRow(label: "Profile", value: "Provisioning managed by Feather")
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _filePathSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "File & Path Information", systemImage: "folder.fill", isExpanded: $_isFilePathExpanded)

            if _isFilePathExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    _pathRow(label: "Source IPA", path: app.archiveURL?.path ?? "N/A")
                    if let uuidDir = Storage.shared.getUuidDirectory(for: app) {
                        _pathRow(label: "Working Dir", path: uuidDir.path)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _performanceMetricsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Network & Performance", systemImage: "bolt.fill", isExpanded: $_isPerformanceExpanded)

            if _isPerformanceExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    _infoRow(label: "Status", value: "Monitoring...")
                    _infoRow(label: "Latency", value: "Normal")
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _advancedDebugSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            _sectionHeader(title: "Advanced Debug", systemImage: "ladybug.fill", isExpanded: $_isDebugExpanded)

            if _isDebugExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    _infoRow(label: "Internal ID", value: app.uuid ?? "N/A")
                    _infoRow(label: "Status Code", value: "\(viewModel.currentStep)")
                    _infoRow(label: "Method ID", value: "\(_installationMethod)")
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func _bottomActions() -> some View {
        VStack(spacing: 12) {
            if viewModel.isCompleted {
                if viewModel.isError {
                    _largeButton(title: "Retry Installation", icon: "arrow.clockwise", color: .blue, action: { onRetry?() })
                } else {
                    HStack(spacing: 12) {
                        _largeButton(title: "Install App", icon: "arrow.down.circle.fill", color: .blue, action: { _showInstallSheet = true })
                        _largeButton(title: "Open App", icon: "arrow.up.right.square", color: .green, action: { onOpen?() })

                        Button {
                            if let archiveURL = app.archiveURL {
                                UIActivityViewController.show(activityItems: [archiveURL])
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                _largeButton(title: "Close", icon: "xmark", color: .secondary, action: { onCancel?() })
            } else if !viewModel.isInProgress {
                _largeButton(title: "Start Installation", icon: "play.fill", color: .blue, action: { onInstall?() })
            } else {
                _largeButton(title: "Cancel Installation", icon: "stop.fill", color: .red, action: { onCancel?() })
            }
        }
        .padding(24)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func _infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func _pathRow(label: String, path: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(path)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private func _progressMiniRow(label: String, progress: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                .tint(progress >= 1.0 ? .green : .blue)
        }
    }

    @ViewBuilder
    private func _largeButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .clipShape(Capsule())
        }
    }

    private func _logColor(for level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error, .critical: return .red
        }
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
}

struct DetailedInstallInfoView: View {
    @Environment(\.dismiss) var dismiss

    var app: AppInfoPresentable
    var installer: ServerInstaller?
    var appSize: String
    var minIOS: String
    var buildNumber: String

    @State private var certPair: CertificatePair?
    @State private var decodedCert: Certificate?

    var body: some View {
        NavigationStack {
            List {
                Section("App Information") {
                    LabeledContent("Name", value: app.name ?? "Unknown")
                    LabeledContent("Identifier", value: app.identifier ?? "N/A")
                    LabeledContent("Version", value: app.version ?? "N/A")
                    LabeledContent("Build", value: buildNumber)
                    LabeledContent("Min iOS", value: minIOS)
                    LabeledContent("Size", value: appSize)
                }

                Section("Signing Details") {
                    if let cert = certPair {
                        LabeledContent("Certificate", value: cert.nickname ?? "N/A")
                        if let decoded = decodedCert {
                            LabeledContent("Team Name", value: decoded.TeamName)
                            LabeledContent("Team ID", value: decoded.TeamIdentifier.first ?? "N/A")
                            LabeledContent("Profile Name", value: decoded.Name)
                            LabeledContent("Expiration", value: decoded.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
                            LabeledContent("Profile UUID", value: decoded.UUID)
                        }
                    } else {
                        Text("No certificate information available")
                            .foregroundColor(.secondary)
                    }
                }

                if let installer = installer {
                    Section("Server Details") {
                        LabeledContent("Port", value: "\(installer.port)")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Manifest URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(installer.plistEndpoint.absoluteString)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPA URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(installer.payloadEndpoint.absoluteString)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }

                    Section("ITMS Link") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(installer.iTunesLink)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        }

                        Button {
                            UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                        } label: {
                            Label("Confirm & Install", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Install Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            certPair = Storage.shared.getCertificate(from: app)
            if let cert = certPair {
                decodedCert = Storage.shared.getProvisionFileDecoded(for: cert)
            }
        }
    }
}
