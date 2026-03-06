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

        let isAllowed = await withTimeout(seconds: 2.0) {
            let pathStream = AsyncStream<NWPath> { continuation in
                let pathMonitor = NWPathMonitor()
                pathMonitor.pathUpdateHandler = { path in
                    continuation.yield(path)
                }
                continuation.onTermination = { _ in
                    pathMonitor.cancel()
                }
                let queue = DispatchQueue(label: "BackgroundRefreshNetworkMonitor")
                pathMonitor.start(queue: queue)
            }

            for await path in pathStream {
                if path.status == .satisfied {
                    switch connectionPreference {
                    case 0: // Both
                        return true
                    case 1: // WiFi
                        return path.usesInterfaceType(.wifi)
                    case 2: // Cellular
                        return path.usesInterfaceType(.cellular)
                    default:
                        return true
                    }
                } else if path.status == .unsatisfied {
                    return false
                }
            }
            return false
        } ?? false

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

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }

            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
}
