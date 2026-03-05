import ActivityKit
import Foundation
import SwiftUI

/// Settings for Live Activity appearance and behavior
struct LiveActivitySettings: Codable, Hashable {
    var accentColor: CodableColor
    var backgroundTexture: BackgroundTexture
    var fontFamily: FontFamily
    var fontWeight: FontWeightOption
    var progressBarStyle: ProgressBarStyle
    var iconSize: IconSize
    var detailDensity: DetailDensity
    var animationStyle: AnimationStyle
    var showEstimatedTime: Bool
    var highFrequencyUpdates: Bool
    
    // New settings
    var glassSettings: GlassSettings
    var gradientSettings: GradientSettings

    // Additional Customization
    var cornerRadius: Double
    var borderWidth: Double
    var borderColor: CodableColor?
    var shadowRadius: Double
    var shadowColor: CodableColor?
    var backgroundOpacity: Double
    var textColor: CodableColor?

    static var `default`: LiveActivitySettings {
        LiveActivitySettings(
            accentColor: CodableColor(red: 0.0, green: 0.478, blue: 1.0),
            backgroundTexture: .blur,
            fontFamily: .system,
            fontWeight: .semibold,
            progressBarStyle: .gradient,
            iconSize: .medium,
            detailDensity: .standard,
            animationStyle: .smooth,
            showEstimatedTime: true,
            highFrequencyUpdates: false,
            glassSettings: .default,
            gradientSettings: .default,
            cornerRadius: 22,
            borderWidth: 0,
            borderColor: nil,
            shadowRadius: 10,
            shadowColor: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.2),
            backgroundOpacity: 1.0,
            textColor: nil
        )
    }
    
    enum BackgroundTexture: String, Codable, Hashable, CaseIterable {
        case blur = "Blur"
        case material = "Material"
        case solid = "Solid"
        case gradient = "Gradient"
        case glass = "Glass"
    }
    
    enum FontFamily: String, Codable, Hashable, CaseIterable {
        case system = "System"
        case rounded = "Rounded"
        case monospaced = "Monospaced"
    }
    
    enum FontWeightOption: String, Codable, Hashable, CaseIterable {
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "Semibold"
        case bold = "Bold"
        
        var fontWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
    
    enum ProgressBarStyle: String, Codable, Hashable, CaseIterable {
        case solid = "Solid"
        case gradient = "Gradient"
        case capsule = "Capsule"
    }
    
    enum IconSize: String, Codable, Hashable, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var size: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 48
            }
        }
    }
    
    enum DetailDensity: String, Codable, Hashable, CaseIterable {
        case minimal = "Minimal"
        case standard = "Standard"
        case detailed = "Detailed"
    }
    
    enum AnimationStyle: String, Codable, Hashable, CaseIterable {
        case none = "None"
        case smooth = "Smooth"
        case spring = "Spring"
    }

    enum GradientDirection: String, Codable, Hashable, CaseIterable {
        case topToBottom = "Top To Bottom"
        case leftToRight = "Left To Right"
        case topLeftToBottomRight = "Top Left To Bottom Right"
        case bottomLeftToTopRight = "Bottom Left To Top Right"
    }

    enum GradientPattern: String, Codable, Hashable, CaseIterable {
        case linear = "Linear"
        case radial = "Radial"
        case angular = "Angular"
    }
}

struct GlassSettings: Codable, Hashable {
    var isTinted: Bool
    var intensity: Double
    var glassEffectAmount: Double

    static var `default`: GlassSettings {
        GlassSettings(isTinted: true, intensity: 0.5, glassEffectAmount: 0.5)
    }
}

struct GradientSettings: Codable, Hashable {
    var colorCount: Int
    var direction: LiveActivitySettings.GradientDirection
    var pattern: LiveActivitySettings.GradientPattern
    var colors: [CodableColor]?

    static var `default`: GradientSettings {
        GradientSettings(
            colorCount: 2,
            direction: .topToBottom,
            pattern: .linear,
            colors: [
                CodableColor(red: 0.0, green: 0.478, blue: 1.0),
                CodableColor(red: 0.639, green: 0.286, blue: 0.639)
            ]
        )
    }
}

/// Codable wrapper for Color
struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

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
        var speed: Double? // bytes per second
        
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
        
        var formattedSpeed: String? {
            guard let speed = speed, speed > 0 else { return nil }
            return ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file) + "/s"
        }
        
        var eta: String? {
            guard let timeRemaining = timeRemaining else { return nil }
            let eta = Date().addingTimeInterval(timeRemaining)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: eta)
        }
    }
    
    // Static properties that don't change
    var appName: String
    var appBundleId: String
    var appVersion: String?
    var appIcon: Data?
    var startTime: Date
    var settings: LiveActivitySettings
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
        case .unzipping: return "arrow.up.bin.fill"
        case .signing: return "signature"
        case .rezipping: return "arrow.down.doc.fill"
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
        case .preparing: return .yellow
        case .downloading: return .blue
        case .unzipping: return .cyan
        case .signing: return .purple
        case .rezipping: return .indigo
        case .installing: return .orange
        case .verifying: return .teal
        case .completed: return .green
        case .failed: return .red
        case .paused: return .yellow
        case .cancelled: return .gray
        }
    }
}
