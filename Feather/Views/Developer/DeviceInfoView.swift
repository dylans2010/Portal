import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct DeviceInfoView: View {
    @State private var deviceInfo: [String: String] = [:]
    @State private var hardwareInfo: [String: String] = [:]
    @State private var storageInfo: [String: String] = [:]
    @State private var batteryInfo: [String: String] = [:]

    var body: some View {
        List {
            deviceSection
            hardwareSection
            storageSection
            batterySection
            appInfoSection
            exportSection
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Device Information")
        .onAppear {
            loadDeviceInfo()
        }
    }

    private var deviceSection: some View {
        Section(header: Text("Device")) {
            ForEach(Array(deviceInfo.keys.sorted()), id: \.self) { key in
                DeveloperDeviceInfoRow(label: key, value: deviceInfo[key] ?? "Unknown")
            }
        }
    }

    private var hardwareSection: some View {
        Section(header: Text("Hardware")) {
            ForEach(Array(hardwareInfo.keys.sorted()), id: \.self) { key in
                DeveloperDeviceInfoRow(label: key, value: hardwareInfo[key] ?? "Unknown")
            }
        }
    }

    private var storageSection: some View {
        Section(header: Text("Storage")) {
            ForEach(Array(storageInfo.keys.sorted()), id: \.self) { key in
                DeveloperDeviceInfoRow(label: key, value: storageInfo[key] ?? "Unknown")
            }
        }
    }

    private var batterySection: some View {
        Section(header: Text("Battery")) {
            ForEach(Array(batteryInfo.keys.sorted()), id: \.self) { key in
                DeveloperDeviceInfoRow(label: key, value: batteryInfo[key] ?? "Unknown")
            }
        }
    }

    private var appInfoSection: some View {
        Section(header: Text("App Information")) {
            DeveloperDeviceInfoRow(label: "App Name", value: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
            DeveloperDeviceInfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            DeveloperDeviceInfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            DeveloperDeviceInfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                exportDeviceInfo()
            } label: {
                Label("Copy Device Info To Clipboard", systemImage: "doc.on.clipboard")
            }
        }
    }

    private func loadDeviceInfo() {
        let device = UIDevice.current

        // Device Info
        deviceInfo = [
            "Name": device.name,
            "Model": device.model,
            "System Name": device.systemName,
            "System Version": device.systemVersion,
            "Identifier": getDeviceIdentifier()
        ]

        // Hardware Info
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }

        hardwareInfo = [
            "Machine": machine,
            "Processor Count": "\(ProcessInfo.processInfo.processorCount) cores",
            "Physical Memory": ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory),
            "Active Processor Count": "\(ProcessInfo.processInfo.activeProcessorCount) cores"
        ]

        // Storage Info
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let totalSpace = attrs[.systemSize] as? Int64 ?? 0
            let freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            let usedSpace = totalSpace - freeSpace

            storageInfo = [
                "Total Space": ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file),
                "Free Space": ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file),
                "Used Space": ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
            ]
        }

        // Battery Info
        device.isBatteryMonitoringEnabled = true
        let batteryState: String
        switch device.batteryState {
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        case .unplugged: batteryState = "Unplugged"
        case .unknown: batteryState = "Unknown"
        @unknown default: batteryState = "Unknown"
        }

        batteryInfo = [
            "Battery Level": "\(Int(device.batteryLevel * 100))%",
            "Battery State": batteryState
        ]
    }

    private func getDeviceIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    private func exportDeviceInfo() {
        var info = "=== Device Information ===\n\n"

        info += "-- Device --\n"
        for (key, value) in deviceInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }

        info += "\n-- Hardware --\n"
        for (key, value) in hardwareInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }

        info += "\n-- Storage --\n"
        for (key, value) in storageInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }

        info += "\n-- Battery --\n"
        for (key, value) in batteryInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }

        info += "\n-- App --\n"
        info += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        info += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"

        UIPasteboard.general.string = info
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Device info copied to clipboard", type: .success)
    }
}
