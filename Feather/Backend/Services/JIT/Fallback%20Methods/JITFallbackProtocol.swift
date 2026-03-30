
import Foundation
import OSLog


protocol JITFallbackStrategy {
    var identifier: String { get }
    var displayName: String { get }
    var strategyDescription: String { get }
    func execute(context: JITContext) async throws
}


struct JITContext {
    let bundleID: String
    var currentPID: Int64
    let lockdownSession: LockdownSession
    let vpnManager: TunnelManager
    let logger: Logger
}
