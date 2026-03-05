import Foundation
import MultipeerConnectivity
import Combine
import UIKit
import OSLog

// MARK: - Sources Transfer Service
class SourcesTransferService: NSObject, ObservableObject {
    static let serviceType = "portal-sources"

    @Published var state: TransferState = .idle
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var currentItem: String = ""

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    var mode: TransferMode = .receive
    var onSourcesReceived: (([String]) -> Void)?
    var pendingSourcesToSend: [String]?

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
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    // MARK: - Send

    func sendSources(_ urls: [String], to peer: MCPeerID) {
        guard let session = session else { return }

        if session.connectedPeers.contains(peer) {
            performSend(urls, to: peer)
        } else {
            pendingSourcesToSend = urls
            connect(to: peer)
        }
    }

    private func performSend(_ urls: [String], to peer: MCPeerID) {
        guard let session = session else { return }

        state = .connecting
        currentItem = "Sending Sources..."

        let exportDataString = PortalSourceExport.encode(urls: urls)
        guard let data = exportDataString.data(using: .utf8) else {
            state = .failed(NSError(domain: "SourcesTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode sources"]))
            return
        }

        do {
            try session.send(data, toPeers: [peer], with: .reliable)
            state = .completed
            currentItem = "Sources Sent!"
        } catch {
            state = .failed(error)
        }
    }

    // MARK: - Connect

    func connect(to peer: MCPeerID) {
        guard let browser = browser, let session = session else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        state = .connecting
    }
}

// MARK: - MCSessionDelegate
extension SourcesTransferService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.currentItem = "Connected To \(peerID.displayName)"
                if self.mode == .send, let urls = self.pendingSourcesToSend {
                    self.performSend(urls, to: peerID)
                    self.pendingSourcesToSend = nil
                } else if self.mode == .receive {
                    self.state = .connecting
                }
            case .connecting:
                self.currentItem = "Connecting To \(peerID.displayName)..."
            case .notConnected:
                if case .connecting = self.state {
                     self.state = .discovering
                }
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            guard let portalString = String(data: data, encoding: .utf8) else { return }

            if let urls = PortalSourceExport.decode(portalString) {
                self.onSourcesReceived?(urls)
                self.state = .completed
                self.currentItem = "Sources Received!"
            } else {
                self.state = .failed(NSError(domain: "SourcesTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Data Received"]))
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension SourcesTransferService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            // In a production app, you might show an alert here.
            // For Portal's streamlined experience, we accept if in receive mode.
            let shouldAccept = self.mode == .receive
            invitationHandler(shouldAccept, self.session)
            if shouldAccept {
                self.currentItem = "Accepting Invitation..."
            }
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.state = .failed(error)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension SourcesTransferService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.state = .failed(error)
        }
    }
}
