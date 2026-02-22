import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct InstallIPADevView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showInstallModifyDialog = false
    @State private var lastInstallLogs: [String] = []
    @State private var selectedApp: (any AppInfoPresentable)?

    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>

    var body: some View {
        List {
            // Install Queue
            Section(header: Text("Download Queue (\(downloadManager.downloads.count))")) {
                if downloadManager.downloads.isEmpty {
                    Text("No Active Downloads")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(downloadManager.downloads, id: \.id) { download in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(download.fileName)
                                .font(.system(.body, design: .monospaced))
                            ProgressView(value: download.overallProgress)
                            HStack {
                                Text("\(Int(download.progress * 100))% Downloaded")
                                Spacer()
                                Text("\(Int(download.unpackageProgress * 100))% Processed")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Clear Pending Installs", role: .destructive) {
                    clearPendingInstalls()
                }
            }

            // IPA Validation
            Section(header: Text("IPA Tools")) {
                NavigationLink(destination: IPAInspectorView()) {
                    Label("IPA Inspector", systemImage: "doc.zipper")
                }

                NavigationLink(destination: IPAIntegrityCheckerView()) {
                    Label("Integrity Checker", systemImage: "checkmark.shield")
                }
            }

            // InstallModifyDialog Testing
            Section(header: Text("InstallModifyDialog Testing")) {
                if let firstApp = importedApps.first {
                    Button("Show InstallModifyDialog (Full Screen)") {
                        selectedApp = firstApp
                        showInstallModifyDialog = true
                    }
                } else {
                    Text("No Imported Apps Available For Testing")
                        .foregroundStyle(.secondary)
                }

                Toggle("Always Show After Download", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.alwaysShowInstallModify") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.alwaysShowInstallModify") }
                ))
            }

            // Last Install Logs
            Section(header: Text("Last Install Logs")) {
                Button("Load Install Logs") {
                    loadInstallLogs()
                }

                if !lastInstallLogs.isEmpty {
                    ForEach(lastInstallLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Install & IPA")
        .fullScreenCover(isPresented: $showInstallModifyDialog) {
            if let app = selectedApp {
                InstallModifyDialogView(app: app)
            }
        }
    }

    private func clearPendingInstalls() {
        for download in downloadManager.downloads {
            downloadManager.cancelDownload(download)
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Pending Installs Cleared", type: .success)
        AppLogManager.shared.info("Pending Installs Cleared", category: "Developer")
    }

    private func loadInstallLogs() {
        lastInstallLogs = AppLogManager.shared.logs
            .filter { $0.category == "Install" || $0.category == "Download" }
            .prefix(20)
            .map { "[\($0.level.rawValue)] \($0.message)" }
    }
}
