import Foundation
import Network
import Combine

// MARK: - Network Monitor
/// Monitors network connectivity status (WiFi, Cellular, or None)
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.feather.networkmonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case none
        case unknown
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .none: return "No Connection"
            case .unknown: return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .none: return "wifi.slash"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        // Log connection changes
        if isConnected {
            AppLogManager.shared.success("Network Connected: \(connectionType.displayName)", category: "Network")
        } else {
            AppLogManager.shared.warning("Network Disconnected", category: "Network")
        }
    }
    
    deinit {
        monitor.cancel()
    }
    
    // For developer mode simulation
    func simulateOffline(_ simulate: Bool) {
        if simulate {
            isConnected = false
            connectionType = .none
            AppLogManager.shared.info("Simulating Offline Mode", category: "Developer")
        } else {
            // Re-evaluate actual connection
            startMonitoring()
        }
    }
}
