import Foundation
import SwiftUI
import AltSourceKit
import Combine
import NimbleJSON

// MARK: - Tracked App Configuration
struct TrackedAppConfig: Codable, Identifiable, Equatable {
    var id: String { bundleIdentifier }
    var bundleIdentifier: String
    var appName: String
    var sourceURL: String
    var sourceName: String
    var lastKnownVersion: String
    var iconURL: String?
    var isEnabled: Bool
    var dateAdded: Date
    
    init(bundleIdentifier: String, appName: String, sourceURL: String, sourceName: String, lastKnownVersion: String, iconURL: String? = nil, isEnabled: Bool = true) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.sourceURL = sourceURL
        self.sourceName = sourceName
        self.lastKnownVersion = lastKnownVersion
        self.iconURL = iconURL
        self.isEnabled = isEnabled
        self.dateAdded = Date()
    }
}

// MARK: - Cached App Info for fast loading
struct CachedAppInfo: Codable, Identifiable, Equatable {
    var id: String { bundleIdentifier }
    var bundleIdentifier: String
    var appName: String
    var version: String?
    var iconURL: String?
    var sourceURL: String
    var sourceName: String
    var cachedDate: Date
    
    init(from app: ASRepository.App, source: AltSource) {
        self.bundleIdentifier = app.id ?? UUID().uuidString
        self.appName = app.name ?? "Unknown"
        self.version = app.version
        self.iconURL = app.iconURL?.absoluteString
        self.sourceURL = source.sourceURL?.absoluteString ?? ""
        self.sourceName = source.name ?? "Unknown"
        self.cachedDate = Date()
    }
}

// MARK: - App Update Info
struct AppUpdateInfo: Identifiable, Equatable {
    var id: String { bundleIdentifier }
    var bundleIdentifier: String
    var appName: String
    var currentVersion: String
    var newVersion: String
    var sourceURL: String
    var sourceName: String
    var iconURL: String?
    var downloadURL: String?
    var changelog: String?
    var updateDate: Date
    
    static func == (lhs: AppUpdateInfo, rhs: AppUpdateInfo) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.newVersion == rhs.newVersion
    }
}

// MARK: - App Update Tracking Manager
final class AppUpdateTrackingManager: ObservableObject {
    static let shared = AppUpdateTrackingManager()
    
    private let trackedAppsKey = "Feather.trackedAppsForUpdates"
    private let lastCheckKey = "Feather.lastUpdateCheck"
    private let dismissedUpdatesKey = "Feather.dismissedAppUpdates"
    private let cachedAppsKey = "Feather.cachedAvailableApps"
    private let lastAutoFetchKey = "Feather.lastAutoSourceFetch"
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour cache
    private let autoFetchInterval: TimeInterval = 3600 // 1 hour auto-fetch interval
    
    @Published var trackedApps: [TrackedAppConfig] = []
    @Published var availableUpdates: [AppUpdateInfo] = []
    @Published var isCheckingForUpdates = false
    @Published var lastCheckDate: Date?
    
    // Cached apps for fast loading
    @Published var cachedApps: [CachedAppInfo] = []
    @Published var isCacheLoading = false
    @Published var lastCacheDate: Date?
    
    // Auto-fetch state
    @Published var isFetchingAllSources = false
    @Published var lastAutoFetchDate: Date?
    @Published var autoFetchProgress: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var autoFetchTimer: Timer?
    private let dataService = NBFetchService()
    
    init() {
        loadTrackedApps()
        loadLastCheckDate()
        loadCachedApps()
        loadLastAutoFetchDate()
        startAutoFetchTimer()
    }
    
    deinit {
        stopAutoFetchTimer()
    }
    
    // MARK: - Auto Fetch Timer
    private func startAutoFetchTimer() {
        // Check immediately if we need to fetch
        checkAndPerformAutoFetch()
        
        // Set up hourly timer
        autoFetchTimer = Timer.scheduledTimer(withTimeInterval: autoFetchInterval, repeats: true) { [weak self] _ in
            self?.checkAndPerformAutoFetch()
        }
    }
    
    private func stopAutoFetchTimer() {
        autoFetchTimer?.invalidate()
        autoFetchTimer = nil
    }
    
    private func checkAndPerformAutoFetch() {
        // Check if it's been more than an hour since last fetch
        if let lastFetch = lastAutoFetchDate {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < autoFetchInterval {
                AppLogManager.shared.debug("Skipping auto-fetch - last fetch was \(Int(timeSinceLastFetch / 60)) minutes ago", category: "AutoFetch")
                return
            }
        }
        
        // Perform auto-fetch
        Task {
            await fetchAllSourcesAutomatically()
        }
    }
    
    private func loadLastAutoFetchDate() {
        if let date = UserDefaults.standard.object(forKey: lastAutoFetchKey) as? Date {
            lastAutoFetchDate = date
        }
    }
    
    private func saveLastAutoFetchDate() {
        lastAutoFetchDate = Date()
        UserDefaults.standard.set(lastAutoFetchDate, forKey: lastAutoFetchKey)
    }
    
    // MARK: - Fetch All Sources
    func fetchAllSourcesAutomatically() async {
        guard !isFetchingAllSources else {
            AppLogManager.shared.debug("Already fetching sources, skipping", category: "AutoFetch")
            return
        }
        
        await MainActor.run {
            isFetchingAllSources = true
            autoFetchProgress = 0
            // Start background audio to keep app alive during fetch
            BackgroundAudioManager.shared.start()
        }
        
        AppLogManager.shared.info("Starting automatic source fetch for all sources", category: "AutoFetch")
        
        // Get all sources from CoreData
        let context = Storage.shared.container.viewContext
        let fetchRequest = AltSource.fetchRequest()
        
        do {
            let sources = try context.fetch(fetchRequest)
            let totalSources = sources.count
            
            guard totalSources > 0 else {
                await MainActor.run {
                    isFetchingAllSources = false
                    autoFetchProgress = 1.0
                    BackgroundAudioManager.shared.stop()
                }
                AppLogManager.shared.info("No sources to fetch", category: "AutoFetch")
                return
            }
            
            var fetchedSources: [AltSource: ASRepository] = [:]
            var completedCount = 0
            
            for source in sources {
                guard let url = source.sourceURL else {
                    completedCount += 1
                    continue
                }
                
                // Fetch the source
                let result = await fetchSourceRepository(from: url)
                if let repo = result {
                    fetchedSources[source] = repo
                }
                
                completedCount += 1
                let currentProgress = Double(completedCount) / Double(totalSources)
                await MainActor.run {
                    autoFetchProgress = currentProgress
                }
            }
            
            // Clear old cache and update with new data
            let sourcesToCache = fetchedSources
            await MainActor.run {
                clearCache()
                updateCache(from: sourcesToCache)
                saveLastAutoFetchDate()
                isFetchingAllSources = false
                autoFetchProgress = 1.0
                BackgroundAudioManager.shared.stop()
            }
            
            AppLogManager.shared.success("Auto-fetch completed: \(fetchedSources.count)/\(totalSources) sources fetched, \(cachedApps.count) apps cached", category: "AutoFetch")
            
            // Also check for updates after fetching
            await checkForUpdates(sources: fetchedSources)
            
        } catch {
            await MainActor.run {
                isFetchingAllSources = false
                autoFetchProgress = 0
                BackgroundAudioManager.shared.stop()
            }
            AppLogManager.shared.error("Auto-fetch failed: \(error.localizedDescription)", category: "AutoFetch")
        }
    }
    
    // Manual fetch triggered by user
    func manualFetchAllSources() async {
        // Reset the last fetch date to force a new fetch
        lastAutoFetchDate = nil
        await fetchAllSourcesAutomatically()
    }
    
    private func fetchSourceRepository(from url: URL) async -> ASRepository? {
        return await withCheckedContinuation { continuation in
            dataService.fetch(from: url) { (result: Result<ASRepository, Error>) in
                switch result {
                case .success(let repo):
                    continuation.resume(returning: repo)
                case .failure(let error):
                    AppLogManager.shared.warning("Failed to fetch source \(url.absoluteString): \(error.localizedDescription)", category: "AutoFetch")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Persistence
    private func loadTrackedApps() {
        if let data = UserDefaults.standard.data(forKey: trackedAppsKey),
           let decoded = try? JSONDecoder().decode([TrackedAppConfig].self, from: data) {
            trackedApps = decoded
        }
    }
    
    private func saveTrackedApps() {
        if let encoded = try? JSONEncoder().encode(trackedApps) {
            UserDefaults.standard.set(encoded, forKey: trackedAppsKey)
        }
    }
    
    private func loadLastCheckDate() {
        if let date = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            lastCheckDate = date
        }
    }
    
    // MARK: - Cache Management
    private func loadCachedApps() {
        if let data = UserDefaults.standard.data(forKey: cachedAppsKey),
           let decoded = try? JSONDecoder().decode([CachedAppInfo].self, from: data) {
            cachedApps = decoded
            lastCacheDate = decoded.first?.cachedDate
        }
    }
    
    private func saveCachedApps() {
        if let encoded = try? JSONEncoder().encode(cachedApps) {
            UserDefaults.standard.set(encoded, forKey: cachedAppsKey)
        }
    }
    
    func isCacheValid() -> Bool {
        guard let lastCache = lastCacheDate else { return false }
        return Date().timeIntervalSince(lastCache) < cacheExpirationInterval
    }
    
    func updateCache(from sources: [AltSource: ASRepository]) {
        var newCache: [CachedAppInfo] = []
        
        for (source, repo) in sources {
            for app in repo.apps {
                let cachedApp = CachedAppInfo(from: app, source: source)
                newCache.append(cachedApp)
            }
        }
        
        // Sort by app name
        newCache.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        
        DispatchQueue.main.async {
            self.cachedApps = newCache
            self.lastCacheDate = Date()
            self.saveCachedApps()
        }
    }
    
    func getCachedAppsFiltered(searchText: String, excludeTracked: Bool = true) -> [CachedAppInfo] {
        var filtered = cachedApps
        
        // Filter out already tracked apps
        if excludeTracked {
            let trackedIds = Set(trackedApps.map { $0.bundleIdentifier })
            filtered = filtered.filter { !trackedIds.contains($0.bundleIdentifier) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { app in
                app.appName.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func clearCache() {
        cachedApps = []
        lastCacheDate = nil
        UserDefaults.standard.removeObject(forKey: cachedAppsKey)
    }
    
    private func saveLastCheckDate() {
        lastCheckDate = Date()
        UserDefaults.standard.set(lastCheckDate, forKey: lastCheckKey)
    }
    
    // MARK: - Dismissed Updates
    private func getDismissedUpdates() -> [String: String] {
        if let data = UserDefaults.standard.data(forKey: dismissedUpdatesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            return decoded
        }
        return [:]
    }
    
    private func saveDismissedUpdates(_ updates: [String: String]) {
        if let encoded = try? JSONEncoder().encode(updates) {
            UserDefaults.standard.set(encoded, forKey: dismissedUpdatesKey)
        }
    }
    
    func dismissUpdate(for bundleIdentifier: String, version: String) {
        var dismissed = getDismissedUpdates()
        dismissed[bundleIdentifier] = version
        saveDismissedUpdates(dismissed)
        
        // Remove from available updates
        availableUpdates.removeAll { $0.bundleIdentifier == bundleIdentifier }
    }
    
    func isUpdateDismissed(bundleIdentifier: String, version: String) -> Bool {
        let dismissed = getDismissedUpdates()
        return dismissed[bundleIdentifier] == version
    }
    
    // MARK: - Track/Untrack Apps
    func addTrackedApp(_ config: TrackedAppConfig) {
        guard !trackedApps.contains(where: { $0.bundleIdentifier == config.bundleIdentifier }) else { return }
        trackedApps.append(config)
        saveTrackedApps()
        HapticsManager.shared.success()
        AppLogManager.shared.info("Added tracked app: \(config.appName)", category: "AppUpdates")
    }
    
    func removeTrackedApp(bundleIdentifier: String) {
        trackedApps.removeAll { $0.bundleIdentifier == bundleIdentifier }
        availableUpdates.removeAll { $0.bundleIdentifier == bundleIdentifier }
        saveTrackedApps()
        HapticsManager.shared.softImpact()
        AppLogManager.shared.info("Removed tracked app: \(bundleIdentifier)", category: "AppUpdates")
    }
    
    func toggleTrackedApp(bundleIdentifier: String) {
        if let index = trackedApps.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            trackedApps[index].isEnabled.toggle()
            saveTrackedApps()
            
            if !trackedApps[index].isEnabled {
                availableUpdates.removeAll { $0.bundleIdentifier == bundleIdentifier }
            }
        }
    }
    
    func isAppTracked(bundleIdentifier: String) -> Bool {
        trackedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    func updateLastKnownVersion(bundleIdentifier: String, version: String) {
        if let index = trackedApps.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            trackedApps[index].lastKnownVersion = version
            saveTrackedApps()
            
            // Remove from available updates since user has acknowledged
            availableUpdates.removeAll { $0.bundleIdentifier == bundleIdentifier }
        }
    }
    
    // MARK: - Check for Updates
    func checkForUpdates(sources: [AltSource: ASRepository]) async {
        guard !isCheckingForUpdates else { return }
        
        await MainActor.run {
            isCheckingForUpdates = true
        }
        
        let enabledTrackedApps = trackedApps.filter { $0.isEnabled }
        guard !enabledTrackedApps.isEmpty else {
            await MainActor.run {
                isCheckingForUpdates = false
                saveLastCheckDate()
            }
            return
        }
        
        // Collect updates in a local array first
        var foundUpdates: [AppUpdateInfo] = []
        
        for trackedApp in enabledTrackedApps {
            // Find the source
            guard let sourceEntry = sources.first(where: { $0.key.sourceURL?.absoluteString == trackedApp.sourceURL }),
                  let app = sourceEntry.value.apps.first(where: { $0.id == trackedApp.bundleIdentifier }) else {
                continue
            }
            
            // Check if there's a newer version
            guard let currentVersion = app.version,
                  isVersionNewer(currentVersion, than: trackedApp.lastKnownVersion) else {
                continue
            }
            
            // Check if this update was dismissed
            if isUpdateDismissed(bundleIdentifier: trackedApp.bundleIdentifier, version: currentVersion) {
                continue
            }
            
            let updateInfo = AppUpdateInfo(
                bundleIdentifier: trackedApp.bundleIdentifier,
                appName: app.name ?? trackedApp.appName,
                currentVersion: trackedApp.lastKnownVersion,
                newVersion: currentVersion,
                sourceURL: trackedApp.sourceURL,
                sourceName: trackedApp.sourceName,
                iconURL: app.iconURL?.absoluteString ?? trackedApp.iconURL,
                downloadURL: app.downloadURL?.absoluteString,
                changelog: app.versions?.first?.localizedDescription,
                updateDate: Date()
            )
            
            foundUpdates.append(updateInfo)
        }
        
        // Update on main actor with the collected updates
        let updatesToAdd = foundUpdates
        await MainActor.run {
            // Merge with existing updates, avoiding duplicates
            for update in updatesToAdd {
                if !availableUpdates.contains(where: { $0.bundleIdentifier == update.bundleIdentifier && $0.newVersion == update.newVersion }) {
                    availableUpdates.append(update)
                }
            }
            
            if !updatesToAdd.isEmpty {
                AppLogManager.shared.info("Found \(updatesToAdd.count) app update(s)", category: "AppUpdates")
            }
            
            isCheckingForUpdates = false
            saveLastCheckDate()
        }
    }
    
    // MARK: - Version Comparison
    private func isVersionNewer(_ newVersion: String, than oldVersion: String) -> Bool {
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let oldComponents = oldVersion.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(newComponents.count, oldComponents.count)
        
        for i in 0..<maxLength {
            let newPart = i < newComponents.count ? newComponents[i] : 0
            let oldPart = i < oldComponents.count ? oldComponents[i] : 0
            
            if newPart > oldPart {
                return true
            } else if newPart < oldPart {
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Get Apps from Sources for Selection
    func getAvailableAppsFromSources(_ sources: [AltSource: ASRepository]) -> [(source: AltSource, repo: ASRepository, app: ASRepository.App)] {
        var apps: [(source: AltSource, repo: ASRepository, app: ASRepository.App)] = []
        
        for (source, repo) in sources {
            for app in repo.apps {
                apps.append((source: source, repo: repo, app: app))
            }
        }
        
        return apps.sorted { ($0.app.name ?? "") < ($1.app.name ?? "") }
    }
    
    // MARK: - Simulated Data for Developer Mode
    static func createSimulatedUpdate() -> AppUpdateInfo {
        AppUpdateInfo(
            bundleIdentifier: "com.example.simulatedapp",
            appName: "Simulated App",
            currentVersion: "1.0.0",
            newVersion: "2.0.0",
            sourceURL: "https://example.com/repo.json",
            sourceName: "Example Source",
            iconURL: nil,
            downloadURL: "https://example.com/app.ipa",
            changelog: "• New features\n• Bug fixes\n• Performance improvements",
            updateDate: Date()
        )
    }
}
