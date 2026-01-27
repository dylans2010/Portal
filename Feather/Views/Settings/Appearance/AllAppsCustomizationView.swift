import SwiftUI

struct AllAppsCustomizationView: View {
    @AppStorage("Feather.allApps.showVersion") private var showVersion: Bool = true
    @AppStorage("Feather.allApps.showSize") private var showSize: Bool = true
    @AppStorage("Feather.allApps.showSorting") private var showSorting: Bool = true
    @AppStorage("Feather.allApps.iconPadding") private var iconPadding: Double = 0

    var body: some View {
        List {
            Section {
                Toggle(isOn: $showVersion) {
                    AppearanceRowLabel(icon: "tag.fill", title: "Show Version Number", color: .blue)
                }
                Toggle(isOn: $showSize) {
                    AppearanceRowLabel(icon: "internaldrive.fill", title: "Show App Size", color: .green)
                }
                Toggle(isOn: $showSorting) {
                    AppearanceRowLabel(icon: "line.3.horizontal.decrease.circle.fill", title: "Show Sorting Options", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Visibility", icon: "eye.fill")
            } footer: {
                Text("Customize which information is displayed in the All Apps view.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.left.and.right", title: "Icon Left Gap: \(Int(iconPadding))", color: .orange)
                    Slider(value: $iconPadding, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)
            } header: {
                AppearanceSectionHeader(title: "Layout", icon: "square.grid.2x2.fill")
            } footer: {
                Text("Adjust the horizontal padding for app icons.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Apps")
    }
}
