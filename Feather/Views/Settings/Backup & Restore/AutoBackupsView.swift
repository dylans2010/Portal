import SwiftUI

struct AutoBackupsView: View {
    @AppStorage("autoBackupEnabled") var autoBackupEnabled = false
    @AppStorage("autoBackupIncludeCertificates") var includeCertificates = true
    @AppStorage("autoBackupIncludeSignedApps") var includeSignedApps = false
    @AppStorage("autoBackupIncludeImportedApps") var includeImportedApps = false
    @AppStorage("autoBackupIncludeSources") var includeSources = true
    @AppStorage("autoBackupIncludeDefaultFrameworks") var includeDefaultFrameworks = true
    @AppStorage("autoBackupIncludeArchives") var includeArchives = false

    @AppStorage("autoBackupStartTime") var autoBackupStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("autoBackupFrequency") var autoBackupFrequency: String = "Daily"

    private var startTimeBinding: Binding<Date> {
        Binding(get: {
            Date(timeIntervalSince1970: autoBackupStartTime)
        }, set: { newValue in
            autoBackupStartTime = newValue.timeIntervalSince1970
        })
    }

    var body: some View {
        List {
            Section {
                Toggle(.localized("Enable Automatic Backups"), isOn: $autoBackupEnabled)
            } footer: {
                Text(.localized("Automatically create backups of your data based on the selected schedule."))
            }

            if autoBackupEnabled {
                Section(.localized("Schedule")) {
                    DatePicker(.localized("Start Time"), selection: startTimeBinding, displayedComponents: .hourAndMinute)

                    Picker(.localized("Frequency"), selection: $autoBackupFrequency) {
                        Text(.localized("Daily")).tag("Daily")
                        Text(.localized("Weekly")).tag("Weekly")
                        Text(.localized("Monthly")).tag("Monthly")
                    }
                }

                Section(.localized("Backup Content")) {
                    Toggle(.localized("Certificates"), isOn: $includeCertificates)
                    Toggle(.localized("Signed Apps"), isOn: $includeSignedApps)
                    Toggle(.localized("Imported Apps"), isOn: $includeImportedApps)
                    Toggle(.localized("Sources"), isOn: $includeSources)
                    Toggle(.localized("Default Frameworks"), isOn: $includeDefaultFrameworks)
                    Toggle(.localized("Archives"), isOn: $includeArchives)
                }

                if includeSignedApps || includeImportedApps {
                    Section {
                        Label {
                            Text(.localized("Including apps will make backups significantly larger and may take longer to complete."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle(.localized("Automatic Backups"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AutoBackupsView()
    }
}
