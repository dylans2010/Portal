import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct NetworkSystemDevView: View {
    @AppStorage("dev.simulateOffline") private var simulateOffline = false
    @AppStorage("dev.latencyInjection") private var latencyInjection: Double = 0
    @AppStorage("dev.verboseLogging") private var verboseLogging = false
    @AppStorage("dev.logNetworkRequests") private var logNetworkRequests = false
    @State private var networkLogs: [String] = []
    @State private var systemInfo: [String: String] = [:]

    var body: some View {
        List {
            // Network Simulation
            Section(header: Text("Network Simulation")) {
                Toggle("Simulate Offline Mode", isOn: $simulateOffline)
                    .onChange(of: simulateOffline) { newValue in
                        AppLogManager.shared.info("Offline Simulation: \(newValue ? "Enabled" : "Disabled")", category: "Developer")
                    }

                VStack(alignment: .leading) {
                    Text("Latency Injection: \(Int(latencyInjection))ms")
                    Slider(value: $latencyInjection, in: 0...5000, step: 100)
                }

                Toggle("Log Network Requests", isOn: $logNetworkRequests)
            }

            // Logging
            Section(header: Text("Logging")) {
                Toggle("Verbose Logging", isOn: $verboseLogging)
                    .onChange(of: verboseLogging) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "verboseLogging")
                    }

                NavigationLink(destination: AppLogsView()) {
                    Label("View App Logs", systemImage: "terminal")
                }

                Button("Export Logs") {
                    exportLogs()
                }
            }

            // System Info
            Section(header: Text("System Information")) {
                Button("Refresh System Info") {
                    loadSystemInfo()
                }

                ForEach(Array(systemInfo.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(systemInfo[key] ?? "")
                            .foregroundStyle(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            // Failure Inspection
            Section(header: Text("Failure Inspection")) {
                NavigationLink(destination: FailureInspectorView()) {
                    Label("View Recent Failures", systemImage: "exclamationmark.triangle")
                }

                Button("Simulate Network Failure") {
                    simulateNetworkFailure()
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Network & System")
        .onAppear {
            loadSystemInfo()
        }
    }

    private func loadSystemInfo() {
        systemInfo = [
            "Device": UIDevice.current.model,
            "iOS Version": UIDevice.current.systemVersion,
            "Portal Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "Build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "Memory": getMemoryUsage(),
            "Disk Free": getDiskSpace(),
            "Network": getNetworkStatus()
        ]
    }

    private func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
        }
        return "Unknown"
    }

    private func getDiskSpace() -> String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
        }
        return "Unknown"
    }

    private func getNetworkStatus() -> String {
        return simulateOffline ? "Offline (Simulated)" : "Online"
    }

    private func exportLogs() {
        let logs = AppLogManager.shared.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
        AppLogManager.shared.success("Logs exported to clipboard", category: "Developer")
    }

    private func simulateNetworkFailure() {
        NotificationCenter.default.post(
            name: DownloadManager.downloadDidFailNotification,
            object: nil,
            userInfo: ["error": "Simulated network failure", "downloadId": "test"]
        )
        ToastManager.shared.show("⚠️ Network failure simulated", type: .warning)
        AppLogManager.shared.warning("Network failure simulated", category: "Developer")
    }
}
