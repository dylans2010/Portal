import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	let heartbeat = HeartbeatManager.shared

	@StateObject var downloadManager = DownloadManager.shared
	@StateObject var networkMonitor = NetworkMonitor.shared
	let storage = Storage.shared

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("dev.updateBannerDismissed") private var updateBannerDismissed = false
    @State private var hasDylibsDetected: Bool = false
    @State private var showUpdateBanner = false
    @State private var latestVersion: String = ""
    @State private var latestReleaseURL: String = ""
    @State private var navigateToUpdates = false

	var body: some Scene {
		WindowGroup(content: {
			Group {
				// CRITICAL: Check for .dylib files first - blocks all navigation if found
				if hasDylibsDetected {
					DylibBlockerView()
						.onAppear {
							// Prevent any navigation or state changes
							UIApplication.shared.isIdleTimerDisabled = false
						}
				} else if !networkMonitor.isConnected && !UserDefaults.standard.bool(forKey: "dev.simulateOffline") {
					// Show offline view when no connectivity (unless simulating)
					OfflineView()
				} else if !hasCompletedOnboarding {
					if #available(iOS 17.0, *) {
						OnboardingView()
							.onAppear {
								_setupTheme()
							}
					} else {
						// Fallback for iOS 16
						OnboardingViewLegacy()
							.onAppear {
								_setupTheme()
							}
					}
				} else {
					VStack(spacing: 0) {
						// Modern Update Available banner at the top
						if showUpdateBanner && !updateBannerDismissed {
							UpdateAvailableView(
								version: latestVersion,
                                releaseURL: latestReleaseURL,
								onDismiss: {
									updateBannerDismissed = true
									showUpdateBanner = false
									AppLogManager.shared.info("Update Banner Dismissed", category: "Updates")
								},
								onNavigateToUpdates: {
									navigateToUpdates = true
									AppLogManager.shared.info("Navigating to Check for Updates", category: "Updates")
								}
							)
							.transition(.move(edge: .top).combined(with: .opacity))
						}
						
						DownloadHeaderView(downloadManager: downloadManager)
							.transition(.move(edge: .top).combined(with: .opacity))
						VariedTabbarView()
							.environment(\.managedObjectContext, storage.context)
							.environment(\.navigateToUpdates, $navigateToUpdates)
							.onOpenURL(perform: _handleURL)
							.transition(.move(edge: .top).combined(with: .opacity))
					}
					.animation(animationForPlatform(), value: downloadManager.manualDownloads.description)
					.animation(animationForPlatform(), value: showUpdateBanner)
					.onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
						DispatchQueue.main.async {
							UIAlertController.showAlertWithOk(
								title: "InvalidHostID",
								message: .localized("Your pairing file is invalid and is incompatible with your device, please import a valid pairing file.")
							)
						}
					}
					// dear god help me
					.onAppear {
						_setupTheme()
						_checkForUpdates()
					}
					.overlay(StatusBarOverlay())
				}
			}
			.handleStatusBarHiding()
			.onAppear {
				// Scan for dylibs at launch
				_checkForDylibs()
			}
		})
	}
    
    private func _checkForDylibs() {
        // Perform dylib scan on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let detector = DylibDetector.shared
            let dylibsFound = detector.hasDylibs()

            DispatchQueue.main.async {
                if dylibsFound {
                    Logger.misc.error("🚫 .dylib files detected in app bundle - blocking navigation")
                    hasDylibsDetected = true
                } else {
                    Logger.misc.info("✅ No .dylib files detected")
                }
            }
        }
    }

    private func _setupTheme() {
        if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
            UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
        }

        let colorType = UserDefaults.standard.string(forKey: "Feather.userTintColorType") ?? "solid"
        if colorType == "gradient" {
            // For gradient, use the start color as the tint
            let gradientStartHex = UserDefaults.standard.string(forKey: "Feather.userTintGradientStart") ?? "#0077BE"
            UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: gradientStartHex))
        } else {
            UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#0077BE"))
        }
    }
    
    private func animationForPlatform() -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.35)
        }
    }
    
    private func _checkForUpdates() {
        // Check for updates on GitHub
        let urlString = "https://api.github.com/repos/aoyn1xw/Portal/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let data = data, error == nil else {
                AppLogManager.shared.warning("Failed to check for updates: \(error?.localizedDescription ?? "Unknown error")", category: "Updates")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let release = try decoder.decode(GitHubRelease.self, from: data)
                
                // Get current version
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                
                // Compare versions using proper semantic versioning
                if self.compareVersions(releaseVersion, currentVersion) == .orderedDescending {
                    DispatchQueue.main.async {
                        self.latestVersion = releaseVersion
                        self.latestReleaseURL = release.htmlUrl
                        self.showUpdateBanner = true
                        AppLogManager.shared.info("Update available: \(release.tagName)", category: "Updates")
                    }
                } else {
                    AppLogManager.shared.info("App is up to date", category: "Updates")
                }
            } catch {
                AppLogManager.shared.warning("Failed to parse update info: \(error.localizedDescription)", category: "Updates")
            }
        }.resume()
    }
    
    /// Compare two semantic version strings (e.g., "1.2.3" vs "1.3.0")
    /// Returns .orderedAscending if v1 < v2, .orderedDescending if v1 > v2, .orderedSame if equal
    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(components1.count, components2.count)
        
        for i in 0..<maxLength {
            let num1 = i < components1.count ? components1[i] : 0
            let num2 = i < components2.count ? components2[i] : 0
            
            if num1 < num2 {
                return .orderedAscending
            } else if num1 > num2 {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
	
	private func _handleURL(_ url: URL) {
		if url.scheme == "feather" {
			/// feather://import-certificate?p12=<base64>&mobileprovision=<base64>&password=<base64>
			if url.host == "import-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
					let queryItems = components.queryItems
				else {
					return
				}
				
				func queryValue(_ name: String) -> String? {
					queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
				}
				
				guard
					let p12Base64 = queryValue("p12"),
					let provisionBase64 = queryValue("mobileprovision"),
					let passwordBase64 = queryValue("password"),
					let passwordData = Data(base64Encoded: passwordBase64),
					let password = String(data: passwordData, encoding: .utf8)
				else {
					return
				}
				
				guard
					let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
					let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
					FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
				else {
					HapticsManager.shared.error()
					return
				}
				
				FR.handleCertificateFiles(
					p12URL: p12URL,
					provisionURL: provisionURL,
					p12Password: password
				) { error in
					if let error = error {
						UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
					} else {
						HapticsManager.shared.success()
					}
				}
				
				return
			}
			/// feather://export-certificate?callback_template=<template>
			/// ?callback_template=: This is how we callback to the application requesting the certificate, this will be a url scheme
			/// 	example: livecontainer%3A%2F%2Fcertificate%3Fcert%3D%24%28BASE64_CERT%29%26password%3D%24%28PASSWORD%29
			/// 	decoded: livecontainer://certificate?cert=$(BASE64_CERT)&password=$(PASSWORD)
			/// $(BASE64_CERT) and $(PASSWORD) must be presenting in the callback template so we can replace them with the proper content
			if url.host == "export-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
				else {
					return
				}
				
				let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
				guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
				
				FR.exportCertificateAndOpenUrl(using: callbackTemplate)
			}
			/// feather://source/<url>
			if let fullPath = url.validatedScheme(after: "/source/") {
				FR.handleSource(fullPath) { }
			}
			/// feather://install/<url.ipa>
			if
				let fullPath = url.validatedScheme(after: "/install/"),
				let downloadURL = URL(string: fullPath)
			{
				_ = DownloadManager.shared.startDownload(from: downloadURL)
			}
		} else {
			if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
				if FileManager.default.isFileFromFileProvider(at: url) {
					guard url.startAccessingSecurityScopedResource() else { return }
					FR.handlePackageFile(url) { _ in }
				} else {
					FR.handlePackageFile(url) { _ in }
				}
				
				return
			}
		}
	}
}

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		_setupCrashHandler()
		_createPipeline()
		_createDocumentsDirectories()
		ResetView.clearWorkCache()
		_addDefaultCertificates()
		
		// Initialize source ordering (one-time migration)
		Storage.shared.initializeSourceOrders()
		
		// Log app launch
		AppLogManager.shared.info("Application launched successfully", category: "Lifecycle")
		
		return true
	}
	
	// MARK: - UISceneSession Lifecycle (iPad Multi-Window Support)
	
	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		let configuration = UISceneConfiguration(
			name: "Default Configuration",
			sessionRole: connectingSceneSession.role
		)
		configuration.delegateClass = SceneDelegate.self
		return configuration
	}
	
	func application(
		_ application: UIApplication,
		didDiscardSceneSessions sceneSessions: Set<UISceneSession>
	) {
		// Called when the user discards a scene session (iPad multi-window)
		AppLogManager.shared.info("Scene session discarded", category: "Lifecycle")
	}
	
	private func _setupCrashHandler() {
		// Set up NSException handler for crash logging
		NSSetUncaughtExceptionHandler { exception in
			let crashInfo = """
			CRASH DETECTED:
			Name: \(exception.name.rawValue)
			Reason: \(exception.reason ?? "Unknown")
			Call Stack: \(exception.callStackSymbols.joined(separator: "\n"))
			"""
			
			AppLogManager.shared.critical(crashInfo, category: "Crash")
			
			// Force persist logs immediately
			if let data = try? JSONEncoder().encode(AppLogManager.shared.logs.suffix(1000)) {
				UserDefaults.standard.set(data, forKey: "Feather.AppLogs")
				UserDefaults.standard.synchronize()
			}
		}
		
		// Set up signal handler for crashes
		signal(SIGABRT) { signal in
			AppLogManager.shared.critical("App crashed with SIGABRT signal", category: "Crash")
		}
		signal(SIGILL) { signal in
			AppLogManager.shared.critical("App crashed with SIGILL signal", category: "Crash")
		}
		signal(SIGSEGV) { signal in
			AppLogManager.shared.critical("App crashed with SIGSEGV signal", category: "Crash")
		}
		signal(SIGFPE) { signal in
			AppLogManager.shared.critical("App crashed with SIGFPE signal", category: "Crash")
		}
		signal(SIGBUS) { signal in
			AppLogManager.shared.critical("App crashed with SIGBUS signal", category: "Crash")
		}
		signal(SIGPIPE) { signal in
			AppLogManager.shared.critical("App crashed with SIGPIPE signal", category: "Crash")
		}
	}
	
	private func _createPipeline() {
		DataLoader.sharedUrlCache.diskCapacity = 0
		
		let pipeline = ImagePipeline {
			let dataLoader: DataLoader = {
				let config = URLSessionConfiguration.default
				config.urlCache = nil
				return DataLoader(configuration: config)
			}()
			let dataCache = try? DataCache(name: "ayon1xw.Feather.datacache") // disk cache
			let imageCache = Nuke.ImageCache() // memory cache
			dataCache?.sizeLimit = 500 * 1024 * 1024
			imageCache.costLimit = 100 * 1024 * 1024
			$0.dataCache = dataCache
			$0.imageCache = imageCache
			$0.dataLoader = dataLoader
			$0.dataCachePolicy = .automatic
			$0.isStoringPreviewsInMemoryCache = false
		}
		
		ImagePipeline.shared = pipeline
	}
	
	private func _createDocumentsDirectories() {
		let fileManager = FileManager.default

		let directories: [URL] = [
			fileManager.archives,
			fileManager.certificates,
			fileManager.signed,
			fileManager.unsigned
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
	
	private func _addDefaultCertificates() {
		guard
			UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
			let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil)
		else {
			return
		}
		
		do {
			let folderContents = try FileManager.default.contentsOfDirectory(
				at: signingAssetsURL,
				includingPropertiesForKeys: nil,
				options: .skipsHiddenFiles
			)
			
			for folderURL in folderContents {
				guard folderURL.hasDirectoryPath else { continue }
				
				let certName = folderURL.lastPathComponent
				
				let p12Url = folderURL.appendingPathComponent("cert.p12")
				let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
				let passwordUrl = folderURL.appendingPathComponent("cert.txt")
				
				guard
					FileManager.default.fileExists(atPath: p12Url.path),
					FileManager.default.fileExists(atPath: provisionUrl.path),
					FileManager.default.fileExists(atPath: passwordUrl.path)
				else {
					Logger.misc.warning("Skipping \(certName): missing required files")
					continue
				}
				
				let password = try String(contentsOf: passwordUrl, encoding: .utf8)
				
				FR.handleCertificateFiles(
					p12URL: p12Url,
					provisionURL: provisionUrl,
					p12Password: password,
					certificateName: certName,
					isDefault: true
				) { _ in
					
				}
			}
			UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
		} catch {
			Logger.misc.error("Failed to list signing-assets: \(error)")
		}
	}

}

// MARK: - Scene Delegate (iPad Multi-Window Support)
class SceneDelegate: NSObject, UIWindowSceneDelegate {
	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		// Configure the scene for multi-window support
		guard let windowScene = scene as? UIWindowScene else { return }
		
		// Set up window-specific configurations
		AppLogManager.shared.info("Scene connected: \(session.persistentIdentifier)", category: "Lifecycle")
		
		// Apply theme to the window
		if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
			windowScene.windows.first?.overrideUserInterfaceStyle = style
		}
		
		// Apply tint color
		let colorType = UserDefaults.standard.string(forKey: "Feather.userTintColorType") ?? "solid"
		if colorType == "gradient" {
			let gradientStartHex = UserDefaults.standard.string(forKey: "Feather.userTintGradientStart") ?? "#0077BE"
			windowScene.windows.first?.tintColor = UIColor(SwiftUI.Color(hex: gradientStartHex))
		} else {
			windowScene.windows.first?.tintColor = UIColor(SwiftUI.Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#0077BE"))
		}
	}
	
	func sceneDidDisconnect(_ scene: UIScene) {
		// Called when scene is being released by the system
		AppLogManager.shared.info("Scene disconnected", category: "Lifecycle")
	}
	
	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when scene has moved from inactive to active state
		AppLogManager.shared.debug("Scene became active", category: "Lifecycle")
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		// Called when scene is about to move from active to inactive state
		AppLogManager.shared.debug("Scene will resign active", category: "Lifecycle")
	}
	
	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as scene transitions from background to foreground
		AppLogManager.shared.debug("Scene entering foreground", category: "Lifecycle")
	}
	
	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as scene transitions from foreground to background
		AppLogManager.shared.debug("Scene entered background", category: "Lifecycle")
		
		// Save any pending changes
		Storage.shared.saveContext()
	}
}
