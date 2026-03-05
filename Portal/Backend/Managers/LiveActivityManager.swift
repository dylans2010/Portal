import Foundation
import ActivityKit
import SwiftUI
import UIKit

/// Manager for handling Live Activities for app installations
@available(iOS 16.2, *)
class LiveActivityManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LiveActivityManager()
    
    // MARK: - Published Properties
    @Published var currentActivity: Activity<InstallationActivityAttributes>?
    @Published var isActivityActive: Bool = false
    
    // MARK: - Private Properties
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Settings storage key
    private let settingsKey = "Feather.liveActivitySettings"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Settings Management
    
    /// Load saved settings or return default
    func loadSettings() -> LiveActivitySettings {
        guard let defaults = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(LiveActivitySettings.self, from: defaults) else {
            return .default
        }
        return settings
    }
    
    /// Save settings
    func saveSettings(_ settings: LiveActivitySettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    // MARK: - Activity Management
    
    /// Start a new Live Activity
    /// - Parameters:
    ///   - appName: Name of the app being installed
    ///   - bundleId: Bundle identifier of the app
    ///   - appVersion: Version of the app
    ///   - iconData: Optional icon data
    /// - Returns: The created activity, or nil if creation failed
    @discardableResult
    func startActivity(appName: String, bundleId: String, appVersion: String? = nil, iconData: Data? = nil) -> Activity<InstallationActivityAttributes>? {
        // End any existing activity first
        endActivity(dismissalPolicy: .immediate)
        
        // Load settings
        let settings = loadSettings()
        
        // Create attributes
        let attributes = InstallationActivityAttributes(
            appName: appName,
            appBundleId: bundleId,
            appVersion: appVersion,
            appIcon: iconData,
            startTime: Date(),
            settings: settings
        )
        
        // Create initial state
        let initialState = InstallationActivityAttributes.ContentState(
            progress: 0.0,
            bytesDownloaded: 0,
            totalBytes: 0,
            status: .preparing,
            timeRemaining: nil,
            speed: nil
        )
        
        do {
            // Request activity
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            
            // Store activity
            self.currentActivity = activity
            self.isActivityActive = true
            
            print("✅ Live Activity started for \(appName)")
            return activity
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Update the current Live Activity with new progress
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - bytesDownloaded: Bytes downloaded so far
    ///   - totalBytes: Total bytes to download
    ///   - status: Current installation status
    ///   - timeRemaining: Estimated time remaining
    ///   - speed: Download/processing speed in bytes per second
    func updateActivity(
        progress: Double,
        bytesDownloaded: Int64,
        totalBytes: Int64,
        status: InstallationStatus,
        timeRemaining: TimeInterval? = nil,
        speed: Double? = nil
    ) async {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }
        
        let newState = InstallationActivityAttributes.ContentState(
            progress: progress,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
            status: status,
            timeRemaining: timeRemaining,
            speed: speed
        )
        
        do {
            await activity.update(using: newState)
            print("✅ Live Activity updated: \(status.rawValue) - \(Int(progress * 100))%")
        } catch {
            print("❌ Failed to update Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// End the current Live Activity
    /// - Parameters:
    ///   - finalState: Optional final state to display
    ///   - dismissalPolicy: When to dismiss the activity
    func endActivity(finalState: InstallationActivityAttributes.ContentState? = nil, dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to end")
            return
        }
        
        Task {
            // Update with final state if provided
            if let finalState = finalState {
                await activity.update(using: finalState)
            }
            
            // End the activity
            await activity.end(using: nil, dismissalPolicy: dismissalPolicy)
            
            await MainActor.run {
                self.currentActivity = nil
                self.isActivityActive = false
            }
            
            print("✅ Live Activity ended with policy: \(dismissalPolicy)")
        }
        
        // End background task if running
        endBackgroundTask()
    }
    
    /// End activity with success state
    func endActivityWithSuccess() {
        guard let activity = currentActivity else { return }
        
        let finalState = InstallationActivityAttributes.ContentState(
            progress: 1.0,
            bytesDownloaded: activity.content.state.totalBytes,
            totalBytes: activity.content.state.totalBytes,
            status: .completed,
            timeRemaining: 0,
            speed: nil
        )
        
        endActivity(finalState: finalState, dismissalPolicy: .default)
    }
    
    /// End activity with error state
    func endActivityWithError() {
        guard let activity = currentActivity else { return }
        
        let finalState = InstallationActivityAttributes.ContentState(
            progress: activity.content.state.progress,
            bytesDownloaded: activity.content.state.bytesDownloaded,
            totalBytes: activity.content.state.totalBytes,
            status: .failed,
            timeRemaining: nil,
            speed: nil
        )
        
        endActivity(finalState: finalState, dismissalPolicy: .default)
    }
    
    /// End activity with cancelled state
    func endActivityWithCancellation() {
        guard let activity = currentActivity else { return }
        
        let finalState = InstallationActivityAttributes.ContentState(
            progress: activity.content.state.progress,
            bytesDownloaded: activity.content.state.bytesDownloaded,
            totalBytes: activity.content.state.totalBytes,
            status: .cancelled,
            timeRemaining: nil,
            speed: nil
        )
        
        endActivity(finalState: finalState, dismissalPolicy: .immediate)
    }
    
    // MARK: - Background Task Management
    
    /// Begin a background task to allow short continuation when app is backgrounded
    func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else {
            print("⚠️ Background task already active")
            return
        }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⚠️ Background task expired")
            self?.endBackgroundTask()
        }
        
        print("✅ Background task started: \(backgroundTaskID.rawValue)")
    }
    
    /// End the current background task
    func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        
        print("✅ Background task ended")
    }
    
    // MARK: - Mock Activity for Testing
    
    /// Start a mock Live Activity for testing
    @discardableResult
    func startMockActivity() -> Activity<InstallationActivityAttributes>? {
        let mockIconData = createMockIcon()
        let activity = startActivity(appName: "Portal", bundleId: "ayon1xw.PortalDev", iconData: mockIconData)
        
        // Simulate progress updates
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let progress = Double(i) / 10.0
                let bytesDownloaded = Int64(Double(100_000_000) * progress)
                let totalBytes: Int64 = 100_000_000
                let status: InstallationStatus
                
                switch i {
                case 1...3:
                    status = .downloading
                case 4...5:
                    status = .unzipping
                case 6...7:
                    status = .signing
                case 8...9:
                    status = .rezipping
                default:
                    status = .installing
                }
                
                await updateActivity(
                    progress: progress,
                    bytesDownloaded: bytesDownloaded,
                    totalBytes: totalBytes,
                    status: status,
                    timeRemaining: TimeInterval((10 - i) * 2),
                    speed: 1_000_000.0
                )
            }
            
            // Complete after 5 seconds
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            endActivityWithSuccess()
        }
        
        return activity
    }
    
    private func createMockIcon() -> Data? {
        // Create a simple colored square as mock icon
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Gradient background
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), 
                                     colors: [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor] as CFArray, 
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, 
                                                 start: CGPoint(x: 0, y: 0), 
                                                 end: CGPoint(x: size.width, y: size.height), 
                                                 options: [])
            
            // Icon
            let icon = UIImage(systemName: "app.badge.fill")
            icon?.withTintColor(.white).draw(in: CGRect(x: 35, y: 35, width: 50, height: 50))
        }
        
        return image.pngData()
    }
}
