import Foundation
import SwiftUI

@MainActor
class BackupAdvancedManager: ObservableObject {
    static let shared = BackupAdvancedManager()

    @Published var healthScore: Int = 0
    @Published var expiringCertsCount: Int = 0
    @Published var chainIntegrityStatus: String = "Unknown"
    @Published var lastBackupTime: Date?

    @Published var usedStorage: Int64 = 0
    @Published var availableStorage: Int64 = 0
    @Published var storagePercentage: Double = 0

    private let fileManager = FileManager.default
    private let backupsDirectory: URL

    private init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        backupsDirectory = documentsURL.appendingPathComponent("LocalBackups")
    }

    func refreshStats(backups: [LocalBackup]) {
        calculateBackupHealth(backups: backups)
        calculateStorageUsage(backups: backups)
    }

    func getCurrentStateMetadata() -> [String: Any] {
        var metadata: [String: Any] = [:]

        let certificates = Storage.shared.getAllCertificates()
        metadata["certificates"] = certificates.map { ["uuid": $0.uuid ?? "", "name": $0.nickname ?? ""] }

        // Profiles (Mocked as we don't have separate entity)
        metadata["profiles"] = []

        let sources = Storage.shared.getSources()
        metadata["sources"] = sources.map { ["url": $0.sourceURL?.absoluteString ?? "", "name": $0.name ?? ""] }

        // Signed/Imported apps - we'd need to fetch them from Core Data
        // Simplified for this manager
        metadata["signed_apps"] = []
        metadata["imported_apps"] = []

        metadata["settings"] = ["status": "present"]

        return metadata
    }

    func loadManifest(from url: URL) async -> [String: Int64] {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fileManager.removeItem(at: tempDir) }

        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            // This is a simplified version - in reality we would need to decrypt if necessary
            // For now, assume it's accessible or handled
            // try fileManager.unzipItem(at: url, to: tempDir) // We can't easily unzip here without knowing if it's encrypted

            let manifestURL = tempDir.appendingPathComponent("manifest.json")
            if fileManager.fileExists(atPath: manifestURL.path),
               let data = try? Data(contentsOf: manifestURL),
               let manifest = try? JSONDecoder().decode([String: Int64].self, from: data) {
                return manifest
            }
        } catch {}
        return [:]
    }

    func loadAndRefresh() {
        do {
            let metadataFile = backupsDirectory.appendingPathComponent("backups_metadata.json")
            if fileManager.fileExists(atPath: metadataFile.path) {
                let data = try Data(contentsOf: metadataFile)
                let backups = try JSONDecoder().decode([LocalBackup].self, from: data)
                refreshStats(backups: backups)
            }
        } catch {
            print("Failed to load backups for stats: \(error)")
        }
    }

    private func calculateBackupHealth(backups: [LocalBackup]) {
        lastBackupTime = backups.map { $0.date }.max()

        // Count expiring certs (simulated logic for now, should use Storage.shared)
        let certificates = Storage.shared.getAllCertificates()
        let now = Date()
        let thirtyDaysOut = now.addingTimeInterval(30 * 24 * 3600)

        expiringCertsCount = certificates.filter { cert in
            guard let date = cert.date else { return false }
            return date > now && date < thirtyDaysOut
        }.count

        // Chain Integrity
        let hasBrokenChain = backups.contains { backup in
            if let parentID = backup.parentSnapshotID, !parentID.isEmpty {
                return !backups.contains { $0.snapshotID == parentID }
            }
            return false
        }
        chainIntegrityStatus = hasBrokenChain ? "Broken" : "Intact"

        // Health Score
        var score = 100
        if backups.isEmpty {
            score = 0
        } else {
            if hasBrokenChain { score -= 30 }
            if expiringCertsCount > 0 { score -= 10 * expiringCertsCount }
            if let last = lastBackupTime, now.timeIntervalSince(last) > 7 * 24 * 3600 {
                score -= 20
            }
        }
        healthScore = max(0, score)
    }

    private func calculateStorageUsage(backups: [LocalBackup]) {
        usedStorage = backups.reduce(0) { $0 + $1.size }

        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64,
           let totalSpace = attrs[.systemSize] as? Int64 {
            availableStorage = freeSpace
            let totalUsedSpace = totalSpace - freeSpace
            // We want percentage of APP'S backup storage vs total? No, maybe just used/total.
            // Let's do usedStorage vs (usedStorage + availableStorage)
            let totalAvailable = Double(usedStorage + availableStorage)
            storagePercentage = totalAvailable > 0 ? Double(usedStorage) / totalAvailable : 0
        }
    }

    func generateChangeSummary(parent: LocalBackup?, currentOptions: BackupOptions) -> String {
        var changes: [String] = []
        if parent == nil {
            return "Initial full snapshot"
        }

        // This is a simplified summary generator
        if currentOptions.includeCertificates { changes.append("Certificates") }
        if currentOptions.includeSignedApps { changes.append("Signed Apps") }
        if currentOptions.includeImportedApps { changes.append("Imported Apps") }
        if currentOptions.includeSources { changes.append("Sources") }

        return "Incremental update: " + changes.joined(separator: ", ")
    }

    // Logic for Diff Viewer
    struct DiffItem: Identifiable {
        let id = UUID()
        let name: String
        let status: DiffStatus
        let category: String
    }

    enum DiffStatus: String {
        case added = "Added"
        case removed = "Removed"
        case modified = "Modified"
        case unchanged = "Unchanged"

        var color: Color {
            switch self {
            case .added: return .green
            case .removed: return .red
            case .modified: return .orange
            case .unchanged: return .secondary
            }
        }
    }

    func compareBackups(currentMetadata: [String: Any], backupMetadata: [String: Any]) -> [DiffItem] {
        var diffs: [DiffItem] = []

        let categories = ["Certificates", "Profiles", "Signed Apps", "Imported Apps", "Sources", "Settings"]
        let keys = ["certificates", "profiles", "signed_apps", "imported_apps", "sources", "settings"]

        for (index, key) in keys.enumerated() {
            let category = categories[index]
            let currentItems = currentMetadata[key] as? [[String: String]] ?? []
            let backupItems = backupMetadata[key] as? [[String: String]] ?? []

            let currentIDs = Set(currentItems.compactMap { $0["uuid"] ?? $0["url"] ?? $0["id"] })
            let backupIDs = Set(backupItems.compactMap { $0["uuid"] ?? $0["url"] ?? $0["id"] })

            // Added in current (Missing in backup)
            for id in currentIDs.subtracting(backupIDs) {
                if let item = currentItems.first(where: { ($0["uuid"] ?? $0["url"] ?? $0["id"]) == id }) {
                    diffs.append(DiffItem(name: item["name"] ?? id, status: .added, category: category))
                }
            }

            // Removed in current (Present in backup but not in current)
            for id in backupIDs.subtracting(currentIDs) {
                if let item = backupItems.first(where: { ($0["uuid"] ?? $0["url"] ?? $0["id"]) == id }) {
                    diffs.append(DiffItem(name: item["name"] ?? id, status: .removed, category: category))
                }
            }

            // Common items (Unchanged for now, as we don't have detailed comparison)
            for id in currentIDs.intersection(backupIDs) {
                if let item = currentItems.first(where: { ($0["uuid"] ?? $0["url"] ?? $0["id"]) == id }) {
                    diffs.append(DiffItem(name: item["name"] ?? id, status: .unchanged, category: category))
                }
            }
        }

        return diffs
    }

    // Logic for Restore Simulation
    struct SimulationResult {
        let overwritten: [String]
        let removed: [String]
        let unchanged: [String]
        let conflicts: [String]
    }

    func simulateRestore(backupMetadata: [String: Any]) -> SimulationResult {
        var overwritten: [String] = []
        var removed: [String] = []
        var unchanged: [String] = []
        var conflicts: [String] = []

        // 1. Check Certificates & Profiles
        let backupCerts = (backupMetadata["certificates"] as? [[String: String]] ?? []) + (backupMetadata["profiles"] as? [[String: String]] ?? [])
        let currentCerts = Storage.shared.getAllCertificates()
        let currentCertUUIDs = Set(currentCerts.compactMap { $0.uuid })

        for cert in backupCerts {
            if let uuid = cert["uuid"] {
                if currentCertUUIDs.contains(uuid) {
                    overwritten.append("Certificate: \(cert["name"] ?? uuid)")
                } else {
                    unchanged.append("New Certificate: \(cert["name"] ?? uuid)")
                }
            }
        }

        // 2. Check Apps
        let backupApps = (backupMetadata["signed_apps"] as? [[String: String]] ?? []) + (backupMetadata["imported_apps"] as? [[String: String]] ?? [])
        // We'd need to check local filesystem for apps, but for simulation let's use bundle IDs if available
        for app in backupApps {
            if let name = app["name"] {
                overwritten.append("App: \(name)")
            }
        }

        // 3. Settings
        if backupMetadata["settings"] != nil {
            overwritten.append("System Settings")
            overwritten.append("App Preferences")
        }

        return SimulationResult(
            overwritten: overwritten,
            removed: removed,
            unchanged: unchanged,
            conflicts: conflicts
        )
    }
}
