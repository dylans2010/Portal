import SwiftUI

struct StatusBarOverlay: View {
    // Legacy custom text/symbol settings
    @AppStorage("statusBar.customText") private var customText: String = ""
    @AppStorage("statusBar.showCustomText") private var showCustomText: Bool = false
    @AppStorage("statusBar.sfSymbol") private var sfSymbol: String = "circle.fill"
    @AppStorage("statusBar.showSFSymbol") private var showSFSymbol: Bool = false
    @AppStorage("statusBar.bold") private var isBold: Bool = false
    @AppStorage("statusBar.color") private var colorHex: String = "#007AFF"

    // New Options
    @AppStorage("statusBar.fontSize") private var fontSize: Double = 12
    @AppStorage("statusBar.fontDesign") private var fontDesign: String = "default"
    @AppStorage("statusBar.showBackground") private var showBackground: Bool = false
    @AppStorage("statusBar.backgroundColor") private var backgroundColorHex: String = "#000000"
    @AppStorage("statusBar.backgroundOpacity") private var backgroundOpacity: Double = 0.2
    @AppStorage("statusBar.alignment") private var alignment: String = "center"
    @AppStorage("statusBar.cornerRadius") private var cornerRadius: Double = 12
    @AppStorage("statusBar.enableAnimation") private var enableAnimation: Bool = false
    @AppStorage("statusBar.animationType") private var animationType: String = "bounce"
    @AppStorage("statusBar.hideDefaultStatusBar") private var hideDefaultStatusBar: Bool = true
    @AppStorage("statusBar.blurBackground") private var blurBackground: Bool = false
    @AppStorage("statusBar.shadowEnabled") private var shadowEnabled: Bool = false
    @AppStorage("statusBar.shadowColor") private var shadowColorHex: String = "#000000"
    @AppStorage("statusBar.shadowRadius") private var shadowRadius: Double = 4
    @AppStorage("statusBar.borderWidth") private var borderWidth: Double = 0
    @AppStorage("statusBar.borderColor") private var borderColorHex: String = "#007AFF"
    
    // Gradient Text
    @AppStorage("statusBar.useGradientText") private var useGradientText: Bool = false
    @AppStorage("statusBar.gradientStartColor") private var gradientStartColorHex: String = "#007AFF"
    @AppStorage("statusBar.gradientEndColor") private var gradientEndColorHex: String = "#5856D6"
    @AppStorage("statusBar.gradientAngle") private var gradientAngle: Double = 0
    
    // Glow Effect
    @AppStorage("statusBar.enableGlow") private var enableGlow: Bool = false
    @AppStorage("statusBar.glowColor") private var glowColorHex: String = "#007AFF"
    @AppStorage("statusBar.glowRadius") private var glowRadius: Double = 4
    @AppStorage("statusBar.glowIntensity") private var glowIntensity: Double = 0.5
    
    // Text Layout
    @AppStorage("statusBar.textAlignment") private var textAlignment: String = "center"
    @AppStorage("statusBar.textLeftPadding") private var textLeftPadding: Double = 0
    @AppStorage("statusBar.textRightPadding") private var textRightPadding: Double = 0
    @AppStorage("statusBar.textTopPadding") private var textTopPadding: Double = 0
    @AppStorage("statusBar.textBottomPadding") private var textBottomPadding: Double = 0
    
    // SF Symbol Layout
    @AppStorage("statusBar.sfSymbolAlignment") private var sfSymbolAlignment: String = "center"
    @AppStorage("statusBar.sfSymbolLeftPadding") private var sfSymbolLeftPadding: Double = 0
    @AppStorage("statusBar.sfSymbolRightPadding") private var sfSymbolRightPadding: Double = 0
    @AppStorage("statusBar.sfSymbolTopPadding") private var sfSymbolTopPadding: Double = 0
    @AppStorage("statusBar.sfSymbolBottomPadding") private var sfSymbolBottomPadding: Double = 0
    
    // Time display settings and layout
    @AppStorage("statusBar.showTime") private var showTime: Bool = false
    @AppStorage("statusBar.showSeconds") private var showSeconds: Bool = false
    @AppStorage("statusBar.use24HourClock") private var use24HourClock: Bool = false
    @AppStorage("statusBar.animateTime") private var animateTime: Bool = true
    @AppStorage("statusBar.timeAccentColored") private var timeAccentColored: Bool = false
    @AppStorage("statusBar.timeColor") private var timeColorHex: String = "#FFFFFF"
    @AppStorage("statusBar.timeAlignment") private var timeAlignment: String = "center"
    @AppStorage("statusBar.timeLeftPadding") private var timeLeftPadding: Double = 0
    @AppStorage("statusBar.timeRightPadding") private var timeRightPadding: Double = 0
    @AppStorage("statusBar.timeTopPadding") private var timeTopPadding: Double = 0
    @AppStorage("statusBar.timeBottomPadding") private var timeBottomPadding: Double = 0
    
    // Battery settings and layout (new standalone approach)
    @AppStorage("statusBar.showBattery") private var showBattery: Bool = false
    @AppStorage("statusBar.batteryAccentColored") private var batteryAccentColored: Bool = false
    @AppStorage("statusBar.batteryUseAutoColor") private var batteryUseAutoColor: Bool = true
    @AppStorage("statusBar.batteryColor") private var batteryColorHex: String = "#FFFFFF"
    @AppStorage("statusBar.batteryStyle") private var batteryStyle: String = "icon"
    @AppStorage("statusBar.batteryAlignment") private var batteryAlignment: String = "center"
    @AppStorage("statusBar.batteryLeftPadding") private var batteryLeftPadding: Double = 0
    @AppStorage("statusBar.batteryRightPadding") private var batteryRightPadding: Double = 0
    @AppStorage("statusBar.batteryTopPadding") private var batteryTopPadding: Double = 0
    @AppStorage("statusBar.batteryBottomPadding") private var batteryBottomPadding: Double = 0
    
    // Legacy widget support (kept for backwards compatibility)
    @AppStorage("statusBar.widgetType") private var widgetTypeRaw: String = "none"
    @AppStorage("statusBar.widgetAccentColored") private var widgetAccentColored: Bool = false
    
    // Network Status
    @AppStorage("statusBar.showNetworkStatus") private var showNetworkStatus: Bool = false
    @AppStorage("statusBar.networkIconStyle") private var networkIconStyle: String = "bars"
    
    // Memory Usage
    @AppStorage("statusBar.showMemoryUsage") private var showMemoryUsage: Bool = false
    @AppStorage("statusBar.memoryDisplayStyle") private var memoryDisplayStyle: String = "percentage"
    
    @State private var isVisible = false
    @State private var isConnected = true
    @State private var memoryUsage: Double = 0
    @State private var currentTime = Date()
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    
    // Timer for updating time
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Nearly transparent but still blocks the status bar area
    private let nearlyTransparentOpacity: Double = 0.00001
    
    private var widgetType: StatusBarWidgetType {
        StatusBarWidgetType(rawValue: widgetTypeRaw) ?? .none
    }

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }
    
    // Gradient for text
    private var textGradient: LinearGradient {
        let angle = Angle(degrees: gradientAngle)
        let startPoint = UnitPoint(
            x: 0.5 + 0.5 * cos(angle.radians - .pi / 2),
            y: 0.5 + 0.5 * sin(angle.radians - .pi / 2)
        )
        let endPoint = UnitPoint(
            x: 0.5 - 0.5 * cos(angle.radians - .pi / 2),
            y: 0.5 - 0.5 * sin(angle.radians - .pi / 2)
        )
        return LinearGradient(
            colors: [Color(hex: gradientStartColorHex), Color(hex: gradientEndColorHex)],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    private var selectedAlignment: Alignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private func getAlignment(for type: String) -> Alignment {
        switch type {
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        default: return .center
        }
    }
    
    private var contentAnimation: Animation? {
        guard enableAnimation else { return nil }
        
        switch animationType {
        case "bounce": return .spring(response: 0.6, dampingFraction: 0.6)
        case "fade": return .easeInOut(duration: 0.5)
        case "slide": return .easeOut(duration: 0.4)
        case "scale": return .spring(response: 0.5, dampingFraction: 0.7)
        default: return nil
        }
    }
    
    private var timeAnimation: Animation? {
        animateTime ? .easeInOut(duration: 0.3) : nil
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        if use24HourClock {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.timeStyle = showSeconds ? .medium : .short
        }
        return formatter.string(from: currentTime)
    }
    
    private var hasContent: Bool {
        showCustomText || showSFSymbol || showTime || showBattery || showNetworkStatus || showMemoryUsage || widgetType != .none
    }
    
    private var batteryIconName: String {
        switch batteryState {
        case .charging, .full:
            return "battery.100.bolt"
        case .unplugged:
            if batteryLevel >= 0.75 {
                return "battery.100"
            } else if batteryLevel >= 0.50 {
                return "battery.75"
            } else if batteryLevel >= 0.25 {
                return "battery.50"
            } else {
                return "battery.25"
            }
        default:
            return "battery.0"
        }
    }
    
    private func getBatteryColor() -> Color {
        if !batteryUseAutoColor {
            return batteryAccentColored ? Color.accentColor : SwiftUI.Color(hex: batteryColorHex)
        }
        
        // Auto color based on battery level
        if batteryState == .charging || batteryState == .full {
            return .green
        } else if batteryLevel <= 0.2 {
            return .red
        } else if batteryLevel <= 0.5 {
            return .yellow
        } else if batteryLevel <= 0.8 {
            return .green
        } else {
            return .white
        }
    }

    // Get safe area insets for notch/Dynamic Island handling
    private var safeAreaTopInset: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.top ?? 0
    }
    
    var body: some View {
        if hasContent {
            ZStack {
                // Always overlay to hide default status bar area
                Color.black
                    .opacity(nearlyTransparentOpacity)
                    .frame(height: max(50, safeAreaTopInset + 10)) // Dynamically adjust for notch/Dynamic Island
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    ZStack {
                        // Time display with its own layout
                        if showTime {
                            HStack {
                                if getAlignment(for: timeAlignment) == .center || getAlignment(for: timeAlignment) == .trailing {
                                    Spacer()
                                }
                                
                                styledText(timeString)
                                    .animation(timeAnimation, value: timeString)
                                    .padding(.leading, timeLeftPadding)
                                    .padding(.trailing, timeRightPadding)
                                    .padding(.top, timeTopPadding)
                                    .padding(.bottom, timeBottomPadding)
                                
                                if getAlignment(for: timeAlignment) == .center || getAlignment(for: timeAlignment) == .leading {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Custom text with its own layout
                        if showCustomText && !customText.isEmpty {
                            HStack {
                                if getAlignment(for: textAlignment) == .center || getAlignment(for: textAlignment) == .trailing {
                                    Spacer()
                                }
                                
                                styledText(customText)
                                    .padding(.leading, textLeftPadding)
                                    .padding(.trailing, textRightPadding)
                                    .padding(.top, textTopPadding)
                                    .padding(.bottom, textBottomPadding)
                                
                                if getAlignment(for: textAlignment) == .center || getAlignment(for: textAlignment) == .leading {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // SF Symbol with its own layout
                        if showSFSymbol && !sfSymbol.isEmpty {
                            HStack {
                                if getAlignment(for: sfSymbolAlignment) == .center || getAlignment(for: sfSymbolAlignment) == .trailing {
                                    Spacer()
                                }
                                
                                styledSymbol(sfSymbol)
                                    .padding(.leading, sfSymbolLeftPadding)
                                    .padding(.trailing, sfSymbolRightPadding)
                                    .padding(.top, sfSymbolTopPadding)
                                    .padding(.bottom, sfSymbolBottomPadding)
                                
                                if getAlignment(for: sfSymbolAlignment) == .center || getAlignment(for: sfSymbolAlignment) == .leading {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Battery display with its own layout (new standalone)
                        if showBattery {
                            HStack {
                                if getAlignment(for: batteryAlignment) == .center || getAlignment(for: batteryAlignment) == .trailing {
                                    Spacer()
                                }
                                
                                HStack(spacing: 2) {
                                    if batteryStyle == "icon" || batteryStyle == "both" {
                                        Image(systemName: batteryIconName)
                                            .font(.system(size: fontSize * 0.9))
                                    }
                                    if batteryStyle == "percentage" || batteryStyle == "both" {
                                        Text("\(Int(batteryLevel * 100))%")
                                            .font(.system(size: fontSize * 0.8, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                                    }
                                }
                                .foregroundStyle(getBatteryColor())
                                .padding(.leading, batteryLeftPadding)
                                .padding(.trailing, batteryRightPadding)
                                .padding(.top, batteryTopPadding)
                                .padding(.bottom, batteryBottomPadding)
                                
                                if getAlignment(for: batteryAlignment) == .center || getAlignment(for: batteryAlignment) == .leading {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Network Status display
                        if showNetworkStatus {
                            HStack {
                                Spacer()
                                networkStatusView
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Memory Usage display
                        if showMemoryUsage {
                            HStack {
                                Spacer()
                                memoryUsageView
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Widget display with its own layout (legacy support)
                        if widgetType != .none {
                            HStack {
                                if getAlignment(for: batteryAlignment) == .center || getAlignment(for: batteryAlignment) == .trailing {
                                    Spacer()
                                }
                                
                                buildWidget()
                                    .padding(.leading, batteryLeftPadding)
                                    .padding(.trailing, batteryRightPadding)
                                    .padding(.top, batteryTopPadding)
                                    .padding(.bottom, batteryBottomPadding)
                                
                                if getAlignment(for: batteryAlignment) == .center || getAlignment(for: batteryAlignment) == .leading {
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, max(8, safeAreaTopInset - 35)) // Dynamically adjust for notch/Dynamic Island
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : (animationType == "scale" ? 0.8 : 1))
                    .offset(y: isVisible ? 0 : (animationType == "slide" ? -20 : 0))
                    
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .zIndex(10000)
            .onAppear {
                currentTime = Date()
                // Start battery monitoring if battery is displayed
                if showBattery {
                    UIDevice.current.isBatteryMonitoringEnabled = true
                    batteryLevel = UIDevice.current.batteryLevel
                    batteryState = UIDevice.current.batteryState
                }
                // Update memory usage
                if showMemoryUsage {
                    updateMemoryUsage()
                }
                if enableAnimation {
                    withAnimation(contentAnimation) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
            .onDisappear {
                // Stop battery monitoring when view disappears
                if showBattery {
                    UIDevice.current.isBatteryMonitoringEnabled = false
                }
            }
            .onReceive(timer) { time in
                currentTime = time
                // Update battery info if battery is displayed
                if showBattery {
                    batteryLevel = UIDevice.current.batteryLevel
                    batteryState = UIDevice.current.batteryState
                }
                // Update memory usage periodically
                if showMemoryUsage {
                    updateMemoryUsage()
                }
            }
        }
    }
    
    // MARK: - Network Status View
    @ViewBuilder
    private var networkStatusView: some View {
        let color = Color(hex: colorHex)
        
        switch networkIconStyle {
        case "bars":
            Image(systemName: isConnected ? "wifi" : "wifi.slash")
                .font(.system(size: fontSize))
                .foregroundStyle(isConnected ? color : .red)
        case "dot":
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        case "text":
            Text(isConnected ? "Online" : "Offline")
                .font(.system(size: fontSize * 0.8, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                .foregroundStyle(isConnected ? color : .red)
        default:
            Image(systemName: "wifi")
                .font(.system(size: fontSize))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Memory Usage View
    @ViewBuilder
    private var memoryUsageView: some View {
        let color = Color(hex: colorHex)
        
        switch memoryDisplayStyle {
        case "percentage":
            Text("\(Int(memoryUsage))%")
                .font(.system(size: fontSize * 0.9, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                .foregroundStyle(color)
        case "mb":
            Text("\(Int(getMemoryMB())) MB")
                .font(.system(size: fontSize * 0.9, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                .foregroundStyle(color)
        case "both":
            HStack(spacing: 4) {
                Text("\(Int(memoryUsage))%")
                Text("·")
                Text("\(Int(getMemoryMB())) MB")
            }
            .font(.system(size: fontSize * 0.8, weight: isBold ? .bold : .regular, design: selectedFontDesign))
            .foregroundStyle(color)
        default:
            Text("\(Int(memoryUsage))%")
                .font(.system(size: fontSize * 0.9, weight: isBold ? .bold : .regular, design: selectedFontDesign))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Memory Helpers
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            memoryUsage = (usedMemory / totalMemory) * 100
        }
    }
    
    private func getMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024
        }
        return 0
    }
    
    @ViewBuilder
    private func buildWidget() -> some View {
        let widgetColor = widgetAccentColored ? SwiftUI.Color(hex: colorHex) : SwiftUI.Color(hex: batteryColorHex)
        
        switch widgetType {
        case .none:
            EmptyView()
        case .text:
            if !customText.isEmpty {
                styledText(customText)
            }
        case .sfSymbol:
            if !sfSymbol.isEmpty {
                styledSymbol(sfSymbol)
            }
        case .battery:
            SystemBatteryView()
                .foregroundStyle(widgetColor)
                .frame(width: 60)
        }
    }
    
    // MARK: - Styled Text with Gradient and Glow
    @ViewBuilder
    private func styledText(_ text: String) -> some View {
        let baseText = Text(text)
            .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
            .lineLimit(1)
        
        if useGradientText {
            if enableGlow {
                baseText
                    .foregroundStyle(textGradient)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity), radius: glowRadius, x: 0, y: 0)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity * 0.5), radius: glowRadius * 1.5, x: 0, y: 0)
            } else {
                baseText
                    .foregroundStyle(textGradient)
            }
        } else {
            if enableGlow {
                baseText
                    .foregroundStyle(SwiftUI.Color(hex: colorHex))
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity), radius: glowRadius, x: 0, y: 0)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity * 0.5), radius: glowRadius * 1.5, x: 0, y: 0)
            } else {
                baseText
                    .foregroundStyle(SwiftUI.Color(hex: colorHex))
            }
        }
    }
    
    // MARK: - Styled Symbol with Gradient and Glow
    @ViewBuilder
    private func styledSymbol(_ symbolName: String) -> some View {
        let baseSymbol = Image(systemName: symbolName)
            .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: selectedFontDesign))
        
        if useGradientText {
            if enableGlow {
                baseSymbol
                    .foregroundStyle(textGradient)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity), radius: glowRadius, x: 0, y: 0)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity * 0.5), radius: glowRadius * 1.5, x: 0, y: 0)
            } else {
                baseSymbol
                    .foregroundStyle(textGradient)
            }
        } else {
            if enableGlow {
                baseSymbol
                    .foregroundStyle(SwiftUI.Color(hex: colorHex))
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity), radius: glowRadius, x: 0, y: 0)
                    .shadow(color: Color(hex: glowColorHex).opacity(glowIntensity * 0.5), radius: glowRadius * 1.5, x: 0, y: 0)
            } else {
                baseSymbol
                    .foregroundStyle(SwiftUI.Color(hex: colorHex))
            }
        }
    }
}
