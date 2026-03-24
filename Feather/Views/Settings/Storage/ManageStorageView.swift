import SwiftUI
import NimbleViews
import Nuke
import CoreData

// MARK: - Storage Category Model
struct StorageCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    var size: Int64
    let action: (() -> Void)?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - ManageStorageView
struct ManageStorageView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @State private var cleanupPeriod: CleanupPeriod = .thirtyDays
    @State private var isCalculating = false
    @State private var showStorageAnalyzer = false
    @State private var showDuplicateFinder = false
    @State private var showLargeFilesFinder = false
    @State private var animateProgress = false
    @State private var selectedCategory: StorageCategory?

    // Storage data
    @State private var usedSpace: Int64 = 0
    @State private var totalSpace: Int64 = 0
    @State private var availableSpace: Int64 = 0

    // Breakdown data
    @State private var signedAppsSize: Int64 = 0
    @State private var importedAppsSize: Int64 = 0
    @State private var certificatesSize: Int64 = 0
    @State private var cacheSize: Int64 = 0
    @State private var archivesSize: Int64 = 0
    @State private var logsSize: Int64 = 0
    @State private var tempFilesSize: Int64 = 0

    // Cleanup data
    @State private var reclaimableSpace: Int64 = 0
    @State private var duplicateFilesCount: Int = 0
    @State private var largeFilesCount: Int = 0

    // Animation states
    @State private var ringProgress: CGFloat = 0

    private var storageCategories: [StorageCategory] {
        [
            StorageCategory(name: .localized("Signed Apps"), icon: "checkmark.seal.fill", color: .blue, size: signedAppsSize, action: deleteSignedApps),
            StorageCategory(name: .localized("Imported Apps"), icon: "square.and.arrow.down.fill", color: .green, size: importedAppsSize, action: deleteImportedApps),
            StorageCategory(name: .localized("Certificates"), icon: "key.horizontal.fill", color: .orange, size: certificatesSize, action: resetCertificates),
            StorageCategory(name: .localized("Cache"), icon: "arrow.clockwise.circle.fill", color: .purple, size: cacheSize, action: clearNetworkCache),
            StorageCategory(name: .localized("Archives"), icon: "archivebox.fill", color: .cyan, size: archivesSize, action: nil),
            StorageCategory(name: .localized("Logs"), icon: "doc.text.fill", color: .pink, size: logsSize, action: clearLogs),
            StorageCategory(name: .localized("Temp Files"), icon: "clock.arrow.circlepath", color: .gray, size: tempFilesSize, action: clearWorkCache)
        ]
    }

    var body: some View {
        NBNavigationView(.localized("Manage Storage"), displayMode: .inline) {
            ScrollView {
                VStack(spacing: 24) {
                    // Modern Storage Ring Card
                    storageRingCard

                    // Quick Actions Grid
                    quickActionsGrid

                    // Storage Breakdown with Interactive Cards
                    storageBreakdownCards

                    // Smart Cleanup Section
                    smartCleanupCard

                    // Advanced Tools Section
                    advancedToolsSection

                    // Danger Zone
                    dangerZoneSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .globalTheme()
            .onAppear {
                calculateStorageData()
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    animateProgress = true
                }
            }
            .refreshable {
                await refreshStorageData()
            }
        }
        .sheet(isPresented: $showStorageAnalyzer) {
            StorageDeepAnalyzerView()
        }
        .sheet(isPresented: $showDuplicateFinder) {
            StorageDuplicateFinderView()
        }
        .sheet(isPresented: $showLargeFilesFinder) {
            StorageLargeFilesFinderView()
        }
    }

    // MARK: - Storage Ring Card
    private var storageRingCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Device Storage"))
                        .font(.title2.bold())
                        .themedText(.primary)
                    Text(.localized("Manage Portal Storage"))
                        .font(.subheadline)
                        .themedText(.secondary)
                }
                Spacer()

                if isCalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        calculateStorageData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                    }
                }
            }

            // Animated Ring Progress & Stats
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: animateProgress ? CGFloat(usedSpace) / CGFloat(max(totalSpace, 1)) : 0)
                        .stroke(
                            LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2), value: animateProgress)

                    VStack(spacing: 2) {
                        if totalSpace > 0 {
                            Text(String(format: "%d%%", Int((Double(usedSpace) / Double(totalSpace)) * 100)))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        }
                        Text(.localized("Used"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    StorageStatRowCompact(label: .localized("Used"), value: formatBytes(usedSpace), color: themeManager.accentColor)
                    StorageStatRowCompact(label: .localized("Available"), value: formatBytes(availableSpace), color: Color.green)
                    StorageStatRowCompact(label: .localized("Total"), value: formatBytes(totalSpace), color: Color.gray)
                }
            }
            .padding(.vertical, 8)

            // App Storage Bar
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(.localized("App Storage"))
                        .font(.system(size: 14, weight: .bold))
                        .themedText(.primary)
                    Spacer()
                    Text(formatBytes(totalFeatherStorage))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(themeManager.accentColor)
                }

                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(storageCategories.filter { $0.size > 0 }) { category in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(category.color)
                                .frame(width: max(2, geometry.size.width * CGFloat(category.size) / CGFloat(max(totalFeatherStorage, 1))))
                        }
                    }
                }
                .frame(height: 6)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.1)))

                // Legend Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(storageCategories.filter { $0.size > 0 }) { category in
                            HStack(spacing: 4) {
                                Circle().fill(category.color).frame(width: 6, height: 6)
                                Text(category.name).font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .themedCard()
    }

    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            StorageQuickActionButton(icon: "sparkles", title: .localized("Clean"), color: .orange, action: performCleanup)
            StorageQuickActionButton(icon: "chart.pie.fill", title: .localized("Analyze"), color: .purple, action: { showStorageAnalyzer = true })
            StorageQuickActionButton(icon: "doc.on.doc.fill", title: .localized("Duplicates"), color: .blue, action: { showDuplicateFinder = true })
            StorageQuickActionButton(icon: "arrow.up.doc.fill", title: .localized("Large"), color: .pink, action: { showLargeFilesFinder = true })
        }
    }

    // MARK: - Storage Breakdown Cards
    private var storageBreakdownCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Storage Breakdown"))
                .font(.system(size: 14, weight: .bold))
                .themedText(.primary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(storageCategories) { category in
                    StorageCategoryRow(category: category) {
                        if let action = category.action {
                            showResetAlert(
                                title: String(format: .localized("Clear %@"), category.name),
                                message: category.formattedSize,
                                action: action
                            )
                        }
                    }
                    if category.id != storageCategories.last?.id {
                        Divider().padding(.leading, 36)
                    }
                }
            }
            .padding(12)
            .themedCard()
        }
    }

    // MARK: - Smart Cleanup Card
    private var smartCleanupCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 0) {
                    Text(.localized("Smart Cleanup"))
                        .font(.system(size: 16, weight: .bold))
                        .themedText(.primary)
                    Text(.localized("Free up space automatically"))
                        .font(.system(size: 11))
                        .themedText(.secondary)
                }
                Spacer()
            }

            HStack {
                Text(.localized("Cutoff Period"))
                    .font(.system(size: 13))
                    .themedText(.primary)
                Spacer()
                Menu {
                    ForEach(CleanupPeriod.allCases, id: \.self) { period in
                        Button(period.displayName) {
                            cleanupPeriod = period
                            calculateReclaimableSpace()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(cleanupPeriod.displayName).bold()
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(themeManager.accentColor)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(.localized("Reclaimable")).font(.system(size: 10)).themedText(.secondary)
                    Text(formatBytes(reclaimableSpace)).font(.system(size: 18, weight: .bold)).foregroundStyle(Color.orange)
                }
                Spacer()
                Button(action: performCleanup) {
                    Text(.localized("Clean Now"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: themeManager.resolvedColors.buttonText))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange, in: Capsule())
                }
                .disabled(reclaimableSpace == 0 || isCalculating)
                .opacity(reclaimableSpace == 0 ? 0.5 : 1)
            }
            .padding(12)
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .themedCard()
    }

    // MARK: - Advanced Tools Section
    private var advancedToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Advanced Tools"))
                .font(.system(size: 14, weight: .bold))
                .themedText(.primary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                AdvancedToolButton(icon: "network", title: .localized("Network Cache"), color: themeManager.accentColor) {
                    showResetAlert(title: .localized("Clear Network Cache"), message: formatBytes(Int64(URLCache.shared.currentDiskUsage)), action: clearNetworkCache)
                }
                Divider().padding(.leading, 36)
                AdvancedToolButton(icon: "folder", title: .localized("Work Cache"), color: Color.purple) {
                    showResetAlert(title: .localized("Clear Work Cache"), action: clearWorkCache)
                }
                Divider().padding(.leading, 36)
                AdvancedToolButton(icon: "doc.text", title: .localized("App Logs"), color: Color.green) {
                    showResetAlert(title: .localized("Clear Logs"), message: formatBytes(logsSize), action: clearLogs)
                }
                Divider().padding(.leading, 36)
                AdvancedToolButton(icon: "square.stack", title: .localized("Source Cache"), color: Color.cyan) {
                    showResetAlert(title: .localized("Reset Source Cache"), action: resetSourceCache)
                }
            }
            .padding(.horizontal, 12)
            .themedCard()
        }
    }

    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Danger Zone"))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                DangerZoneButtonCompact(title: .localized("Clear Signed Apps"), size: formatBytes(signedAppsSize)) {
                    showResetAlert(title: .localized("Clear Signed Apps"), message: formatBytes(signedAppsSize), action: deleteSignedApps)
                }
                Divider().padding(.leading, 12)
                DangerZoneButtonCompact(title: .localized("Clear Imported Apps"), size: formatBytes(importedAppsSize)) {
                    showResetAlert(title: .localized("Clear Imported Apps"), message: formatBytes(importedAppsSize), action: deleteImportedApps)
                }
                Divider().padding(.leading, 12)
                DangerZoneButtonCompact(title: .localized("Clear Certificates"), size: formatBytes(certificatesSize)) {
                    showResetAlert(title: .localized("Clear Certificates"), message: formatBytes(certificatesSize), action: resetCertificates)
                }
                Divider().padding(.leading, 12)
                DangerZoneButtonCompact(title: .localized("Reset All Sources")) {
                    showResetAlert(title: .localized("Reset All Sources"), action: resetSources)
                }
            }
            .themedCard()
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.1), lineWidth: 1))
        }
        .padding(.bottom, 20)
    }

    // MARK: - Storage Overview Section
    private var storageOverviewSection: some View {
        Section {
            VStack(spacing: 16) {
                // Header with icon
                HStack {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(.localized("Device Storage"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding(.bottom, 8)

                HStack(alignment: .top, spacing: 0) {
                    // Used column
                    VStack(spacing: 6) {
                        Text(.localized("Used"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(usedSpace))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 50)

                    // Total column
                    VStack(spacing: 6) {
                        Text(.localized("Total"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(totalSpace))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 50)

                    // Available column
                    VStack(spacing: 6) {
                        Text(.localized("Available"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(formatBytes(availableSpace))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)

                // Progress bar with improved design
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 12)

                            if totalSpace > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue,
                                                Color.cyan,
                                                Color.purple.opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(usedSpace) / CGFloat(totalSpace), height: 12)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                            }
                        }
                    }
                    .frame(height: 12)

                    // Percentage indicator
                    if totalSpace > 0 {
                        let percentage = Int((Double(usedSpace) / Double(totalSpace)) * 100)
                        Text(String(format: .localized("%d%% Used"), percentage))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } footer: {
            Text(.localized("Shows storage used by Portal on this device."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Storage Breakdown Section
    private var storageBreakdownSection: some View {
        Section {
            VStack(spacing: 12) {
                storageBreakdownRow(label: .localized("Signed Apps"), size: signedAppsSize, icon: "doc.badge.checkmark", color: .blue)
                storageBreakdownRow(label: .localized("Imported Apps"), size: importedAppsSize, icon: "square.and.arrow.down", color: .green)
                storageBreakdownRow(label: .localized("Certificates"), size: certificatesSize, icon: "key.horizontal", color: .orange)
                storageBreakdownRow(label: .localized("Cache"), size: cacheSize, icon: "arrow.clockwise.circle", color: .purple)
                storageBreakdownRow(label: .localized("Archives"), size: archivesSize, icon: "archivebox", color: .cyan)

                Divider()
                    .padding(.vertical, 4)

                // Total row - emphasized with better design
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Text(.localized("Total"))
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(formatBytes(totalFeatherStorage))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.vertical, 8)
            }
            .padding(.vertical, 8)
        } header: {
            Label(.localized("Storage Breakdown"), systemImage: "chart.pie")
                .font(.headline)
        } footer: {
            Text(.localized("Detailed breakdown of storage used by Portal."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Storage Cleanup Section
    private var storageCleanupSection: some View {
        Section {
            VStack(spacing: 16) {
                // Cleanup icon and header
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(.localized("Smart Cleanup"))
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(.localized("Free up space automatically"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // Cleanup period selector
                VStack(alignment: .leading, spacing: 12) {
                    Text(.localized("Remove items older than"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Menu {
                        ForEach(CleanupPeriod.allCases, id: \.self) { period in
                            Button(period.displayName) {
                                cleanupPeriod = period
                                calculateReclaimableSpace()
                            }
                        }
                    } label: {
                        HStack {
                            Text(cleanupPeriod.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }

                Divider()

                // Description and reclaimable space
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)

                        Text(.localized("This will remove temporary files, cached data, and old work files that are no longer needed."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Reclaimable space highlight with better design
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(.localized("Can Be Removed"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(formatBytes(reclaimableSpace))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }

                // Cleanup button with improved design
                Button {
                    performCleanup()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))

                        Text(.localized("Clean Up Storage"))
                            .font(.headline)

                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(reclaimableSpace == 0 || isCalculating)
                .opacity(reclaimableSpace == 0 || isCalculating ? 0.5 : 1.0)
            }
            .padding(.vertical, 8)
        } header: {
            Label(.localized("Storage Cleanup"), systemImage: "arrow.clockwise")
                .font(.headline)
        } footer: {
            Text(.localized("Free up space by removing temporary files and old data."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Advanced Cleanup Section
    private var advancedCleanupSection: some View {
        Section {
            VStack(spacing: 8) {
                // Reset Work Cache
                cleanupOptionButton(
                    title: .localized("Reset Work Cache"),
                    systemImage: "folder.badge.minus",
                    description: .localized("Clear Temporary Files"),
                    action: {
                        showResetAlert(
                            title: .localized("Reset Work Cache"),
                            message: "",
                            action: clearWorkCache
                        )
                    }
                )

                Divider()
                    .padding(.leading, 52)

                // Reset Network Cache
                cleanupOptionButton(
                    title: .localized("Reset Network Cache"),
                    systemImage: "network.badge.shield.half.filled",
                    description: .localized("Clear cached images and network data"),
                    action: {
                        let cacheSize = URLCache.shared.currentDiskUsage
                        showResetAlert(
                            title: .localized("Reset Network Cache"),
                            message: formatBytes(Int64(cacheSize)),
                            action: clearNetworkCache
                        )
                    }
                )

                Divider()
                    .padding(.leading, 52)

                // Reset Sources
                cleanupOptionButton(
                    title: .localized("Reset Sources"),
                    systemImage: "square.stack.3d.down.right",
                    description: .localized("Remove all added sources"),
                    action: {
                        showResetAlert(
                            title: .localized("Reset Sources"),
                            message: "",
                            action: resetSources
                        )
                    }
                )

                Divider()
                    .padding(.leading, 52)

                // Delete Signed Apps
                cleanupOptionButton(
                    title: .localized("Delete Signed Apps"),
                    systemImage: "doc.badge.minus",
                    description: .localized("Remove all signed IPA files"),
                    action: {
                        showResetAlert(
                            title: .localized("Delete Signed Apps"),
                            message: formatBytes(signedAppsSize),
                            action: deleteSignedApps
                        )
                    },
                    isDestructive: true
                )

                Divider()
                    .padding(.leading, 52)

                // Delete Imported Apps
                cleanupOptionButton(
                    title: .localized("Delete Imported Apps"),
                    systemImage: "square.and.arrow.down.on.square",
                    description: .localized("Remove all imported apps"),
                    action: {
                        showResetAlert(
                            title: .localized("Delete Imported Apps"),
                            message: formatBytes(importedAppsSize),
                            action: deleteImportedApps
                        )
                    },
                    isDestructive: true
                )

                Divider()
                    .padding(.leading, 52)

                // Delete Certificates
                cleanupOptionButton(
                    title: .localized("Delete Certificates"),
                    systemImage: "key.horizontal",
                    description: .localized("Remove All Certificates"),
                    action: {
                        showResetAlert(
                            title: .localized("Delete Certificates"),
                            message: formatBytes(certificatesSize),
                            action: resetCertificates
                        )
                    },
                    isDestructive: true
                )
            }
            .padding(.vertical, 4)
        } header: {
            Label(.localized("Advanced Cleanup"), systemImage: "gearshape.2")
        } footer: {
            Text(.localized("Delete specific data categories. These actions cannot be undone."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helper Views
    private func storageBreakdownRow(label: LocalizedStringKey, size: Int64, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)

            Spacer()

            Text(formatBytes(size))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func cleanupOptionButton(
        title: LocalizedStringKey,
        systemImage: String,
        description: LocalizedStringKey,
        action: @escaping () -> Void,
        isDestructive: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isDestructive
                            ? Color.red.opacity(0.15)
                            : Color.blue.opacity(0.15)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(isDestructive ? Color.red : Color.blue)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isDestructive ? .red : .primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties
    private var totalFeatherStorage: Int64 {
        signedAppsSize + importedAppsSize + certificatesSize + cacheSize + archivesSize + logsSize + tempFilesSize
    }

    // MARK: - Async Refresh
    private func refreshStorageData() async {
        await MainActor.run {
            animateProgress = false
        }
        calculateStorageData()
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateProgress = true
            }
        }
    }

    // MARK: - Storage Calculation Methods
    private func calculateStorageData() {
        isCalculating = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Calculate device storage
            let fileSystemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let totalSpaceValue = (fileSystemAttributes?[.systemSize] as? NSNumber)?.int64Value ?? 0
            let freeSpaceValue = (fileSystemAttributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0

            // Calculate category sizes
            let signedSize = calculateDirectorySize(at: FileManager.default.signed)
            let importedSize = calculateDirectorySize(at: FileManager.default.unsigned)
            let certificatesSizeCalc = calculateDirectorySize(at: FileManager.default.certificates)
            let archivesSizeCalc = calculateDirectorySize(at: FileManager.default.archives)
            let cacheSizeCalc = calculateCacheSize()
            let logsSizeCalc = calculateLogsSize()
            let tempFilesSizeCalc = calculateTempFilesSize()

            // Count duplicates and large files
            let duplicates = findDuplicateFilesCount()
            let largeFiles = findLargeFilesCount()

            DispatchQueue.main.async {
                self.totalSpace = totalSpaceValue
                self.availableSpace = freeSpaceValue
                self.usedSpace = totalSpaceValue - freeSpaceValue

                self.signedAppsSize = signedSize
                self.importedAppsSize = importedSize
                self.certificatesSize = certificatesSizeCalc
                self.archivesSize = archivesSizeCalc
                self.cacheSize = cacheSizeCalc
                self.logsSize = logsSizeCalc
                self.tempFilesSize = tempFilesSizeCalc
                self.duplicateFilesCount = duplicates
                self.largeFilesCount = largeFiles

                self.calculateReclaimableSpace()
                self.isCalculating = false
            }
        }
    }

    private func calculateLogsSize() -> Int64 {
        let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
        guard let logsDir = logsDirectory else { return 0 }
        return calculateDirectorySize(at: logsDir)
    }

    private func calculateTempFilesSize() -> Int64 {
        return calculateDirectorySize(at: FileManager.default.temporaryDirectory)
    }

    private func findDuplicateFilesCount() -> Int {
        var fileHashes: [Int64: Int] = [:]
        let directories = [FileManager.default.signed, FileManager.default.unsigned]

        for directory in directories {
            if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        fileHashes[Int64(size), default: 0] += 1
                    }
                }
            }
        }

        return fileHashes.values.filter { $0 > 1 }.reduce(0, +)
    }

    private func findLargeFilesCount() -> Int {
        var count = 0
        let threshold: Int64 = 50 * 1024 * 1024 // 50MB
        let directories = [FileManager.default.signed, FileManager.default.unsigned, FileManager.default.archives]

        for directory in directories {
            if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                       Int64(size) > threshold {
                        count += 1
                    }
                }
            }
        }

        return count
    }

    private func clearLogs() {
        let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
        guard let logsDir = logsDirectory else { return }
        try? FileManager.default.removeItem(at: logsDir)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    }

    private func resetSourceCache() {
        RepositoryCacheManager.shared.clearCache()
    }

    private func calculateDirectorySize(at url: URL) -> Int64 {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return 0
        }

        var totalSize: Int64 = 0

        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }

    private func calculateCacheSize() -> Int64 {
        var totalCacheSize = Int64(URLCache.shared.currentDiskUsage)

        // Add temporary directory size
        let tmpDirectory = FileManager.default.temporaryDirectory
        totalCacheSize += calculateDirectorySize(at: tmpDirectory)

        return totalCacheSize
    }

    private func calculateReclaimableSpace() {
        DispatchQueue.global(qos: .userInitiated).async {
            let reclaimable = self.calculateOldCacheSize(olderThan: self.cleanupPeriod.days)

            DispatchQueue.main.async {
                self.reclaimableSpace = reclaimable
            }
        }
    }

    private func calculateOldCacheSize(olderThan days: Int) -> Int64 {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return 0
        }
        var oldCacheSize: Int64 = 0

        let tmpDirectory = FileManager.default.temporaryDirectory

        if let enumerator = FileManager.default.enumerator(at: tmpDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                   let modificationDate = resourceValues.contentModificationDate,
                   let fileSize = resourceValues.fileSize,
                   modificationDate < cutoffDate {
                    oldCacheSize += Int64(fileSize)
                }
            }
        }

        return oldCacheSize
    }

    // MARK: - Cleanup Action
    private func performCleanup() {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -cleanupPeriod.days, to: Date()) else {
            return
        }

        isCalculating = true

        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let tmpDirectory = fileManager.temporaryDirectory

            // Collect files to delete first to avoid race conditions
            var filesToDelete: [URL] = []

            if let enumerator = fileManager.enumerator(at: tmpDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if let modificationDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                       modificationDate < cutoffDate {
                        filesToDelete.append(fileURL)
                    }
                }
            }

            // Now delete the collected files
            for fileURL in filesToDelete {
                try? fileManager.removeItem(at: fileURL)
            }

            // Clear network cache
            URLCache.shared.removeAllCachedResponses()

            DispatchQueue.main.async {
                HapticsManager.shared.success()
                self.calculateStorageData()
            }
        }
    }

    // MARK: - Formatting
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    // MARK: - Alert Helper
    private func showResetAlert(
        title: String,
        message: String = "",
        action: @escaping () -> Void
    ) {
        let alertAction = UIAlertAction(
            title: .localized("Proceed"),
            style: .destructive
        ) { _ in
            action()
            HapticsManager.shared.success()
            calculateStorageData()
        }

        let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad
        ? .alert
        : .actionSheet

        var msg = ""
        if !message.isEmpty { msg = message + "\n" }
        msg.append(.localized("This action cannot be undone. Would you like to proceed?"))

        UIAlertController.showAlertWithCancel(
            title: title,
            message: msg,
            style: style,
            actions: [alertAction]
        )
    }

    // MARK: - Reset Methods (from ResetView)
    private func clearWorkCache() {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory

        if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory.path()) {
            for file in files {
                try? fileManager.removeItem(atPath: tmpDirectory.appendingPathComponent(file).path())
            }
        }
    }

    private func clearNetworkCache() {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        if let dataCache = ImagePipeline.shared.configuration.dataCache as? DataCache {
            dataCache.removeAll()
        }

        if let imageCache = ImagePipeline.shared.configuration.imageCache as? Nuke.ImageCache {
            imageCache.removeAll()
        }
    }

    private func resetSources() {
        Storage.shared.clearContext(request: AltSource.fetchRequest())
    }

    private func deleteSignedApps() {
        Storage.shared.clearContext(request: Signed.fetchRequest())
        try? FileManager.default.removeFileIfNeeded(at: FileManager.default.signed)
    }

    private func deleteImportedApps() {
        Storage.shared.clearContext(request: Imported.fetchRequest())
        try? FileManager.default.removeFileIfNeeded(at: FileManager.default.unsigned)
    }

    private func resetCertificates() {
        Storage.shared.clearContext(request: CertificatePair.fetchRequest())
        try? FileManager.default.removeFileIfNeeded(at: FileManager.default.certificates)
    }
}

// MARK: - CleanupPeriod Enum
enum CleanupPeriod: CaseIterable {
    case sevenDays
    case thirtyDays
    case ninetyDays
    case oneYear

    var displayName: String {
        switch self {
        case .sevenDays: return .localized("7 Days")
        case .thirtyDays: return .localized("30 Days")
        case .ninetyDays: return .localized("90 Days")
        case .oneYear: return .localized("1 Year")
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneYear: return 365
        }
    }
}

// MARK: - Storage Stat Row Compact
struct StorageStatRowCompact: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .themedText(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .themedText(.primary)
            }
        }
    }
}

// MARK: - Storage Quick Action Button
struct StorageQuickActionButton: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .themedText(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .themedCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storage Category Row
struct StorageCategoryRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let category: StorageCategory
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundStyle(category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .themedText(.primary)
                Text(category.formattedSize)
                    .font(.system(size: 11))
                    .themedText(.secondary)
            }

            Spacer()

            if category.action != nil && category.size > 0 {
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(8)
                        .background(Color.red.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Advanced Tool Button
struct AdvancedToolButton: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14))
                    .themedText(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Danger Zone Button Compact
struct DangerZoneButtonCompact: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let title: LocalizedStringKey
    var size: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
                Spacer()
                if let size = size {
                    Text(size)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 4)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storage Analyzer View
struct StorageDeepAnalyzerView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = true
    @State private var analysisResults: [StorageAnalysisItem] = []

    struct StorageAnalysisItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let size: Int64
        let type: String
        let color: Color
    }

    var body: some View {
        NavigationStack {
            Group {
                if isAnalyzing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(.localized("Analyzing Storage..."))
                            .font(.headline)
                        Text(.localized("This may take a moment"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(analysisResults) { item in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .themedText(.primary)
                                    Text(item.path)
                                        .font(.caption)
                                        .themedText(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                    .font(.caption.bold())
                                    .themedText(.secondary)
                            }
                        }
                    }
                    .globalTheme()
                }
            }
            .navigationTitle(.localized("Storage Analyzer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            })
            .onAppear {
                performAnalysis()
            }
        }
    }

    private func performAnalysis() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
            var results: [StorageAnalysisItem] = []
            let directories: [(String, URL, Color)] = [
                ("Signed Apps", FileManager.default.signed, .blue),
                ("Imported Apps", FileManager.default.unsigned, .green),
                ("Certificates", FileManager.default.certificates, .orange),
                ("Archives", FileManager.default.archives, .cyan)
            ]

            for (name, url, color) in directories {
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
                    for case let fileURL as URL in enumerator {
                        if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                           let isDirectory = values.isDirectory, !isDirectory,
                           let size = values.fileSize {
                            results.append(StorageAnalysisItem(
                                name: fileURL.lastPathComponent,
                                path: fileURL.path,
                                size: Int64(size),
                                type: name,
                                color: color
                            ))
                        }
                    }
                }
            }

            results.sort { $0.size > $1.size }

            DispatchQueue.main.async {
                self.analysisResults = Array(results.prefix(50))
                self.isAnalyzing = false
            }
        }
    }
}

// MARK: - Duplicate Finder View
struct StorageDuplicateFinderView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = true
    @State private var duplicates: [[URL]] = []

    var body: some View {
        NavigationStack {
            Group {
                if isScanning {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(.localized("Scanning For Duplicates..."))
                            .font(.headline)
                    }
                } else if duplicates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.green)
                        Text(.localized("No Duplicates Found"))
                            .font(.title2.bold())
                            .themedText(.primary)
                        Text(.localized("Your storage is clean!"))
                            .font(.subheadline)
                            .themedText(.secondary)
                    }
                } else {
                    List {
                        ForEach(duplicates.indices, id: \.self) { index in
                            Section("Group \(index + 1)") {
                                ForEach(duplicates[index], id: \.absoluteString) { url in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(url.lastPathComponent)
                                                .font(.subheadline)
                                                .themedText(.primary)
                                            Text(url.deletingLastPathComponent().lastPathComponent)
                                                .font(.caption)
                                                .themedText(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .globalTheme()
                }
            }
            .navigationTitle(.localized("Duplicate Finder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            })
            .onAppear {
                scanForDuplicates()
            }
        }
    }

    private func scanForDuplicates() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            var filesBySize: [Int64: [URL]] = [:]
            let directories = [FileManager.default.signed, FileManager.default.unsigned]

            for directory in directories {
                if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let fileURL as URL in enumerator {
                        if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            filesBySize[Int64(size), default: []].append(fileURL)
                        }
                    }
                }
            }

            let duplicateGroups = filesBySize.values.filter { $0.count > 1 }

            DispatchQueue.main.async {
                self.duplicates = Array(duplicateGroups)
                self.isScanning = false
            }
        }
    }
}

// MARK: - Large Files Finder View
struct StorageLargeFilesFinderView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = true
    @State private var largeFiles: [(url: URL, size: Int64)] = []

    var body: some View {
        NavigationStack {
            Group {
                if isScanning {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(.localized("Finding Large Files..."))
                            .font(.headline)
                    }
                } else if largeFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.green)
                        Text(.localized("No Large Files Found"))
                            .font(.title2.bold())
                            .themedText(.primary)
                        Text(.localized("No Files Over 50MB"))
                            .font(.subheadline)
                            .themedText(.secondary)
                    }
                } else {
                    List {
                        ForEach(largeFiles, id: \.url.absoluteString) { file in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.url.lastPathComponent)
                                        .font(.subheadline)
                                        .themedText(.primary)
                                    Text(file.url.deletingLastPathComponent().lastPathComponent)
                                        .font(.caption)
                                        .themedText(.secondary)
                                }

                                Spacer()

                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.pink)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                try? FileManager.default.removeItem(at: largeFiles[index].url)
                            }
                            largeFiles.remove(atOffsets: indexSet)
                        }
                    }
                    .globalTheme()
                }
            }
            .navigationTitle(.localized("Large Files"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            })
            .onAppear {
                findLargeFiles()
            }
        }
    }

    private func findLargeFiles() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
            var files: [(url: URL, size: Int64)] = []
            let threshold: Int64 = 50 * 1024 * 1024
            let directories = [FileManager.default.signed, FileManager.default.unsigned, FileManager.default.archives]

            for directory in directories {
                if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let fileURL as URL in enumerator {
                        if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                           Int64(size) > threshold {
                            files.append((url: fileURL, size: Int64(size)))
                        }
                    }
                }
            }

            files.sort { $0.size > $1.size }

            DispatchQueue.main.async {
                self.largeFiles = files
                self.isScanning = false
            }
        }
    }
}

// MARK: - Preview
struct ManageStorageView_Previews: PreviewProvider {
    static var previews: some View {
        ManageStorageView()
    }
}
