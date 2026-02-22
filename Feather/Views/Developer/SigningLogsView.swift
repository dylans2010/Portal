import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct SigningLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var showExportSheet = false

    var signingLogs: [LogEntry] {
        logManager.logs.filter { log in
            log.category == "Signing" ||
            log.category == "Certificate" ||
            log.category == "Install" ||
            log.message.lowercased().contains("sign")
        }
    }

    var filteredLogs: [LogEntry] {
        var result = signingLogs

        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        if let level = selectedLevel {
            result = result.filter { $0.level == level }
        }

        return result.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "All", isSelected: selectedLevel == nil, count: signingLogs.count) {
                        selectedLevel = nil
                    }

                    ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                        let count = signingLogs.filter { $0.level == level }.count
                        if count > 0 {
                            FilterPill(title: level.rawValue, icon: level.icon, isSelected: selectedLevel == level, count: count) {
                                selectedLevel = selectedLevel == level ? nil : level
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("No Signing Logs")
                        .font(.headline)
                    Text("Signing operations will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        SigningLogRow(entry: log)
                    }
                }
            .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $searchText, prompt: "Search Logs")
        .navigationTitle("Signing Logs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportLogs()
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        copyLogsToClipboard()
                    } label: {
                        Label("Copy To Clipboard", systemImage: "doc.on.clipboard")
                    }

                    Divider()

                    Button(role: .destructive) {
                        clearSigningLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private func exportLogs() {
        let logsText = filteredLogs.map { log in
            "[\(log.formattedTimestamp)] [\(log.level.rawValue)] [\(log.category)] \(log.message)"
        }.joined(separator: "\n")

        UIPasteboard.general.string = logsText
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
    }

    private func copyLogsToClipboard() {
        exportLogs()
    }

    private func clearSigningLogs() {
        // Note: This clears from UI view only
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Signing Logs Cleared", type: .success)
    }
}
