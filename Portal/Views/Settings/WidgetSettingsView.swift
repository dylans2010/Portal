import SwiftUI
import WidgetKit
import NimbleViews

struct WidgetSettingsView: View {
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    WidgetHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text(.localized("How to Add Widgets"))
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        instructionStep(number: "1", text: .localized("Long-press on your Home Screen until apps start to jiggle."))
                        instructionStep(number: "2", text: .localized("Tap the '+' button in the top-left corner."))
                        instructionStep(number: "3", text: .localized("Search for \"Portal\" and select it."))
                        instructionStep(number: "4", text: .localized("Choose your preferred widget and tap \"Add Widget\"."))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text(.localized("Instructions"))
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.iphone")
                            .foregroundStyle(.purple)
                        Text(.localized("Lock Screen Widgets"))
                            .font(.headline)
                    }

                    Text(.localized("You can also add Portal widgets to your Lock Screen for even quicker access to signing tools. Customize your Lock Screen to add them."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text(.localized("Lock Screen"))
            }

            Section {
                WidgetPreviewRow(
                    title: .localized("Quick Actions"),
                    description: .localized("Add sources, certificates, and check expiry directly from your Home Screen."),
                    icon: "plus.circle.fill",
                    color: .blue
                )

                WidgetPreviewRow(
                    title: .localized("Certificate Status"),
                    description: .localized("Monitor the expiration status of your active certificate at a glance."),
                    icon: "checkmark.seal.fill",
                    color: .green
                )
            } header: {
                Text(.localized("Available Widgets"))
            }

            Section {
                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                    HapticsManager.shared.success()
                } label: {
                    HStack {
                        Text(.localized("Reload All Widgets"))
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                }
            } footer: {
                Text(.localized("Force an immediate refresh of all Portal widgets on your Home Screen and Lock Screen."))
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(.localized("Widgets"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.subheadline)
        }
    }
}

struct WidgetPreviewRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
