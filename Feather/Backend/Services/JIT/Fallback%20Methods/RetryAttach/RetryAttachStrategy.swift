

import Foundation
import OSLog


struct RetryAttachStrategy: JITFallbackStrategy {

    let identifier = "retry-attach"
    let displayName = "Retry Attach"
    let strategyDescription = "Reconnects the debug socket and retries the attach operation once. Best for transient connection drops."

    func execute(context: JITContext) async throws {
        context.logger.info("RetryAttachStrategy: Starting retry attach for \(context.bundleID)")

        guard let provider = context.lockdownSession.provider else {
            context.logger.error("RetryAttachStrategy: No active lockdown provider")
            throw JITError.lockdownAuthenticationFailed
        }

        context.logger.info("RetryAttachStrategy: Creating new DebugServerClient for PID \(context.currentPID)")
        let client = DebugServerClient()

        do {
            try client.attachAndEnableJIT(pid: context.currentPID, provider: provider)
            context.logger.info("RetryAttachStrategy: Attach succeeded on retry")
        } catch {
            context.logger.error("RetryAttachStrategy: Retry attach failed: \(error.localizedDescription)")
            throw JITError.attachFailed
        }
    }
}
