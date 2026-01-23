import Foundation
import SwiftUI
import AltSourceKit
import Combine

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
    
    @Published var trackedApps: [TrackedAppConfig] = []
    @Published var availableUpdates: [AppUpdateInfo] = []
    @Published var isCheckingForUpdates = false
    @Published var lastCheckDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTrackedApps()
        loadLastCheckDate()
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
        
        defer {
            Task { @MainActor in
                isCheckingForUpdates = false
                saveLastCheckDate()
            }
        }
        
        let enabledTrackedApps = trackedApps.filter { $0.isEnabled }
        guard !enabledTrackedApps.isEmpty else { return }
        
        var newUpdates: [AppUpdateInfo] = []
        
        for trackedApp in enabledTrackedApps {
            // Find the source
            guard let sourceEntry = sources.first(where: { $0.key.sourceURL?.absoluteString == trackedApp.sourceURL }),
                  let app = sourceEntry.value.apps.first(where: { $0.bundleIdentifier == trackedApp.bundleIdentifier }) else {
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
            
            newUpdates.append(updateInfo)
        }
        
        await MainActor.run {
            // Merge with existing updates, avoiding duplicates
            for update in newUpdates {
                if !availableUpdates.contains(where: { $0.bundleIdentifier == update.bundleIdentifier && $0.newVersion == update.newVersion }) {
                    availableUpdates.append(update)
                }
            }
            
            if !newUpdates.isEmpty {
                AppLogManager.shared.info("Found \(newUpdates.count) app update(s)", category: "AppUpdates")
            }
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
