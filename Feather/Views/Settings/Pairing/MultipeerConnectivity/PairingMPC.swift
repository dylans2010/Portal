import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Pairing MPC State

enum PairingMPCState: Equatable {
    case idle
    case advertising
    case browsing
    case connecting
    case connected
    case failed(String)

    static func == (lhs: PairingMPCState, rhs: PairingMPCState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.advertising, .advertising),
             (.browsing, .browsing), (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

@MainActor
final class PairingMPCService: NSObject, ObservableObject {

    static let serviceType = "portal-pair"

    // MARK: - Bonjour Retry Constants

    private static let netServicesErrorDomain = "NSNetServicesErrorDomain"
    private static let kNetServicesFailedCode = -72008
    private static let maxRetryCount = 5
    private static let retryDelaySeconds: Double = 3.0

    // MARK: Published State

    @Published var nearbyPeers: [MCPeerID] = []
    @Published var state: PairingMPCState = .idle
    @Published var isHost: Bool = true
    @Published var connectedPeerName: String?
    @Published var transferPhase: TransferPhase = .idle
    @Published var transferStartTime: Date?

    // Performance Tracking
    @Published var transferSpeed: Double = 0 // Bytes per second
    @Published var currentItemName: String = ""

    // MARK: Callbacks

    var onTransferComplete: ((URL) -> Void)?
    var onTransferError: ((Error) -> Void)?

    // MARK: Private

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var advertisingRetryCount = 0
    private var browsingRetryCount = 0

    private var progressObservation: NSKeyValueObservation?

    override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Send (host / advertiser) flow

    /// Starts advertising this device so nearby receivers can discover it.
    func startAdvertising() {
        stopAll()
        isHost = true
        advertisingRetryCount = 0
        setupSession()
        beginAdvertising()
        state = .advertising
    }

    // MARK: - Receive (joiner / browser) flow

    /// Starts browsing for nearby devices that are advertising via MPC Direct.
    func startBrowsing() {
        stopAll()
        isHost = false
        browsingRetryCount = 0
        setupSession()
        beginBrowsing()
        state = .browsing
    }

    /// Invites `peer` to join the current session (receiver taps a found device).
    func connectToPeer(_ peer: MCPeerID) {
        guard let session = session else { return }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        state = .connecting
    }

    func sendMirrorData() async throws {
        guard let session = session, let peer = session.connectedPeers.first else {
            throw NSError(
                domain: "PairingMPC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: String.localized("No connected peer to send data to.")]
            )
        }

        currentItemName = String.localized("Preparing Mirror Data...")
        transferPhase = .preparingData

        let mirrorURL = FileManager.default.temporaryDirectory.appendingPathComponent(BackupPayload.mirrorFilename)
        try await BackupPayload.createFullMirror(at: mirrorURL)

        currentItemName = String.localized("Initiating Full Mirror Transfer...")

        let progress = session.sendResource(at: mirrorURL, withName: BackupPayload.mirrorFilename, toPeer: peer) { error in
            Task { @MainActor in
                if let error = error {
                    self.transferPhase = .failed(error.localizedDescription)
                    self.onTransferError?(error)
                } else {
                    self.transferPhase = .complete(receivedURL: nil)
                    try? FileManager.default.removeItem(at: mirrorURL)
                }
            }
        }

        if let progress = progress {
            setupProgressObservation(progress, isSending: true)
        }
    }

    private func saveHistoryRecord(receivedURL: URL?, deviceName: String) async {
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
            if let items = try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("certificates").path) {
                certsCount = items.filter { !$0.hasPrefix(".") }.count
            }
            if let items = try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("signed_apps").path) {
                signedCount = items.filter { !$0.hasPrefix(".") }.count
            }
            if let items = try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("imported_apps").path) {
                importedCount = items.filter { !$0.hasPrefix(".") }.count
            }
            if let items = try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("default_frameworks").path) {
                fwCount = items.filter { !$0.hasPrefix(".") }.count
            }
            if let items = try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("archives").path) {
                archivesCount = items.filter { !$0.hasPrefix(".") }.count
            }
            settingsIncluded = fm.fileExists(atPath: url.appendingPathComponent("settings/settings.plist").path)
        } else {
            // Host side
            sourcesCount = Storage.shared.getSources().count
            certsCount = Storage.shared.getAllCertificates().count
            signedCount = (try? Storage.shared.context.count(for: Signed.fetchRequest())) ?? 0
            importedCount = (try? Storage.shared.context.count(for: Imported.fetchRequest())) ?? 0
            fwCount = (try? fm.contentsOfDirectory(atPath: Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks").path).count) ?? 0
            archivesCount = (try? fm.contentsOfDirectory(atPath: fm.archives.path).count) ?? 0
            settingsIncluded = true
        }

        let record = PairRecord(
            id: UUID(),
            date: Date(),
            deviceName: deviceName,
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

    private func setupProgressObservation(_ progress: Progress, isSending: Bool) {
        progressObservation?.invalidate()

        let startTime = Date()
        var lastBytes: Int64 = 0
        var lastUpdate = Date()

        progressObservation = progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            let fraction = progress.fractionCompleted
            let totalBytes = progress.totalUnitCount
            let completedBytes = progress.completedUnitCount

            Task { @MainActor in
                if isSending {
                    self?.transferPhase = .sending(progress: fraction)
                } else {
                    self?.transferPhase = .receiving(progress: fraction)
                }

                let now = Date()
                let elapsed = now.timeIntervalSince(lastUpdate)
                if elapsed >= 0.5 {
                    let bytesSinceLast = completedBytes - lastBytes
                    self?.transferSpeed = Double(bytesSinceLast) / elapsed
                    lastBytes = completedBytes
                    lastUpdate = now
                }

                self?.updateOperationName(progress: fraction)
            }
        }
    }

    private func updateOperationName(progress: Double) {
        if progress < 0.2 {
            currentItemName = String.localized("Transferring Certificates...")
        } else if progress < 0.5 {
            currentItemName = String.localized("Transferring App Data...")
        } else if progress < 0.8 {
            currentItemName = String.localized("Transferring Repository Sources...")
        } else {
            currentItemName = String.localized("Finalizing Mirror...")
        }
    }

    // MARK: - Cancel

    func cancel() {
        stopAll()
        state = .idle
        nearbyPeers = []
        connectedPeerName = nil
        transferPhase = .idle
        transferStartTime = nil
        advertisingRetryCount = 0
        browsingRetryCount = 0
        transferSpeed = 0
        currentItemName = ""
        progressObservation?.invalidate()
        progressObservation = nil
    }

    // MARK: - Private helpers

    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    private func beginAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["mpcDirect": "1"],
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func beginBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    private func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
    }

    // MARK: - Bonjour Retry Logic

    /// Retries advertising after a Bonjour failure (error -72008).
    /// Falls back to a user-friendly failure message after `maxRetryCount` attempts.
    private func retryAdvertising() {
        guard advertisingRetryCount < Self.maxRetryCount else {
            advertisingRetryCount = 0
            let msg: String = .localized(
                "Unable to start advertising. Please ensure Wi-Fi is enabled, " +
                "both devices are on the same network, and try again."
            )
            state = .failed(msg)
            return
        }
        advertisingRetryCount += 1
        Task {
            try? await Task.sleep(
                nanoseconds: UInt64(Self.retryDelaySeconds * 1_000_000_000)
            )
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            beginAdvertising()
        }
    }

    /// Retries browsing after a Bonjour failure (error -72008).
    /// Falls back to a user-friendly failure message after `maxRetryCount` attempts.
    private func retryBrowsing() {
        guard browsingRetryCount < Self.maxRetryCount else {
            browsingRetryCount = 0
            let msg: String = .localized(
                "Network discovery is unavailable. Please ensure Wi-Fi is enabled, " +
                "both devices are on the same network, and try again."
            )
            state = .failed(msg)
            return
        }
        browsingRetryCount += 1
        Task {
            try? await Task.sleep(
                nanoseconds: UInt64(Self.retryDelaySeconds * 1_000_000_000)
            )
            browser?.stopBrowsingForPeers()
            browser = nil
            beginBrowsing()
        }
    }
}

// MARK: - MCSessionDelegate

extension PairingMPCService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeerName = peerID.displayName
                self.state = .connected
                self.transferStartTime = Date()
                // If this device is the host, kick off the transfer automatically.
                if self.isHost {
                    Task {
                        do {
                            try await self.sendMirrorData()
                            // Save history record
                            await self.saveHistoryRecord(receivedURL: nil, deviceName: self.connectedPeerName ?? "")
                        } catch {
                            self.transferPhase = .failed(error.localizedDescription)
                            self.onTransferError?(error)
                        }
                    }
                }
            case .notConnected:
                if case .connected = self.state {
                    let msg: String = .localized("Connection lost. Please try again.")
                    self.state = .failed(msg)
                    self.transferPhase = .failed(msg)
                }
            default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // We use sendResource now for large data
    }

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Task { @MainActor in
            self.currentItemName = String.localized("Receiving Full Mirror...")
            self.setupProgressObservation(progress, isSending: false)
        }
    }

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.transferPhase = .failed(error.localizedDescription)
                self.onTransferError?(error)
                return
            }

            guard let localURL = localURL else {
                let err = NSError(domain: "PairingMPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Resource URL is nil"])
                self.transferPhase = .failed(err.localizedDescription)
                self.onTransferError?(err)
                return
            }

            do {
                self.currentItemName = String.localized("Verifying Data Integrity...")

                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("MPCMirrorReceived_\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Extract the received ZIP
                try FileManager.default.unzipItem(at: localURL, to: tempDir)

                // Manifest check
                let markerPath = tempDir.appendingPathComponent(BackupPayload.markerFilename)
                guard FileManager.default.fileExists(atPath: markerPath.path) else {
                    throw NSError(domain: "PairingMPC", code: -1, userInfo: [NSLocalizedDescriptionKey: String.localized("Mirror validation failed: Marker file missing.")])
                }

                UserDefaults.standard.set(tempDir.path, forKey: "pendingNearbyBackupRestore")
                self.transferPhase = .complete(receivedURL: tempDir)
                self.onTransferComplete?(tempDir)
                self.currentItemName = String.localized("Mirror Complete!")

                // Save history record
                await self.saveHistoryRecord(receivedURL: tempDir, deviceName: self.connectedPeerName ?? "")
            } catch {
                self.transferPhase = .failed(error.localizedDescription)
                self.onTransferError?(error)
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PairingMPCService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.retryAdvertising()
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PairingMPCService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            // Only show peers that are using MPC Direct (not animation-pairing peers).
            guard info?["mpcDirect"] == "1" else { return }
            if !self.nearbyPeers.contains(where: { $0 == peerID }) {
                self.nearbyPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.retryBrowsing()
        }
    }
}
