
import Foundation
import IDevice
import IDeviceSwift
import OSLog

class LockdownSession {

    // MARK: - Types

    typealias TcpProviderHandle = OpaquePointer

    private(set) var provider: TcpProviderHandle?

    // MARK: - Init / teardown

    init() {}

    deinit {
        disconnect()
    }

    // MARK: - Connect

    func connect(timeout: TimeInterval = 5.0) throws {
        Logger.jit.info("LockdownSession: Attempting to connect to device")

        let pairingManager = PairingManager.shared
        let pairingFile = try pairingManager.readPairingFile()
        defer { idevice_pairing_file_free(pairingFile) }

        // Define device address
        var addr = sockaddr_in()
        memset(&addr, 0, MemoryLayout.size(ofValue: addr))
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = CFSwapInt16HostToBig(UInt16(LOCKDOWN_PORT))

        guard inet_pton(AF_INET, "10.7.0.1", &addr.sin_addr) == 1 else {
            throw JITError.unknown("Invalid loopback IP address")
        }

        // Create TCP provider
        var providerPtr: TcpProviderHandle?
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                idevice_tcp_provider_new(sockaddrPtr, pairingFile, "Portal-JIT", &providerPtr)
            }
        }

        if let err = result {
            idevice_error_free(err)
            Logger.jit.error("LockdownSession: Failed to create TCP provider")
            throw JITError.lockdownAuthenticationFailed
        }

        guard let p = providerPtr else {
            throw JITError.lockdownAuthenticationFailed
        }

        self.provider = p
        Logger.jit.info("LockdownSession: Authenticated and connected successfully")
    }

    // MARK: - Disconnect

    func disconnect() {

        provider = nil
    }
}
