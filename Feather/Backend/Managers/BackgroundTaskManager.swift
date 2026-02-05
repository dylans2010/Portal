import Foundation
import BackgroundTasks
import OSLog

/// BackgroundTaskManager handles background task scheduling and execution for app installations
/// Uses BGTaskScheduler for iOS 13+ with fallback support for older versions
@available(iOS 13.0, *)
class BackgroundTaskManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BackgroundTaskManager()
    
    // MARK: - Constants
    private let taskIdentifier = "com.portal.app.cleanup.background"
    private let logger = Logger(subsystem: "com.portal.app", category: "BackgroundTaskManager")
    
    // MARK: - Published Properties
    @Published var isTaskScheduled: Bool = false
    @Published var activeInstallations: [InstallationTask] = []
    
    // MARK: - Private Properties
    private var installationCallbacks: [String: (InstallationProgress) -> Void] = [:]
    
    // MARK: - Initialization
    private init() {
        logger.info("BackgroundTaskManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Register background task handler - should be called on app launch
    func registerBackgroundTasks() {
        guard #available(iOS 13.0, *) else {
            logger.warning("BackgroundTasks not available on this iOS version")
            return
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task: task as! BGProcessingTask)
        }
        
        logger.info("Background task registered with identifier: \(self.taskIdentifier)")
    }
    
    /// Schedule a background task for app installation
    /// - Parameter appName: Name of the app being installed
    /// - Parameter appSize: Size of the app in bytes
    /// - Parameter callback: Progress callback closure
    func scheduleInstallation(
        appName: String,
        appSize: Int64,
        callback: @escaping (InstallationProgress) -> Void
    ) {
        guard #available(iOS 13.0, *) else {
            logger.warning("Background tasks not available, using foreground fallback")
            // Fallback to foreground installation
            callback(.started(appName: appName, appSize: appSize))
            return
        }
        
        let installTask = InstallationTask(
            id: UUID().uuidString,
            appName: appName,
            appSize: appSize,
            progress: 0.0,
            status: .downloading
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations.append(installTask)
        }
        
        installationCallbacks[installTask.id] = callback
        
        scheduleBackgroundTask()
        
        logger.info("Scheduled installation for app: \(appName)")
    }
    
    /// Cancel an active installation
    /// - Parameter taskId: The ID of the installation task to cancel
    func cancelInstallation(taskId: String) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations.remove(at: index)
        }
        
        installationCallbacks.removeValue(forKey: taskId)
        
        if let callback = installationCallbacks[taskId] {
            callback(.cancelled)
        }
        
        logger.info("Cancelled installation task: \(taskId)")
    }
    
    /// Update progress for an active installation
    /// - Parameters:
    ///   - taskId: The ID of the installation task
    ///   - progress: Progress value between 0.0 and 1.0
    func updateProgress(taskId: String, progress: Double) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations[index].progress = progress
            self?.activeInstallations[index].status = .installing
        }
        
        if let callback = installationCallbacks[taskId],
           let task = activeInstallations.first(where: { $0.id == taskId }) {
            callback(.progress(progress: progress, appName: task.appName, appSize: task.appSize))
        }
    }
    
    /// Mark an installation as completed
    /// - Parameter taskId: The ID of the installation task
    func completeInstallation(taskId: String) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        let task = activeInstallations[index]
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations[index].status = .completed
            
            // Remove completed task after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let idx = self?.activeInstallations.firstIndex(where: { $0.id == taskId }) {
                    self?.activeInstallations.remove(at: idx)
                }
            }
        }
        
        if let callback = installationCallbacks[taskId] {
            callback(.completed(appName: task.appName))
        }
        
        installationCallbacks.removeValue(forKey: taskId)
        
        logger.info("Completed installation: \(task.appName)")
    }
    
    /// Mark an installation as failed
    /// - Parameters:
    ///   - taskId: The ID of the installation task
    ///   - error: The error that occurred
    func failInstallation(taskId: String, error: Error) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        let task = activeInstallations[index]
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations[index].status = .failed
            
            // Remove failed task after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let idx = self?.activeInstallations.firstIndex(where: { $0.id == taskId }) {
                    self?.activeInstallations.remove(at: idx)
                }
            }
        }
        
        if let callback = installationCallbacks[taskId] {
            callback(.failed(error: error, appName: task.appName))
        }
        
        installationCallbacks.removeValue(forKey: taskId)
        
        logger.error("Failed installation: \(task.appName) - \(error.localizedDescription)")
    }
    
    // MARK: - Private Methods
    
    private func scheduleBackgroundTask() {
        guard #available(iOS 13.0, *) else { return }
        
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            DispatchQueue.main.async { [weak self] in
                self?.isTaskScheduled = true
            }
            logger.info("Background task scheduled successfully")
        } catch {
            logger.error("Failed to schedule background task: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.isTaskScheduled = false
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleBackgroundTask(task: BGProcessingTask) {
        logger.info("Background cleanup task started")
        
        // Schedule next background task
        scheduleBackgroundTask()
        
        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background cleanup task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform background cleanup work only
        Task {
            do {
                // Clean up temporary files, old logs, expired data, etc.
                await performCleanupTasks()
                task.setTaskCompleted(success: true)
                logger.info("Background cleanup task completed successfully")
            } catch {
                logger.error("Background cleanup task failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func performCleanupTasks() async {
        // Clean up temporary download files
        let tempDirectory = FileManager.default.temporaryDirectory
        let customTempDir = tempDirectory.appendingPathComponent("FeatherDownloads", isDirectory: true)
        
        do {
            if FileManager.default.fileExists(atPath: customTempDir.path) {
                let contents = try FileManager.default.contentsOfDirectory(at: customTempDir, includingPropertiesForKeys: [.creationDateKey])
                let now = Date()
                
                // Remove files older than 24 hours
                for fileURL in contents {
                    if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                       now.timeIntervalSince(creationDate) > 86400 {
                        try? FileManager.default.removeItem(at: fileURL)
                        logger.info("Cleaned up old temp file: \(fileURL.lastPathComponent)")
                    }
                }
            }
        } catch {
            logger.error("Cleanup error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Models

/// Installation task model
struct InstallationTask: Identifiable, Equatable {
    let id: String
    let appName: String
    let appSize: Int64
    var progress: Double
    var status: InstallationStatus
}

/// Installation progress enum
enum InstallationProgress {
    case started(appName: String, appSize: Int64)
    case progress(progress: Double, appName: String, appSize: Int64)
    case completed(appName: String)
    case failed(error: Error, appName: String)
    case cancelled
}

// MARK: - Fallback for older iOS versions

/// Fallback manager for iOS versions < 13
class BackgroundTaskManagerLegacy: ObservableObject {
    static let shared = BackgroundTaskManagerLegacy()
    
    @Published var activeInstallations: [InstallationTask] = []
    
    private init() {}
    
    func scheduleInstallation(
        appName: String,
        appSize: Int64,
        callback: @escaping (InstallationProgress) -> Void
    ) {
        // Fallback implementation for older iOS versions
        // Would use URLSession background tasks or similar
        callback(.started(appName: appName, appSize: appSize))
    }
}
