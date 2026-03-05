
import Foundation

// MARK: - JITError

/// Structured error type for the entire JIT enabling pipeline.
enum JITError: LocalizedError {
    case deviceCommunicationFailure
    case pairingMissing
    case pairingInvalid
    case vpnNotActive
    case vpnStartFailed
    case lockdownConnectionFailed
    case lockdownAuthenticationFailed
    case debugServerUnavailable
    case processNotRunning(bundleID: String)
    case pidResolutionFailed(bundleID: String)
    case attachFailed
    case resumeFailed
    case unsupportedIOSVersion(current: String)
    case timeout(stage: String)
    case brokenPipe
    case socketRejection
    case lockdownHandshakeFailed
    case subnetMismatch(vpnIP: String, physicalSubnet: String)
    case unknown(String)
    
    var isRecoverable: Bool {
        switch self {
        case .unsupportedIOSVersion, .pairingMissing, .pairingInvalid:
            return false
        case .brokenPipe, .socketRejection, .lockdownHandshakeFailed, .subnetMismatch:
            return true
        default:
            return true
        }
    }

    var errorDescription: String? {
        switch self {
        case .deviceCommunicationFailure:
            return String.localized("Failed to communicate with the device. Verify the pairing record is valid and the device is trusted.")
        case .pairingMissing:
            return String.localized("No pairing record found. Please import a valid pairing file.")
        case .pairingInvalid:
            return String.localized("The pairing file is invalid or corrupted.")
        case .vpnNotActive:
            return String.localized("The local VPN tunnel is not active. Start the VPN and try again.")
        case .vpnStartFailed:
            return String.localized("The VPN tunnel failed to start. Check VPN permissions and try again.")
        case .lockdownConnectionFailed:
            return String.localized("Failed to establish a secure session with the device.")
        case .lockdownAuthenticationFailed:
            return String.localized("Authentication with the device failed. The pairing record may be invalid.")
        case .debugServerUnavailable:
            return String.localized("Debug server could not be started on the device.")
        case .processNotRunning(let bundleID):
            return String.localized("The app \(bundleID) is not running. Launch the app and try again.")
        case .pidResolutionFailed(let bundleID):
            return String.localized("Unable to locate the running process for \(bundleID).")
        case .attachFailed:
            return String.localized("Failed to attach to the app process. JIT could not be enabled.")
        case .resumeFailed:
            return String.localized("Attached to the app, but failed to resume execution.")
        case .unsupportedIOSVersion(let current):
            return String.localized("iOS \(current) is not supported for JIT enabling.")
        case .timeout(let stage):
            return String.localized("The operation timed out during \(stage).")
        case .brokenPipe:
            return String.localized("Connection lost (broken pipe). The device may have dropped the session.")
        case .socketRejection:
            return String.localized("The device rejected the socket connection. Verify VPN and pairing status.")
        case .lockdownHandshakeFailed:
            return String.localized("The lockdown handshake failed. The device session could not be established.")
        case .subnetMismatch(let vpnIP, let physicalSubnet):
            return String.localized("VPN interface IP \(vpnIP) is not within the physical subnet \(physicalSubnet). A compatible IP will be assigned automatically.")
        case .unknown(let message):
            return String.localized("An unexpected error occurred: \(message)")
        }
    }
}
