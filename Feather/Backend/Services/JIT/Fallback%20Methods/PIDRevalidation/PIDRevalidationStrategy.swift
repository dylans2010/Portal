
import Foundation
import OSLog

struct PIDRevalidationStrategy: JITFallbackStrategy {

    let identifier = "pid-revalidation"
    let displayName = "PID Revalidation"
    let strategyDescription = "Re-resolves the app process ID and retries attach. Useful when the app has restarted or its PID changed."

    func execute(context: JITContext) async throws {
        context.logger.info("PIDRevalidationStrategy: Re-resolving PID for \(context.bundleID)")

        guard let provider = context.lockdownSession.provider else {
            context.logger.error("PIDRevalidationStrategy: No active lockdown provider")
            throw JITError.lockdownAuthenticationFailed
        }

        let newPID: Int64
        do {
            newPID = try ProcessResolver.shared.launchSuspended(bundleID: context.bundleID, provider: provider)
        } catch {
            context.logger.error("PIDRevalidationStrategy: PID re-resolution failed: \(error.localizedDescription)")
            throw JITError.pidResolutionFailed(bundleID: context.bundleID)
        }

        if newPID != context.currentPID {
            context.logger.info("PIDRevalidationStrategy: PID changed from \(context.currentPID) to \(newPID); retrying attach")
        } else {
            context.logger.info("PIDRevalidationStrategy: PID unchanged (\(newPID)); retrying attach anyway")
        }

        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        context.logger.info("PIDRevalidationStrategy: Attaching to PID \(newPID)")
        let client = DebugServerClient()
        do {
            try client.attachAndEnableJIT(pid: newPID, provider: provider)
            context.logger.info("PIDRevalidationStrategy: Attach succeeded for PID \(newPID)")
        } catch {
            context.logger.error("PIDRevalidationStrategy: Attach failed after PID revalidation: \(error.localizedDescription)")
            throw JITError.attachFailed
        }
    }
}
