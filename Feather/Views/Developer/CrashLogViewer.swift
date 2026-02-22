import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct CrashLogViewer: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var crashLogs: [LogEntry] = []

    var body: some View {
        List {
            if crashLogs.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("No Crash Logs")
                            .font(.headline)

                        Text("Portal has not recorded any crashes. This is good!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Critical Errors (\(crashLogs.count))")) {
                    ForEach(crashLogs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.level.icon)
                                Text(log.formattedTimestamp)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Text(log.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.red)

                            HStack {
                                Text("[\(log.category)]")
                                Text("\(log.file):\(log.line)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        clearCrashLogs()
                    } label: {
                        Label("Clear Crash Logs", systemImage: "trash")
                    }
                }
            }

            // Export Section
            Section {
                Button {
                    exportCrashLogs()
                } label: {
                    Label("Export All Logs", systemImage: "square.and.arrow.up")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Crash Logs")
        .onAppear {
            loadCrashLogs()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    loadCrashLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private func loadCrashLogs() {
        crashLogs = logManager.logs.filter { $0.level == .critical || $0.level == .error }
    }

    private func clearCrashLogs() {
        // Note: This only removes them from view, not from the actual log manager logic
        crashLogs.removeAll()
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Crash logs cleared from view", type: .success)
    }

    private func exportCrashLogs() {
        let logs = logManager.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
    }
}

// MARK: - Quick Actions Dev View
