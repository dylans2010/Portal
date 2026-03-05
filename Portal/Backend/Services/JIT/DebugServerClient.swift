

import Foundation
import IDevice
import OSLog

class DebugServerClient {


    typealias CoreDeviceProxyHandle = OpaquePointer
    typealias AdapterHandle = OpaquePointer
    typealias RsdHandshakeHandle = OpaquePointer
    typealias RemoteServerHandle = OpaquePointer
    typealias DebugProxyHandle = OpaquePointer
    typealias DebugserverCommandHandle = OpaquePointer


    private var adapter: AdapterHandle?
    private var handshake: RsdHandshakeHandle?
    private var remoteServer: RemoteServerHandle?
    private var debugProxy: DebugProxyHandle?

    init() {}

    deinit {
        disconnect()
    }

    func attachAndEnableJIT(pid: Int64, provider: OpaquePointer) throws {
        defer { disconnect() }

        Logger.jit.info("DebugServerClient: Establishing RSD session")
        try connectDebugSession(provider: provider)

        Logger.jit.info("DebugServerClient: Attaching to PID \(pid)")
        try performAttachDetachSequence(pid: pid)

        Logger.jit.info("DebugServerClient: JIT successfully enabled for PID \(pid)")
    }


    private func connectDebugSession(provider: OpaquePointer) throws {
        var coreDevicePtr: OpaquePointer?
        var err = core_device_proxy_connect(provider, &coreDevicePtr)
        if let e = err {
            idevice_error_free(e)
            throw JITError.debugServerUnavailable
        }
        guard let coreDevicePtr else {
            throw JITError.debugServerUnavailable
        }

        var rsdPort: UInt16 = 0
        err = core_device_proxy_get_server_rsd_port(coreDevicePtr, &rsdPort)
        if let e = err {
            idevice_error_free(e)
            core_device_proxy_free(coreDevicePtr)
            throw JITError.debugServerUnavailable
        }

        var adapterPtr: OpaquePointer?
        err = core_device_proxy_create_tcp_adapter(coreDevicePtr, &adapterPtr)
        if let e = err {
            idevice_error_free(e)
            core_device_proxy_free(coreDevicePtr)
            throw JITError.debugServerUnavailable
        }
        self.adapter = adapterPtr

        var streamPtr: OpaquePointer?
        err = adapter_connect(adapterPtr, rsdPort, &streamPtr)
        if let e = err {
            idevice_error_free(e)
            throw JITError.debugServerUnavailable
        }

        var handshakePtr: OpaquePointer?
        err = rsd_handshake_new(streamPtr, &handshakePtr)
        if let e = err {
            idevice_error_free(e)
            throw JITError.debugServerUnavailable
        }
        self.handshake = handshakePtr

        var remoteServerPtr: OpaquePointer?
        err = remote_server_connect_rsd(adapterPtr, handshakePtr, &remoteServerPtr)
        if let e = err {
            idevice_error_free(e)
            throw JITError.debugServerUnavailable
        }
        self.remoteServer = remoteServerPtr

        var debugProxyPtr: OpaquePointer?
        err = debug_proxy_connect_rsd(adapterPtr, handshakePtr, &debugProxyPtr)
        if let e = err {
            idevice_error_free(e)
            throw JITError.debugServerUnavailable
        }
        self.debugProxy = debugProxyPtr
    }


    private func performAttachDetachSequence(pid: Int64) throws {
        guard let debugProxy else {
            throw JITError.attachFailed
        }

        debug_proxy_send_ack(debugProxy)
        debug_proxy_send_ack(debugProxy)

        var response: UnsafeMutablePointer<CChar>?
        let noAckCmd = debugserver_command_new("QStartNoAckMode", nil, 0)
        _ = debug_proxy_send_command(debugProxy, noAckCmd, &response)
        debugserver_command_free(noAckCmd)
        if let resp = response { idevice_string_free(resp) }

        debug_proxy_set_ack_mode(debugProxy, 0)

        let attachCmdStr = String(format: "vAttach;%llx", pid)
        let attachCmd = debugserver_command_new(attachCmdStr, nil, 0)
        var err = debug_proxy_send_command(debugProxy, attachCmd, &response)
        debugserver_command_free(attachCmd)

        if let resp = response {
            let respStr = String(cString: resp)
            Logger.jit.debug("DebugServerClient: vAttach response: \(respStr)")
            idevice_string_free(resp)

            if respStr.hasPrefix("E") {
                throw JITError.attachFailed
            }
        }

        if let e = err {
            idevice_error_free(e)
            throw JITError.attachFailed
        }

        let detachCmd = debugserver_command_new("D", nil, 0)
        err = debug_proxy_send_command(debugProxy, detachCmd, &response)
        debugserver_command_free(detachCmd)

        if let resp = response {
            Logger.jit.debug("DebugServerClient: Detach response: \(String(cString: resp))")
            idevice_string_free(resp)
        }

        if let e = err {
            Logger.jit.warning("DebugServerClient: Detach error (non-fatal): \(e.pointee.code)")
            idevice_error_free(e)
        }
    }


    func disconnect() {
        if let dp = debugProxy { debug_proxy_free(dp); debugProxy = nil }
        if let rs = remoteServer { remote_server_free(rs); remoteServer = nil }
        if let hs = handshake { rsd_handshake_free(hs); handshake = nil }
        if let ad = adapter { adapter_free(ad); adapter = nil }
    }
}
