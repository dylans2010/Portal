import ActivityKit
import Foundation
import UIKit
import OSLog

@available(iOS 16.1, *)
class LiveActivityCoordinator: ObservableObject {
    
    static let shared = LiveActivityCoordinator()
    
    private var activityRegistry = ActivityRegistry()
    private var performanceTracker = PerformanceTracker()
    private var backgroundWorkCoordinator = BackgroundWorkCoordinator()
    private let diagnostics = Logger(subsystem: "com.portal.app", category: "LiveActivityCoordinator")
    
    private init() {
        diagnostics.info("Activity coordinator initialized")
    }
    
    func launchActivityForDownload(_ downloadIdentifier: String, appTitle: String, bundleId: String = "com.unknown.app", iconData: Data? = nil) -> String? {
        guard UserDefaults.standard.bool(forKey: "liveActivityEnabled") else { return nil }
        guard !activityRegistry.hasEntry(downloadIdentifier) else { return downloadIdentifier }
        
        let styleConfig = StyleConfiguration.fromUserDefaults()
        let attrs = InstallationActivityAttributes(
            appName: appTitle,
            appBundleId: bundleId,
            appIcon: iconData,
            startTime: Date(),
            accentColor: styleConfig.colorHex,
            backgroundMaterial: styleConfig.materialType,
            fontFamily: styleConfig.typeface,
            fontWeight: styleConfig.typefaceWeight,
            progressBarStyle: styleConfig.progressVisualization,
            iconSize: styleConfig.iconScale,
            detailDensity: styleConfig.infoLevel,
            animationStyle: styleConfig.motionType
        )
        
        let genesis = InstallationActivityAttributes.ContentState(
            progress: 0.0, bytesDownloaded: 0, totalBytes: 0,
            status: .preparing, timeRemaining: nil, downloadSpeed: nil
        )
        
        do {
            let activityHandle = try Activity<InstallationActivityAttributes>.request(
                attributes: attrs, content: .init(state: genesis, staleDate: nil), pushType: nil
            )
            activityRegistry.register(downloadIdentifier, activity: activityHandle)
            performanceTracker.initializeTracking(downloadIdentifier)
            diagnostics.info("Activity launched for \(downloadIdentifier)")
            return downloadIdentifier
        } catch {
            diagnostics.error("Launch failure: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateActivityState(_ downloadIdentifier: String, percentComplete: Double, downloadedBytes: Int64, totalBytes: Int64, currentPhase: InstallationStatus) {
        guard let activityHandle = activityRegistry.retrieve(downloadIdentifier) else { return }
        
        let metrics = performanceTracker.computeMetrics(downloadIdentifier, currentBytes: downloadedBytes, totalBytes: totalBytes)
        let revisedState = InstallationActivityAttributes.ContentState(
            progress: percentComplete, bytesDownloaded: downloadedBytes, totalBytes: totalBytes,
            status: currentPhase, timeRemaining: metrics.estimatedRemaining, downloadSpeed: metrics.bytesPerSecond
        )
        
        Task { await activityHandle.update(using: .init(state: revisedState, staleDate: nil)) }
    }
    
    func terminateActivity(_ downloadIdentifier: String, finalPhase: InstallationStatus, policy: ActivityUIDismissalPolicy = .default) {
        guard let activityHandle = activityRegistry.retrieve(downloadIdentifier) else { return }
        
        let conclusion = InstallationActivityAttributes.ContentState(
            progress: finalPhase == .completed ? 1.0 : activityHandle.content.state.progress,
            bytesDownloaded: activityHandle.content.state.bytesDownloaded,
            totalBytes: activityHandle.content.state.totalBytes,
            status: finalPhase, timeRemaining: nil, downloadSpeed: nil
        )
        
        Task {
            await activityHandle.end(using: .init(state: conclusion, staleDate: nil), dismissalPolicy: policy)
            diagnostics.info("Activity terminated for \(downloadIdentifier)")
        }
        
        activityRegistry.deregister(downloadIdentifier)
        performanceTracker.removeTracking(downloadIdentifier)
        backgroundWorkCoordinator.releaseBackgroundSlot(downloadIdentifier)
    }
    
    func requestBackgroundTime(_ downloadIdentifier: String) {
        backgroundWorkCoordinator.acquireBackgroundSlot(downloadIdentifier)
    }
    
    func releaseBackgroundTime(_ downloadIdentifier: String) {
        backgroundWorkCoordinator.releaseBackgroundSlot(downloadIdentifier)
    }
    
    func isMonitoring(_ downloadIdentifier: String) -> Bool {
        activityRegistry.hasEntry(downloadIdentifier)
    }
}

@available(iOS 16.1, *)
private class ActivityRegistry {
    private var entries: [String: Activity<InstallationActivityAttributes>] = [:]
    
    func register(_ key: String, activity: Activity<InstallationActivityAttributes>) {
        entries[key] = activity
    }
    
    func retrieve(_ key: String) -> Activity<InstallationActivityAttributes>? {
        entries[key]
    }
    
    func deregister(_ key: String) {
        entries.removeValue(forKey: key)
    }
    
    func hasEntry(_ key: String) -> Bool {
        entries[key] != nil
    }
}

@available(iOS 16.1, *)
private class PerformanceTracker {
    private struct TransferSnapshot {
        var timestamp: Date
        var bytesAtSnapshot: Int64
        var recentRates: [Double] = []
    }
    
    private var snapshots: [String: TransferSnapshot] = [:]
    
    func initializeTracking(_ key: String) {
        snapshots[key] = TransferSnapshot(timestamp: Date(), bytesAtSnapshot: 0)
    }
    
    func computeMetrics(_ key: String, currentBytes: Int64, totalBytes: Int64) -> (bytesPerSecond: Double?, estimatedRemaining: TimeInterval?) {
        guard var snapshot = snapshots[key] else { return (nil, nil) }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(snapshot.timestamp)
        guard elapsed > 0.2 else { return (nil, nil) }
        
        let byteDelta = currentBytes - snapshot.bytesAtSnapshot
        let instantRate = Double(byteDelta) / elapsed
        
        snapshot.recentRates.append(instantRate)
        if snapshot.recentRates.count > 6 { snapshot.recentRates.removeFirst() }
        
        snapshot.timestamp = now
        snapshot.bytesAtSnapshot = currentBytes
        snapshots[key] = snapshot
        
        let meanRate = snapshot.recentRates.reduce(0.0, +) / Double(snapshot.recentRates.count)
        let eta = meanRate > 50 ? Double(totalBytes - currentBytes) / meanRate : nil
        
        return (meanRate, eta)
    }
    
    func removeTracking(_ key: String) {
        snapshots.removeValue(forKey: key)
    }
}

@available(iOS 16.1, *)
private class BackgroundWorkCoordinator {
    private var slots: [String: UIBackgroundTaskIdentifier] = [:]
    private let diagnostics = Logger(subsystem: "com.portal.app", category: "BackgroundWork")
    
    func acquireBackgroundSlot(_ key: String) {
        guard slots[key] == nil else { return }
        
        let slotId = UIApplication.shared.beginBackgroundTask(withName: "ActivityUpdate_\(key)") { [weak self] in
            self?.diagnostics.warning("Background slot expired for \(key)")
            self?.releaseBackgroundSlot(key)
        }
        
        slots[key] = slotId
    }
    
    func releaseBackgroundSlot(_ key: String) {
        guard let slotId = slots[key], slotId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(slotId)
        slots.removeValue(forKey: key)
    }
}

@available(iOS 16.1, *)
private struct StyleConfiguration {
    let colorHex: String
    let materialType: String
    let typeface: String
    let typefaceWeight: String
    let progressVisualization: String
    let iconScale: String
    let infoLevel: String
    let motionType: String
    
    static func fromUserDefaults() -> StyleConfiguration {
        let prefs = UserDefaults.standard
        return StyleConfiguration(
            colorHex: prefs.string(forKey: "liveActivityAccentColor") ?? "#007AFF",
            materialType: prefs.string(forKey: "liveActivityBackgroundMaterial") ?? "regular",
            typeface: prefs.string(forKey: "liveActivityFontFamily") ?? "system",
            typefaceWeight: prefs.string(forKey: "liveActivityFontWeight") ?? "medium",
            progressVisualization: prefs.string(forKey: "liveActivityProgressBarStyle") ?? "gradient",
            iconScale: prefs.string(forKey: "liveActivityIconSize") ?? "medium",
            infoLevel: prefs.string(forKey: "liveActivityDetailDensity") ?? "normal",
            motionType: prefs.string(forKey: "liveActivityAnimationStyle") ?? "smooth"
        )
    }
}
