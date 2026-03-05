import SwiftUI

struct AutoBackupsView: View {
    @AppStorage("Feather.autoBackupEnabled") private var isEnabled = false
    @AppStorage("Feather.autoBackupFrequency") private var frequency = 0 // 0: Daily, 1: Weekly, 2: Monthly
    @AppStorage("Feather.autoBackupMaxCount") private var maxCount = 5

    @AppStorage("Feather.autoBackupIncludeCerts") private var includeCerts = true
    @AppStorage("Feather.autoBackupIncludeApps") private var includeApps = false
    @AppStorage("Feather.autoBackupIncludeSources") private var includeSources = true

    var body: some View {
        List {
            Section {
                Toggle(isOn: $isEnabled) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Automatic Backups")
                            Text("Automatically secure your data.").font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.clock").foregroundStyle(.blue)
                    }
                }
            } footer: {
                Text("Automatic backups run when the app is opened or in the background if iOS allows it.")
            }

            if isEnabled {
                Section {
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag(0)
                        Text("Weekly").tag(1)
                        Text("Monthly").tag(2)
                    }

                    Stepper(value: $maxCount, in: 1...20) {
                        HStack {
                            Text("Keep Last")
                            Spacer()
                            Text("\(maxCount) Backups").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    Toggle("Certificates", isOn: $includeCerts)
                    Toggle("Apps (IPA)", isOn: $includeApps)
                    Toggle("Sources", isOn: $includeSources)
                } header: {
                    Text("Content")
                } footer: {
                    if includeApps {
                        Text("Including Apps will significantly increase backup size and may slow down the process.")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Automatic Backups")
        .navigationBarTitleDisplayMode(.inline)
    }
}
