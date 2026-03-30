
import Foundation
import OSLog


struct DelayedAttachStrategy: JITFallbackStrategy {

    let identifier = "delayed-attach"
    let displayName = "Delayed Attach"
    let strategyDescription = "Waits 500ms–1s before retrying attach. Useful when the app has not fully started up yet."

    private let minDelayNs: UInt64 = 500_000_000
    private let maxDelayNs: UInt64 = 1_000_000_000

    func execute(context: JITContext) async throws {
        let delayNs = UInt64.random(in: minDelayNs...maxDelayNs)
        let delayMs = delayNs / 1_000_000
        context.logger.info("DelayedAttachStrategy: Waiting \(delayMs)ms before retrying attach for \(context.bundleID)")

        try await Task.sleep(nanoseconds: delayNs)

        guard let provider = context.lockdownSession.provider else {
            context.logger.error("DelayedAttachStrategy: No active lockdown provider")
            throw JITError.lockdownAuthenticationFailed
        }

        context.logger.info("DelayedAttachStrategy: Retrying attach for PID \(context.currentPID)")
        let client = DebugServerClient()
        do {
            try client.attachAndEnableJIT(pid: context.currentPID, provider: provider)
            context.logger.info("DelayedAttachStrategy: Delayed attach succeeded")
        } catch {
            context.logger.error("DelayedAttachStrategy: Delayed attach failed: \(error.localizedDescription)")
            throw JITError.attachFailed
        }
    }
}
