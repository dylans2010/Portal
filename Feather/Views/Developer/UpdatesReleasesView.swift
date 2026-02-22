import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct UpdatesReleasesView: View {
    @State private var isCheckingUpdates = false
    @State private var latestRelease: GitHubRelease?
    @State private var allReleases: [GitHubRelease] = []
    @State private var errorMessage: String?
    @State private var showPrereleases = false
    @AppStorage("dev.mandatoryUpdateEnabled") private var mandatoryUpdateEnabled = false
    @AppStorage("dev.updateBannerDismissed") private var updateBannerDismissed = false
    @AppStorage("dev.showUpdateBannerPreview") private var showUpdateBannerPreview = false

    private let repoOwner = "dylans2010"
    private let repoName = "Portal"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        List {
            // Current Version Info
            Section(header: Text("Current Installed Version")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(currentVersion)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(currentBuild)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                }
            }

            // Update Check
            Section(header: Text("GitHub Releases")) {
                Button {
                    checkForUpdates()
                } label: {
                    HStack {
                        if isCheckingUpdates {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check For Updates")
                    }
                }
                .disabled(isCheckingUpdates)

                Toggle("Include Prereleases", isOn: $showPrereleases)
                    .onChange(of: showPrereleases) { _ in
                        checkForUpdates()
                    }

                if let release = latestRelease {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Latest: \(release.tagName)")
                                .font(.headline)
                            if release.prerelease {
                                Text("Pre Release")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(release.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let publishedAt = release.publishedAt {
                            Text("Published: \(publishedAt, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // All Releases
            if !allReleases.isEmpty {
                Section(header: Text("All Releases (\(allReleases.count))")) {
                    ForEach(allReleases, id: \.id) { release in
                        NavigationLink(destination: ReleaseDetailView(release: release)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(release.tagName)
                                            .font(.system(.body, design: .monospaced))
                                        if release.prerelease {
                                            Text("Pre Release")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.2))
                                                .foregroundStyle(.orange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(release.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Update Settings
            Section(header: Text("Portal Update Settings")) {
                Toggle("Mandatory Update Enforcement", isOn: $mandatoryUpdateEnabled)

                Toggle("Show Update Banner Preview", isOn: $showUpdateBannerPreview)

                Button("Reset Dismissed Update State") {
                    updateBannerDismissed = false
                    HapticsManager.shared.success()
                    AppLogManager.shared.info("Update banner dismissed state reset", category: "Developer")
                }

                HStack {
                    Text("Banner Dismissed")
                    Spacer()
                    Text(updateBannerDismissed ? "Yes" : "No")
                        .foregroundStyle(updateBannerDismissed ? .orange : .green)
                }
            }

            // Developer Testing
            Section(header: Text("Developer Testing")) {
                Button {
                    forceShowFakeUpdate()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                        Text("Force Show Update")
                        Spacer()
                        Text("Test")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.purple))
                    }
                }

                if UserDefaults.standard.bool(forKey: "dev.forceShowUpdate") {
                    Button {
                        stopForcedUpdate()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.red)
                            Text("Stop Force Show Update")
                            Spacer()
                            Text("Reset")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.red))
                        }
                    }
                }

                Text("Simulates an available update to test the CheckForUpdatesView and update banner.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Updates & Releases")
        .onAppear {
            if allReleases.isEmpty {
                checkForUpdates()
            }
        }
    }

    private func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid GitHub URL"
            isCheckingUpdates = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingUpdates = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    AppLogManager.shared.error("Failed to check updates: \(error.localizedDescription)", category: "Developer")
                    return
                }

                guard let data = data else {
                    errorMessage = "No Data Received"
                    return
                }

                do {
                    // Configure JSONDecoder with ISO8601 date decoding strategy
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    allReleases = showPrereleases ? releases : releases.filter { !$0.prerelease }
                    latestRelease = allReleases.first
                    AppLogManager.shared.success("Fetched \(releases.count) Releases", category: "Developer")
                } catch {
                    errorMessage = "Failed to parse releases: \(error.localizedDescription)"
                    AppLogManager.shared.error("Failed to parse releases: \(error.localizedDescription)", category: "Developer")
                }
            }
        }.resume()
    }

    private func forceShowFakeUpdate() {
        // Create a fake release with a higher version number
        let fakeAsset = GitHubAsset(
            id: 999999,
            name: "Portal-99.0.0.ipa",
            size: 50_000_000,
            downloadCount: 1000,
            browserDownloadUrl: "https://github.com/dylans2010/Portal/releases/download/v99.0.0/Portal-99.0.0.ipa"
        )

        let fakeRelease = GitHubRelease(
            id: 999999,
            tagName: "v99.0.0",
            name: "Portal v99.0.0 - Test Release",
            body: """
            ## 🧪 Test Release

            This is a **FAKE UPDATE** generated for debugging the CheckForUpdatesView.

            ### What's New
            - ✨ Amazing new features
            - 🐛 Bug fixes
            - 🚀 Performance improvements
            - 🎨 UI enhancements

            ### Notes
            This release is simulated by the Developer Mode "Force Show Update" feature.
            """,
            prerelease: false,
            draft: false,
            publishedAt: Date(),
            htmlUrl: "https://github.com/dylans2010/Portal/releases/tag/v99.0.0",
            assets: [fakeAsset]
        )

        // Store the fake release info for the Check for Updates view
        UserDefaults.standard.set(true, forKey: "dev.forceShowUpdate")
        UserDefaults.standard.set("99.0.0", forKey: "dev.fakeUpdateVersion")

        // Reset the dismissed state so the banner shows
        updateBannerDismissed = false

        // Post notification to trigger update banner
        NotificationCenter.default.post(name: .forceShowUpdateNotification, object: fakeRelease)

        HapticsManager.shared.success()
        AppLogManager.shared.info("Force showing fake update v99.0.0", category: "Developer")
    }

    private func stopForcedUpdate() {
        // Clear the forced update flags
        UserDefaults.standard.removeObject(forKey: "dev.forceShowUpdate")
        UserDefaults.standard.removeObject(forKey: "dev.fakeUpdateVersion")

        // Check for real updates again
        checkForUpdates()

        HapticsManager.shared.success()
        AppLogManager.shared.info("Stopped forcing fake update, checking for real updates from GitHub", category: "Developer")
    }
}
