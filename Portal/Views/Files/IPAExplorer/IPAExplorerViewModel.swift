import SwiftUI
import Zip
import CryptoKit

class IPAExplorerViewModel: ObservableObject {
    enum State {
        case idle
        case hashing
        case extracting
        case indexing
        case ready
        case error(String)
    }

    @Published var state: State = .idle
    @Published var progress: Double = 0
    @Published var extractionURL: URL?
    @Published var appBundleURL: URL?
    @Published var ipaHash: String = ""
    @Published var summary: IPASummary?
    @Published var isModified: Bool = false

    let ipaURL: URL
    private let fileManager = FileManager.default
    private var initialHashes: [URL: String] = [:]

    struct IPASummary {
        let name: String
        let bundleId: String
        let version: String
        let build: String
        let minOS: String
        let icon: UIImage?
        let isSigned: Bool
        let hasProvision: Bool
    }

    init(ipaURL: URL) {
        self.ipaURL = ipaURL
    }

    deinit {
        cleanup()
    }

    func start() {
        Task {
            await performExploration()
        }
    }

    @MainActor
    private func performExploration() async {
        let isSecurityScoped = ipaURL.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { ipaURL.stopAccessingSecurityScopedResource() } }

        do {
            // 1. Hashing
            state = .hashing
            ipaHash = try await computeSHA256(url: ipaURL)

            // 2. Extraction
            state = .extracting
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let uniqueDir = cacheDir.appendingPathComponent("IPAExplorer_\(UUID().uuidString)")
            try fileManager.createDirectory(at: uniqueDir, withIntermediateDirectories: true)
            extractionURL = uniqueDir

            // Copy to temp to ensure stability during unzip
            let tempIPA = uniqueDir.appendingPathComponent("temp.ipa")
            try fileManager.copyItem(at: ipaURL, to: tempIPA)

            try await Task.detached(priority: .userInitiated) {
                try Zip.unzipFile(tempIPA, destination: uniqueDir, overwrite: true, password: nil, progress: { p in
                    Task { @MainActor in
                        self.progress = p
                    }
                })
                try? FileManager.default.removeItem(at: tempIPA)
            }.value

            // 3. Indexing & Analysis
            state = .indexing
            try await Task.detached(priority: .userInitiated) {
                try await self.analyzeExtractedContent(at: uniqueDir)
            }.value

            state = .ready
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func analyzeExtractedContent(at root: URL) async throws {
        let payloadURL = root.appendingPathComponent("Payload")
        guard fileManager.fileExists(atPath: payloadURL.path) else {
            throw NSError(domain: "IPAExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid IPA: Payload folder missing"])
        }

        let contents = try fileManager.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPAExplorer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid IPA: .app bundle missing in Payload"])
        }

        await MainActor.run {
            self.appBundleURL = appBundle
        }

        let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            throw NSError(domain: "IPAExplorer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid IPA: Info.plist missing or corrupt"])
        }

        let name = plist["CFBundleDisplayName"] as? String ?? plist["CFBundleName"] as? String ?? "Unknown"
        let bundleId = plist["CFBundleIdentifier"] as? String ?? "unknown"
        let version = plist["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = plist["CFBundleVersion"] as? String ?? "1"
        let minOS = plist["MinimumOSVersion"] as? String ?? "13.0"

        // Icon
        let appIcon: UIImage? = {
            if let icons = plist["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let lastIcon = iconFiles.last {
                // Note: iOS app icons usually don't have extension in Info.plist, and might have @2x/@3x
                // For simplicity, we try to find a matching file
                if let files = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
                    if let matchedIcon = files.first(where: { $0.lastPathComponent.hasPrefix(lastIcon) }) {
                        return UIImage(contentsOfFile: matchedIcon.path)
                    }
                }
            }
            return nil
        }()

        let provisionURL = appBundle.appendingPathComponent("embedded.mobileprovision")
        let hasProvision = fileManager.fileExists(atPath: provisionURL.path)
        let isSigned = fileManager.fileExists(atPath: appBundle.appendingPathComponent("_CodeSignature").path)

        await MainActor.run {
            self.summary = IPASummary(
                name: name,
                bundleId: bundleId,
                version: version,
                build: build,
                minOS: minOS,
                icon: appIcon,
                isSigned: isSigned,
                hasProvision: hasProvision
            )
        }

        // Record initial hashes for integrity check
        recordInitialHashes(appBundle: appBundle, plistURL: infoPlistURL, provisionURL: provisionURL)
    }

    private func recordInitialHashes(appBundle: URL, plistURL: URL, provisionURL: URL) {
        let criticalFiles = [plistURL, provisionURL]
        for file in criticalFiles {
            if fileManager.fileExists(atPath: file.path) {
                initialHashes[file] = try? computeSHA256Sync(url: file)
            }
        }

        // Also record executable hash
        if let plistData = try? Data(contentsOf: plistURL),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
           let execName = plist["CFBundleExecutable"] as? String {
            let execURL = appBundle.appendingPathComponent(execName)
            if fileManager.fileExists(atPath: execURL.path) {
                initialHashes[execURL] = try? computeSHA256Sync(url: execURL)
            }
        }
    }

    func checkIntegrity() -> Bool {
        for (url, originalHash) in initialHashes {
            guard fileManager.fileExists(atPath: url.path) else { return false }
            let currentHash = try? computeSHA256Sync(url: url)
            if currentHash != originalHash {
                return false
            }
        }
        return true
    }

    func markAsModified() {
        isModified = true
    }

    func cleanup() {
        if let url = extractionURL {
            try? fileManager.removeItem(at: url)
        }
    }

    private func computeSHA256(url: URL) async throws -> String {
        try await Task.detached {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            var hasher = SHA256()
            while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
                hasher.update(data: data)
            }
            return hasher.finalize().map { String(format: "%02x", $0) }.joined()
        }.value
    }

    private func computeSHA256Sync(url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
