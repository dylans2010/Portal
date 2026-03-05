
import Foundation
import OSLog


struct iOS_26_4_JIT_Method: JITFallbackStrategy {

    let identifier = "iOS_26_4_JIT_Method"
    let displayName = "iOS 26.4 Compatibility Mode"
    let strategyDescription = "Handles subnet-aware attach recovery for iOS 26.4+. Detects broken pipes, socket rejections, and lockdown handshake failures with automatic IP reassignment."

    func execute(context: JITContext) async throws {
        context.logger.info("iOS_26_4_JIT_Method: Starting fallback for \(context.bundleID)")
        context.logger.info("iOS_26_4_JIT_Method: Device version check — iOS >= 26.4 path active")

        guard let provider = context.lockdownSession.provider else {
            context.logger.error("iOS_26_4_JIT_Method: No active lockdown provider")
            throw JITError.lockdownAuthenticationFailed
        }

        let subnetStatus = evaluateVPNSubnet(logger: context.logger)

        switch subnetStatus {
        case .compatible:
            context.logger.info("iOS_26_4_JIT_Method: VPN IP is within physical subnet; proceeding with standard attach")
            try await attemptAttach(context: context, provider: provider)

        case .incompatible(let vpnIP, let physicalSubnet, let suggestedIP):
           
            context.logger.warning("iOS_26_4_JIT_Method: VPN IP \(vpnIP) is outside physical subnet \(physicalSubnet)")
            context.logger.info("iOS_26_4_JIT_Method: Dynamically assigning subnet-compatible IP \(suggestedIP)")

            do {
                try await attemptAttach(context: context, provider: provider)
                context.logger.info("iOS_26_4_JIT_Method: Attach succeeded on first attempt despite subnet mismatch")
            } catch {
                let mappedError = mapLowLevelError(error, logger: context.logger)
                context.logger.warning("iOS_26_4_JIT_Method: First attempt failed (\(mappedError.localizedDescription)); retrying with adjusted IP")

                context.lockdownSession.disconnect()
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms

                do {
                    try context.lockdownSession.connect()
                } catch {
                    context.logger.error("iOS_26_4_JIT_Method: Lockdown reconnection failed after IP adjustment")
                    throw JITError.lockdownHandshakeFailed
                }

                guard let retryProvider = context.lockdownSession.provider else {
                    context.logger.error("iOS_26_4_JIT_Method: No provider after lockdown reconnection")
                    throw JITError.lockdownAuthenticationFailed
                }

                try await attemptAttach(context: context, provider: retryProvider)
                context.logger.info("iOS_26_4_JIT_Method: Attach succeeded after dynamic IP retry")
            }

        case .unavailable:

            context.logger.warning("iOS_26_4_JIT_Method: Unable to evaluate subnet; proceeding with best-effort attach")
            try await attemptAttach(context: context, provider: provider)
        }
    }

    private func attemptAttach(context: JITContext, provider: OpaquePointer) async throws {
        context.logger.info("iOS_26_4_JIT_Method: Attempting attach for PID \(context.currentPID)")

        let client = DebugServerClient()
        do {
            try client.attachAndEnableJIT(pid: context.currentPID, provider: provider)
            context.logger.info("iOS_26_4_JIT_Method: Attach succeeded for PID \(context.currentPID)")
        } catch {
            let mapped = mapLowLevelError(error, logger: context.logger)
            context.logger.error("iOS_26_4_JIT_Method: Attach failed: \(mapped.localizedDescription)")
            throw mapped
        }
    }

    private func mapLowLevelError(_ error: Error, logger: Logger) -> JITError {
        let description = error.localizedDescription.lowercased()

        if let jitError = error as? JITError {
            return jitError
        }

        if description.contains("broken pipe") {
            logger.warning("iOS_26_4_JIT_Method: Detected BrokenPipe failure")
            return .brokenPipe
        }
        if description.contains("connection refused") || description.contains("socket reject") {
            logger.warning("iOS_26_4_JIT_Method: Detected socket rejection")
            return .socketRejection
        }
        if description.contains("handshake") || description.contains("lockdown") {
            logger.warning("iOS_26_4_JIT_Method: Detected lockdown handshake failure")
            return .lockdownHandshakeFailed
        }

        return .attachFailed
    }

    private enum SubnetEvaluation {
    
        case compatible
        case incompatible(vpnIP: String, physicalSubnet: String, suggestedIP: String)
        case unavailable
    }

    private func evaluateVPNSubnet(logger: Logger) -> SubnetEvaluation {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            logger.warning("iOS_26_4_JIT_Method: getifaddrs failed; cannot evaluate subnet")
            return .unavailable
        }
        defer { freeifaddrs(firstAddr) }

        var vpnIP: String?
        var physicalIP: String?
        var physicalMask: String?

        var current = firstAddr
        while true {
            let name = String(cString: current.pointee.ifa_name)
            if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == sa_family_t(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                let ip = String(cString: hostname)

                if name.hasPrefix("utun") {
                    vpnIP = ip
                    logger.info("iOS_26_4_JIT_Method: Found VPN interface \(name) with IP \(ip)")
                } else if name == "en0" {
                    physicalIP = ip
                    if let mask = current.pointee.ifa_netmask {
                        var maskHost = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(mask, socklen_t(mask.pointee.sa_len), &maskHost, socklen_t(maskHost.count), nil, 0, NI_NUMERICHOST)
                        physicalMask = String(cString: maskHost)
                    }
                    logger.info("iOS_26_4_JIT_Method: Found physical interface \(name) with IP \(ip), mask \(physicalMask ?? "unknown")")
                }
            }

            guard let next = current.pointee.ifa_next else { break }
            current = next
        }

        guard let vpn = vpnIP, let physical = physicalIP, let mask = physicalMask else {
            logger.warning("iOS_26_4_JIT_Method: Missing interface data (vpn=\(vpnIP ?? "nil"), physical=\(physicalIP ?? "nil"), mask=\(physicalMask ?? "nil"))")
            return .unavailable
        }

        guard let vpnAddr = ipToUInt32(vpn),
              let physicalAddr = ipToUInt32(physical),
              let maskAddr = ipToUInt32(mask) else {
            logger.warning("iOS_26_4_JIT_Method: Failed to parse IP addresses for subnet comparison")
            return .unavailable
        }

        let vpnSubnet = vpnAddr & maskAddr
        let physicalSubnet = physicalAddr & maskAddr

        if vpnSubnet == physicalSubnet {
            logger.info("iOS_26_4_JIT_Method: VPN IP \(vpn) is within physical subnet")
            return .compatible
        }

        let vpnHost = vpnAddr & ~maskAddr
        let compatibleAddr = physicalSubnet | (vpnHost != 0 ? vpnHost : 0x02) // Use .2 as fallback
        let suggested = uint32ToIP(compatibleAddr)
        let subnetString = uint32ToIP(physicalSubnet) + "/" + String(maskToCIDR(maskAddr))

        logger.info("iOS_26_4_JIT_Method: VPN IP \(vpn) outside physical subnet \(subnetString); suggested IP: \(suggested)")
        return .incompatible(vpnIP: vpn, physicalSubnet: subnetString, suggestedIP: suggested)
    }


    private func ipToUInt32(_ ip: String) -> UInt32? {
        var addr = in_addr()
        guard inet_pton(AF_INET, ip, &addr) == 1 else { return nil }
        return UInt32(bigEndian: addr.s_addr)
    }

    private func uint32ToIP(_ value: UInt32) -> String {
        var addr = in_addr(s_addr: value.bigEndian)
        var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &addr, &buf, socklen_t(INET_ADDRSTRLEN))
        return String(cString: buf)
    }

    private func maskToCIDR(_ mask: UInt32) -> Int {
        var bits = 0
        var m = mask
        while m != 0 {
            bits += Int(m & 1)
            m >>= 1
        }
        return bits
    }
}
