import Foundation
import BackgroundTasks
import OSLog
import Network

@available(iOS 13.0, *)
class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()
    private let logger = Logger(subsystem: "com.portal.app", category: "BackgroundRefresh")
    private let taskIdentifier = "com.portal.app.refresh"

    @Published var isRefreshScheduled: Bool = false

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundRefresh() {
        let useBackgroundRefresh = UserDefaults.standard.bool(forKey: "Feather.useBackgroundRefresh")
        guard useBackgroundRefresh else { return }

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            DispatchQueue.main.async {
                self.isRefreshScheduled = true
            }
            logger.info("Background refresh task scheduled")
        } catch {
            logger.error("Failed to schedule background refresh: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isRefreshScheduled = false
            }
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            self.logger.warning("Background refresh task expired")
        }

        Task {
            let success = await performRefresh()
            task.setTaskCompleted(success: success)
        }
    }

    private func performRefresh() async -> Bool {
        let connectionPreference = UserDefaults.standard.integer(forKey: "Feather.backgroundRefreshConnection")
        // 0: Both, 1: WiFi, 2: Cellular

        let pathMonitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isAllowed = false

        pathMonitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                switch connectionPreference {
                case 0: // Both
                    isAllowed = true
                case 1: // WiFi
                    isAllowed = path.usesInterfaceType(.wifi)
                case 2: // Cellular
                    isAllowed = path.usesInterfaceType(.cellular)
                default:
                    isAllowed = true
                }
            }
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "BackgroundRefreshNetworkMonitor")
        pathMonitor.start(queue: queue)

        _ = semaphore.wait(timeout: .now() + 2.0)
        pathMonitor.cancel()

        if !isAllowed {
            logger.info("Background refresh skipped: Connection does not match user preference (\(connectionPreference))")
            return true // Successfully handled by skipping
        }

        logger.info("Performing background refresh...")

        do {
            // Refresh sources
            let sources = Storage.shared.getSources()
            await SourcesViewModel.shared.forceFetchAllSources(sources)

            // Check for app updates
            await AppUpdateTrackingManager.shared.manualFetchAllSources()

            logger.info("Background refresh completed successfully")
            return true
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
            return false
        }
    }
}
