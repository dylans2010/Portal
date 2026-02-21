import SwiftUI
import NimbleViews
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var backgroundManager = ColorBackgroundManager.shared

    let heartbeat = HeartbeatManager.shared

    @StateObject var downloadManager = DownloadManager.shared
    @StateObject var networkMonitor = NetworkMonitor.shared
    let storage = Storage.shared

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenNearbyShareIntro") var hasSeenNearbyShareIntro: Bool = false
    @AppStorage("dev.updateBannerDismissed") private var updateBannerDismissed = false
    @State private var showUpdateBanner = false
    @State private var latestVersion: String = ""
    @State private var latestReleaseURL: String = ""
    @State private var navigateToUpdates = false
    @State private var showNearbyShareIntro = false

    // URL Scheme Handling
    @State private var _pendingSourceURL: String? = nil
    @State private var _showSourceConfirmation = false
    @State private var _showCertAdd = false
    @State private var _showCertificates = false
    @State private var _showQuickActions = false
    @State private var _showNearbyRestore = false
    @State private var _shouldAutoSignNextImport = false
    
    // IPA Import Handling
    @State private var _isImportingIPA = false
    @State private var _importErrorMessage: String?
    @State private var _showImportError = false

    var body: some Scene {
        WindowGroup(content: {
            Group {
                if !networkMonitor.isConnected && !UserDefaults.standard.bool(forKey: "dev.simulateOffline") {
                    OfflineView()
                } else if !hasCompletedOnboarding {
                    if #available(iOS 17.0, *) {
                        OnboardingView()
                            .onAppear { _setupTheme() }
                    } else {
                        OnboardingViewLegacy()
                            .onAppear { _setupTheme() }
                    }
                } else if !hasSeenNearbyShareIntro {
                    if #available(iOS 17.0, *) {
                        NearbyShareIntroView()
                            .onAppear { _setupTheme() }
                    } else {
                        NearbyShareIntroViewLegacy()
                            .onAppear { _setupTheme() }
                    }
                } else {
                    VStack(spacing: 0) {
                        if showUpdateBanner && !updateBannerDismissed {
                            UpdateAvailableView(
                                version: latestVersion,
                                releaseURL: latestReleaseURL,
                                onDismiss: {
                                    updateBannerDismissed = true
                                    showUpdateBanner = false
                                },
                                onNavigateToUpdates: {
                                    navigateToUpdates = true
                                }
                            )
                            .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                        }

                        VariedTabbarView()
                            .environment(\.managedObjectContext, storage.context)
                            .environment(\.navigateToUpdates, $navigateToUpdates)
                            .onOpenURL(perform: _handleURL)
                            .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                            .sheet(isPresented: $_showCertAdd) {
                                CertificatesAddView()
                                    .applyGlobalTheme()
                            }
                            .sheet(isPresented: $_showCertificates) {
                                NBNavigationView(.localized("Certificates")) {
                                    CertificatesView()
                                }
                                .applyGlobalTheme()
                            }
                            .sheet(isPresented: $_showQuickActions) {
                                QuickActionsSheetView()
                                    .applyGlobalTheme()
                            }
                            .sheet(isPresented: $_showNearbyRestore) {
                                RestoreOptionsView()
                                    .applyGlobalTheme()
                            }
                            .confirmationDialog(
                                .localized("Add Source"),
                                isPresented: $_showSourceConfirmation,
                                titleVisibility: .visible,
                                presenting: _pendingSourceURL
                            ) { sourceURL in
                                Button(.localized("Add")) {
                                    FR.handleSource(sourceURL) { }
                                    _pendingSourceURL = nil
                                }
                                Button(.localized("Cancel"), role: .cancel) {
                                    _pendingSourceURL = nil
                                }
                            } message: { sourceURL in
                                Text(.localized("Add \"\(sourceURL)\" source to Portal?"))
                            }
                            .alert(.localized("Import Failed"), isPresented: $_showImportError) {
                                Button(.localized("OK"), role: .cancel) { }
                            } message: {
                                Text(_importErrorMessage ?? .localized("An unknown error occurred during import."))
                            }
                            .overlay {
                                if _isImportingIPA {
                                    ZStack {
                                        VStack(spacing: 16) {
                                            ProgressView()
                                                .scaleEffect(1.5)
                                                .tint(.white)
                                            Text(.localized("Importing IPA..."))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        .padding(32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.black.opacity(0.8))
                                        )
                                    }
                                }
                            }
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
                    .onAppear {
                        _setupTheme()
                        _checkForUpdates()
                        _handlePendingWidgetAction()
                        _checkForPendingNearbyRestore()
                    }
                    .overlay(StatusBarOverlay())
                }
            }
            .applyGlobalTheme()
            .environmentObject(backgroundManager)
            .handleStatusBarHiding()
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                _handlePendingWidgetAction()
            }
        })
    }

    private func _handlePendingWidgetAction() {
        let userDefaults = UserDefaults(suiteName: Storage.appGroupID) ?? .standard
        if let urlString = userDefaults.string(forKey: "widget.pendingAction"), let url = URL(string: urlString) {
            userDefaults.removeObject(forKey: "widget.pendingAction")
            userDefaults.synchronize()
            _handleURL(url)
        }
    }

    private func _checkForPendingNearbyRestore() {
        if UserDefaults.standard.string(forKey: "pendingNearbyBackupRestore") != nil {
            _showNearbyRestore = true
        }
    }
    
    private func _setupTheme() {
        if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
            UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
        }

        // UIKit Interception
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.backgroundColor = .clear }

        let colorType = UserDefaults.standard.string(forKey: "Feather.userTintColorType") ?? "solid"
        if colorType == "gradient" {
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
        let urlString = "https://api.github.com/repos/aoyn1xw/Portal/releases/latest"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let release = try decoder.decode(GitHubRelease.self, from: data)
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                if self.compareVersions(releaseVersion, currentVersion) == .orderedDescending {
                    DispatchQueue.main.async {
                        self.latestVersion = releaseVersion
                        self.latestReleaseURL = release.htmlUrl
                        self.showUpdateBanner = true
                    }
                }
            } catch {}
        }.resume()
    }
    
    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxLength = max(components1.count, components2.count)
        for i in 0..<maxLength {
            let num1 = i < components1.count ? components1[i] : 0
            let num2 = i < components2.count ? components2[i] : 0
            if num1 < num2 { return .orderedAscending }
            else if num1 > num2 { return .orderedDescending }
        }
        return .orderedSame
    }
    
    private func _handleURL(_ url: URL) {
        if let action = URLActionHandler.parse(url) {
            switch action {
            case .addSource(let sourceURL):
                _pendingSourceURL = sourceURL
                _showSourceConfirmation = true
            }
            return
        }

        if url.scheme == "feather" || url.scheme == "portal" {
            switch url.host {
            case "import-certificate":
                guard
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let queryItems = components.queryItems
                else { return }

                func queryValue(_ name: String) -> String? {
                    queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
                }

                guard
                    let p12Base64 = queryValue("p12"),
                    let provisionBase64 = queryValue("mobileprovision"),
                    let passwordBase64 = queryValue("password"),
                    let passwordData = Data(base64Encoded: passwordBase64),
                    let password = String(data: passwordData, encoding: .utf8)
                else { return }

                guard
                    let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
                    let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
                    FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
                else {
                    HapticsManager.shared.error()
                    return
                }

                FR.handleCertificateFiles(p12URL: p12URL, provisionURL: provisionURL, p12Password: password) { error in
                    if let error = error {
                        UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
                    } else {
                        HapticsManager.shared.success()
                    }
                }

            case "export-certificate":
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
                FR.exportCertificateAndOpenUrl(using: callbackTemplate)

            case "add-source":
                NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.sources)
            case "add-certificate":
                _showCertAdd = true
            case "open-certificates":
                _showCertificates = true
            case "quick-actions":
                _showQuickActions = true
            case "sign-app":
                NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.library)
                if let latest = Storage.shared.getLatestImportedApp() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: Notification.Name("Feather.openSigningView"), object: latest)
                    }
                } else {
                    HapticsManager.shared.error()
                }
            case "add-and-sign":
                NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.library)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: Notification.Name("Feather.TriggerImport"), object: nil, userInfo: ["autoSign": true])
                }
            case "clear-caches":
                ResetView.clearWorkCache()
                HapticsManager.shared.success()
            case "export-logs":
                if let logsData = try? JSONEncoder().encode(AppLogManager.shared.logs) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalLogs.json")
                    try? logsData.write(to: tempURL)
                    UIActivityViewController.show(activityItems: [tempURL])
                }
            case "rebuild-icon-cache":
                HapticsManager.shared.success()
            case "open-settings":
                NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.settings)
            case "open-about":
                NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.settings)
            default:
                if let fullPath = url.validatedScheme(after: "/source/") {
                    FR.handleSource(fullPath) { }
                }
                if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) {
                    _ = DownloadManager.shared.startDownload(from: downloadURL)
                }
            }
        } else if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
            NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: TabEnum.library)
            _isImportingIPA = true
            let needsSecurityScope = FileManager.default.isFileFromFileProvider(at: url)
            if needsSecurityScope {
                guard url.startAccessingSecurityScopedResource() else {
                    _isImportingIPA = false
                    _importErrorMessage = .localized("Failed to access the file. Please try again.")
                    _showImportError = true
                    return
                }
            }
            FR.handlePackageFile(url) { [self] error in
                if needsSecurityScope { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    _isImportingIPA = false
                    if let error = error {
                        _importErrorMessage = error.localizedDescription
                        _showImportError = true
                        HapticsManager.shared.error()
                    } else {
                        HapticsManager.shared.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if let latestApp = Storage.shared.getLatestImportedApp() {
                                NotificationCenter.default.post(name: Notification.Name("Feather.openSigningView"), object: latestApp)
                            }
                        }
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _setupCrashHandler()
        _createPipeline()
        _createDocumentsDirectories()
        ResetView.clearWorkCache()
        _addDefaultCertificates()
        AutoSignManager.shared.setupObservers()
        Storage.shared.initializeSourceOrders()
        if let defaultCert = Storage.shared.getCertificates().first(where: { $0.isDefault }) ?? Storage.shared.getCertificates().first {
            Storage.shared.updateWidgetData(certName: defaultCert.nickname ?? "Certificate", expiryDate: defaultCert.expiration)
        }
        _ = KeyboardCustomizeManager.shared
        _ = SourcesViewModel.shared
        _ = AppUpdateTrackingManager.shared
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    private func _setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let crashInfo = "CRASH DETECTED:\nName: \(exception.name.rawValue)\nReason: \(exception.reason ?? "Unknown")\nStack: \(exception.callStackSymbols.joined(separator: "\n"))"
            AppLogManager.shared.critical(crashInfo, category: "Crash")
            if let data = try? JSONEncoder().encode(AppLogManager.shared.logs.suffix(1000)) {
                UserDefaults.standard.set(data, forKey: "Feather.AppLogs")
                UserDefaults.standard.synchronize()
            }
        }
    }

    private func _createPipeline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        ImagePipeline.shared = ImagePipeline {
            let dataCache = try? DataCache(name: "ayon1xw.PortalDev.datacache")
            $0.dataCache = dataCache
            $0.imageCache = Nuke.ImageCache()
            $0.dataCachePolicy = .automatic
        }
    }

    private func _createDocumentsDirectories() {
        let directories: [URL] = [FileManager.default.archives, FileManager.default.certificates, FileManager.default.signed, FileManager.default.unsigned]
        for url in directories { try? FileManager.default.createDirectoryIfNeeded(at: url) }
    }

    private func _addDefaultCertificates() {
        guard UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
              let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil) else { return }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: signingAssetsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for folderURL in folderContents {
                guard folderURL.hasDirectoryPath else { continue }
                let certName = folderURL.lastPathComponent
                let p12Url = folderURL.appendingPathComponent("cert.p12")
                let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
                let passwordUrl = folderURL.appendingPathComponent("cert.txt")
                guard FileManager.default.fileExists(atPath: p12Url.path), FileManager.default.fileExists(atPath: provisionUrl.path), FileManager.default.fileExists(atPath: passwordUrl.path) else { continue }
                let password = try String(contentsOf: passwordUrl, encoding: .utf8)
                FR.handleCertificateFiles(p12URL: p12Url, provisionURL: provisionUrl, p12Password: password, certificateName: certName, isDefault: true) { _ in }
            }
            UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
        } catch {}
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
            windowScene.windows.first?.overrideUserInterfaceStyle = style
        }
        windowScene.windows.forEach { $0.backgroundColor = .clear }
        let colorType = UserDefaults.standard.string(forKey: "Feather.userTintColorType") ?? "solid"
        if colorType == "gradient" {
            let gradientStartHex = UserDefaults.standard.string(forKey: "Feather.userTintGradientStart") ?? "#0077BE"
            windowScene.windows.first?.tintColor = UIColor(SwiftUI.Color(hex: gradientStartHex))
        } else {
            windowScene.windows.first?.tintColor = UIColor(SwiftUI.Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#0077BE"))
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) { Storage.shared.saveContext() }
}
