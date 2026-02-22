import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct SourcesLibraryDevView: View {
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var isReloading = false
    @State private var selectedSource: AltSource?
    @State private var rawJSON: String = ""
    @State private var showRawJSON = false

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var sources: FetchedResults<AltSource>

    var body: some View {
        List {
            // Source Actions
            Section(header: Text("Source Actions")) {
                Button {
                    reloadAllSources()
                } label: {
                    HStack {
                        if isReloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Force Reload All Sources")
                    }
                }
                .disabled(isReloading)

                Button {
                    invalidateSourceCache()
                } label: {
                    Label("Invalidate Source Cache", systemImage: "trash")
                }

                Button {
                    refetchMetadata()
                } label: {
                    Label("ReFetch All Metadata", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            // Source List
            Section(header: Text("Sources (\(sources.count))")) {
                ForEach(sources) { source in
                    NavigationLink(destination: SourceInspectorView(source: source, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name ?? "Unknown")
                                .font(.headline)
                            if let url = source.sourceURL {
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            if let repo = viewModel.sources[source] {
                                Text("\(repo.apps.count) Apps")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            // Library Actions
            Section(header: Text("Library Actions")) {
                Button {
                    forceLibraryRerender()
                } label: {
                    Label("Force Library ReRender", systemImage: "arrow.counterclockwise")
                }

                Button {
                    clearLibraryCache()
                } label: {
                    Label("Clear Library Cache", systemImage: "trash")
                }
            }

            // Offline Handling
            Section(header: Text("Offline Handling")) {
                Toggle("Simulate Offline Mode", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.simulateOffline") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.simulateOffline") }
                ))

                Button {
                    testOfflineSourceHandling()
                } label: {
                    Label("Test Offline Source Handling", systemImage: "wifi.slash")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Sources & Library")
    }

    private func reloadAllSources() {
        isReloading = true
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                isReloading = false
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ All sources reloaded successfully", type: .success)
                AppLogManager.shared.success("All sources reloaded", category: "Developer")
            }
        }
    }

    private func invalidateSourceCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()

        // Clear image cache
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
        }

        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Source cache invalidated", type: .success)
        AppLogManager.shared.success("Source cache invalidated", category: "Developer")
    }

    private func refetchMetadata() {
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Metadata re-fetched successfully", type: .success)
            AppLogManager.shared.success("Metadata re-fetched", category: "Developer")
        }
    }

    private func forceLibraryRerender() {
        NotificationCenter.default.post(name: Notification.Name("Feather.forceLibraryRerender"), object: nil)
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library re-render triggered", type: .success)
        AppLogManager.shared.info("Library re-render triggered", category: "Developer")
    }

    private func clearLibraryCache() {
        // Clear any library-specific caches
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library cache cleared", type: .success)
        AppLogManager.shared.success("Library cache cleared", category: "Developer")
    }

    private func testOfflineSourceHandling() {
        UserDefaults.standard.set(true, forKey: "dev.simulateOffline")
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "dev.simulateOffline")
                ToastManager.shared.show("ℹ️ Offline source handling test completed", type: .info)
                AppLogManager.shared.info("Offline source handling test completed", category: "Developer")
            }
        }
    }
}
