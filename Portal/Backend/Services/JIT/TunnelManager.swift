
import Foundation
import NetworkExtension
import OSLog

class TunnelManager {
    static let shared = TunnelManager()

    private let bundleIdentifier = "com.feather.portal.PacketTunnel"
    private let serverAddress = "10.7.0.1"

    private init() {}

    func ensureTunnelActive() async throws {
        Logger.jit.info("TunnelManager: Ensuring loopback VPN is active")

        do {
            try await performEnsureTunnelActive()
        } catch let error as JITError {
            throw error
        } catch {
            throw JITError.vpnStartFailed
        }
    }

    private func performEnsureTunnelActive() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager: NETunnelProviderManager

        if let existing = managers.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == bundleIdentifier }) {
            manager = existing
            Logger.jit.info("TunnelManager: Found existing VPN configuration")
        } else {
            Logger.jit.info("TunnelManager: Creating new VPN configuration")
            manager = NETunnelProviderManager()
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = bundleIdentifier
            protocolConfiguration.serverAddress = serverAddress
            manager.protocolConfiguration = protocolConfiguration
            manager.localizedDescription = "Portal JIT Loopback"
            manager.isEnabled = true
            try await manager.saveToPreferences()
        }
        if !manager.isEnabled {
            manager.isEnabled = true
            try await manager.saveToPreferences()
        }

        let status = manager.connection.status
        if status == .connected || status == .connecting {
            Logger.jit.info("TunnelManager: VPN is already active or connecting")
            return
        }

        Logger.jit.info("TunnelManager: Starting VPN tunnel")
        do {
            try manager.connection.startVPNTunnel()
        } catch {
            throw JITError.vpnStartFailed
        }
        let deadline = Date().addingTimeInterval(10)
        while manager.connection.status != .connected {
            if Date() > deadline {
                Logger.jit.error("TunnelManager: VPN start timed out")
                throw JITError.timeout(stage: "VPN Start")
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            try await manager.loadFromPreferences() // Refresh status
        }

        Logger.jit.info("TunnelManager: VPN tunnel established")
    }

    func stopTunnel() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        if let manager = managers.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == bundleIdentifier }) {
            manager.connection.stopVPNTunnel()
            Logger.jit.info("TunnelManager: VPN tunnel stopped")
        }
    }
}
