import Foundation
import AltSourceKit

struct CachedSourceApp: Codable, Identifiable, Hashable {
    let id: String
    let sourceName: String
    let sourceIdentifier: String
    let appName: String
    let bundleID: String
    let version: String
    let developer: String
    let subtitle: String
    let size: Int
    let iconRemoteURL: String?
    let iconLocalFileName: String?
    let cachedDate: Date
}

enum CacheDataDuration: String, CaseIterable {
    case everyHour
    case every6Hours
    case everyDay
    case everyWeek

    var interval: TimeInterval {
        switch self {
        case .everyHour: return 60 * 60
        case .every6Hours: return 60 * 60 * 6
        case .everyDay: return 60 * 60 * 24
        case .everyWeek: return 60 * 60 * 24 * 7
        }
    }
}

final class CacheData: @unchecked Sendable {
    static let shared = CacheData()

    private let queue = DispatchQueue(label: "Feather.CacheData", qos: .utility)

    private var cacheRoot: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Apps/Caches", isDirectory: true)
    }

    private var appsCacheFile: URL { cacheRoot.appendingPathComponent("apps_cache.json") }
    private var metadataFile: URL { cacheRoot.appendingPathComponent("cache_metadata.json") }
    private var iconDirectory: URL { cacheRoot.appendingPathComponent("icons", isDirectory: true) }

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "Feather.cacheDataOnStart")
    }

    var duration: CacheDataDuration {
        let value = UserDefaults.standard.string(forKey: "Feather.cacheDataDuration")
        return CacheDataDuration(rawValue: value ?? "") ?? .everyDay
    }

    func ensureCacheDirectories() {
        do {
            try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: iconDirectory, withIntermediateDirectories: true)
        } catch {
            AppLogManager.shared.error("Failed to create cache directory: \(error.localizedDescription)", category: "CacheData")
        }
    }

    func isExpired() -> Bool {
        guard let metadataData = try? Data(contentsOf: metadataFile),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData) else {
            return true
        }

        return Date().timeIntervalSince(metadata.lastUpdated) >= duration.interval
    }

    func clearCache() {
        queue.async {
            try? FileManager.default.removeItem(at: self.cacheRoot)
        }
    }

    func loadCache() async -> [CachedSourceApp] {
        await withCheckedContinuation { continuation in
            queue.async {
                self.ensureCacheDirectories()

                guard let data = try? Data(contentsOf: self.appsCacheFile) else {
                    continuation.resume(returning: [])
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode([CachedSourceApp].self, from: data)
                    continuation.resume(returning: decoded)
                } catch {
                    AppLogManager.shared.error("Corrupt cache detected. Falling back to live sources.", category: "CacheData")
                    try? FileManager.default.removeItem(at: self.appsCacheFile)
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func saveCache(from apps: [(source: ASRepository, app: ASRepository.App)]) {
        queue.async {
            self.ensureCacheDirectories()

            let cacheDate = Date()
            let cachedApps = apps.map { entry -> CachedSourceApp in
                let iconRemote = entry.app.iconURL
                let iconFileName = self.persistIconIfNeeded(from: iconRemote, appID: entry.app.currentUniqueId)

                return CachedSourceApp(
                    id: entry.app.currentUniqueId,
                    sourceName: entry.source.name ?? "Unknown Source",
                    sourceIdentifier: entry.source.id ?? entry.source.name ?? "unknown_source",
                    appName: entry.app.currentName,
                    bundleID: entry.app.bundleIdentifier ?? "unknown.bundle.id",
                    version: entry.app.currentVersion ?? "N/A",
                    developer: entry.app.developer ?? "Unknown",
                    subtitle: entry.app.subtitle ?? "",
                    size: entry.app.size ?? 0,
                    iconRemoteURL: iconRemote?.absoluteString,
                    iconLocalFileName: iconFileName,
                    cachedDate: cacheDate
                )
            }

            do {
                let data = try JSONEncoder().encode(cachedApps)
                try data.write(to: self.appsCacheFile, options: .atomic)

                let metadata = CacheMetadata(lastUpdated: cacheDate, appCount: cachedApps.count)
                let metadataData = try JSONEncoder().encode(metadata)
                try metadataData.write(to: self.metadataFile, options: .atomic)
            } catch {
                AppLogManager.shared.error("Failed to write cache: \(error.localizedDescription)", category: "CacheData")
            }
        }
    }

    func localIconURL(for cachedApp: CachedSourceApp) -> URL? {
        guard let iconLocalFileName = cachedApp.iconLocalFileName else { return nil }
        let path = iconDirectory.appendingPathComponent(iconLocalFileName)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    private func persistIconIfNeeded(from url: URL?, appID: String) -> String? {
        guard let url else { return nil }
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension
        let fileName = "\(appID).\(ext)"
        let localURL = iconDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            return fileName
        }

        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            try data.write(to: localURL, options: .atomic)
            return fileName
        } catch {
            AppLogManager.shared.error("Failed to persist icon \(appID): \(error.localizedDescription)", category: "CacheData")
            return nil
        }
    }
}

private struct CacheMetadata: Codable {
    let lastUpdated: Date
    let appCount: Int
}
