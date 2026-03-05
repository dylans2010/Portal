import Foundation
import SwiftUI
import Combine

/// Singleton manager for automatic update checking
final class CheckUpdatesManager: ObservableObject {
    static let shared = CheckUpdatesManager()

    @Published var isChecking = false
    @Published var latestRelease: GitHubRelease?
    @Published var isUpdateAvailable = false

    private let repoOwner = "dylans2010"
    private let repoName = "Portal"

    @AppStorage("Feather.autoCheckUpdates") private var autoCheckUpdates = true

    private init() {}

    /// Checks for updates if enabled in settings and not already checking
    func checkIfNeeded() {
        guard autoCheckUpdates else {
            AppLogManager.shared.debug("Automatic update check is disabled", category: "Updates")
            return
        }

        guard !isChecking else {
            AppLogManager.shared.debug("Update check already in progress", category: "Updates")
            return
        }

        Task {
            await checkForUpdates()
        }
    }

    /// Performs the update check against GitHub API
    func checkForUpdates() async {
        await MainActor.run { isChecking = true }

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            await MainActor.run { isChecking = false }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let release = try decoder.decode(GitHubRelease.self, from: data)

            await MainActor.run {
                self.latestRelease = release

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")

                self.isUpdateAvailable = compareVersions(releaseVersion, currentVersion) == .orderedDescending
                self.isChecking = false

                if self.isUpdateAvailable {
                    AppLogManager.shared.info("Automatic check found update: \(release.tagName)", category: "Updates")
                    NotificationCenter.default.post(name: .init("Feather.UpdateAvailable"), object: release)
                } else {
                    AppLogManager.shared.info("Automatic check: App is up to date", category: "Updates")
                }
            }
        } catch {
            AppLogManager.shared.warning("Automatic update check failed: \(error.localizedDescription)", category: "Updates")
            await MainActor.run { isChecking = false }
        }
    }

    /// Compare two semantic version strings
    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(components1.count, components2.count)

        for i in 0..<maxLength {
            let num1 = i < components1.count ? components1[i] : 0
            let num2 = i < components2.count ? components2[i] : 0

            if num1 < num2 {
                return .orderedAscending
            } else if num1 > num2 {
                return .orderedDescending
            }
        }

        return .orderedSame
    }
}
