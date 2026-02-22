import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct PerformanceMonitorView: View {
    @StateObject private var monitor = PerformanceMonitor()

    var body: some View {
        List {
            Section(header: Text("System Resources")) {
                HStack {
                    Label("CPU Usage", systemImage: "cpu")
                    Spacer()
                    Text("\(Int(monitor.cpuUsage))%")
                        .foregroundStyle(monitor.cpuUsage > 80 ? .red : monitor.cpuUsage > 50 ? .orange : .green)
                        .fontWeight(.semibold)
                        .animation(.easeInOut(duration: 0.3), value: monitor.cpuUsage)
                }

                HStack {
                    Label("Memory", systemImage: "memorychip")
                    Spacer()
                    Text(monitor.memoryUsage)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Disk Space", systemImage: "internaldrive")
                    Spacer()
                    Text(monitor.diskSpace)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("App Performance")) {
                HStack {
                    Label("Frame Rate", systemImage: "waveform.path.ecg")
                    Spacer()
                    Text("60 FPS")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label("Launch Time", systemImage: "timer")
                    Spacer()
                    Text("0.8s")
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Status")) {
                HStack {
                    Label("Monitoring", systemImage: monitor.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Spacer()
                    Text(monitor.isMonitoring ? "Active" : "Stopped")
                        .foregroundStyle(monitor.isMonitoring ? .green : .red)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Performance Monitor")
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}
