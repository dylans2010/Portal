import Foundation
import UIKit
import Combine

/// Manager to handle automatic signing and installation after download
@MainActor
class AutoSignManager {
    static let shared = AutoSignManager()

    private var cancellables = Set<AnyCancellable>()
    private let autoSignKey = "Feather.autoSignAfterDownload"

    private init() {}

    func setupObservers() {
        NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)
            .sink { [weak self] notification in
                Task {
                    await self?.handleImportSucceeded(notification)
                }
            }
            .store(in: &cancellables)

        AppLogManager.shared.info("AutoSignManager initialized and observing imports", category: "AutoSign")
    }

    private func handleImportSucceeded(_ notification: Notification) async {
        guard UserDefaults.standard.bool(forKey: autoSignKey) else { return }

        // Short delay to ensure database is updated
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        guard let latestApp = Storage.shared.getLatestImportedApp() else {
            AppLogManager.shared.warning("AutoSign: No imported app found to sign", category: "AutoSign")
            return
        }

        AppLogManager.shared.info("AutoSign: Starting automatic signing for \(latestApp.name ?? "Unknown")", category: "AutoSign")
        await autoSign(app: latestApp)
    }

    private func autoSign(app: Imported) async {
        // Get default certificate
        let certificates = Storage.shared.getCertificates()
        guard let cert = certificates.first(where: { $0.isDefault }) ?? certificates.first else {
            AppLogManager.shared.error("AutoSign: No certificate available for signing", category: "AutoSign")
            return
        }

        // Prepare options
        var options = OptionsManager.shared.options
        options.post_installAppAfterSigned = true // Force install after signing

        // Start Live Activity if enabled
        if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
            LiveActivityManager.shared.startActivity(appName: app.name ?? "App", bundleId: app.identifier ?? "unknown")
            await LiveActivityManager.shared.updateActivity(
                progress: 0.1,
                bytesDownloaded: 0,
                totalBytes: 0,
                status: .signing
            )
        }

        // Perform signing
        FR.signPackageFile(
            app,
            using: options,
            icon: nil,
            certificate: cert
        ) { error in
            if let error = error {
                AppLogManager.shared.error("AutoSign: Signing failed - \(error.localizedDescription)", category: "AutoSign")
                if #available(iOS 16.2, *) {
                    LiveActivityManager.shared.endActivityWithError()
                }
            } else {
                AppLogManager.shared.success("AutoSign: Successfully signed \(app.name ?? "App")", category: "AutoSign")

                // Cleanup unsigned app if option enabled
                if options.post_deleteAppAfterSigned {
                    Storage.shared.deleteApp(for: app)
                }


                if #available(iOS 16.2, *) {
                    LiveActivityManager.shared.endActivityWithSuccess()
                }
            }
        }
    }
}
