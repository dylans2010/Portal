import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct FailureInspectorView: View {
    @StateObject private var logManager = AppLogManager.shared

    var failureLogs: [LogEntry] {
        logManager.logs.filter { $0.level == .error || $0.level == .critical }
    }

    var body: some View {
        List {
            if failureLogs.isEmpty {
                Text("No Failures Recorded")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(failureLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.icon)
                            Text(log.formattedTimestamp)
                                .font(.caption.monospaced())
                        }
                        Text(log.message)
                            .font(.system(.body, design: .monospaced))
                        Text("[\(log.category)] \(log.file):\(log.line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Failures")
    }
}

// MARK: - State & Persistence Dev View
