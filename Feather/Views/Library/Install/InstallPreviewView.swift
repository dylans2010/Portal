import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - Modern Toaster Install Preview View
struct InstallPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var appearAnimation = false
    @State private var _contentOpacity: Double = 1.0
    @State private var _metalState: MetalAnimationState = .idle
    @State private var _errorMessage: String? = nil
    
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
            Spacer()
            HStack(spacing: 12) {
                // Compact Icon
                FRAppIconView(app: app, size: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .scaleEffect(appearAnimation ? 1 : 0.9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name ?? "Unknown App")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)

                    if let error = _errorMessage {
                        Text(error)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.statusImage)
                                .font(.system(size: 10))
                                .bounceEffect(viewModel.status)
                            Text(viewModel.statusLabel)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }

                Spacer()

                // Compact Progress
                if !viewModel.isCompleted && _errorMessage == nil {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: viewModel.overallProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: viewModel.overallProgress)

                        Text("\(Int(viewModel.overallProgress * 100))")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                } else {
                    actionButtons
                }
            }
            .padding(16)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
            Spacer()
        }
        .padding(.horizontal, 16)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
.applyGlobalTheme()
}
        .onChange(of: viewModel.status) { newStatus in
            _handleStatusChange(newStatus)
        }
        .onReceive(viewModel.$status) { newStatus in
            if _installationMethod == 0 {
                if case .ready = newStatus {
                    if _serverMethod == 0 {
                        UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                    } else if _serverMethod == 3 {
                        UIApplication.shared.open(URL(string: installer.iTunesLinkExternal)!)
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
    
    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCompleted {
            Button {
                if fromLibraryTab {
                    UIApplication.openApp(with: app.identifier ?? "")
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: fromLibraryTab ? "play.fill" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        } else if _errorMessage != nil {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
    }
    
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
            )
            return
        }
        
        Task.detached {
            await MainActor.run { _metalState = .loading }

            do {
                let handler = await ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                let packageUrl = try await handler.archive()
                
                if await !isSharing {
                    if await _installationMethod == 0 {
                        await MainActor.run {
                            _metalState = .success
                            installer.packageUrl = packageUrl
                            viewModel.status = .ready
                        }
                    } else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                        await MainActor.run { _metalState = .success }
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
                    await MainActor.run {
                        _metalState = .success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            dismiss()
                            if _useShareSheet, let package {
                                UIActivityViewController.show(activityItems: [package])
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    _errorMessage = error.localizedDescription
                    _metalState = .error
                }
            }
        }
    }

    private func _handleStatusChange(_ status: InstallerStatusViewModel.InstallerStatus) {
        switch status {
        case .none: break
        case .ready: _metalState = .success
        case .sendingManifest, .sendingPayload, .installing: _metalState = .loading
        case .completed(_):
            _metalState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        case .broken(let error):
            _errorMessage = error.localizedDescription
            _metalState = .error
        }
    }
}
