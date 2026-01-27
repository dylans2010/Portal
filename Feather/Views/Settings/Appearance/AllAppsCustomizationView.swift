import SwiftUI

struct AllAppsCustomizationView: View {
    @AppStorage("Feather.allApps.showVersion") private var showVersion: Bool = true
    @AppStorage("Feather.allApps.showSize") private var showSize: Bool = true
    @AppStorage("Feather.allApps.showHeader") private var showHeader: Bool = true

    var body: some View {
        List {
            Section {
                Toggle(isOn: $showVersion) {
                    Label {
                        Text("Show Version Number")
                    } icon: {
                        Image(systemName: "number")
                            .foregroundStyle(.blue)
                    }
                }

                Toggle(isOn: $showSize) {
                    Label {
                        Text("Show App Size")
                    } icon: {
                        Image(systemName: "externaldrive")
                            .foregroundStyle(.green)
                    }
                }

                Toggle(isOn: $showHeader) {
                    Label {
                        Text("Show Header (App Count)")
                    } icon: {
                        Image(systemName: "list.bullet.rectangle.stack")
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Visibility")
            } footer: {
                Text("Customize which information is displayed in the All Apps view.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Apps")
    }
}
