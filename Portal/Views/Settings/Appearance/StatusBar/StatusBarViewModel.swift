import SwiftUI
import Combine

// MARK: - Alignment Constants
enum StatusBarAlignment: String {
    case left = "left"
    case center = "center"
    case right = "right"
    
    // Compatibility with existing string-based storage
    static func from(_ string: String) -> StatusBarAlignment {
        return StatusBarAlignment(rawValue: string) ?? .center
    }
}

// MARK: - Widget Type Enum
enum StatusBarWidgetType: String, CaseIterable {
    case none = "none"
    case text = "text"
    case sfSymbol = "symbol"
    case battery = "battery"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .text: return "Text"
        case .sfSymbol: return "SF Symbol"
        case .battery: return "Battery"
        }
    }
}

// MARK: - Device Type Enum
enum DeviceType: String, CaseIterable, Identifiable {
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15Plus = "iPhone 15 Plus"
    case iPhone15 = "iPhone 15"
    case iPhone14ProMax = "iPhone 14 Pro Max"
    case iPhone14Pro = "iPhone 14 Pro"
    case iPhone14Plus = "iPhone 14 Plus"
    case iPhone14 = "iPhone 14"
    case iPhoneSE = "iPhone SE"
    
    var id: String { rawValue }
    
    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .iPhone15ProMax, .iPhone14ProMax:
            return (300, 650)
        case .iPhone15Pro, .iPhone14Pro:
            return (280, 610)
        case .iPhone15Plus, .iPhone14Plus:
            return (295, 640)
        case .iPhone15, .iPhone14:
            return (280, 610)
        case .iPhoneSE:
            return (260, 560)
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .iPhoneSE:
            return 20
        default:
            return 40
        }
    }
}

// MARK: - Device Color Enum
enum DeviceColor: String, CaseIterable, Identifiable {
    case black = "Black"
    case white = "White"
    case silver = "Silver"
    case gold = "Gold"
    case blue = "Blue"
    case purple = "Purple"
    case red = "Red"
    case pink = "Pink"
    case yellow = "Yellow"
    case green = "Green"
    
    var id: String { rawValue }
    
    var colorValue: Color {
        switch self {
        case .black: return Color(hex: "#1C1C1E")
        case .white: return Color(hex: "#F5F5F7")
        case .silver: return Color(hex: "#C0C0C0")
        case .gold: return Color(hex: "#FCEBD3")
        case .blue: return Color(hex: "#276FBF")
        case .purple: return Color(hex: "#9D8AC7")
        case .red: return Color(hex: "#BA0C2F")
        case .pink: return Color(hex: "#FADDD8")
        case .yellow: return Color(hex: "#F9E5C9")
        case .green: return Color(hex: "#394C38")
        }
    }
}

// MARK: - View Model
class StatusBarViewModel: ObservableObject {
    // Custom Text
    @AppStorage("statusBar.customText") var customText: String = ""
    @AppStorage("statusBar.showCustomText") var showCustomText: Bool = false
    
    // SF Symbol
    @AppStorage("statusBar.sfSymbol") var sfSymbol: String = "circle.fill"
    @AppStorage("statusBar.showSFSymbol") var showSFSymbol: Bool = false
    
    // Styling
    @AppStorage("statusBar.bold") var isBold: Bool = false
    @AppStorage("statusBar.color") var colorHex: String = "#007AFF"
    @AppStorage("statusBar.fontSize") var fontSize: Double = 12
    @AppStorage("statusBar.fontDesign") var fontDesign: String = "default"
    
    // Background
    @AppStorage("statusBar.showBackground") var showBackground: Bool = false
    @AppStorage("statusBar.backgroundColor") var backgroundColorHex: String = "#000000"
    @AppStorage("statusBar.backgroundOpacity") var backgroundOpacity: Double = 0.2
    @AppStorage("statusBar.blurBackground") var blurBackground: Bool = false
    @AppStorage("statusBar.cornerRadius") var cornerRadius: Double = 12
    @AppStorage("statusBar.borderWidth") var borderWidth: Double = 0
    @AppStorage("statusBar.borderColor") var borderColorHex: String = "#007AFF"
    
    // Shadow
    @AppStorage("statusBar.shadowEnabled") var shadowEnabled: Bool = false
    @AppStorage("statusBar.shadowColor") var shadowColorHex: String = "#000000"
    @AppStorage("statusBar.shadowRadius") var shadowRadius: Double = 4
    
    // Layout
    @AppStorage("statusBar.alignment") var alignment: String = "center"
    @AppStorage("statusBar.leftPadding") var leftPadding: Double = 0
    @AppStorage("statusBar.rightPadding") var rightPadding: Double = 0
    @AppStorage("statusBar.topPadding") var topPadding: Double = 0
    @AppStorage("statusBar.bottomPadding") var bottomPadding: Double = 0
    
    // Text Layout
    @AppStorage("statusBar.textAlignment") var textAlignment: String = "center"
    @AppStorage("statusBar.textLeftPadding") var textLeftPadding: Double = 0
    @AppStorage("statusBar.textRightPadding") var textRightPadding: Double = 0
    @AppStorage("statusBar.textTopPadding") var textTopPadding: Double = 0
    @AppStorage("statusBar.textBottomPadding") var textBottomPadding: Double = 0
    
    // SF Symbol Layout (keep existing, used ONLY for SF symbols)
    @AppStorage("statusBar.sfSymbolAlignment") var sfSymbolAlignment: String = "center"
    @AppStorage("statusBar.sfSymbolLeftPadding") var sfSymbolLeftPadding: Double = 0
    @AppStorage("statusBar.sfSymbolRightPadding") var sfSymbolRightPadding: Double = 0
    @AppStorage("statusBar.sfSymbolTopPadding") var sfSymbolTopPadding: Double = 0
    @AppStorage("statusBar.sfSymbolBottomPadding") var sfSymbolBottomPadding: Double = 0
    
    // Time Layout
    @AppStorage("statusBar.timeAlignment") var timeAlignment: String = "center"
    @AppStorage("statusBar.timeLeftPadding") var timeLeftPadding: Double = 0
    @AppStorage("statusBar.timeRightPadding") var timeRightPadding: Double = 0
    @AppStorage("statusBar.timeTopPadding") var timeTopPadding: Double = 0
    @AppStorage("statusBar.timeBottomPadding") var timeBottomPadding: Double = 0
    
    // Battery Layout
    @AppStorage("statusBar.batteryAlignment") var batteryAlignment: String = "center"
    @AppStorage("statusBar.batteryLeftPadding") var batteryLeftPadding: Double = 0
    @AppStorage("statusBar.batteryRightPadding") var batteryRightPadding: Double = 0
    @AppStorage("statusBar.batteryTopPadding") var batteryTopPadding: Double = 0
    @AppStorage("statusBar.batteryBottomPadding") var batteryBottomPadding: Double = 0
    
    // Animation
    @AppStorage("statusBar.enableAnimation") var enableAnimation: Bool = false
    @AppStorage("statusBar.animationType") var animationType: String = "bounce"
    @AppStorage("statusBar.animationDuration") var animationDuration: Double = 0.3
    @AppStorage("statusBar.animationDelay") var animationDelay: Double = 0.0
    
    // System Integration
    @AppStorage("statusBar.hideDefaultStatusBar") var hideDefaultStatusBar: Bool = true
    
    // Advanced Features
    @AppStorage("statusBar.showDate") var showDate: Bool = false
    @AppStorage("statusBar.dateFormat") var dateFormat: String = "short" // short, medium, long, custom
    @AppStorage("statusBar.customDateFormat") var customDateFormat: String = "MMM d"
    @AppStorage("statusBar.showWeekday") var showWeekday: Bool = false
    
    // Network Status
    @AppStorage("statusBar.showNetworkStatus") var showNetworkStatus: Bool = false
    @AppStorage("statusBar.networkIconStyle") var networkIconStyle: String = "bars" // bars, dot, text
    
    // Memory/Performance
    @AppStorage("statusBar.showMemoryUsage") var showMemoryUsage: Bool = false
    @AppStorage("statusBar.memoryDisplayStyle") var memoryDisplayStyle: String = "percentage" // percentage, mb, both
    
    // Gradient Text
    @AppStorage("statusBar.useGradientText") var useGradientText: Bool = false
    @AppStorage("statusBar.gradientStartColor") var gradientStartColorHex: String = "#007AFF"
    @AppStorage("statusBar.gradientEndColor") var gradientEndColorHex: String = "#5856D6"
    @AppStorage("statusBar.gradientAngle") var gradientAngle: Double = 0
    
    // Glow Effect
    @AppStorage("statusBar.enableGlow") var enableGlow: Bool = false
    @AppStorage("statusBar.glowColor") var glowColorHex: String = "#007AFF"
    @AppStorage("statusBar.glowRadius") var glowRadius: Double = 4
    @AppStorage("statusBar.glowIntensity") var glowIntensity: Double = 0.5
    
    // Blur Style
    @AppStorage("statusBar.blurStyle") var blurStyle: String = "regular" // regular, thin, thick, chrome, material
    
    // Auto-hide
    @AppStorage("statusBar.autoHide") var autoHide: Bool = false
    @AppStorage("statusBar.autoHideDelay") var autoHideDelay: Double = 3.0
    @AppStorage("statusBar.showOnTap") var showOnTap: Bool = true
    
    // Spacing
    @AppStorage("statusBar.itemSpacing") var itemSpacing: Double = 8
    @AppStorage("statusBar.verticalOffset") var verticalOffset: Double = 0
    
    // Icon Customization
    @AppStorage("statusBar.iconSize") var iconSize: Double = 16
    @AppStorage("statusBar.iconWeight") var iconWeight: String = "regular"
    
    // Time and Battery - NEW unified widget approach
    @AppStorage("statusBar.showTime") var showTime: Bool = false
    @AppStorage("statusBar.showSeconds") var showSeconds: Bool = false
    @AppStorage("statusBar.use24HourClock") var use24HourClock: Bool = false
    @AppStorage("statusBar.animateTime") var animateTime: Bool = true
    @AppStorage("statusBar.timeAccentColored") var timeAccentColored: Bool = false
    @AppStorage("statusBar.timeColor") var timeColorHex: String = "#FFFFFF"
    
    @AppStorage("statusBar.showBattery") var showBattery: Bool = false
    @AppStorage("statusBar.batteryAccentColored") var batteryAccentColored: Bool = false
    @AppStorage("statusBar.batteryUseAutoColor") var batteryUseAutoColor: Bool = true
    @AppStorage("statusBar.batteryColor") var batteryColorHex: String = "#FFFFFF"
    @AppStorage("statusBar.batteryStyle") var batteryStyle: String = "icon" // "icon", "percentage", "both"
    
    // Device Preview Properties
    @AppStorage("statusBar.selectedDeviceType") var selectedDeviceTypeRaw: String = DeviceType.iPhone15Pro.rawValue
    @AppStorage("statusBar.selectedDeviceColor") var selectedDeviceColorRaw: String = DeviceColor.black.rawValue
    
    var selectedDeviceType: DeviceType {
        get { DeviceType(rawValue: selectedDeviceTypeRaw) ?? .iPhone15Pro }
        set { selectedDeviceTypeRaw = newValue.rawValue }
    }
    
    var selectedDeviceColor: DeviceColor {
        get { DeviceColor(rawValue: selectedDeviceColorRaw) ?? .black }
        set { selectedDeviceColorRaw = newValue.rawValue }
    }
    
    // Legacy compatibility - remove widget type approach
    @AppStorage("statusBar.widgetType") var widgetTypeRaw: String = "none"
    @AppStorage("statusBar.widgetAccentColored") var widgetAccentColored: Bool = false
    
    var widgetType: StatusBarWidgetType {
        get { StatusBarWidgetType(rawValue: widgetTypeRaw) ?? .none }
        set { widgetTypeRaw = newValue.rawValue }
    }
    
    // SF Symbols Picker State
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var recentSymbols: [String] = []
    @Published var favoriteSymbols: [String] = []
    @Published var selectedWeight: String = "regular"
    @Published var selectedScale: String = "medium"
    @Published var selectedRenderingMode: String = "monochrome"
    
    // Color picker states
    @Published var selectedColor: Color = .blue
    @Published var selectedBackgroundColor: Color = .black
    @Published var selectedShadowColor: Color = .black
    @Published var selectedBorderColor: Color = .blue
    @Published var selectedTimeColor: Color = .white
    @Published var selectedBatteryColor: Color = .white
    
    init() {
        selectedColor = Color(hex: colorHex)
        selectedBackgroundColor = Color(hex: backgroundColorHex)
        selectedShadowColor = Color(hex: shadowColorHex)
        selectedBorderColor = Color(hex: borderColorHex)
        selectedTimeColor = Color(hex: timeColorHex)
        selectedBatteryColor = Color(hex: batteryColorHex)
        
        // Load recent and favorite symbols from UserDefaults
        if let recents = UserDefaults.standard.stringArray(forKey: "statusBar.recentSymbols") {
            recentSymbols = recents
        }
        if let favorites = UserDefaults.standard.stringArray(forKey: "statusBar.favoriteSymbols") {
            favoriteSymbols = favorites
        }
    }
    
    // MARK: - Methods
    
    func selectSymbol(_ symbol: String) {
        sfSymbol = symbol
        addToRecents(symbol)
    }
    
    func addToRecents(_ symbol: String) {
        recentSymbols.removeAll { $0 == symbol }
        recentSymbols.insert(symbol, at: 0)
        if recentSymbols.count > 20 {
            recentSymbols.removeLast()
        }
        UserDefaults.standard.set(recentSymbols, forKey: "statusBar.recentSymbols")
    }
    
    func toggleFavorite(_ symbol: String) {
        if favoriteSymbols.contains(symbol) {
            favoriteSymbols.removeAll { $0 == symbol }
        } else {
            favoriteSymbols.append(symbol)
        }
        UserDefaults.standard.set(favoriteSymbols, forKey: "statusBar.favoriteSymbols")
    }
    
    func isFavorite(_ symbol: String) -> Bool {
        favoriteSymbols.contains(symbol)
    }
    
    func handleHideDefaultStatusBarChange(_ newValue: Bool) {
        // If user is trying to disable (show default status bar) and there are custom changes
        if !newValue && hasCustomChanges() {
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Show Default Status Bar?",
                message: "If you disable this, you won't see the custom Status Bar changes anymore. Are you sure?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                // Revert the toggle
                DispatchQueue.main.async {
                    self?.hideDefaultStatusBar = true
                }
            })
            
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
                // Clear custom changes
                self?.clearCustomChanges()
                // Post notification
                NotificationCenter.default.post(name: NSNotification.Name("StatusBarHidingPreferenceChanged"), object: nil)
            })
            
            // Present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                topController.present(alert, animated: true)
            }
        } else {
            // No custom changes or enabling hide, just post notification
            NotificationCenter.default.post(name: NSNotification.Name("StatusBarHidingPreferenceChanged"), object: nil)
        }
    }
    
    func hasCustomChanges() -> Bool {
        return showCustomText || showSFSymbol || showBackground || showTime || showBattery
    }
    
    func clearCustomChanges() {
        showCustomText = false
        showSFSymbol = false
        showBackground = false
        showTime = false
        showBattery = false
    }
    
    func resetToDefaults() {
        customText = ""
        showCustomText = false
        sfSymbol = "circle.fill"
        showSFSymbol = false
        isBold = false
        colorHex = "#007AFF"
        fontSize = 12
        fontDesign = "default"
        showBackground = false
        backgroundColorHex = "#000000"
        backgroundOpacity = 0.2
        blurBackground = false
        cornerRadius = 12
        borderWidth = 0
        borderColorHex = "#007AFF"
        shadowEnabled = false
        shadowColorHex = "#000000"
        shadowRadius = 4
        alignment = "center"
        leftPadding = 0
        rightPadding = 0
        topPadding = 0
        bottomPadding = 0
        textAlignment = StatusBarAlignment.left.rawValue
        textLeftPadding = 0
        textRightPadding = 0
        textTopPadding = 0
        textBottomPadding = 0
        sfSymbolAlignment = StatusBarAlignment.left.rawValue
        sfSymbolLeftPadding = 0
        sfSymbolRightPadding = 0
        sfSymbolTopPadding = 0
        sfSymbolBottomPadding = 0
        timeAlignment = StatusBarAlignment.left.rawValue
        timeLeftPadding = 0
        timeRightPadding = 0
        timeTopPadding = 0
        timeBottomPadding = 0
        batteryAlignment = StatusBarAlignment.right.rawValue
        batteryLeftPadding = 0
        batteryRightPadding = 0
        batteryTopPadding = 0
        batteryBottomPadding = 0
        enableAnimation = false
        animationType = "bounce"
        animationDuration = 0.3
        animationDelay = 0.0
        hideDefaultStatusBar = true
        showTime = false
        showSeconds = false
        use24HourClock = false
        animateTime = true
        timeAccentColored = false
        timeColorHex = "#FFFFFF"
        showBattery = false
        batteryAccentColored = false
        batteryUseAutoColor = true
        batteryColorHex = "#FFFFFF"
        batteryStyle = "icon"
        widgetTypeRaw = "none"
        widgetAccentColored = false
        selectedDeviceTypeRaw = DeviceType.iPhone15Pro.rawValue
        selectedDeviceColorRaw = DeviceColor.black.rawValue
        
        // Reset new advanced features
        showDate = false
        dateFormat = "short"
        customDateFormat = "MMM d"
        showWeekday = false
        showNetworkStatus = false
        networkIconStyle = "bars"
        showMemoryUsage = false
        memoryDisplayStyle = "percentage"
        useGradientText = false
        gradientStartColorHex = "#007AFF"
        gradientEndColorHex = "#5856D6"
        gradientAngle = 0
        enableGlow = false
        glowColorHex = "#007AFF"
        glowRadius = 4
        glowIntensity = 0.5
        blurStyle = "regular"
        autoHide = false
        autoHideDelay = 3.0
        showOnTap = true
        itemSpacing = 8
        verticalOffset = 0
        iconSize = 16
        iconWeight = "regular"
        
        selectedColor = .blue
        selectedBackgroundColor = .black
        selectedShadowColor = .black
        selectedBorderColor = .blue
        selectedTimeColor = .white
        selectedBatteryColor = .white
    }
    
    // MARK: - Positioning Logic
    
    // Get available positions for a widget type
    func getAvailablePositions(for widgetType: String) -> [String] {
        var availablePositions = [
            StatusBarAlignment.left.rawValue,
            StatusBarAlignment.center.rawValue,
            StatusBarAlignment.right.rawValue
        ]
        
        // Check what positions are taken
        let takenPositions = getOccupiedPositions(excluding: widgetType)
        
        // Remove taken positions
        availablePositions.removeAll { takenPositions.contains($0) }
        
        return availablePositions
    }
    
    // Get currently occupied positions, excluding a specific widget type
    func getOccupiedPositions(excluding: String) -> [String] {
        var occupied: [String] = []
        
        let excludingLower = excluding.lowercased()
        
        if excludingLower != "text" && showCustomText && !customText.isEmpty {
            occupied.append(textAlignment)
        }
        if excludingLower != "sf symbol" && excludingLower != "sfsymbol" && showSFSymbol {
            occupied.append(sfSymbolAlignment)
        }
        if excludingLower != "time" && showTime {
            occupied.append(timeAlignment)
        }
        if excludingLower != "battery" && showBattery {
            occupied.append(batteryAlignment)
        }
        
        return occupied
    }
    
    // Check if a position is available for a widget type
    func isPositionAvailable(_ position: String, for widgetType: String) -> Bool {
        let available = getAvailablePositions(for: widgetType)
        return available.contains(position)
    }
    
    // Get battery color based on level (auto mode)
    func getBatteryColor(level: Float, charging: Bool) -> Color {
        if !batteryUseAutoColor {
            return batteryAccentColored ? Color.accentColor : Color(hex: batteryColorHex)
        }
        
        // Auto color based on battery level
        if charging {
            return .green
        } else if level <= 0.2 {
            return .red
        } else if level <= 0.5 {
            return .yellow
        } else if level <= 0.8 {
            return .green
        } else {
            return .white
        }
    }
}
