
import Foundation
import UIKit
import OSLog

@MainActor
class JITManager: ObservableObject {

    // MARK: - Singleton

    static let shared = JITManager()
    private init() {}

    // MARK: - Published state

    @Published var state: JITState = .idle
    @Published var lastError: JITError?
    
    var isIOS264OrLater: Bool {
        let version = UIDevice.current.systemVersion
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        let major = components[0]
        let minor = components[1]
        return major > 26 || (major == 26 && minor >= 4)
    }

    @Published var selectedFallbackStrategyIdentifier: String = UserDefaults.standard.string(forKey: "Feather.jitFallbackStrategy") ?? "retry-attach" {
        didSet { UserDefaults.standard.set(selectedFallbackStrategyIdentifier, forKey: "Feather.jitFallbackStrategy") }
    }

    var selectedFallbackStrategy: any JITFallbackStrategy {
        if isIOS264OrLater {
            return JITFallbackRegistry.availableStrategies.first { $0.identifier == "iOS_26_4_JIT_Method" }
                ?? JITFallbackRegistry.availableStrategies[0]
        }
        return JITFallbackRegistry.availableStrategies.first { $0.identifier == selectedFallbackStrategyIdentifier }
            ?? JITFallbackRegistry.availableStrategies[0]
    }


    private let pairingManager = PairingManager.shared
    private let tunnelManager = TunnelManager.shared

    func enableJIT(for bundleID: String) async throws {
        lastError = nil
        Logger.jit.info("JITManager: Starting JIT pipeline for \(bundleID)")

        do {

            try validateIOSVersion()

            state = .checkingVPN
            try await tunnelManager.ensureTunnelActive()

            state = .validatingPairing
            guard pairingManager.hasPairingFile else {
                throw JITError.pairingMissing
            }
            guard pairingManager.validatePairingFile() else {
                throw JITError.pairingInvalid
            }


            state = .connectingLockdown
            let lockdown = LockdownSession()
            try lockdown.connect()
            guard let provider = lockdown.provider else {
                throw JITError.lockdownAuthenticationFailed
            }

            state = .connectingDebugServer
            let pid = try ProcessResolver.shared.launchSuspended(bundleID: bundleID, provider: provider)

            let client = DebugServerClient()
            do {
                try client.attachAndEnableJIT(pid: pid, provider: provider)
            } catch let attachError as JITError where attachError.isRecoverable {
                Logger.jit.warning("JITManager: Primary attach failed (\(attachError.localizedDescription)); invoking fallback strategy '\(self.selectedFallbackStrategy.identifier)'")
                let context = JITContext(
                    bundleID: bundleID,
                    currentPID: pid,
                    lockdownSession: lockdown,
                    vpnManager: tunnelManager,
                    logger: Logger.jit
                )
                try await selectedFallbackStrategy.execute(context: context)
            }

            state = .jitEnabled
            Logger.jit.info("JITManager: JIT successfully enabled for \(bundleID)")

        } catch let error as JITError {
            lastError = error
            state = .failed(error)
            Logger.jit.error("JITManager: Pipeline failed: \(error.localizedDescription)")
            throw error
        } catch {
            let wrappedError = JITError.unknown(error.localizedDescription)
            lastError = wrappedError
            state = .failed(wrappedError)
            Logger.jit.error("JITManager: Unexpected error: \(error.localizedDescription)")
            throw wrappedError
        }
    }


    private func validateIOSVersion() throws {
        let version = UIDevice.current.systemVersion
        Logger.jit.info("JITManager: Device iOS version: \(version)")

        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            throw JITError.unsupportedIOSVersion(current: version)
        }

        let major = components[0]
        let minor = components[1]

        if major < 17 || (major == 17 && minor < 4) {
            throw JITError.unsupportedIOSVersion(current: version)
        }
    }
}


enum JITState: Equatable {
    case idle
    case validatingPairing
    case checkingVPN
    case connectingLockdown
    case connectingDebugServer
    case jitEnabled
    case failed(JITError)

    static func == (lhs: JITState, rhs: JITState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.validatingPairing, .validatingPairing),
             (.checkingVPN, .checkingVPN),
             (.connectingLockdown, .connectingLockdown),
             (.connectingDebugServer, .connectingDebugServer),
             (.jitEnabled, .jitEnabled):
            return true
        case (.failed(let a), .failed(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }

    var displayTitle: String {
        switch self {
        case .idle:                  return String.localized("Ready")
        case .validatingPairing:     return String.localized("Validating Pairing Record...")
        case .checkingVPN:           return String.localized("Activating Loopback VPN...")
        case .connectingLockdown:    return String.localized("Authenticating with Device...")
        case .connectingDebugServer: return String.localized("Enabling JIT...")
        case .jitEnabled:            return String.localized("JIT Enabled!")
        case .failed:                return String.localized("Failed")
        }
    }

    var isInProgress: Bool {
        switch self {
        case .validatingPairing, .checkingVPN, .connectingLockdown, .connectingDebugServer:
            return true
        default:
            return false
        }
    }
}
