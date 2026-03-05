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
    private let taskIdentifier = "com.portal.app.install.background"
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
    
    func scheduleInstallation(
        appName: String,
        appSize: Int64,
        callback: @escaping (InstallationProgress) -> Void
    ) {
        guard #available(iOS 13.0, *) else {
            logger.warning("Background tasks not available, using foreground fallback")
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
    
    func completeInstallation(taskId: String) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        let task = activeInstallations[index]
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations[index].status = .completed
            
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
    
    func failInstallation(taskId: String, error: Error) {
        guard let index = activeInstallations.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        let task = activeInstallations[index]
        
        DispatchQueue.main.async { [weak self] in
            self?.activeInstallations[index].status = .failed
            
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
        
        logger.error("Failed Installation: \(task.appName) - \(error.localizedDescription)")
    }
    
    
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
            logger.info("Background Task Scheduled Successfully")
        } catch {
            logger.error("Failed to schedule background task: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.isTaskScheduled = false
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleBackgroundTask(task: BGProcessingTask) {
        logger.info("Background Task Started")
        
        scheduleBackgroundTask()
        
        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background Task Expired")
            task.setTaskCompleted(success: false)
        }
        
        
        Task {
            do {
            
                await processInstallations()
                task.setTaskCompleted(success: true)
                logger.info("Background task completed successfully")
            } catch {
                logger.error("Background task failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func processInstallations() async {
        for installation in activeInstallations where installation.status == .downloading {
            logger.info("Processing installation: \(installation.appName)")

        }
    }
}

// MARK: - Models

struct InstallationTask: Identifiable, Equatable {
    let id: String
    let appName: String
    let appSize: Int64
    var progress: Double
    var status: InstallationStatus
}


enum InstallationProgress {
    case started(appName: String, appSize: Int64)
    case progress(progress: Double, appName: String, appSize: Int64)
    case completed(appName: String)
    case failed(error: Error, appName: String)
    case cancelled
}

class BackgroundTaskManagerLegacy: ObservableObject {
    static let shared = BackgroundTaskManagerLegacy()
    
    @Published var activeInstallations: [InstallationTask] = []
    
    private init() {}
    
    func scheduleInstallation(
        appName: String,
        appSize: Int64,
        callback: @escaping (InstallationProgress) -> Void
    ) {

        callback(.started(appName: appName, appSize: appSize))
    }
}
