//
//  PacketTunnelProvider.swift
//  Feather
//

import NetworkExtension
import OSLog

/// A simple loopback VPN provider that routes traffic for 10.7.0.1 to the device itself.
/// This enables idevice services to communicate over a stable virtual interface.
class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.7.0.1")

        let ipv4Settings = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.252"])
        ipv4Settings.includedRoutes = [NEIPv4Route(destinationAddress: "10.7.0.1", subnetMask: "255.255.255.255")]
        tunnelNetworkSettings.ipv4Settings = ipv4Settings

        tunnelNetworkSettings.mtu = 1500

        setTunnelNetworkSettings(tunnelNetworkSettings) { error in
            if let error = error {
                Logger.jit.error("PacketTunnelProvider: Failed to set network settings: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                Logger.jit.info("PacketTunnelProvider: Tunnel started successfully")
                completionHandler(nil)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        Logger.jit.info("PacketTunnelProvider: Tunnel stopping with reason: \(String(describing: reason))")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        completionHandler?(nil)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
    }
}
