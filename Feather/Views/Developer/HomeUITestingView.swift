import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct HomeUITestingView: View {
    @AppStorage("Feather.devShowSimulatedUpdateBanner") private var showSimulatedUpdateBanner = false
    @AppStorage("Feather.showAppUpdateBanner") private var showAppUpdateBanner = true
    @StateObject private var updateTrackingManager = AppUpdateTrackingManager.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: $showSimulatedUpdateBanner) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrow.down.app.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Simulated Update Banner")
                                .font(.system(size: 15, weight: .medium))
                            Text("Display a fake app update banner on Home view.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.green)
            } header: {
                Text("App Update Banner")
            } footer: {
                Text("Enable this to see how the app update banner looks on the Home screen with simulated data. This is useful for testing the UI without having actual app updates.")
            }

            Section {
                Toggle(isOn: $showAppUpdateBanner) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        Text("Enable Update Banners")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
                .tint(.blue)
            } header: {
                Text("Banner Settings")
            } footer: {
                Text("Master toggle for showing app update banners on the Home screen.")
            }

            Section {
                HStack {
                    Text("Tracked Apps")
                    Spacer()
                    Text("\(updateTrackingManager.trackedApps.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Available Updates")
                    Spacer()
                    Text("\(updateTrackingManager.availableUpdates.count)")
                        .foregroundStyle(.secondary)
                }

                if let lastCheck = updateTrackingManager.lastCheckDate {
                    HStack {
                        Text("Last Check")
                        Spacer()
                        Text(lastCheck, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Update Tracking Status")
            }

            Section {
                Button {
                    // Add a simulated tracked app for testing
                    let testConfig = TrackedAppConfig(
                        bundleIdentifier: "com.test.simulatedapp.\(UUID().uuidString.prefix(8))",
                        appName: "Test App \(Int.random(in: 1...100))",
                        sourceURL: "https://example.com/repo.json",
                        sourceName: "DEBUG",
                        lastKnownVersion: "1.0.0",
                        iconURL: nil,
                        isEnabled: true
                    )
                    updateTrackingManager.addTrackedApp(testConfig)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                        Text("Add Test Tracked App")
                    }
                }

                Button(role: .destructive) {
                    // Clear all tracked apps
                    for app in updateTrackingManager.trackedApps {
                        updateTrackingManager.removeTrackedApp(bundleIdentifier: app.bundleIdentifier)
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                        Text("Clear All Tracked Apps")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Testing Actions")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Home UI Testing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
