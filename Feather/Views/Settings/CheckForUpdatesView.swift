// Created by dylan on 1.11.26

import SwiftUI

struct CheckForUpdatesView: View {
    @StateObject private var updateManager = UpdateManager()
    @State private var showFullReleaseNotes = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section
                heroSection
                
                // Update Status Card
                updateStatusCard
                
                // What's New Section (if update available)
                if updateManager.isUpdateAvailable, let release = updateManager.latestRelease {
                    whatsNewSection(release)
                }
                
                // Previous Releases
                if updateManager.allReleases.count > 1 {
                    previousReleasesSection
                }
                
                // Error Section
                if let error = updateManager.errorMessage {
                    errorSection(error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Check For Updates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    updateManager.checkForUpdates()
                } label: {
                    if updateManager.isCheckingUpdates {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(updateManager.isCheckingUpdates)
            }
        }
        .onAppear {
            if !updateManager.hasChecked {
                updateManager.checkForUpdates()
            }
        }
        .sheet(isPresented: $showFullReleaseNotes) {
            if let release = updateManager.latestRelease {
                FullReleaseNotesView(release: release)
            }
        }
        .sheet(isPresented: $updateManager.showUpdateFinished) {
            if let ipaURL = updateManager.downloadedIPAURL {
                UpdateFinishedView(
                    ipaURL: ipaURL,
                    fileName: updateManager.downloadedFileName,
                    onDismiss: {
                        updateManager.showUpdateFinished = false
                    }
                )
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 20) {
            // App Icon with glow effect
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                
                if let iconName = Bundle.main.iconFileName,
                   let icon = UIImage(named: iconName) {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                }
            }
            .padding(.top, 20)
            
            // App Name and Version
            VStack(spacing: 8) {
                Text("Portal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                // Modern version badge
                HStack(spacing: 8) {
                    Text("v\(currentVersion)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    Text("Build \(currentBuild)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            }
            
            // Check for Updates Button
            Button {
                updateManager.checkForUpdates()
            } label: {
                HStack(spacing: 12) {
                    if updateManager.isCheckingUpdates {
                        LoadingDotsView()
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(updateManager.isCheckingUpdates ? "Checking For Updates" : "Check For Updates")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 320 : .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundStyle(.white)
                .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(updateManager.isCheckingUpdates)
            .scaleEffect(updateManager.isCheckingUpdates ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: updateManager.isCheckingUpdates)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Update Status Card
    private var updateStatusCard: some View {
        VStack(spacing: 0) {
            if updateManager.hasChecked {
                if updateManager.isUpdateAvailable, let release = updateManager.latestRelease {
                    // Update Available
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Animated icon
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                if #available(iOS 17.0, *) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.green)
                                        .symbolEffect(.pulse, options: .repeating)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update Available!")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Version \(release.tagName.replacingOccurrences(of: "v", with: ""))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // New badge
                            Text("New")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                        
                        // Download button
                        Button {
                            updateManager.downloadUpdate()
                        } label: {
                            HStack(spacing: 10) {
                                if updateManager.isDownloading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.to.line.compact")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                if updateManager.isDownloading {
                                    Text("Downloading... \(Int(updateManager.downloadProgress * 100))%")
                                        .font(.system(size: 15, weight: .semibold))
                                } else {
                                    Text("Download Update")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.green)
                                    
                                    // Progress overlay
                                    if updateManager.isDownloading {
                                        GeometryReader { geo in
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.green.opacity(0.3))
                                                .frame(width: geo.size.width * updateManager.downloadProgress)
                                        }
                                    }
                                }
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(updateManager.isDownloading)
                    }
                } else {
                    // Up to Date
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You're Up To Date")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Portal version \(currentVersion) is the latest and greatest version!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            } else {
                // Not checked yet
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Check For Updates")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Tap the button above to check.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    updateManager.isUpdateAvailable ? Color.green.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - What's New Section
    private func whatsNewSection(_ release: GitHubRelease) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("What's New")
                    .font(.title3.bold())
                
                Spacer()
                
                // Modern build badge
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                    Text(release.tagName)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            
            // Release date
            if let date = release.publishedAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Released On \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // Release notes preview
            if let body = release.body, !body.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                    
                    // View More button
                    Button {
                        showFullReleaseNotes = true
                        HapticsManager.shared.softImpact()
                    } label: {
                        HStack(spacing: 6) {
                            Text("View More")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            // Prerelease badge if applicable
            if release.prerelease {
                HStack(spacing: 6) {
                    Image(systemName: "testtube.2")
                        .font(.caption)
                    Text("Beta")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Previous Releases Section
    private var previousReleasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Releases")
                .font(.title3.bold())
                .padding(.horizontal, 4)
            
            previousReleasesListContent
        }
    }
    
    private var previousReleasesListContent: some View {
        let releases = Array(updateManager.allReleases.dropFirst().prefix(5))
        
        return VStack(spacing: 0) {
            ForEach(Array(releases.enumerated()), id: \.element.id) { index, release in
                previousReleaseRow(release: release, index: index, totalCount: releases.count)
            }
            
            viewAllReleasesButton
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private func previousReleaseRow(release: GitHubRelease, index: Int, totalCount: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                if let url = URL(string: release.htmlUrl) {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.softImpact()
            } label: {
                releaseRowContent(release: release)
            }
            
            if index < totalCount - 1 {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
    
    private func releaseRowContent(release: GitHubRelease) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(release.tagName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if release.prerelease {
                        betaBadge
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
    
    private var betaBadge: some View {
        Text("Beta")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
    }
    
    @ViewBuilder
    private var viewAllReleasesButton: some View {
        if updateManager.allReleases.count > 6 {
            Divider()
                .padding(.leading, 16)
            
            Button {
                if let url = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(Color.accentColor)
                    Text("View All Releases")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Error Section
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unable to Check for Updates")
                    .font(.subheadline.weight(.semibold))
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Loading Dots Animation View
struct LoadingDotsView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                    .opacity(animationPhase == index ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: false)) {
                animationPhase = 2
            }
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Full Release Notes View
struct FullReleaseNotesView: View {
    let release: GitHubRelease
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            // Version badge
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                Text(release.tagName)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            
                            if release.prerelease {
                                Text("BETA")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                            }
                        }
                        
                        Text(release.name)
                            .font(.title2.bold())
                        
                        if let date = release.publishedAt {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text("Released On \(date.formatted(date: .long, time: .omitted))")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Release notes content
                    if let body = release.body, !body.isEmpty {
                        ModernMarkdownView(markdown: body)
                    } else {
                        Text("No Release Notes Available.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    
                    // Assets section
                    if !release.assets.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Downloads")
                                .font(.headline)
                            
                            ForEach(release.assets) { asset in
                                HStack {
                                    Image(systemName: "doc.zipper")
                                        .foregroundStyle(Color.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.name)
                                            .font(.subheadline.weight(.medium))
                                        Text(formatFileSize(asset.size))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        if let url = URL(string: asset.browserDownloadUrl) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(UIColor.tertiarySystemBackground))
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Release Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Update Manager
class UpdateManager: ObservableObject {
    @Published var isCheckingUpdates = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var latestRelease: GitHubRelease?
    @Published var allReleases: [GitHubRelease] = []
    @Published var errorMessage: String?
    @Published var hasChecked = false
    @Published var isUpdateAvailable = false
    @Published var showUpdateFinished = false
    @Published var downloadedIPAURL: URL?
    @Published var downloadedFileName: String = ""
    
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil
        HapticsManager.shared.softImpact()
        
        // Check for forced fake update first
        if UserDefaults.standard.bool(forKey: "dev.forceShowUpdate") {
            checkForForcedUpdate()
            return
        }
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isCheckingUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isCheckingUpdates = false
                self.hasChecked = true
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    HapticsManager.shared.error()
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No Data Received"
                    HapticsManager.shared.error()
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    self.allReleases = releases.filter { !$0.prerelease }
                    self.latestRelease = self.allReleases.first
                    
                    // Check if update is available
                    if let release = self.latestRelease {
                        let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                        self.isUpdateAvailable = self.compareVersions(releaseVersion, self.currentVersion) == .orderedDescending
                    }
                    
                    if self.isUpdateAvailable {
                        HapticsManager.shared.success()
                    } else {
                        HapticsManager.shared.softImpact()
                    }
                } catch {
                    self.errorMessage = "Failed to parse releases"
                    HapticsManager.shared.error()
                }
            }
        }.resume()
    }
    
    private func checkForForcedUpdate() {
        // Create fake release for testing
        let fakeVersion = UserDefaults.standard.string(forKey: "dev.fakeUpdateVersion") ?? "99.0.0"
        
        let fakeAsset = GitHubAsset(
            id: 999999,
            name: "Portal-\(fakeVersion).ipa",
            size: 50_000_000,
            downloadCount: 1000,
            browserDownloadUrl: "https://github.com/dylans2010/Portal/releases/download/v\(fakeVersion)/Portal-\(fakeVersion).ipa"
        )
        
        let fakeRelease = GitHubRelease(
            id: 999999,
            tagName: "v\(fakeVersion)",
            name: "Portal v\(fakeVersion) - Test Release",
            body: """
            ## 🧪 Test Release
            
            This is a **fake update** generated for testing purposes.
            
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
            htmlUrl: "https://github.com/dylans2010/Portal/releases/tag/v\(fakeVersion)",
            assets: [fakeAsset]
        )
        
        DispatchQueue.main.async {
            self.isCheckingUpdates = false
            self.hasChecked = true
            self.latestRelease = fakeRelease
            self.allReleases = [fakeRelease]
            self.isUpdateAvailable = true
            HapticsManager.shared.success()
            AppLogManager.shared.info("Showing forced fake update v\(fakeVersion)", category: "Updates")
        }
    }
    
    func downloadUpdate() {
        guard let release = latestRelease else { return }
        
        // Find IPA asset
        let ipaAsset = release.assets.first { $0.name.hasSuffix(".ipa") }
        
        if let asset = ipaAsset {
            downloadAsset(asset, fileName: asset.name)
        } else {
            // Fallback to opening GitHub page if no IPA found
            errorMessage = "No IPA file found in release assets"
            if let url = URL(string: release.htmlUrl) {
                UIApplication.shared.open(url)
            }
            HapticsManager.shared.error()
        }
    }
    
    private func downloadAsset(_ asset: GitHubAsset, fileName: String) {
        guard let url = URL(string: asset.browserDownloadUrl) else {
            errorMessage = "Invalid Download URL"
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadedFileName = fileName
        errorMessage = nil
        
        HapticsManager.shared.softImpact()
        AppLogManager.shared.info("Starting download: \(fileName)", category: "Updates")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300 // 5 minutes timeout
        
        let delegate = DownloadDelegate(manager: self)
        downloadSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        downloadTask = downloadSession?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func updateDownloadProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
    
    func downloadCompleted(at location: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isDownloading = false
            self.downloadProgress = 1.0
            
            // Create destination URL in documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = self.downloadedFileName.isEmpty ? "Portal-Update.ipa" : self.downloadedFileName
            let destinationURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Move downloaded file to documents
                try FileManager.default.moveItem(at: location, to: destinationURL)
                
                self.downloadedIPAURL = destinationURL
                self.showUpdateFinished = true
                
                HapticsManager.shared.success()
                AppLogManager.shared.success("Update downloaded successfully: \(destinationURL.path)", category: "Updates")
                
                // Clear forced update flag
                UserDefaults.standard.set(false, forKey: "dev.forceShowUpdate")
                
            } catch {
                self.errorMessage = "Failed to save update: \(error.localizedDescription)"
                HapticsManager.shared.error()
                AppLogManager.shared.error("Failed to save update: \(error.localizedDescription)", category: "Updates")
            }
        }
    }
    
    func downloadFailed(with error: Error) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadProgress = 0.0
            self.errorMessage = "Download failed: \(error.localizedDescription)"
            HapticsManager.shared.error()
            AppLogManager.shared.error("Download failed: \(error.localizedDescription)", category: "Updates")
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadSession?.invalidateAndCancel()
        isDownloading = false
        downloadProgress = 0.0
        HapticsManager.shared.softImpact()
        AppLogManager.shared.info("Download Cancelled", category: "Updates")
    }
    
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

// MARK: - Download Delegate
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var manager: UpdateManager?
    
    init(manager: UpdateManager) {
        self.manager = manager
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // IMPORTANT: The temp file at `location` is deleted immediately after this method returns.
        // We must copy/move the file synchronously before returning.
        
        guard let manager = manager else { return }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = manager.downloadedFileName.isEmpty ? "Portal-Update.ipa" : manager.downloadedFileName
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Ensure documents directory exists
            if !fileManager.fileExists(atPath: documentsPath.path) {
                try fileManager.createDirectory(at: documentsPath, withIntermediateDirectories: true)
            }
            
            // Remove existing file if present
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the file synchronously (must happen before this method returns)
            try fileManager.copyItem(at: location, to: destinationURL)
            
            // Now dispatch to main queue for UI updates
            DispatchQueue.main.async {
                manager.downloadedIPAURL = destinationURL
                manager.isDownloading = false
                manager.downloadProgress = 1.0
                manager.showUpdateFinished = true
                
                HapticsManager.shared.success()
                AppLogManager.shared.success("Update downloaded successfully: \(destinationURL.path)", category: "Updates")
                
                // Clear forced update flag
                UserDefaults.standard.set(false, forKey: "dev.forceShowUpdate")
            }
        } catch {
            DispatchQueue.main.async {
                manager.isDownloading = false
                manager.downloadProgress = 0.0
                manager.errorMessage = "Failed to save update: \(error.localizedDescription)"
                HapticsManager.shared.error()
                AppLogManager.shared.error("Failed to save update: \(error.localizedDescription)", category: "Updates")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        manager?.updateDownloadProgress(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            manager?.downloadFailed(with: error)
        }
    }
}

// MARK: - Update Finished View
struct UpdateFinishedView: View {
    let ipaURL: URL
    let fileName: String
    let onDismiss: () -> Void
    
    @State private var showShareSheet = false
    @State private var isAddingToLibrary = false
    @State private var addedToLibrary = false
    @State private var errorMessage: String?
    @State private var successAnimation = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Compact Success Header
                successHeader
                
                // File Info Card
                fileInfoCard
                
                // Action Buttons
                actionButtons
                
                // Error message if any
                if let error = errorMessage {
                    errorView(error)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Portal Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(urls: [ipaURL])
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    successAnimation = true
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        HStack(spacing: 14) {
            // Compact checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.green)
                    .scaleEffect(successAnimation ? 1 : 0)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Download Complete")
                    .font(.headline)
                
                Text(fileName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - File Info Card
    private var fileInfoCard: some View {
        HStack(spacing: 14) {
            // IPA Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "app.badge.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if let fileSize = getFileSize() {
                    Text(fileSize)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                
                Text("Ready To Sign")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Add to Library Button (primary action)
            Button {
                addToLibrary()
            } label: {
                HStack(spacing: 10) {
                    if isAddingToLibrary {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    } else if addedToLibrary {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Image(systemName: "plus.app")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(addedToLibrary ? "Added To Library" : "Add to Library")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(addedToLibrary ? Color.green : Color.accentColor)
                )
                .foregroundStyle(.white)
            }
            .disabled(isAddingToLibrary || addedToLibrary)
            
            // Share IPA Button
            Button {
                showShareSheet = true
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share IPA")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Helper Methods
    private func getFileSize() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: ipaURL.path)
            if let size = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: size)
            }
        } catch {
            // Ignore error
        }
        return nil
    }
    
    private func addToLibrary() {
        isAddingToLibrary = true
        errorMessage = nil
        HapticsManager.shared.softImpact()
        
        // Move file to unsigned directory for library
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let unsignedDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("unsigned", isDirectory: true)
                
                // Create unsigned directory if needed
                if !FileManager.default.fileExists(atPath: unsignedDir.path) {
                    try FileManager.default.createDirectory(at: unsignedDir, withIntermediateDirectories: true)
                }
                
                let destinationURL = unsignedDir.appendingPathComponent(fileName)
                
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Copy file to library
                try FileManager.default.copyItem(at: ipaURL, to: destinationURL)
                
                DispatchQueue.main.async {
                    isAddingToLibrary = false
                    addedToLibrary = true
                    HapticsManager.shared.success()
                    AppLogManager.shared.success("Added update to library: \(fileName)", category: "Updates")
                    
                    // Handle the IPA file using FR helper if available
                    FR.handlePackageFile(destinationURL) { error in
                        if let error = error {
                            AppLogManager.shared.error("Failed to process IPA: \(error.localizedDescription)", category: "Updates")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isAddingToLibrary = false
                    errorMessage = "Failed to add to library: \(error.localizedDescription)"
                    HapticsManager.shared.error()
                    AppLogManager.shared.error("Failed to add to library: \(error.localizedDescription)", category: "Updates")
                }
            }
        }
    }
}

// MARK: - Modern Markdown View
struct ModernMarkdownView: View {
    let markdown: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parseMarkdown(markdown).enumerated()), id: \.offset) { _, element in
                renderElement(element)
                    .padding(.bottom, element.bottomPadding)
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var currentCodeBlock: [String] = []
        var inCodeBlock = false
        var currentList: [String] = []
        var inList = false
        
        for line in lines {
            // Code block detection
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    elements.append(.codeBlock(currentCodeBlock.joined(separator: "\n")))
                    currentCodeBlock = []
                    inCodeBlock = false
                } else {
                    // Start code block
                    if inList {
                        elements.append(.bulletList(currentList))
                        currentList = []
                        inList = false
                    }
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                currentCodeBlock.append(line)
                continue
            }
            
            // Headers
            if line.hasPrefix("### ") {
                if inList {
                    elements.append(.bulletList(currentList))
                    currentList = []
                    inList = false
                }
                elements.append(.header3(String(line.dropFirst(4))))
                continue
            } else if line.hasPrefix("## ") {
                if inList {
                    elements.append(.bulletList(currentList))
                    currentList = []
                    inList = false
                }
                elements.append(.header2(String(line.dropFirst(3))))
                continue
            } else if line.hasPrefix("# ") {
                if inList {
                    elements.append(.bulletList(currentList))
                    currentList = []
                    inList = false
                }
                elements.append(.header1(String(line.dropFirst(2))))
                continue
            }
            
            // Lists
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                inList = true
                currentList.append(String(line.dropFirst(2)))
                continue
            } else if inList && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                elements.append(.bulletList(currentList))
                currentList = []
                inList = false
            }
            
            // Empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList {
                    elements.append(.bulletList(currentList))
                    currentList = []
                    inList = false
                }
                continue
            }
            
            // Regular paragraphs
            if !inList {
                elements.append(.paragraph(line))
            }
        }
        
        // Handle any remaining list items
        if inList {
            elements.append(.bulletList(currentList))
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .header1(let text):
            Text(processInlineMarkdown(text))
                .font(.title.bold())
                .foregroundStyle(.primary)
                .padding(.top, 8)
                
        case .header2(let text):
            Text(processInlineMarkdown(text))
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .padding(.top, 6)
                
        case .header3(let text):
            Text(processInlineMarkdown(text))
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .padding(.top, 4)
                
        case .paragraph(let text):
            Text(processInlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body.bold())
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 12)
                        Text(processInlineMarkdown(item))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)
            
        case .codeBlock(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(colorScheme == .dark ? .green : .purple)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func processInlineMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Bold (**text** or __text__)
        let boldPattern = #"\*\*(.+?)\*\*|__(.+?)__"#
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range])
                        .replacingOccurrences(of: "**", with: "")
                        .replacingOccurrences(of: "__", with: "")
                    
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                        if let boldRange = attributedString.range(of: content) {
                            attributedString[boldRange].font = .body.bold()
                        }
                    }
                }
            }
        }
        
        // Italic (*text* or _text_) - single only
        let italicPattern = #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(.+?)(?<!_)_(?!_)"#
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range])
                        .replacingOccurrences(of: "*", with: "")
                        .replacingOccurrences(of: "_", with: "")
                    
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                        if let italicRange = attributedString.range(of: content) {
                            attributedString[italicRange].font = .body.italic()
                        }
                    }
                }
            }
        }
        
        // Inline code (`code`)
        let codePattern = #"`(.+?)`"#
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range])
                        .replacingOccurrences(of: "`", with: "")
                    
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                        if let codeRange = attributedString.range(of: content) {
                            attributedString[codeRange].font = .body.monospaced()
                            attributedString[codeRange].foregroundColor = .accentColor
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
}

// MARK: - Markdown Elements
enum MarkdownElement {
    case header1(String)
    case header2(String)
    case header3(String)
    case paragraph(String)
    case bulletList([String])
    case codeBlock(String)
    
    var bottomPadding: CGFloat {
        switch self {
        case .header1: return 12
        case .header2: return 10
        case .header3: return 8
        case .paragraph: return 8
        case .bulletList: return 12
        case .codeBlock: return 12
        }
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
