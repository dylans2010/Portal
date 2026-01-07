import SwiftUI
import NimbleViews
import Nuke
import CoreData

// MARK: - ManageStorageView
struct ManageStorageView: View {
    @State private var cleanupPeriod: CleanupPeriod = .thirtyDays
    @State private var isCalculating = false
    
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
    
    // Cleanup data
    @State private var reclaimableSpace: Int64 = 0
    
    var body: some View {
        NBNavigationView(.localized("Manage Storage"), displayMode: .inline) {
            Form {
                storageOverviewSection
                storageBreakdownSection
                storageCleanupSection
                advancedCleanupSection
            }
            .onAppear {
                calculateStorageData()
            }
        }
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
                        Text("\(percentage)% used")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } footer: {
            Text(.localized("Shows storage used by this app on this device"))
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
            Text(.localized("Detailed breakdown of storage used by this app"))
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
                            Text(.localized("Can be removed"))
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
                    description: .localized("Clear temporary files"),
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
                    description: .localized("Remove all certificates"),
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
        signedAppsSize + importedAppsSize + certificatesSize + cacheSize + archivesSize
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
            let certificatesSize = calculateDirectorySize(at: FileManager.default.certificates)
            let archivesSize = calculateDirectorySize(at: FileManager.default.archives)
            let cacheSize = calculateCacheSize()
            
            DispatchQueue.main.async {
                self.totalSpace = totalSpaceValue
                self.availableSpace = freeSpaceValue
                self.usedSpace = totalSpaceValue - freeSpaceValue
                
                self.signedAppsSize = signedSize
                self.importedAppsSize = importedSize
                self.certificatesSize = certificatesSize
                self.archivesSize = archivesSize
                self.cacheSize = cacheSize
                
                self.calculateReclaimableSpace()
                self.isCalculating = false
            }
        }
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

// MARK: - Preview
struct ManageStorageView_Previews: PreviewProvider {
    static var previews: some View {
        ManageStorageView()
    }
}
