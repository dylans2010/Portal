//
//  InstallPreview.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//

import SwiftUI
import NimbleViews
import IDeviceSwift
import OSLog

struct InstallPreviewView: View {
    var onDismiss: () -> Void

    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @AppStorage("Feather.showAdvancedInstallView") private var _showAdvancedInstallView: Bool = false
    @State private var _isWebviewPresenting = false
    @State private var progressTask: Task<Void, Never>?

    var app: AppInfoPresentable
    var installSource: InstallSource
    @StateObject var viewModel: InstallerStatusViewModel
    @StateObject var installer: ServerInstaller

    @State var isSharing: Bool

    init(
        app: AppInfoPresentable,
        isSharing: Bool = false,
        installSource: InstallSource = .userImported,
        onDismiss: @escaping () -> Void
    ) {
        self.app = app
        self.isSharing = isSharing
        self.installSource = installSource
        self.onDismiss = onDismiss
        let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
    }

    var body: some View {
        Group {
            if _showAdvancedInstallView {
                AdvancedInfoDisplayView(
                    app: app,
                    viewModel: viewModel,
                    installer: installer,
                    installSource: installSource,
                    onInstall: _install,
                    onOpen: {
                        if let bundleID = app.identifier,
                           let url = URL(string: "portal://open?bundleID=\(bundleID)") {
                            UIApplication.shared.open(url)
                        }
                        onDismiss()
                    },
                    onRetry: _install,
                    onCancel: onDismiss
                ) {
                    _closeButton()
                }
            } else {
                InstallProgressView(
                    app: app,
                    viewModel: viewModel,
                    installSource: installSource,
                    onInstall: _install,
                    onOpen: {
                        if let bundleID = app.identifier,
                           let url = URL(string: "portal://open?bundleID=\(bundleID)") {
                            UIApplication.shared.open(url)
                        }
                        onDismiss()
                    }
                ) {
                    _closeButton()
                }
            }
        }
        .sheet(isPresented: $_isWebviewPresenting) {
            SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
        }
        .onReceive(viewModel.$status) { newStatus in
            if _installationMethod == 0 {
                if case .ready = newStatus {
                    if _serverMethod == 0 {
                        UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                    } else if _serverMethod == 1 {
                        _isWebviewPresenting = true
                    }
                }

                if case .sendingPayload = newStatus, _serverMethod == 1 {
                    _isWebviewPresenting = false
                }

                if case .installing = newStatus {
                    if progressTask == nil {
                        progressTask = startInstallProgressPolling(
                            bundleID: app.identifier!,
                            viewModel: viewModel
                        )
                    }
                }

                switch newStatus {
                case .completed, .broken(_):
                    progressTask?.cancel()
                    progressTask = nil
                    BackgroundAudioManager.shared.stop()
                default:
                    break
                }
            }
        }
        .onAppear {
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            progressTask?.cancel()
            progressTask = nil
            BackgroundAudioManager.shared.stop()
        }
    }

    @ViewBuilder
    private func _closeButton() -> some View {
        Button {
            onDismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 30, height: 30)
                .background {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                        Circle()
                            .fill(Color.primary.opacity(0.04))
                        Circle()
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    }
                }
                .clipShape(Circle())
        }
    }

    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
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

                        if case .installing = await viewModel.status {
                            let task = await startInstallProgressPolling(
                                bundleID: app.identifier!,
                                viewModel: viewModel
                            )

                            await MainActor.run {
                                progressTask = task
                            }
                        }
                    } else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)

                    if await !_useShareSheet {
                        await MainActor.run {
                            onDismiss()
                        }
                    } else {
                        if let package {
                            await MainActor.run {
                                onDismiss()
                                UIActivityViewController.show(activityItems: [package])
                            }
                        }
                    }
                }
            } catch {
                await progressTask?.cancel()

                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Install"),
                        message: String(describing: error),
                        action: {
                            HeartbeatManager.shared.start(true)
                            onDismiss()
                        }
                    )
                }
            }
        }
    }

    private func startInstallProgressPolling(
        bundleID: String,
        viewModel: InstallerStatusViewModel
    ) -> Task<Void, Never> {

        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                viewModel.installProgress = 1.0
                viewModel.status = .completed(.success(()))
            }
        }
    }
}
