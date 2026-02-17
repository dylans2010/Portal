import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - Modern Install Preview View
struct InstallPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    var onDismiss: (() -> Void)? = nil

    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var appearAnimation = false
    
    var app: AppInfoPresentable
    @StateObject var viewModel: InstallerStatusViewModel
    @StateObject var installer: ServerInstaller
    
    @State var isSharing: Bool
    @State var fromLibraryTab: Bool = true
    
    init(app: AppInfoPresentable, isSharing: Bool = false, fromLibraryTab: Bool = true) {
        self.app = app
        self.isSharing = isSharing
        self.fromLibraryTab = fromLibraryTab
        let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    InstallProgressView(app: app, viewModel: viewModel)
                        .scaleEffect(appearAnimation ? 1 : 0.9)
                        .opacity(appearAnimation ? 1 : 0)

                    if onDismiss != nil {
                        Spacer()

                        Button {
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .padding(.top, 4)
                    }
                }
                
                statusLabel
                    .offset(y: appearAnimation ? 0 : 10)
                    .opacity(appearAnimation ? 1 : 0)
                
                actionButtons
                    .offset(y: appearAnimation ? 0 : 15)
                    .opacity(appearAnimation ? 1 : 0)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(16)

            if onDismiss == nil {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appearAnimation = true
            }
            _install()
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            BackgroundAudioManager.shared.stop()
        }
        .sheet(isPresented: $_isWebviewPresenting) {
            SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
        }
        .onReceive(viewModel.$status) { newStatus in
            if _installationMethod == 0 {
                if case .ready = newStatus {
                    if _serverMethod == 0 {
                        UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                    } else if _serverMethod == 1 || _serverMethod == 2 {
                        _isWebviewPresenting = true
                    }
                }
                
                if case .sendingPayload = newStatus, (_serverMethod == 1 || _serverMethod == 2) {
                    _isWebviewPresenting = false
                }
                
                if case .completed = newStatus {
                    BackgroundAudioManager.shared.stop()
                }
            }
        }
    }
    
    // MARK: - Status Label
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.statusImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(statusColor)
            
            Text(viewModel.statusLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.statusImage)
    }
    
    private var statusColor: Color {
        if viewModel.isCompleted {
            return .green
        } else if case .broken = viewModel.status {
            return .red
        }
        return .accentColor
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCompleted {
            if fromLibraryTab {
                Button {
                    UIApplication.openApp(with: app.identifier ?? "")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Open")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            } else {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: Notification.Name("Feather.openSigningView"),
                                object: app
                            )
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Modify")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    
                    Button {
                        viewModel.status = .none
                        viewModel.uploadProgress = 0
                        viewModel.packageProgress = 0
                        viewModel.installProgress = 0
                        _install()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Install")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Install logic to avoid signing the app with the same app
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
            )
            return
        }
        
        Task.detached {
            do {
                let handler = await ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                
                let packageUrl = try await handler.archive()
                
                if await !isSharing {
                    if await _installationMethod == 0 {
                        await MainActor.run {
                            installer.packageUrl = packageUrl
                            viewModel.status = .ready
                        }
                    } else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
                    
                    if await !_useShareSheet {
                        await MainActor.run {
                            if let onDismiss { onDismiss() } else { dismiss() }
                        }
                    } else {
                        if let package {
                            await MainActor.run {
                                if let onDismiss { onDismiss() } else { dismiss() }
                                UIActivityViewController.show(activityItems: [package])
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Install"),
                        message: String(describing: error),
                        action: {
                            HeartbeatManager.shared.start(true)
                            if let onDismiss { onDismiss() } else { dismiss() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct ContentTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.symbolEffect)
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}
