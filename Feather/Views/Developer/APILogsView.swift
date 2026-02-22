import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct APILogsView: View {
    @StateObject private var logManager = AppLogManager.shared

    var apiLogs: [LogEntry] {
        logManager.logs.filter { log in
            log.category == "API" || log.category == "Webhook"
        }.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            if apiLogs.isEmpty {
                if #available(iOS 17, *) {
                    ContentUnavailableView {
                        Label("No API Logs", systemImage: "network.slash")
                    } description: {
                        Text("API and webhook activity will appear here.")
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No API Logs")
                            .font(.headline)
                        Text("API and webhook activity will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                ForEach(apiLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.icon)
                            Text(log.formattedTimestamp)
                                .font(.caption2.monospaced())
                            Text("[\(log.category)]")
                                .font(.caption2.bold())
                                .foregroundStyle(.blue)
                        }

                        Text(log.message)
                            .font(.caption.monospaced())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("API Logs")
    }
}
