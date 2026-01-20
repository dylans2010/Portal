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
                VStack(spacing: 20) {
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
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
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
            StorageAnalyzerView()
        }
        .sheet(isPresented: $showDuplicateFinder) {
            DuplicateFinderView()
        }
        .sheet(isPresented: $showLargeFilesFinder) {
            LargeFilesFinderView()
        }
    }
    
    // MARK: - Storage Ring Card
    private var storageRingCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Device Storage"))
                        .font(.title2.bold())
                    Text(.localized("Manage Portal Storage"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            // Animated Ring Progress
            HStack(spacing: 30) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                        .frame(width: 140, height: 140)
                    
                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0, to: animateProgress ? CGFloat(usedSpace) / CGFloat(max(totalSpace, 1)) : 0)
                        .stroke(
                            AngularGradient(
                                colors: [.blue, .cyan, .purple, .pink, .blue],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2), value: animateProgress)
                    
                    // Center content
                    VStack(spacing: 4) {
                        if totalSpace > 0 {
                            Text("\(Int((Double(usedSpace) / Double(totalSpace)) * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        Text(.localized("Used"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    StorageStatRow(
                        label: .localized("Used"),
                        value: formatBytes(usedSpace),
                        color: .blue
                    )
                    StorageStatRow(
                        label: .localized("Available"),
                        value: formatBytes(availableSpace),
                        color: .green
                    )
                    StorageStatRow(
                        label: .localized("Total"),
                        value: formatBytes(totalSpace),
                        color: .gray
                    )
                }
            }
            .padding(.vertical, 8)
            
            // App Storage Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(.localized("App Storage"))
                        .font(.subheadline.bold())
                    Spacer()
                    Text(formatBytes(totalFeatherStorage))
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
                
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(storageCategories.filter { $0.size > 0 }) { category in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.color)
                                .frame(width: max(4, geometry.size.width * CGFloat(category.size) / CGFloat(max(totalFeatherStorage, 1))))
                        }
                    }
                }
                .frame(height: 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                )
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(storageCategories.filter { $0.size > 0 }.prefix(6)) { category in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            Text(category.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionCard(
                icon: "sparkles",
                title: .localized("Quick Clean"),
                subtitle: formatBytes(reclaimableSpace),
                color: .orange,
                action: performCleanup
            )
            
            QuickActionCard(
                icon: "chart.pie.fill",
                title: .localized("Analyze"),
                subtitle: .localized("Deep Scan"),
                color: .purple,
                action: { showStorageAnalyzer = true }
            )
            
            QuickActionCard(
                icon: "doc.on.doc.fill",
                title: .localized("Duplicates"),
                subtitle: duplicateFilesCount > 0 ? "\(duplicateFilesCount) Found" : .localized("Scan"),
                color: .blue,
                action: { showDuplicateFinder = true }
            )
            
            QuickActionCard(
                icon: "arrow.up.doc.fill",
                title: .localized("Large Files"),
                subtitle: largeFilesCount > 0 ? "\(largeFilesCount) Found" : .localized("Find"),
                color: .pink,
                action: { showLargeFilesFinder = true }
            )
        }
    }
    
    // MARK: - Storage Breakdown Cards
    private var storageBreakdownCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Storage Breakdown"))
                .font(.headline)
                .padding(.horizontal, 4)
            
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
            }
        }
    }
    
    // MARK: - Smart Cleanup Card
    private var smartCleanupCard: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Smart Cleanup"))
                        .font(.headline)
                    Text(.localized("Automatically Free Up Space"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Cleanup Period Picker
            HStack {
                Text(.localized("Remove items older than"))
                    .font(.subheadline)
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
                        Text(cleanupPeriod.displayName)
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            // Reclaimable Space Indicator
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("Can Be Freed"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatBytes(reclaimableSpace))
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                Button {
                    performCleanup()
                } label: {
                    Text(.localized("Clean"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(reclaimableSpace == 0 || isCalculating)
                .opacity(reclaimableSpace == 0 ? 0.5 : 1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Advanced Tools Section
    private var advancedToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Advanced Tools"))
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                AdvancedToolRow(
                    icon: "network.badge.shield.half.filled",
                    title: .localized("Clear Network Cache"),
                    subtitle: .localized("Images, API responses"),
                    color: .blue
                ) {
                    let cacheSize = URLCache.shared.currentDiskUsage
                    showResetAlert(
                        title: .localized("Clear Network Cache"),
                        message: formatBytes(Int64(cacheSize)),
                        action: clearNetworkCache
                    )
                }
                
                Divider().padding(.leading, 56)
                
                AdvancedToolRow(
                    icon: "folder.badge.minus",
                    title: .localized("Clear Work Cache"),
                    subtitle: .localized("Temporary Processing Files"),
                    color: .purple
                ) {
                    showResetAlert(
                        title: .localized("Clear Work Cache"),
                        message: "",
                        action: clearWorkCache
                    )
                }
                
                Divider().padding(.leading, 56)
                
                AdvancedToolRow(
                    icon: "doc.text.magnifyingglass",
                    title: .localized("Clear Logs"),
                    subtitle: .localized("App Diagnostic Logs"),
                    color: .green
                ) {
                    showResetAlert(
                        title: .localized("Clear Logs"),
                        message: formatBytes(logsSize),
                        action: clearLogs
                    )
                }
                
                Divider().padding(.leading, 56)
                
                AdvancedToolRow(
                    icon: "square.stack.3d.down.right",
                    title: .localized("Reset Source Cache"),
                    subtitle: .localized("Cached repository data"),
                    color: .cyan
                ) {
                    showResetAlert(
                        title: .localized("Reset Source Cache"),
                        message: "",
                        action: resetSourceCache
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(.localized("Danger Zone"))
                    .font(.headline)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                DangerZoneRow(
                    icon: "doc.badge.minus",
                    title: .localized("Delete All Signed Apps"),
                    subtitle: formatBytes(signedAppsSize)
                ) {
                    showResetAlert(
                        title: .localized("Delete All Signed Apps"),
                        message: formatBytes(signedAppsSize),
                        action: deleteSignedApps
                    )
                }
                
                Divider().padding(.leading, 56)
                
                DangerZoneRow(
                    icon: "square.and.arrow.down.on.square",
                    title: .localized("Delete All Imported Apps"),
                    subtitle: formatBytes(importedAppsSize)
                ) {
                    showResetAlert(
                        title: .localized("Delete All Imported Apps"),
                        message: formatBytes(importedAppsSize),
                        action: deleteImportedApps
                    )
                }
                
                Divider().padding(.leading, 56)
                
                DangerZoneRow(
                    icon: "key.horizontal",
                    title: .localized("Delete All Certificates"),
                    subtitle: formatBytes(certificatesSize)
                ) {
                    showResetAlert(
                        title: .localized("Delete All Certificates"),
                        message: formatBytes(certificatesSize),
                        action: resetCertificates
                    )
                }
                
                Divider().padding(.leading, 56)
                
                DangerZoneRow(
                    icon: "square.stack.3d.down.right",
                    title: .localized("Reset All Sources"),
                    subtitle: .localized("Remove all added sources")
                ) {
                    showResetAlert(
                        title: .localized("Reset All Sources"),
                        message: "",
                        action: resetSources
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
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
                        Text("\(percentage)% Used")
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
                        .font(.system(.body, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(formatBytes(totalFeatherStorage))
                        .font(.system(.title3, design: .rounded, weight: .bold))
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

// MARK: - Storage Stat Row
struct StorageStatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storage Category Row
struct StorageCategoryRow: View {
    let category: StorageCategory
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.body.bold())
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(category.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if category.action != nil && category.size > 0 {
                Button {
                    onClear()
                } label: {
                    Text(.localized("Clear"))
                        .font(.caption.bold())
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(category.color.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Advanced Tool Row
struct AdvancedToolRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Danger Zone Row
struct DangerZoneRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storage Analyzer View
struct StorageAnalyzerView: View {
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
                                    Text(item.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(.localized("Storage Analyzer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
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
struct DuplicateFinderView: View {
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
                            .foregroundStyle(.green)
                        Text(.localized("No Duplicates Found"))
                            .font(.title2.bold())
                        Text(.localized("Your storage is clean!"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                                            Text(url.deletingLastPathComponent().lastPathComponent)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(.localized("Duplicate Finder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
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
struct LargeFilesFinderView: View {
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
                            .foregroundStyle(.green)
                        Text(.localized("No Large Files Found"))
                            .font(.title2.bold())
                        Text(.localized("No Files Over 50MB"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(largeFiles, id: \.url.absoluteString) { file in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.url.lastPathComponent)
                                        .font(.subheadline)
                                    Text(file.url.deletingLastPathComponent().lastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption.bold())
                                    .foregroundStyle(.pink)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                try? FileManager.default.removeItem(at: largeFiles[index].url)
                            }
                            largeFiles.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle(.localized("Large Files"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
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
