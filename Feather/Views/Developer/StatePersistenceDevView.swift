import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct StatePersistenceDevView: View {
    @State private var userDefaultsKeys: [String] = []
    @State private var appStorageKeys: [String] = []
    @State private var cacheSize: String = "Calculating..."
    @State private var showClearConfirmation = false
    @State private var clearTarget: ClearTarget = .all

    enum ClearTarget {
        case all, userDefaults, caches, onboarding
    }

    var body: some View {
        List {
            // AppStorage / UserDefaults
            Section(header: Text("UserDefaults")) {
                NavigationLink(destination: UserDefaultsEditorView()) {
                    Label("UserDefaults Editor", systemImage: "list.bullet.rectangle")
                }

                Button("Clear All UserDefaults", role: .destructive) {
                    clearTarget = .userDefaults
                    showClearConfirmation = true
                }
            }

            // Caches
            Section(header: Text("Caches")) {
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }

                Button("Clear URL Cache") {
                    URLCache.shared.removeAllCachedResponses()
                    calculateCacheSize()
                    HapticsManager.shared.success()
                    ToastManager.shared.show("✅ URL cache cleared", type: .success)
                    AppLogManager.shared.success("URL cache cleared", category: "Developer")
                }

                Button("Clear Image Cache") {
                    clearImageCache()
                    ToastManager.shared.show("✅ Image cache cleared", type: .success)
                }

                Button("Clear All Caches", role: .destructive) {
                    clearTarget = .caches
                    showClearConfirmation = true
                }
            }

            // Onboarding State
            Section(header: Text("Onboarding State")) {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") ? "True" : "False")
                        .foregroundStyle(.secondary)
                }

                Button("Reset Onboarding") {
                    clearTarget = .onboarding
                    showClearConfirmation = true
                }
            }

            // CoreData
            Section(header: Text("CoreData")) {
                NavigationLink(destination: CoreDataInspectorView()) {
                    Label("CoreData Inspector", systemImage: "cylinder.split.1x2")
                }
            }

            // Danger Zone
            Section(header: Text("Danger Zone")) {
                Button("Reset All App Data", role: .destructive) {
                    clearTarget = .all
                    showClearConfirmation = true
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("State & Persistence")
        .onAppear {
            calculateCacheSize()
        }
        .alert("Confirm Clear", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClear()
            }
        } message: {
            Text(clearConfirmationMessage)
        }
    }

    private var clearConfirmationMessage: String {
        switch clearTarget {
        case .all: return "This will reset all app data including settings, sources, and certificates. This cannot be undone."
        case .userDefaults: return "This will clear all UserDefaults. Some settings may be lost."
        case .caches: return "This will clear all cached data including images and network responses."
        case .onboarding: return "This will reset the onboarding state. You will see the onboarding screen on next launch."
        }
    }

    private func calculateCacheSize() {
        var totalSize: Int64 = 0

        // URL Cache
        totalSize += Int64(URLCache.shared.currentDiskUsage)

        // Image cache directory
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let size = try? FileManager.default.allocatedSizeOfDirectory(at: cacheURL) {
                totalSize += Int64(size)
            }
        }

        cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    private func clearImageCache() {
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let nukeCache = cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache")
            try? FileManager.default.removeItem(at: nukeCache)
        }
        calculateCacheSize()
        HapticsManager.shared.success()
        AppLogManager.shared.success("Image Cache Cleared", category: "Developer")
    }

    private func performClear() {
        switch clearTarget {
        case .all:
            // Clear everything
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("⚠️ All app data reset", type: .warning)
            AppLogManager.shared.warning("All app data reset", category: "Developer")

        case .userDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            ToastManager.shared.show("✅ UserDefaults cleared", type: .success)
            AppLogManager.shared.info("UserDefaults cleared", category: "Developer")

        case .caches:
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared", category: "Developer")

        case .onboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            ToastManager.shared.show("✅ Onboarding state reset", type: .success)
            AppLogManager.shared.info("Onboarding state reset", category: "Developer")
        }

        calculateCacheSize()
        HapticsManager.shared.success()
    }
}
