import ActivityKit
import Foundation
import SwiftUI

/// Activity attributes for app installation Live Activity
@available(iOS 16.1, *)
struct InstallationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that can be updated
        var progress: Double
        var bytesDownloaded: Int64
        var totalBytes: Int64
        var status: InstallationStatus
        var timeRemaining: TimeInterval?
        var downloadSpeed: Double? // bytes per second
        
        var progressPercentage: String {
            String(format: "%.0f%%", progress * 100)
        }
        
        var formattedBytesDownloaded: String {
            ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        }
        
        var formattedTotalBytes: String {
            ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        }
        
        var formattedTimeRemaining: String? {
            guard let time = timeRemaining else { return nil }
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 2
            return formatter.string(from: time)
        }
        
        var formattedDownloadSpeed: String? {
            guard let speed = downloadSpeed, speed > 0 else { return nil }
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            return "\(formatter.string(fromByteCount: Int64(speed)))/s"
        }
    }
    
    // Static properties that don't change
    var appName: String
    var appBundleId: String
    var appIcon: Data?
    var startTime: Date
    
    // User customization settings
    var accentColor: String // Hex color string
    var backgroundMaterial: String // "regular", "thin", "thick", "ultraThin", "ultraThick"
    var fontFamily: String // "system", "rounded", "monospaced", "serif"
    var fontWeight: String // "regular", "medium", "semibold", "bold"
    var progressBarStyle: String // "linear", "circular", "gradient"
    var iconSize: String // "small", "medium", "large"
    var detailDensity: String // "minimal", "normal", "detailed"
    var animationStyle: String // "smooth", "spring", "instant"
}

/// Installation status enum for Live Activity
enum InstallationStatus: String, Codable, Hashable {
    case preparing = "Preparing"
    case downloading = "Downloading"
    case unzipping = "Unzipping"
    case signing = "Signing"
    case rezipping = "Rezipping"
    case installing = "Installing"
    case verifying = "Verifying"
    case completed = "Completed"
    case failed = "Failed"
    case paused = "Paused"
    case cancelled = "Cancelled"
    
    var icon: String {
        switch self {
        case .preparing: return "hourglass.circle.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .unzipping: return "archivebox.circle.fill"
        case .signing: return "signature"
        case .rezipping: return "archivebox.fill"
        case .installing: return "gear.circle.fill"
        case .verifying: return "checkmark.shield.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "stop.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .preparing: return .orange
        case .downloading: return .blue
        case .unzipping: return .cyan
        case .signing: return .purple
        case .rezipping: return .indigo
        case .installing: return .purple
        case .verifying: return .orange
        case .completed: return .green
        case .failed: return .red
        case .paused: return .yellow
        case .cancelled: return .gray
        }
    }
}
