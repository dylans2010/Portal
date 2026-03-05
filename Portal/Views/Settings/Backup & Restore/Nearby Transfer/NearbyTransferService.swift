import Foundation
import MultipeerConnectivity
import Combine
import UIKit

// MARK: - Constants
private let kOTPExpirationSeconds = 300 // 5 minutes


// MARK: - Nearby Transfer Service
class NearbyTransferService: NSObject, ObservableObject {
    static let serviceType = "portal-backup"
    private let password = "PortalNearbyShareSecureTransferService2026" 
    
    @Published var state: TransferState = .idle
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var discoveredPeersWithOTP: [(peer: MCPeerID, otp: String)] = []
    @Published var currentItem: String = ""
    @Published var canRetry: Bool = false
    
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var transferProgress: Progress?
    private var startTime: Date?
    private var lastBytesTransferred: Int64 = 0
    private var lastSpeedUpdate: Date?
    
    var mode: TransferMode = .receive
    var currentOTP: String?
    var currentPairingMethod: String = "Nearby"
    
    override init() {
        let deviceName = UIDevice.current.name
        self.peerID = MCPeerID(displayName: deviceName)
        super.init()
    }
    
    // MARK: - Start/Stop
    
    func startSendMode() {
        mode = .send
        setupSession()
        startBrowsing()
        state = .discovering
    }
    
    func startReceiveMode() {
        mode = .receive
        setupSession()
        startAdvertising()
        state = .discovering
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        
        advertiser = nil
        browser = nil
        session = nil
        
        state = .idle
        discoveredPeers = []
    }
    
    // MARK: - Setup
    
    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }
    
    private func startAdvertising() {
        // Include OTP in discovery info if available
        var discoveryInfo: [String: String]? = nil
        if let otp = currentOTP {
            discoveryInfo = ["otp": otp, "timestamp": "\(Date().timeIntervalSince1970)"]
        }
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func setOTP(_ otp: String) {
        currentOTP = otp
        // Restart advertising with new OTP if already advertising
        if advertiser != nil {
            advertiser?.stopAdvertisingPeer()
            startAdvertising()
        }
    }
    
    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    // MARK: - Send
    
    func sendBackup(from backupDirectory: URL, to peer: MCPeerID) {
        guard let session = session else { return }
        
        state = .connecting
        currentItem = "Preparing Backup..."
        
        Task {
            do {
                // Create backup payload
                let payload = try BackupPayload(backupDirectory: backupDirectory)
                let encryptedData = try payload.encrypted(with: password)
                
                await MainActor.run {
                    currentItem = "Sending Backup..."
                    startTime = Date()
                    lastBytesTransferred = 0
                    lastSpeedUpdate = Date()
                }
                
                // Send size first
                let sizeData = withUnsafeBytes(of: Int64(encryptedData.count)) { Data($0) }
                try session.send(sizeData, toPeers: [peer], with: .reliable)
                
                // Send data in chunks
                let chunkSize = 1024 * 1024 // 1 MB chunks
                var offset = 0
                
                while offset < encryptedData.count {
                    let end = min(offset + chunkSize, encryptedData.count)
                    let chunk = encryptedData.subdata(in: offset..<end)
                    
                    try session.send(chunk, toPeers: [peer], with: .reliable)
                    offset = end
                    
                    let currentOffset = offset
                    await MainActor.run {
                        updateProgress(bytesTransferred: Int64(currentOffset), totalBytes: Int64(encryptedData.count))
                    }
                    
                    // Small delay to prevent overwhelming the connection
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                
                await MainActor.run {
                    state = .completed
                    currentItem = "Transfer Completed!"
                }
                
            } catch {
                await MainActor.run {
                    state = .failed(error)
                    canRetry = true
                }
            }
        }
    }
    
    // MARK: - Receive
    
    private var receivedData = Data()
    private var expectedSize: Int64 = 0
    private var isReceivingSize = true
    
    func resetReceive() {
        receivedData = Data()
        expectedSize = 0
        isReceivingSize = true
    }
    
    // MARK: - Connect
    
    func connect(to peer: MCPeerID) {
        guard let browser = browser else { return }
        browser.invitePeer(peer, to: session!, withContext: nil, timeout: 30)
        state = .connecting
    }
    
    // MARK: - Cancel
    
    func cancelTransfer() {
        stop()
        canRetry = true
    }
    
    // MARK: - Progress
    
    private func updateProgress(bytesTransferred: Int64, totalBytes: Int64) {
        let progress = Double(bytesTransferred) / Double(totalBytes)
        
        // Calculate speed
        var speed: Double = 0
        if let lastUpdate = lastSpeedUpdate, let _ = startTime {
            let elapsed = Date().timeIntervalSince(lastUpdate)
            if elapsed > 0.5 { // Update speed every 0.5 seconds
                let bytesSinceLastUpdate = bytesTransferred - lastBytesTransferred
                speed = Double(bytesSinceLastUpdate) / elapsed
                lastBytesTransferred = bytesTransferred
                lastSpeedUpdate = Date()
            } else if let start = startTime {
                let totalElapsed = Date().timeIntervalSince(start)
                if totalElapsed > 0 {
                    speed = Double(bytesTransferred) / totalElapsed
                }
            }
        }
        
        state = .transferring(progress: progress, bytesTransferred: bytesTransferred, totalBytes: totalBytes, speed: speed)
    }
}

// MARK: - MCSessionDelegate
extension NearbyTransferService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.state = .connecting
                self.currentItem = "Connected To \(peerID.displayName)"

                // Generate session fingerprint for this connection
                let fingerprint = String(UUID().uuidString.prefix(8)).uppercased()

                // Save secure transfer session record with explicit handshake data
                SecureTransferSessionManager.shared.recordSessionAuthenticated(
                    sessionID: UUID(),
                    createdAt: Date(),
                    method: self.currentPairingMethod,
                    remoteDeviceName: peerID.displayName,
                    encryptionType: "AES-256",
                    sessionFingerprint: fingerprint,
                    isActive: true
                )

            case .connecting:
                self.currentItem = "Connecting To \(peerID.displayName)..."
            case .notConnected:
                // Deactivate secure transfer session
                SecureTransferSessionManager.shared.deactivateSession()

                if case .transferring = self.state {
                    // Transfer was interrupted
                    self.state = .failed(NSError(domain: "NearbyTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection Lost"]))
                    self.canRetry = true
                }
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if self.isReceivingSize {
                // First 8 bytes are the total size
                if data.count >= 8 {
                    self.expectedSize = data.withUnsafeBytes { $0.load(as: Int64.self) }
                    if self.expectedSize <= 0 {
                        self.state = .failed(NSError(domain: "NearbyTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Backup Size"]))
                        return
                    }
                    self.isReceivingSize = false
                    self.startTime = Date()
                    self.lastBytesTransferred = 0
                    self.lastSpeedUpdate = Date()
                    self.currentItem = "Receiving Backup..."
                } else {
                    self.state = .failed(NSError(domain: "NearbyTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Size Data Received"]))
                }
            } else {
                self.receivedData.append(data)
                self.updateProgress(bytesTransferred: Int64(self.receivedData.count), totalBytes: self.expectedSize)
                
                if self.receivedData.count >= self.expectedSize {
                    // Transfer complete, decrypt and extract
                    self.processReceivedBackup()
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
    
    private func processReceivedBackup() {
        Task {
            do {
                let payload = try BackupPayload.decrypted(from: receivedData, password: password)
                
                // Create temporary directory for extraction
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ReceivedBackup_\(UUID().uuidString)")
                try payload.extract(to: tempDir)
                
                await MainActor.run {
                    state = .completed
                    currentItem = "Backup Received Successfully!"
                    // Store the temp directory path for later restoration
                    UserDefaults.standard.set(tempDir.path, forKey: "pendingNearbyBackupRestore")
                }
            } catch {
                await MainActor.run {
                    state = .failed(error)
                    canRetry = true
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NearbyTransferService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.currentItem = "Accepting Connection From \(peerID.displayName)"
            invitationHandler(true, self.session)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.state = .failed(error)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NearbyTransferService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            // Extract OTP from discovery info if available
            if let otp = info?["otp"], let timestampString = info?["timestamp"], 
               let timestamp = Double(timestampString) {
                // Check if OTP is not expired
                let elapsed = Date().timeIntervalSince1970 - timestamp
                if elapsed < Double(kOTPExpirationSeconds) {
                    // Store peer with its OTP
                    if !self.discoveredPeersWithOTP.contains(where: { $0.peer == peerID }) {
                        self.discoveredPeersWithOTP.append((peer: peerID, otp: otp))
                    }
                }
            }
            
            // Also maintain the regular peer list for backward compatibility
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
            self.discoveredPeersWithOTP.removeAll { $0.peer == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.state = .failed(error)
        }
    }
    
    // MARK: - OTP Validation
    func findPeerWithOTP(_ otp: String) -> MCPeerID? {
        return discoveredPeersWithOTP.first(where: { $0.otp == otp })?.peer
    }
}
