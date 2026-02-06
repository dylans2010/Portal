import Foundation
import Combine
import UIKit
import ActivityKit

/// Manager for handling automatic signing and installation after download
@MainActor
class AutoSignManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AutoSignManager()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization
    private init() {
        setupObservers()
    }

    // MARK: - Setup
    private func setupObservers() {
        NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.handleImportSucceeded(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - Handlers
    private func handleImportSucceeded(_ notification: Notification) {
        // Check if auto-sign is enabled
        guard userDefaults.bool(forKey: "Feather.autoSignAfterDownload") else {
            return
        }

        guard let userInfo = notification.userInfo,
              let appName = userInfo["appName"] as? String else {
            return
        }

        AppLogManager.shared.info("AutoSignManager: Triggering auto-sign for \(appName)", category: "AutoSign")

        // Show toaster
        ToastManager.shared.show("Check Lock Screen For A Live Activity!", type: .info)

        // Start auto-sign process
        Task {
            // Give the database a moment to update with the new imported app
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

            guard let importedApp = Storage.shared.getLatestImportedApp() else {
                AppLogManager.shared.error("AutoSignManager: Failed to find latest imported app for \(appName)", category: "AutoSign")
                return
            }

            await performAutoSign(for: importedApp)
        }
    }

    private func performAutoSign(for app: Imported) async {
        // Get default certificate
        guard let certificate = Storage.shared.getCertificates().first(where: { $0.isDefault }) ?? Storage.shared.getCertificates().first else {
            AppLogManager.shared.error("AutoSignManager: No default certificate found for auto-signing", category: "AutoSign")
            return
        }

        // Use global options
        let options = OptionsManager.shared.options

        // Update Live Activity if active
        if #available(iOS 16.2, *) {
            await LiveActivityManager.shared.updateActivity(
                progress: 0.5,
                bytesDownloaded: 0,
                totalBytes: 0,
                status: .signing,
                timeRemaining: nil,
                speed: nil
            )
        }

        // Trigger signing
        FR.signPackageFile(app, using: options, icon: nil, certificate: certificate) { error in
            if let error = error {
                AppLogManager.shared.error("AutoSignManager: Signing failed: \(error.localizedDescription)", category: "AutoSign")

                if #available(iOS 16.2, *) {
                    LiveActivityManager.shared.endActivityWithError()
                }
            } else {
                AppLogManager.shared.success("AutoSignManager: Signing succeeded for \(app.name ?? "App")", category: "AutoSign")

                // Remove from Library (imported entry) if requested or by default for auto-flow
                // The current flow for signing usually moves it to Signed and optionally deletes Unsigned
                if options.post_deleteAppAfterSigned {
                    Storage.shared.deleteApp(for: app)
                }

                // Trigger background installation
                self.triggerInstallation()
            }
        }
    }

    private func triggerInstallation() {
        // Trigger the installation flow
        // In LibraryView, this is done by posting Feather.installApp
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let latestSigned = Storage.shared.getLatestSignedApp() {
                NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: latestSigned)
            } else {
                NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
            }
        }
    }
}
