
import Foundation
import IDevice
import OSLog

class ProcessResolver {

    typealias RemoteServerHandle = OpaquePointer
    typealias ProcessControlHandle = OpaquePointer

    static let shared = ProcessResolver()
    private init() {}

    func launchSuspended(bundleID: String, provider: OpaquePointer) throws -> Int64 {
        Logger.jit.info("ProcessResolver: Opening RSD session for process control")

        let session = try openRsdSession(provider: provider)
        defer {
            remote_server_free(session.remoteServer)
            rsd_handshake_free(session.handshake)
            adapter_free(session.adapter)
        }

        var processControl: ProcessControlHandle?
        let pcErr = process_control_new(session.remoteServer, &processControl)
        if let e = pcErr {
            idevice_error_free(e)
            throw JITError.processNotRunning(bundleID: bundleID)
        }
        guard let pc = processControl else {
            throw JITError.processNotRunning(bundleID: bundleID)
        }
        defer { process_control_free(pc) }

        var pid: UInt64 = 0
        Logger.jit.info("ProcessResolver: Launching \(bundleID) suspended")

        let launchErr = bundleID.withCString { cStr in
            process_control_launch_app(pc, cStr, nil, 0, nil, 0, true, false, &pid)
        }

        if let e = launchErr {
            idevice_error_free(e)
            throw JITError.processNotRunning(bundleID: bundleID)
        }

        Logger.jit.info("ProcessResolver: Successfully launched \(bundleID) with PID \(pid)")
        return Int64(pid)
    }

    private struct RsdSession {
        let adapter: OpaquePointer
        let handshake: OpaquePointer
        let remoteServer: OpaquePointer
    }

    private func openRsdSession(provider: OpaquePointer) throws -> RsdSession {
        var coreDevice: OpaquePointer?
        var err = core_device_proxy_connect(provider, &coreDevice)
        if let e = err {
            idevice_error_free(e)
            throw JITError.lockdownConnectionFailed
        }

        var rsdPort: UInt16 = 0
        err = core_device_proxy_get_server_rsd_port(coreDevice, &rsdPort)
        if let e = err {
            idevice_error_free(e)
            core_device_proxy_free(coreDevice)
            throw JITError.lockdownConnectionFailed
        }

        var adapter: OpaquePointer?
        err = core_device_proxy_create_tcp_adapter(coreDevice, &adapter)
        if let e = err {
            idevice_error_free(e)
            core_device_proxy_free(coreDevice)
            throw JITError.lockdownConnectionFailed
        }

        var stream: OpaquePointer?
        err = adapter_connect(adapter, rsdPort, &stream)
        if let e = err {
            idevice_error_free(e)
            adapter_free(adapter)
            throw JITError.lockdownConnectionFailed
        }

        var handshake: OpaquePointer?
        err = rsd_handshake_new(stream, &handshake)
        if let e = err {
            idevice_error_free(e)
            adapter_free(adapter)
            throw JITError.lockdownConnectionFailed
        }

        var remoteServer: OpaquePointer?
        err = remote_server_connect_rsd(adapter, handshake, &remoteServer)
        if let e = err {
            idevice_error_free(e)
            rsd_handshake_free(handshake)
            adapter_free(adapter)
            throw JITError.lockdownConnectionFailed
        }

        return RsdSession(adapter: adapter!, handshake: handshake!, remoteServer: remoteServer!)
    }
}
