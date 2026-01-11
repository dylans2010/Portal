import SwiftUI

// MARK: - Check For Updates View
/// A modern, user-friendly view for checking and displaying app updates
/// This is a simplified version of the Developer Mode's UpdatesReleasesView
struct CheckForUpdatesView: View {
    @State private var isCheckingUpdates = false
    @State private var latestRelease: GitHubRelease?
    @State private var allReleases: [GitHubRelease] = []
    @State private var errorMessage: String?
    @State private var hasChecked = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let repoOwner = "aoyn1xw"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var isUpdateAvailable: Bool {
        guard let release = latestRelease else { return false }
        let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")
        return compareVersions(releaseVersion, currentVersion) == .orderedDescending
    }
    
    var body: some View {
        List {
            // Current Version Card
            Section {
                currentVersionCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Update Status Section
            if hasChecked {
                Section {
                    updateStatusView
                } header: {
                    Text("Update Status")
                }
            }
            
            // Release Notes Section
            if let release = latestRelease, isUpdateAvailable {
                Section {
                    releaseNotesView(release)
                } header: {
                    Text("What's New")
                } footer: {
                    if let date = release.publishedAt {
                        Text("Released \(date.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
            }
            
            // Previous Releases
            if allReleases.count > 1 {
                Section {
                    ForEach(allReleases.dropFirst().prefix(5), id: \.id) { release in
                        releaseRow(release)
                    }
                    
                    if allReleases.count > 6 {
                        Button {
                            if let url = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("View All Releases")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Previous Releases")
                }
            }
            
            // Error Section
            if let error = errorMessage {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Error")
                }
            }
        }
        .navigationTitle("Check For Updates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    checkForUpdates()
                } label: {
                    if isCheckingUpdates {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isCheckingUpdates)
            }
        }
        .onAppear {
            if !hasChecked {
                checkForUpdates()
            }
        }
    }
    
    // MARK: - Current Version Card
    private var currentVersionCard: some View {
        VStack(spacing: 16) {
            // App Icon
            if let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // App Name and Version
            VStack(spacing: 4) {
                Text("Portal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version \(currentVersion) (\(currentBuild))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Check for Updates Button
            Button {
                checkForUpdates()
            } label: {
                HStack(spacing: 8) {
                    if isCheckingUpdates {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isCheckingUpdates ? "Checking..." : "Check for Updates")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 300 : .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
                .foregroundStyle(.white)
            }
            .disabled(isCheckingUpdates)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Update Status View
    @ViewBuilder
    private var updateStatusView: some View {
        if isUpdateAvailable, let release = latestRelease {
            // Update Available
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Available")
                        .font(.headline)
                    Text("Version \(release.tagName.replacingOccurrences(of: "v", with: "")) is ready to install")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            Button {
                if let url = URL(string: release.htmlUrl) {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.success()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down.to.line")
                    Text("Download Update")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green)
                )
                .foregroundStyle(.white)
            }
        } else {
            // Up to Date
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("You're Up to Date")
                        .font(.headline)
                    Text("Portal \(currentVersion) is the latest version")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Release Notes View
    private func releaseNotesView(_ release: GitHubRelease) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Version Header
            HStack {
                Text(release.tagName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if release.prerelease {
                    Text("BETA")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // Release Notes
            if let body = release.body, !body.isEmpty {
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(10)
            }
            
            // Download Button
            Button {
                if let url = URL(string: release.htmlUrl) {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.success()
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text("View on GitHub")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Release Row
    private func releaseRow(_ release: GitHubRelease) -> some View {
        Button {
            if let url = URL(string: release.htmlUrl) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(release.tagName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        if release.prerelease {
                            Text("BETA")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let date = release.publishedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Check for Updates
    private func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil
        HapticsManager.shared.softImpact()
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isCheckingUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingUpdates = false
                hasChecked = true
                
                if let error = error {
                    errorMessage = "Failed to check: \(error.localizedDescription)"
                    HapticsManager.shared.error()
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    HapticsManager.shared.error()
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    // Filter out prereleases for regular users
                    allReleases = releases.filter { !$0.prerelease }
                    latestRelease = allReleases.first
                    
                    if isUpdateAvailable {
                        HapticsManager.shared.success()
                    } else {
                        HapticsManager.shared.softImpact()
                    }
                } catch {
                    errorMessage = "Failed to parse releases"
                    HapticsManager.shared.error()
                }
            }
        }.resume()
    }
    
    // MARK: - Version Comparison
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

// MARK: - Preview
#if DEBUG
struct CheckForUpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CheckForUpdatesView()
        }
    }
}
#endif
