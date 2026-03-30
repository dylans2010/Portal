import SwiftUI
import NimbleViews
import Nuke
import CoreData

// MARK: - ManageStorageView
struct ManageStorageView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @State private var cleanupPeriod: CleanupPeriod = .thirtyDays
    @State private var isCalculating = false
    @State private var animateProgress = false

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

    @State private var reclaimableSpace: Int64 = 0

    private var totalFeatherStorage: Int64 {
        signedAppsSize + importedAppsSize + certificatesSize + cacheSize + archivesSize + logsSize + tempFilesSize
    }

    var body: some View {
        List {
            // Storage Overview Section
            Section {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 12)
                                .frame(width: 100, height: 100)

                            Circle()
                                .trim(from: 0, to: animateProgress ? CGFloat(usedSpace) / CGFloat(max(totalSpace, 1)) : 0)
                                .stroke(
                                    themeManager.accentColor,
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                if totalSpace > 0 {
                                    Text("\(Int((Double(usedSpace) / Double(totalSpace)) * 100))%")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .themedText(.primary)
                                }
                                Text(.localized("Used"))
                                    .font(.system(size: 10, weight: .medium))
                                    .themedText(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            storageStatRow(label: .localized("Used"), value: formatBytes(usedSpace), color: themeManager.accentColor)
                            storageStatRow(label: .localized("Available"), value: formatBytes(availableSpace), color: .green)
                            storageStatRow(label: .localized("Total"), value: formatBytes(totalSpace), color: .secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            } footer: {
                Text(.localized("Device storage overview."))
            }

            // Breakdown Section
            Section {
                storageCategoryRow(name: .localized("Signed Apps"), size: signedAppsSize, icon: "checkmark.seal.fill", color: .blue, action: deleteSignedApps)
                storageCategoryRow(name: .localized("Imported Apps"), size: importedAppsSize, icon: "square.and.arrow.down.fill", color: .green, action: deleteImportedApps)
                storageCategoryRow(name: .localized("Certificates"), size: certificatesSize, icon: "key.horizontal.fill", color: .orange, action: resetCertificates)
                storageCategoryRow(name: .localized("Cache"), size: cacheSize, icon: "arrow.clockwise.circle.fill", color: .purple, action: clearNetworkCache)
                storageCategoryRow(name: .localized("Archives"), size: archivesSize, icon: "archivebox.fill", color: .cyan, action: nil)
                storageCategoryRow(name: .localized("Logs"), size: logsSize, icon: "doc.text.fill", color: .pink, action: clearLogs)
                storageCategoryRow(name: .localized("Temp Files"), size: tempFilesSize, icon: "clock.arrow.circlepath", color: .gray, action: clearWorkCache)

                HStack {
                    Text(.localized("Total Portal Storage"))
                        .font(.headline)
                    Spacer()
                    Text(formatBytes(totalFeatherStorage))
                        .font(.headline)
                        .foregroundStyle(themeManager.accentColor)
                }
                .padding(.vertical, 4)
            } header: {
                Text(.localized("Portal Data"))
            }

            // Smart Cleanup Section
            Section {
                Picker(.localized("Remove items older than"), selection: $cleanupPeriod) {
                    ForEach(CleanupPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .onChange(of: cleanupPeriod) { _ in calculateReclaimableSpace() }

                HStack {
                    VStack(alignment: .leading) {
                        Text(.localized("Reclaimable Space"))
                            .font(.subheadline)
                        Text(formatBytes(reclaimableSpace))
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Button(action: performCleanup) {
                        Text(.localized("Clean Now"))
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeManager.accentColor, in: Capsule())
                            .foregroundColor(.white)
                    }
                    .disabled(reclaimableSpace == 0 || isCalculating)
                }
            } header: {
                Text(.localized("Smart Cleanup"))
            } footer: {
                Text(.localized("Deletes temporary files and old cached data."))
            }

            // Advanced Tools
            Section {
                Button(.localized("Reset Source Cache")) { resetSourceCache() }
                Button(.localized("Reset All Sources"), role: .destructive) { showResetAlert(title: .localized("Reset All Sources"), action: resetSources) }
            } header: {
                Text(.localized("Advanced"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(.localized("Manage Storage"))
        .navigationBarTitleDisplayMode(.inline)
        .globalTheme()
        .onAppear {
            calculateStorageData()
            withAnimation(.easeInOut(duration: 1.0)) {
                animateProgress = true
            }
        }
        .refreshable {
            calculateStorageData()
        }
    }

    // MARK: - Helper Views

    private func storageStatRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.subheadline).themedText(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold()).themedText(.primary)
        }
    }

    private func storageCategoryRow(name: String, size: Int64, icon: String, color: Color, action: (() -> Void)?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(name).font(.subheadline).themedText(.primary)
                Text(formatBytes(size)).font(.caption).themedText(.secondary)
            }

            Spacer()

            if let action = action, size > 0 {
                Button {
                    showResetAlert(title: String(format: .localized("Clear %@"), name), message: formatBytes(size), action: action)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Logic (re-used and simplified)

    private func calculateStorageData() {
        isCalculating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fileSystemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (fileSystemAttributes?[.systemSize] as? NSNumber)?.int64Value ?? 0
            let free = (fileSystemAttributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0

            let signed = calculateDirectorySize(at: FileManager.default.signed)
            let imported = calculateDirectorySize(at: FileManager.default.unsigned)
            let certs = calculateDirectorySize(at: FileManager.default.certificates)
            let archives = calculateDirectorySize(at: FileManager.default.archives)
            let cache = Int64(URLCache.shared.currentDiskUsage) + calculateDirectorySize(at: FileManager.default.temporaryDirectory)
            let logs = calculateLogsSize()
            let temp = calculateDirectorySize(at: FileManager.default.temporaryDirectory)

            DispatchQueue.main.async {
                self.totalSpace = total
                self.availableSpace = free
                self.usedSpace = total - free
                self.signedAppsSize = signed
                self.importedAppsSize = imported
                self.certificatesSize = certs
                self.archivesSize = archives
                self.cacheSize = cache
                self.logsSize = logs
                self.tempFilesSize = temp
                self.calculateReclaimableSpace()
                self.isCalculating = false
            }
        }
    }

    private func calculateDirectorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                size += Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
        }
        return size
    }

    private func calculateLogsSize() -> Int64 {
        let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
        return logsDir != nil ? calculateDirectorySize(at: logsDir!) : 0
    }

    private func calculateReclaimableSpace() {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -cleanupPeriod.days, to: Date()) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            var size: Int64 = 0
            let tmp = FileManager.default.temporaryDirectory
            if let enumerator = FileManager.default.enumerator(at: tmp, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) {
                for case let fileURL as URL in enumerator {
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                       let modDate = values.contentModificationDate, modDate < cutoffDate {
                        size += Int64(values.fileSize ?? 0)
                    }
                }
            }
            DispatchQueue.main.async { self.reclaimableSpace = size }
        }
    }

    private func performCleanup() {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -cleanupPeriod.days, to: Date()) else { return }
        isCalculating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let tmp = FileManager.default.temporaryDirectory
            if let enumerator = FileManager.default.enumerator(at: tmp, includingPropertiesForKeys: [.contentModificationDateKey]) {
                for case let fileURL as URL in enumerator {
                    if let modDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, modDate < cutoffDate {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
            }
            URLCache.shared.removeAllCachedResponses()
            DispatchQueue.main.async {
                HapticsManager.shared.success()
                self.calculateStorageData()
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func showResetAlert(title: String, message: String = "", action: @escaping () -> Void) {
        let alertAction = UIAlertAction(title: .localized("Proceed"), style: .destructive) { _ in
            action()
            HapticsManager.shared.success()
            calculateStorageData()
        }
        UIAlertController.showAlertWithCancel(title: title, message: message + "\n" + .localized("This action cannot be undone."), style: .alert, actions: [alertAction])
    }

    private func clearWorkCache() {
        let tmp = FileManager.default.temporaryDirectory
        try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil).forEach { try? FileManager.default.removeItem(at: $0) }
    }

    private func clearNetworkCache() {
        URLCache.shared.removeAllCachedResponses()
        if let dataCache = ImagePipeline.shared.configuration.dataCache as? DataCache { dataCache.removeAll() }
        (ImagePipeline.shared.configuration.imageCache as? Nuke.ImageCache)?.removeAll()
    }

    private func clearLogs() {
        if let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs") {
            try? FileManager.default.removeItem(at: logsDir)
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
    }

    private func resetSourceCache() { RepositoryCacheManager.shared.clearCache() }
    private func resetSources() { Storage.shared.clearContext(request: AltSource.fetchRequest()) }
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

enum CleanupPeriod: CaseIterable {
    case sevenDays, thirtyDays, ninetyDays, oneYear
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
