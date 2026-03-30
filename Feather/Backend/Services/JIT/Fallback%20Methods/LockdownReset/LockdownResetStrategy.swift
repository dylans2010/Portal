
import Foundation
import OSLog

struct LockdownResetStrategy: JITFallbackStrategy {

    let identifier = "lockdown-reset"
    let displayName = "Lockdown Reset"
    let strategyDescription = "Tears down and re-establishes the device session, then retries attach. Best for authentication or session errors."

    func execute(context: JITContext) async throws {
        context.logger.info("LockdownResetStrategy: Tearing down lockdown session for \(context.bundleID)")

        context.lockdownSession.disconnect()
        context.logger.info("LockdownResetStrategy: Lockdown session disconnected")

        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        context.logger.info("LockdownResetStrategy: Re-authenticating lockdown session")
        do {
            try context.lockdownSession.connect()
        } catch {
            context.logger.error("LockdownResetStrategy: Re-authentication failed: \(error.localizedDescription)")
            throw JITError.lockdownAuthenticationFailed
        }

        guard let provider = context.lockdownSession.provider else {
            context.logger.error("LockdownResetStrategy: Provider unavailable after re-authentication")
            throw JITError.lockdownAuthenticationFailed
        }

        context.logger.info("LockdownResetStrategy: Re-authentication succeeded; re-resolving PID")

        let newPID: Int64
        do {
            newPID = try ProcessResolver.shared.launchSuspended(bundleID: context.bundleID, provider: provider)
        } catch {
            context.logger.error("LockdownResetStrategy: PID resolution failed: \(error.localizedDescription)")
            throw JITError.pidResolutionFailed(bundleID: context.bundleID)
        }

        context.logger.info("LockdownResetStrategy: Resolved PID \(newPID); retrying attach")

        let client = DebugServerClient()
        do {
            try client.attachAndEnableJIT(pid: newPID, provider: provider)
            context.logger.info("LockdownResetStrategy: Attach succeeded after lockdown reset")
        } catch {
            context.logger.error("LockdownResetStrategy: Attach failed after lockdown reset: \(error.localizedDescription)")
            throw JITError.attachFailed
        }
    }
}
