import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct EnvironmentInspectorView: View {
    @State private var environment: [String: String] = [:]
    @State private var searchText = ""

    var filteredEnvironment: [(key: String, value: String)] {
        let sorted = environment.sorted { $0.key < $1.key }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.key.localizedCaseInsensitiveContains(searchText) || $0.value.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            // Process Info Section
            Section(header: Text("Process Information")) {
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                LabeledContent("Process Name", value: ProcessInfo.processInfo.processName)
                LabeledContent("Host Name", value: ProcessInfo.processInfo.hostName)
                LabeledContent("OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                LabeledContent("Is Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Yes" : "No")
            }

            // Launch Arguments
            Section(header: Text("Launch Arguments (\(ProcessInfo.processInfo.arguments.count))")) {
                ForEach(ProcessInfo.processInfo.arguments, id: \.self) { arg in
                    Text(arg)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                }
            }

            // Environment Variables
            Section(header: Text("Environment Variables (\(filteredEnvironment.count))")) {
                ForEach(filteredEnvironment, id: \.key) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.key)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                        Text(item.value)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
            }

            // Actions
            Section {
                Button {
                    exportEnvironment()
                } label: {
                    Label("Copy Environment To Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search Environment")
        .navigationTitle("Environment Inspector")
        .onAppear {
            loadEnvironment()
        }
    }

    private func loadEnvironment() {
        environment = ProcessInfo.processInfo.environment
    }

    private func exportEnvironment() {
        var output = "=== Environment Variables ===\n\n"
        for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
            output += "\(key)=\(value)\n"
        }
        UIPasteboard.general.string = output
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Environment copied to clipboard", type: .success)
    }
}
