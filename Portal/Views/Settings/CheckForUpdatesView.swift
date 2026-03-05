// Created by dylan on 1.11.26

import SwiftUI

struct CheckForUpdatesView: View {
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @StateObject private var updateManager = UpdateManager()
    @State private var selectedReleaseForNotes: GitHubRelease? = nil
    @State private var hammerTapCount = 0
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if showHeaderViews {
                        UpdatesHeaderView()
                    }

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
            .background(Color.clear)

            // Dynamic Metal Loading Screen
            FullScreenMetalStateView(
                state: $updateManager.metalState,
                errorMessage: updateManager.errorMessage,
                onDismissError: {
                    updateManager.errorMessage = nil
                }
            )
        }
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !updateManager.hasChecked {
                updateManager.checkForUpdates()
            }
        }
        .sheet(item: $selectedReleaseForNotes) { release in
            FullReleaseNotesView(release: release)
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
        VStack(spacing: 24) {
            // App Icon with enhanced glow effect
            ZStack {
                // Dynamic Background Glow
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [Color.accentColor.opacity(0.5), Color.purple.opacity(0.5), Color.blue.opacity(0.5), Color.accentColor.opacity(0.5)],
                            center: .center
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .rotationEffect(.degrees(updateManager.isCheckingUpdates ? 360 : 0))
                    .animation(updateManager.isCheckingUpdates ? .linear(duration: 4).repeatForever(autoreverses: false) : .default, value: updateManager.isCheckingUpdates)
                
                if let iconName = Bundle.main.iconFileName,
                   let icon = UIImage(named: iconName) {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
                }
            }
            .padding(.top, 30)
            
            // App Name and Version
            VStack(spacing: 12) {
                Text("Portal")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("v\(currentVersion)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.05)))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 10))
                        Text(currentBuild)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .onTapGesture {
                        if UserDefaults.standard.bool(forKey: "Feather.devModeUnlocked") {
                            hammerTapCount += 1
                            if hammerTapCount >= 5 {
                                isDeveloperModeEnabled = true
                                hammerTapCount = 0
                                HapticsManager.shared.success()
                                ToastManager.shared.show("🚀 Developer Mode Enabled!", type: .success)
                                UserDefaults.standard.set(false, forKey: "Feather.devModeUnlocked")
                            } else {
                                HapticsManager.shared.softImpact()
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    )
                }
            }
            
            // Modern Check for Updates Button
            Button {
                updateManager.checkForUpdates()
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        if !updateManager.isCheckingUpdates {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 18))
                        }

                        Text(updateManager.isCheckingUpdates ? "Searching..." : "Check For Updates")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 16)

                    if updateManager.isCheckingUpdates {
                        ModernProgressBar(progress: nil)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 320 : .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(updateManager.isCheckingUpdates ? Color.gray : Color.accentColor)
                )
                .foregroundStyle(.white)
                .shadow(color: (updateManager.isCheckingUpdates ? Color.clear : Color.accentColor.opacity(0.3)), radius: 10, x: 0, y: 5)
            }
            .disabled(updateManager.isCheckingUpdates)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Update Status Card
    private var updateStatusCard: some View {
        let isUpToDate = updateManager.hasChecked && !updateManager.isUpdateAvailable

        return VStack(spacing: 0) {
            if updateManager.hasChecked {
                if updateManager.isUpdateAvailable, let release = updateManager.latestRelease {
                    // Update Available
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            ZStack {
                                MetalIntegratedStateView(state: $updateManager.metalState)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())

                                if updateManager.metalState == .idle || updateManager.metalState == .success {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "gearshape.badge.plus")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.accentColor)
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update Available!")
                                    .font(.system(.headline, design: .rounded).bold())

                                Text("Version \(release.tagName.replacingOccurrences(of: "v", with: ""))")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("New")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green))
                        }

                        VStack(spacing: 12) {
                            Button {
                                if updateManager.isPaused {
                                    updateManager.resumeDownload()
                                } else if updateManager.isDownloading {
                                    updateManager.pauseDownload()
                                } else {
                                    updateManager.downloadUpdate()
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        if updateManager.isDownloading {
                                            Image(systemName: updateManager.isPaused ? "play.fill" : "pause.fill")
                                                .font(.system(size: 14))
                                                .transition(.scale.combined(with: .opacity))
                                        } else {
                                            Image(systemName: "arrow.down.to.line.fill")
                                                .font(.system(size: 16))
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(.white.opacity(0.2)))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: updateManager.isDownloading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        let titleText: String = {
                                            if updateManager.isPaused { return "Download Paused" }
                                            if updateManager.isDownloading { return "Downloading Update..." }
                                            return "Download & Install"
                                        }()
                                        Text(titleText)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))

                                        if updateManager.isDownloading {
                                            Text("\(Int(updateManager.downloadProgress * 100))% • \(updateManager.downloadedFileName)")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .opacity(0.9)
                                        }
                                    }

                                    Spacer()

                                    if updateManager.isDownloading && !updateManager.isPaused {
                                        DownloadingWaveAnimation()
                                            .frame(width: 40, height: 20)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )

                                        if updateManager.isDownloading {
                                            GeometryReader { geo in
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .fill(.white.opacity(0.15))
                                                    .frame(width: geo.size.width * updateManager.downloadProgress)
                                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: updateManager.downloadProgress)

                                                // Fluid gloss effect
                                                LinearGradient(
                                                    colors: [.clear, .white.opacity(0.3), .clear],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                .frame(width: 150)
                                                .offset(x: -150 + (geo.size.width + 300) * updateManager.downloadProgress)
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        }
                                    }
                                )
                                .foregroundStyle(.white)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                    }
                } else {
                    // Up to Date
                    HStack(spacing: 16) {
                        ZStack {
                            MetalIntegratedStateView(state: $updateManager.metalState)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())

                            if updateManager.metalState == .idle {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "gear.badge.checkmark")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.blue)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No Updates Found")
                                .font(.system(.headline, design: .rounded))

                            Text("You're running the latest Portal version, keep looking for updates later.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .ifAvailableIOS26Glass()
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            MetalIntegratedStateView(state: .constant(.loading))
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .frame(width: 56, height: 56)

                            Image(systemName: "gear.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Searching For Updates")
                                .font(.system(.headline, design: .rounded))

                            Text("Portal is checking for any avaiilable updates...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    ModernProgressBar(progress: nil)
                }
            }
        }
        .padding(isUpToDate && isAvailableIOS26() ? 0 : 20)
        .background {
            if isUpToDate && isAvailableIOS26() {
                Color.clear
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear, .black.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 8)
            }
        }
    }

    private func isAvailableIOS26() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - What's New Section
    private func whatsNewSection(_ release: GitHubRelease) -> some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                Spacer()
                Label("What's New", systemImage: "sparkles")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.primary)
                Spacer()
            }

            if let date = release.publishedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            if let body = release.body, !body.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Text(AttributedString(processMarkdownForPreview(body)))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(6)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        selectedReleaseForNotes = release
                        HapticsManager.shared.softImpact()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Read Release Notes")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(16)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Previous Releases Section
    private var previousReleasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Previous Releases")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                viewAllReleasesButton
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                if updateManager.isCheckingUpdates {
                    LookingForReleasesView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    let releases = Array(updateManager.allReleases.dropFirst().prefix(3))
                    ForEach(Array(releases.enumerated()), id: \.element.id) { index, release in
                        previousReleaseRow(release: release)

                        if index < releases.count - 1 {
                            Divider()
                                .opacity(0.5)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }

    private func previousReleaseRow(release: GitHubRelease) -> some View {
        Button {
            selectedReleaseForNotes = release
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(release.tagName)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)

                        if release.prerelease {
                            betaBadge
                        }
                    }

                    if let date = release.publishedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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
    
    private func processMarkdownForPreview(_ text: String) -> String {
        // Strip markdown markers for a cleaner preview
        text.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Error Section
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "gearshape.badge.xmark")
                    .font(.system(size: 26))
                    .foregroundStyle(.red)
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Failed To Check")
                    .font(.system(.headline, design: .rounded).bold())

                Text("Portal has failed to check for updates, try again later.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.red.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 20
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Looking For Releases Animation
struct LookingForReleasesView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }

            Text("Portal is looking for past releases...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(isAnimating ? 1.0 : 0.5)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Progress Bar
struct ModernProgressBar: View {
    let progress: Double?
    @State private var indeterminateOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 6)

                if let progress = progress {
                    // Determinate
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)), height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                } else {
                    // Indeterminate
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.accentColor, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.4, height: 6)
                        .offset(x: geo.size.width * indeterminateOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                indeterminateOffset = 1.2
                            }
                        }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 6)
    }
}

// MARK: - Downloading Wave Animation
struct DownloadingWaveAnimation: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white)
                    .frame(width: 3, height: 12)
                    .scaleEffect(y: 0.4 + 0.6 * sin(phase + Double(index) * 0.8))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
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
        VStack(spacing: 0) {
            // Modern Floating Capsule Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Release Notes")
                        .font(.system(size: 22, weight: .black, design: .rounded))

                    Text(release.tagName)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                    HapticsManager.shared.softImpact()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Modern Header Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            if release.prerelease {
                                Text("Beta")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                            } else {
                                Text("Stable")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.green.opacity(0.15)))
                            }

                            Spacer()

                            if let date = release.publishedAt {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(release.name)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                        
                    }
                    
                    Divider()
                    
                    // Release notes content
                    if let body = release.body, !body.isEmpty {
                        ModernMarkdownView(markdown: body)
                    } else {
                        Text("No Release Notes Available")
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
                                        .fill(Color.clear)
                                )
                            }
                        }
                    }
                }
                .padding(20)
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
    @Published var isPaused = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadingReleaseID: Int? = nil
    @Published var latestRelease: GitHubRelease?
    @Published var allReleases: [GitHubRelease] = []
    @Published var errorMessage: String?
    @Published var hasChecked = false
    @Published var isUpdateAvailable = false
    @Published var showUpdateFinished = false
    @Published var downloadedIPAURL: URL?
    @Published var downloadedFileName: String = ""
    @Published var metalState: MetalAnimationState = .idle
    
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    private var resumeData: Data?
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    func checkForUpdates() {
        isCheckingUpdates = true
        metalState = .loading
        errorMessage = nil
        HapticsManager.shared.softImpact()
        
        // Check for forced fake update first
        if UserDefaults.standard.bool(forKey: "dev.forceShowUpdate") {
            checkForForcedUpdate()
            return
        }
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid GitHub URL"
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
                    self.metalState = .error
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
                        self.metalState = .success
                    } else {
                        HapticsManager.shared.softImpact()
                        self.metalState = .idle
                    }
                } catch {
                    self.errorMessage = "Failed to parse releases"
                    self.metalState = .error
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
            - **Debug the CheckForUpdatesView.swift**
            - Check the Update Available section UI
            - Go back to Developer Mode and click on Stop Force Show Update to show main view
            - _Try markdown formatting_
            
            ### Notes
            This release is simulated by the Developer Mode "Force Show Update" feature to debug the updates view
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
        downloadRelease(release)
    }

    func downloadRelease(_ release: GitHubRelease) {
        // Find IPA asset
        let ipaAsset = release.assets.first { $0.name.hasSuffix(".ipa") }
        
        if let asset = ipaAsset {
            downloadingReleaseID = release.id
            downloadAsset(asset, fileName: asset.name)
        } else {
            // Fallback to opening GitHub page if no IPA found
            errorMessage = "No IPA file found for this release. This is a super rare bug, please report it to me on Discord DMs @dylans2010"
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
        AppLogManager.shared.info("Starting Download: \(fileName)", category: "Updates")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300 // 5 minutes timeout
        
        let delegate = DownloadDelegate(manager: self)
        downloadSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        downloadTask = downloadSession?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func pauseDownload() {
        guard isDownloading && !isPaused else {
            return
        }

        downloadTask?.cancel { [weak self] data in
            DispatchQueue.main.async {
                self?.resumeData = data
                self?.isPaused = true
                AppLogManager.shared.info("Download Paused", category: "Updates")
            }
        }
    }

    func resumeDownload() {
        guard isDownloading && isPaused else {
            return
        }

        if let resumeData = resumeData {
            downloadTask = downloadSession?.downloadTask(withResumeData: resumeData)
            downloadTask?.resume()
            isPaused = false
            AppLogManager.shared.info("Download Resumed", category: "Updates")
        } else {
            // If resume data is missing, restart download
            downloadUpdate()
        }
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
            self.errorMessage = "Download Failed: \(error.localizedDescription)"
            HapticsManager.shared.error()
            AppLogManager.shared.error("Download Failed: \(error.localizedDescription)", category: "Updates")
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
        if #available(iOS 16.4, *) {
            mainContent
                .presentationBackground {
                    if #available(iOS 26.0, *) {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)

                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.1), Color.purple.opacity(0.05), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    } else {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                }
                .presentationCornerRadius(32)
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 24) {
            // New Optimized Custom Header
            HStack {
                Text("Portal Update")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Button {
                    onDismiss()
                    dismiss()
                    HapticsManager.shared.softImpact()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(spacing: 24) {
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
            .padding(.horizontal, 24)
        }
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color.clear
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
                Text("Download Complete!")
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
                
                Text("Ready To Sign!")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.clear)
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
                    Text(addedToLibrary ? "Added To Library" : "Add To Library")
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
                        .fill(Color.clear)
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
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 8)
                
        case .header2(let text):
            Text(processInlineMarkdown(text))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 6)
                
        case .header3(let text):
            Text(processInlineMarkdown(text))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 4)
                
        case .paragraph(let text):
            Text(processInlineMarkdown(text))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)

                        Text(processInlineMarkdown(item))
                            .font(.system(.body, design: .rounded))
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
                    .fill(Color.clear)
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

// MARK: - iOS 26 Liquid Glass Extension
extension View {
    @ViewBuilder
    func ifAvailableIOS26Glass() -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(20)
                .background(
                    ZStack {
                        // Liquid Glass Base
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)

                        // Inner Glow
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )

                        // Liquid Border
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear, .black.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.accentColor.opacity(0.1), radius: 20, x: 0, y: 10)
        } else {
            self
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
