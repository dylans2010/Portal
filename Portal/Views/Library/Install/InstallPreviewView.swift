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

// MARK: - View
struct InstallPreviewView: View {
    var onDismiss: () -> Void

    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var progressTask: Task<Void, Never>?
    @ObservedObject var colorManager = AppIconColorManager.shared

    var app: AppInfoPresentable
    @StateObject var viewModel: InstallerStatusViewModel
    @StateObject var installer: ServerInstaller

    @State var isSharing: Bool

    init(app: AppInfoPresentable, isSharing: Bool = false, onDismiss: @escaping () -> Void) {
        self.app = app
        self.isSharing = isSharing
        self.onDismiss = onDismiss
        let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
    }

    // MARK: Body
    var body: some View {
        InstallProgressView(app: app, viewModel: viewModel) {
            _button()
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
        .onAppear(perform: _install)
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
    private func _button() -> some View {
        Button {
            onDismiss()
        } label: {
            Text(viewModel.isCompleted ? "Close" : "Cancel")
                .font(.footnote)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .foregroundColor(colorManager.primaryColor.adaptiveForeground)
                .cornerRadius(20)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isCompleted)
        .compatTransition()
    }

    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update ‘%@‘ with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
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
            // Since UIApplication.installProgress(for:) is not available,
            // we will simulate the completion of the installation.
            // In the future, a proper progress tracking mechanism should be implemented.

            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay to simulate installation

            await MainActor.run {
                viewModel.installProgress = 1.0
                viewModel.status = .completed(.success(()))
            }
        }
    }
}
