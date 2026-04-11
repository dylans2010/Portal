import Foundation
import SwiftUI
import NimbleViews
import CoreData

// MARK: - Pairing Error
enum PairingError: Error {
    case serverError(String)
    case timeout
    case networkUnavailable

    var userMessage: String {
        switch self {
        case .serverError(let reason):
            return reason.isEmpty
                ? .localized("Something went wrong. Please try again.")
                : reason
        case .timeout:
            return .localized("Pairing timed out. Please try again.")
        case .networkUnavailable:
            return .localized("No network connection. Please check your connection.")
        }
    }
}

// MARK: - Transfer Phase

enum TransferPhase: Equatable {
    case idle
    case preparingData
    case sending(progress: Double)
    case receiving(progress: Double)
    case complete(receivedURL: URL?)
    case failed(String)

    static func == (lhs: TransferPhase, rhs: TransferPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.preparingData, .preparingData): return true
        case (.complete, .complete): return true
        case (.sending(let a), .sending(let b)): return a == b
        case (.receiving(let a), .receiving(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

@MainActor
class PairingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var status: PairingStatus = .idle
    /// Morph progress: 0 = full chaos, 1 = perfect Fibonacci sphere.
    @Published var progress: Double = 0.0
    @Published var generatedCode: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    /// Whether this device is the host (generated the code = will send data).
    @Published var isHost: Bool = true
    /// Transfer state after pairing succeeds.
    @Published var transferPhase: TransferPhase = .idle
    /// Whether to show the scan-code sheet.
    @Published var showScanSheet: Bool = false
    /// Code entered by the user on the scan sheet.
    @Published var scanCodeInput: String = ""

    // MARK: - Private

    private var pollingTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var transferTask: Task<Void, Never>?
    private let service = PairingService.shared

    // MARK: - Transfer Timing

    /// Set when the connection is confirmed and the transfer begins.
    @Published var transferStartTime: Date?

    // MARK: - Computed – Peer Info

    /// Display name of the remote peer device, if connected.
    var pairedDeviceName: String? {
        service.connectedPeer?.displayName
    }

    // MARK: - Computed Properties

    var canRetry: Bool {
        if case .failed = status { return true }
        return false
    }

    var statusMessage: String {
        switch status {
        case .idle:
            return .localized("Starting Up…")
        case .generating:
            return .localized("Generating Pairing Code…")
        case .waiting:
            switch transferPhase {
            case .preparingData:  return .localized("Preparing Data For Transfer…")
            case .sending(let p): return .localized("Sending Data… \(Int(p * 100))%")
            case .receiving(let p): return .localized("Receiving Data… \(Int(p * 100))%")
            case .complete:       return .localized("Transfer Complete!")
            case .failed(let r):  return r
            default:
                return isHost
                    ? .localized("Waiting for the other device to scan the animation…")
                    : .localized("Connecting To Sender…")
            }
        case .connected:
            switch transferPhase {
            case .preparingData:  return .localized("Preparing data for transfer…")
            case .sending(let p): return .localized("Sending data… \(Int(p * 100))%")
            case .receiving(let p): return .localized("Receiving data… \(Int(p * 100))%")
            case .complete:       return .localized("Devices paired and data transferred!")
            case .failed(let r):  return r
            default:              return .localized("Devices Connected Successfully!")
            }
        case .failed(let reason):
            return reason
        }
    }
    
    func autoStart() {
        guard status == .idle else { return }
        isHost = true
        startGenerating()
    }

    // MARK: - Actions

    /// Starts the full pairing flow as host: code generation → waiting → connected → transfer.
    func startGenerating() {
        guard status == .idle || canRetry else { return }
        reset()
        isHost = true
        status = .generating
        isLoading = true

        animateProgress(to: 0.30, duration: 0.8)

        Task {
            do {
                let code = try await service.generatePairingCode()
                generatedCode = code
                status = .waiting
                isLoading = false

                animateProgress(to: 0.70, duration: 1.5)
                setupTransferCallbacks()
                startPolling(code: code)
            } catch {
                handleError(error)
            }
        }
    }

    /// Starts the joiner flow: browse for the device advertising `code`.
    func startPairing(with code: String) {
        reset()
        isHost = false
        status = .waiting
        isLoading = true
        generatedCode = nil

        animateProgress(to: 0.50, duration: 1.0)

        Task {
            do {
                let isValid = try await service.validateCode(code)
                guard isValid else {
                    handleError(PairingError.serverError(
                        .localized("Invalid pairing code. Please enter the 6-digit code shown on the other device.")
                    ))
                    return
                }
                setupTransferCallbacks()
                try await service.startPairing(code: code)
                startPolling(code: code)
            } catch {
                handleError(error)
            }
        }
    }

    /// Manually marks the pairing as connected (e.g. after a UI confirmation or polling).
    func confirmConnected() {
        pollingTask?.cancel()
        progressTask?.cancel()
        transferStartTime = Date()
        status = .connected
        withAnimation(.easeInOut(duration: 0.8)) {
            progress = 1.0
        }
        // Host immediately begins preparing and sending data.
        if isHost {
            beginDataTransfer()
        }
    }

    /// Retries the pairing flow after a failure.
    func retry() {
        reset()
        if isHost {
            startGenerating()
        } else if !scanCodeInput.isEmpty {
            startPairing(with: scanCodeInput)
        } else {
            startGenerating()
        }
    }

    /// Cancels any in-progress pairing and returns to idle.
    func cancel() {
        pollingTask?.cancel()
        progressTask?.cancel()
        transferTask?.cancel()
        Task { await service.cancelPairing() }
        reset()
    }

    // MARK: - Data Transfer (Host side)

    private func beginDataTransfer() {
        transferTask = Task {
            do {
                transferPhase = .preparingData
                guard let backupDir = await prepareBackupDirectory() else {
                    transferPhase = .failed(.localized(
                        "Failed to prepare backup data. Please ensure there is enough storage space and try again."
                    ))
                    return
                }

                service.onTransferProgress = { [weak self] p in
                    Task { @MainActor in
                        self?.transferPhase = .sending(progress: p)
                    }
                }

                try await service.sendBackupData(from: backupDir)
                try? FileManager.default.removeItem(at: backupDir)
                transferPhase = .complete(receivedURL: nil)
                HapticsManager.shared.success()
                await saveHistoryRecord(receivedURL: nil)
            } catch {
                transferPhase = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Private Helpers

    private func setupTransferCallbacks() {
        service.onTransferProgress = { [weak self] p in
            Task { @MainActor in
                self?.transferPhase = .receiving(progress: p)
            }
        }
        service.onTransferComplete = { [weak self] url in
            Task { @MainActor in
                self?.transferPhase = .complete(receivedURL: url)
                HapticsManager.shared.success()
                await self?.saveHistoryRecord(receivedURL: url)
            }
        }
        service.onTransferError = { [weak self] error in
            Task { @MainActor in
                self?.transferPhase = .failed(error.localizedDescription)
            }
        }
        service.onStatusChanged = { [weak self] newStatus in
            Task { @MainActor in
                switch newStatus {
                case .connected: self?.confirmConnected()
                case .failed(let msg): self?.handleError(PairingError.serverError(msg))
                default: break
                }
            }
        }
    }

    // MARK: - Pair History

    /// Reads counts from the extracted backup directory and appends a record
    /// to `PairHistoryStore`.
    private func saveHistoryRecord(receivedURL: URL?) async {
        let fm = FileManager.default
        var sourcesCount = 0
        var certsCount = 0
        var signedCount = 0
        var importedCount = 0
        var fwCount = 0
        var archivesCount = 0
        var settingsIncluded = false

        if let url = receivedURL {
            if let data = try? Data(contentsOf: url.appendingPathComponent("sources.json")),
               let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
                sourcesCount = arr.count
            }
            if let data = try? Data(contentsOf: url.appendingPathComponent("certificates_metadata.json")),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                certsCount = arr.count
            }
            if let data = try? Data(contentsOf: url.appendingPathComponent("signed_apps_metadata.json")),
               let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
                signedCount = arr.count
            }
            if let data = try? Data(contentsOf: url.appendingPathComponent("imported_apps_metadata.json")),
               let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
                importedCount = arr.count
            }
            let fwDir = url.appendingPathComponent("default_frameworks")
            if let items = try? fm.contentsOfDirectory(atPath: fwDir.path) {
                fwCount = items.filter { !$0.hasPrefix(".") }.count
            }
            let archDir = url.appendingPathComponent("archives")
            if let items = try? fm.contentsOfDirectory(atPath: archDir.path) {
                archivesCount = items.filter { !$0.hasPrefix(".") }.count
            }
            settingsIncluded = fm.fileExists(atPath: url.appendingPathComponent("settings.plist").path)
        } else {
            // Host side — use counts from the data we just sent
            sourcesCount  = Storage.shared.getSources().count
            let certs = Storage.shared.getAllCertificates()
            certsCount = certs.count
            let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
            signedCount = signedApps.count
            let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
            importedCount = importedApps.count
            let fwSrc = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
            if let items = try? FileManager.default.contentsOfDirectory(atPath: fwSrc.path) {
                fwCount = items.filter { !$0.hasPrefix(".") }.count
            }
            let archSrc = FileManager.default.archives
            if let items = try? FileManager.default.contentsOfDirectory(atPath: archSrc.path) {
                archivesCount = items.filter { !$0.hasPrefix(".") }.count
            }
            settingsIncluded = true
        }

        let record = PairRecord(
            id: UUID(),
            date: Date(),
            deviceName: pairedDeviceName ?? "",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            sourcesCount: sourcesCount,
            certificatesCount: certsCount,
            signedAppsCount: signedCount,
            importedAppsCount: importedCount,
            frameworksCount: fwCount,
            archivesCount: archivesCount,
            settingsIncluded: settingsIncluded,
            wasHost: isHost
        )
        PairHistoryStore.shared.append(record)
    }

    private func reset() {
        pollingTask?.cancel()
        progressTask?.cancel()
        transferTask?.cancel()
        status = .idle
        progress = 0.0
        generatedCode = nil
        errorMessage = nil
        isLoading = false
        transferPhase = .idle
        transferStartTime = nil
    }

    /// Polls `PairingService.checkStatus` every 3 s until connected or failed.
    private func startPolling(code: String) {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let result = try await service.checkStatus(code: code)
                    switch result {
                    case .connected:
                        confirmConnected()
                        return
                    case .failed(let reason):
                        handleError(PairingError.serverError(reason))
                        return
                    default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        handleError(error)
                        return
                    }
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    /// Smoothly animates `progress` toward `target` over `duration` seconds.
    private func animateProgress(to target: Double, duration: Double) {
        progressTask?.cancel()
        let start = progress
        let startTime = Date()

        progressTask = Task {
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let t = min(elapsed / duration, 1.0)
                let eased = 1.0 - pow(1.0 - t, 3.0)
                progress = start + (target - start) * eased
                if t >= 1.0 { break }
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }

    private func handleError(_ error: Error) {
        isLoading = false
        let msg: String
        if let pErr = error as? PairingError {
            msg = pErr.userMessage
        } else {
            msg = .localized("Something went wrong. Please try again.")
        }
        errorMessage = msg
        status = .failed(msg)
        animateProgress(to: 0.0, duration: 0.6)
    }

    // MARK: - Backup Preparation

    /// Copies all Portal data (certificates, apps, sources, settings, database)
    /// into a temporary directory and returns its URL.
    private func prepareBackupDirectory() async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PairingBackup_\(UUID().uuidString)")
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // 1. Certificates
            let certDir = tempDir.appendingPathComponent("certificates")
            try? fm.createDirectory(at: certDir, withIntermediateDirectories: true)
            let certSrc = fm.certificates
            if fm.fileExists(atPath: certSrc.path) {
                for f in (try? fm.contentsOfDirectory(at: certSrc, includingPropertiesForKeys: nil)) ?? [] {
                    try? fm.copyItem(at: f, to: certDir.appendingPathComponent(f.lastPathComponent))
                }
            }
            let certs = Storage.shared.getAllCertificates()
            var certMeta: [[String: Any]] = []
            for cert in certs {
                guard let uuid = cert.uuid else { continue }
                var m: [String: Any] = ["uuid": uuid]
                if let pd = Storage.shared.getProvisionFileDecoded(for: cert) {
                    m["name"] = pd.Name
                    if let tid = pd.TeamIdentifier.first { m["teamID"] = tid }
                    m["teamName"] = pd.TeamName
                }
                if let d = cert.date { m["date"] = d.timeIntervalSince1970 }
                m["ppQCheck"] = cert.ppQCheck
                if let pw = cert.password { m["password"] = pw }
                certMeta.append(m)
            }
            let certJSON = try JSONSerialization.data(withJSONObject: certMeta)
            try certJSON.write(to: tempDir.appendingPathComponent("certificates_metadata.json"))

            // 2. Sources
            let sources = Storage.shared.getSources()
            let srcData = sources.compactMap { s -> [String: String]? in
                guard let url = s.sourceURL?.absoluteString,
                      let name = s.name,
                      let id = s.identifier else { return nil }
                return ["url": url, "name": name, "identifier": id]
            }
            try JSONSerialization.data(withJSONObject: srcData)
                .write(to: tempDir.appendingPathComponent("sources.json"))

            // 3. Signed Apps
            let signedDir = tempDir.appendingPathComponent("signed_apps")
            try? fm.createDirectory(at: signedDir, withIntermediateDirectories: true)
            let signedSrc = fm.signed
            if fm.fileExists(atPath: signedSrc.path) {
                for f in (try? fm.contentsOfDirectory(at: signedSrc, includingPropertiesForKeys: nil)) ?? [] {
                    try? fm.copyItem(at: f, to: signedDir.appendingPathComponent(f.lastPathComponent))
                }
            }
            let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
            let signedMeta = signedApps.compactMap { a -> [String: String]? in
                guard let uuid = a.uuid else { return nil }
                return ["uuid": uuid, "name": a.name ?? "", "identifier": a.identifier ?? "", "version": a.version ?? ""]
            }
            try JSONSerialization.data(withJSONObject: signedMeta)
                .write(to: tempDir.appendingPathComponent("signed_apps_metadata.json"))

            // 4. Imported Apps
            let importedDir = tempDir.appendingPathComponent("imported_apps")
            try? fm.createDirectory(at: importedDir, withIntermediateDirectories: true)
            let unsignedSrc = fm.unsigned
            if fm.fileExists(atPath: unsignedSrc.path) {
                for f in (try? fm.contentsOfDirectory(at: unsignedSrc, includingPropertiesForKeys: nil)) ?? [] {
                    try? fm.copyItem(at: f, to: importedDir.appendingPathComponent(f.lastPathComponent))
                }
            }
            let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
            let importedMeta = importedApps.compactMap { a -> [String: String]? in
                guard let uuid = a.uuid else { return nil }
                return ["uuid": uuid, "name": a.name ?? "", "identifier": a.identifier ?? "", "version": a.version ?? ""]
            }
            try JSONSerialization.data(withJSONObject: importedMeta)
                .write(to: tempDir.appendingPathComponent("imported_apps_metadata.json"))

            // 5. Default Frameworks
            let fwDest = tempDir.appendingPathComponent("default_frameworks")
            try? fm.createDirectory(at: fwDest, withIntermediateDirectories: true)
            let fwSrc = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
            if fm.fileExists(atPath: fwSrc.path) {
                for f in (try? fm.contentsOfDirectory(at: fwSrc, includingPropertiesForKeys: nil)) ?? [] {
                    try? fm.copyItem(at: f, to: fwDest.appendingPathComponent(f.lastPathComponent))
                }
            }

            // 6. Archives
            let archiveDest = tempDir.appendingPathComponent("archives")
            try? fm.createDirectory(at: archiveDest, withIntermediateDirectories: true)
            let archiveSrc = fm.archives
            if fm.fileExists(atPath: archiveSrc.path) {
                for f in (try? fm.contentsOfDirectory(at: archiveSrc, includingPropertiesForKeys: nil)) ?? [] {
                    try? fm.copyItem(at: f, to: archiveDest.appendingPathComponent(f.lastPathComponent))
                }
            }

            // 7. Extra root files (plist, pem, crt, etc.)
            let extraDir = tempDir.appendingPathComponent("extra_files")
            try? fm.createDirectory(at: extraDir, withIntermediateDirectories: true)
            let rootFiles = (try? fm.contentsOfDirectory(at: Storage.shared.documentsURL, includingPropertiesForKeys: nil)) ?? []
            let importantExts = Set(["plist", "pem", "crt", "txt", "json", "log"])
            let importantNames = Set(["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"])
            for f in rootFiles {
                let ext = f.pathExtension.lowercased(), name = f.lastPathComponent
                guard importantExts.contains(ext) || importantNames.contains(name) else { continue }
                guard ext != "sqlite", !name.contains("-shm"), !name.contains("-wal") else { continue }
                try? fm.copyItem(at: f, to: extraDir.appendingPathComponent(name))
            }

            // 8. Core Data store
            let dbDir = tempDir.appendingPathComponent("database")
            try? fm.createDirectory(at: dbDir, withIntermediateDirectories: true)
            if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                let dir = storeURL.deletingLastPathComponent()
                for f in [storeURL.lastPathComponent,
                          "\(storeURL.lastPathComponent)-shm",
                          "\(storeURL.lastPathComponent)-wal"] {
                    let src = dir.appendingPathComponent(f)
                    if fm.fileExists(atPath: src.path) {
                        try? fm.copyItem(at: src, to: dbDir.appendingPathComponent(f))
                    }
                }
            }

            // 9. User defaults (settings)
            let defaults = UserDefaults.standard.dictionaryRepresentation()
            let filtered = defaults.filter { k, _ in
                !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") &&
                !k.hasPrefix("WebKit") && !k.hasPrefix("CPU") && !k.hasPrefix("metal")
            }
            let settingsData = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
            try settingsData.write(to: tempDir.appendingPathComponent("settings.plist"))

            // 10. Backup marker
            try "PORTAL_BACKUP_v1.0_\(Date().timeIntervalSince1970)"
                .write(to: tempDir.appendingPathComponent("PORTAL_BACKUP_MARKER.txt"), atomically: true, encoding: .utf8)

            return tempDir
        } catch {
            try? fm.removeItem(at: tempDir)
            return nil
        }
    }
}
