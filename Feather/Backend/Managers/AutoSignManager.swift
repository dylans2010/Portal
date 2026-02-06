import Foundation
import UIKit
import ActivityKit
import Combine

/// Manager for handling automatic signing after download
/// This manager coordinates downloading, signing, and installation of apps
class AutoSignManager: ObservableObject {
	static let shared = AutoSignManager()
	
	// Constant for auto-sign setting key
	private static let autoSignSettingKey = "Feather.autoSignAfterDownload"
	
	// Track ongoing auto-sign operations
	@Published var activeOperations: [String: AutoSignOperation] = [:]
	
	private init() {}
	
	/// Check if auto-sign is enabled
	var isAutoSignEnabled: Bool {
		UserDefaults.standard.bool(forKey: Self.autoSignSettingKey)
	}
	
	/// Start an auto-sign operation for a downloaded app
	/// - Parameters:
	///   - download: The download that completed
	///   - appInfo: Information about the app (name, bundleId)
	func handleDownloadCompletion(download: Download, appInfo: ImportedAppInfo) {
		guard isAutoSignEnabled else {
			AppLogManager.shared.info("Auto-sign disabled, skipping automatic signing", category: "AutoSign")
			return
		}
		
		AppLogManager.shared.info("Starting auto-sign process for \(appInfo.name)", category: "AutoSign")
		
		// Show toast notification
		DispatchQueue.main.async {
			ToastManager.shared.show(
				"Check Lock Screen For A Live Activity!".localized(),
				type: .info,
				duration: 4.0
			)
		}
		
		// Create operation
		let operation = AutoSignOperation(
			downloadId: download.id,
			appInfo: appInfo
		)
		
		activeOperations[download.id] = operation
		
		// Start the auto-sign process
		Task {
			await performAutoSign(operation: operation)
		}
	}
	
	/// Perform the complete auto-sign process
	private func performAutoSign(operation: AutoSignOperation) async {
		let appInfo = operation.appInfo
		
		do {
			// Step 1: Get the imported app from database
			guard let importedApp = await getImportedApp(name: appInfo.name, bundleId: appInfo.bundleId) else {
				throw AutoSignError.appNotFound
			}
			
			AppLogManager.shared.info("Found imported app: \(appInfo.name)", category: "AutoSign")
			
			// Step 2: Update Live Activity to signing state
			if #available(iOS 16.2, *) {
				await updateLiveActivity(status: .signing, progress: 0.3)
			}
			
			// Step 3: Get default certificate
			guard let certificate = getDefaultCertificate() else {
				throw AutoSignError.noCertificateAvailable
			}
			
			AppLogManager.shared.info("Using certificate: \(certificate.nickname ?? "Default")", category: "AutoSign")
			
			// Step 4: Get signing options
			let options = await getSigningOptions()
			
			// Step 5: Sign the app
			AppLogManager.shared.info("Starting signing process for \(appInfo.name)", category: "AutoSign")
			
			let signedApp = try await signApp(
				app: importedApp,
				certificate: certificate,
				options: options
			)
			
			AppLogManager.shared.success("Successfully signed \(appInfo.name)", category: "AutoSign")
			
			// Step 6: Update Live Activity to installing state
			if #available(iOS 16.2, *) {
				await updateLiveActivity(status: .installing, progress: 0.8)
			}
			
			// Step 7: Install the app if installation method is iDevice
			let installationMethod = UserDefaults.standard.integer(forKey: "Feather.installationMethod")
			if installationMethod == 1 {
				// Get the IPA file URL from the signed app
				guard let ipaURL = signedApp.archiveURL else {
					throw AutoSignError.signedAppNotFound
				}
				
				AppLogManager.shared.info("Installing \(appInfo.name) via iDevice", category: "AutoSign")
				try await installApp(at: ipaURL, bundleId: appInfo.bundleId)
				AppLogManager.shared.success("Successfully installed \(appInfo.name)", category: "AutoSign")
			} else {
				AppLogManager.shared.info("Installation method is server-based, skipping automatic installation", category: "AutoSign")
			}
			
			// Step 8: Delete from library (both imported and signed apps)
			await deleteFromLibrary(app: importedApp)
			await deleteFromLibrary(app: signedApp)
			AppLogManager.shared.info("Deleted \(appInfo.name) from library", category: "AutoSign")
			
			// Step 9: Complete Live Activity
			if #available(iOS 16.2, *) {
				await updateLiveActivity(status: .completed, progress: 1.0)
				DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
					LiveActivityManager.shared.endActivityWithSuccess()
				}
			}
			
			// Success notification
			await MainActor.run {
				HapticsManager.shared.success()
				if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
					NotificationManager.shared.sendAppSignedNotification(appName: appInfo.name)
				}
			}
			
			// Clean up operation and remove download
			await MainActor.run {
				activeOperations.removeValue(forKey: operation.downloadId)
				
				// Remove download from DownloadManager
				if let index = DownloadManager.shared.getDownloadIndex(by: operation.downloadId) {
					DownloadManager.shared.downloads.remove(at: index)
				}
			}
			
		} catch {
			AppLogManager.shared.error("Auto-sign failed: \(error.localizedDescription)", category: "AutoSign")
			
			// Update Live Activity with error
			if #available(iOS 16.2, *) {
				LiveActivityManager.shared.endActivityWithError()
			}
			
			// Show error to user
			await MainActor.run {
				HapticsManager.shared.error()
				UIAlertController.showAlertWithOk(
					title: .localized("Auto-Sign Failed"),
					message: error.localizedDescription
				)
				
				// Clean up operation and remove download
				activeOperations.removeValue(forKey: operation.downloadId)
				
				// Remove download from DownloadManager
				if let index = DownloadManager.shared.getDownloadIndex(by: operation.downloadId) {
					DownloadManager.shared.downloads.remove(at: index)
				}
			}
		}
	}
	
	/// Get imported app from database
	private func getImportedApp(name: String, bundleId: String) async -> Imported? {
		await MainActor.run {
			let apps = Storage.shared.getAllImportedApps()
			// Try to find by bundle ID first (most reliable)
			if let app = apps.first(where: { $0.identifier == bundleId }) {
				return app
			}
			// Fallback to name matching
			return apps.first(where: { $0.name == name })
		}
	}
	
	/// Get default certificate or first available certificate
	private func getDefaultCertificate() -> CertificatePair? {
		let certificates = Storage.shared.getCertificates()
		// Try to get default certificate first
		if let defaultCert = certificates.first(where: { $0.isDefault }) {
			return defaultCert
		}
		// Try to get certificate based on stored selection
		let selectedIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		if certificates.indices.contains(selectedIndex) {
			return certificates[selectedIndex]
		}
		// Fallback to first certificate
		return certificates.first
	}
	
	/// Get signing options from OptionsManager
	private func getSigningOptions() async -> Options {
		await MainActor.run {
			OptionsManager.shared.getOptions()
		}
	}
	
	/// Sign the app using FR.signPackageFile
	private func signApp(
		app: AppInfoPresentable,
		certificate: CertificatePair,
		options: Options
	) async throws -> Signed {
		return try await withCheckedThrowingContinuation { continuation in
			FR.signPackageFile(app, using: options, icon: nil, certificate: certificate) { error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					// Get the signed app from the database (it's the latest one added)
					DispatchQueue.main.async {
						if let signedApp = Storage.shared.getLatestSignedApp() {
							continuation.resume(returning: signedApp)
						} else {
							continuation.resume(throwing: AutoSignError.signedAppNotFound)
						}
					}
				}
			}
		}
	}
	
	/// Install the app using InstallationProxy
	private func installApp(at url: URL, bundleId: String) async throws {
		// Create a view model for installation
		let viewModel = InstallerStatusViewModel(isIdevice: true)
		
		// Create InstallationProxy
		let installer = InstallationProxy(viewModel: viewModel)
		
		// Check if app is Feather itself (needs suspend)
		let suspend = bundleId == Bundle.main.bundleIdentifier!
		
		// Perform installation
		try await installer.install(at: url, suspend: suspend)
		
		// Wait for installation to complete
		// The view model status will change to .completed when done
		try await waitForInstallation(viewModel: viewModel)
	}
	
	/// Wait for installation to complete by observing view model status
	private func waitForInstallation(viewModel: InstallerStatusViewModel) async throws {
		// Create a continuation to wait for completion
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			var cancellable: AnyCancellable?
			var hasResumed = false
			
			// Subscribe to status changes
			cancellable = viewModel.$status
				.sink { status in
					guard !hasResumed else { return }
					
					switch status {
					case .completed:
						hasResumed = true
						cancellable?.cancel()
						continuation.resume()
					case .failed:
						hasResumed = true
						cancellable?.cancel()
						continuation.resume(throwing: AutoSignError.installationFailed)
					default:
						// Still in progress
						break
					}
				}
			
			// Timeout after 60 seconds
			DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
				guard !hasResumed else { return }
				hasResumed = true
				cancellable?.cancel()
				continuation.resume(throwing: AutoSignError.installationTimeout)
			}
		}
	}
	
	/// Delete app from library
	private func deleteFromLibrary(app: AppInfoPresentable) async {
		await MainActor.run {
			Storage.shared.deleteApp(for: app)
			AppLogManager.shared.info("Deleted app from library", category: "AutoSign")
		}
	}
	
	/// Update Live Activity with current status
	@available(iOS 16.2, *)
	private func updateLiveActivity(status: InstallationStatus, progress: Double) async {
		await LiveActivityManager.shared.updateActivity(
			progress: progress,
			bytesDownloaded: 0,
			totalBytes: 0,
			status: status,
			timeRemaining: nil,
			speed: nil,
			isAutoSigning: true
		)
	}
}

// MARK: - Supporting Types

/// Information about an imported app
struct ImportedAppInfo {
	let name: String
	let bundleId: String
}

/// Represents an ongoing auto-sign operation
struct AutoSignOperation {
	let downloadId: String
	let appInfo: ImportedAppInfo
	let startTime: Date = Date()
}

/// Errors that can occur during auto-sign
enum AutoSignError: LocalizedError {
	case appNotFound
	case noCertificateAvailable
	case signedAppNotFound
	case installationFailed
	case installationTimeout
	
	var errorDescription: String? {
		switch self {
		case .appNotFound:
			return "Could not find the downloaded app in library".localized()
		case .noCertificateAvailable:
			return "No certificate available for signing. Please add a certificate first.".localized()
		case .signedAppNotFound:
			return "Signed app file not found after signing".localized()
		case .installationFailed:
			return "Failed to install the app on device".localized()
		case .installationTimeout:
			return "Installation timed out after 60 seconds".localized()
		}
	}
}
