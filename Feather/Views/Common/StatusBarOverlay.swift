import SwiftUI

struct StatusBarOverlay: View {
    // MARK: - App Storage Properties
    @AppStorage("statusBar.customText") private var customText: String = ""
    @AppStorage("statusBar.showCustomText") private var showCustomText: Bool = false
    @AppStorage("statusBar.sfSymbol") private var sfSymbol: String = "circle.fill"
    @AppStorage("statusBar.showSFSymbol") private var showSFSymbol: Bool = false
    @AppStorage("statusBar.bold") private var isBold: Bool = false
    @AppStorage("statusBar.color") private var colorHex: String = "#007AFF"
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
    @AppStorage("statusBar.useGradientText") private var useGradientText: Bool = false
    @AppStorage("statusBar.gradientStartColor") private var gradientStartColorHex: String = "#007AFF"
    @AppStorage("statusBar.gradientEndColor") private var gradientEndColorHex: String = "#5856D6"
    @AppStorage("statusBar.gradientAngle") private var gradientAngle: Double = 0
    @AppStorage("statusBar.enableGlow") private var enableGlow: Bool = false
    @AppStorage("statusBar.glowColor") private var glowColorHex: String = "#007AFF"
    @AppStorage("statusBar.glowRadius") private var glowRadius: Double = 4
    @AppStorage("statusBar.glowIntensity") private var glowIntensity: Double = 0.5
    @AppStorage("statusBar.textAlignment") private var textAlignment: String = "center"
    @AppStorage("statusBar.textLeftPadding") private var textLeftPadding: Double = 0
    @AppStorage("statusBar.textRightPadding") private var textRightPadding: Double = 0
    @AppStorage("statusBar.textTopPadding") private var textTopPadding: Double = 0
    @AppStorage("statusBar.textBottomPadding") private var textBottomPadding: Double = 0
    @AppStorage("statusBar.sfSymbolAlignment") private var sfSymbolAlignment: String = "center"
    @AppStorage("statusBar.sfSymbolLeftPadding") private var sfSymbolLeftPadding: Double = 0
    @AppStorage("statusBar.sfSymbolRightPadding") private var sfSymbolRightPadding: Double = 0
    @AppStorage("statusBar.sfSymbolTopPadding") private var sfSymbolTopPadding: Double = 0
    @AppStorage("statusBar.sfSymbolBottomPadding") private var sfSymbolBottomPadding: Double = 0
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
    @AppStorage("statusBar.widgetType") private var widgetTypeRaw: String = "none"
    @AppStorage("statusBar.widgetAccentColored") private var widgetAccentColored: Bool = false
    @AppStorage("statusBar.showNetworkStatus") private var showNetworkStatus: Bool = false
    @AppStorage("statusBar.networkIconStyle") private var networkIconStyle: String = "bars"
    @AppStorage("statusBar.showMemoryUsage") private var showMemoryUsage: Bool = false
    @AppStorage("statusBar.memoryDisplayStyle") private var memoryDisplayStyle: String = "percentage"
    
    // MARK: - State Properties
    @State private var isVisible = false
    @State private var isConnected = true
    @State private var memoryUsage: Double = 0
    @State private var currentTime = Date()
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed Properties
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
            if batteryLevel >= 0.75 { return "battery.100" }
            else if batteryLevel >= 0.50 { return "battery.75" }
            else if batteryLevel >= 0.25 { return "battery.50" }
            else { return "battery.25" }
        default:
            return "battery.0"
        }
    }
    
    private var safeAreaTopInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
    }
    
    // MARK: - Helper Functions
    private func getAlignment(for type: String) -> Alignment {
        switch type {
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        default: return .center
        }
    }
    
    private func getBatteryColor() -> Color {
        if !batteryUseAutoColor {
            return batteryAccentColored ? Color.accentColor : SwiftUI.Color(hex: batteryColorHex)
        }
        if batteryState == .charging || batteryState == .full { return .green }
        else if batteryLevel <= 0.2 { return .red }
        else if batteryLevel <= 0.5 { return .yellow }
        else { return .green }
    }
    
    // MARK: - Body
    var body: some View {
        if hasContent {
            GeometryReader { geometry in
                statusBarContent(geometry: geometry)
            }
            .frame(height: max(50, safeAreaTopInset + 10))
            .zIndex(10000)
            .onAppear(perform: setupOnAppear)
            .onDisappear(perform: cleanupOnDisappear)
            .onReceive(timer, perform: updateOnTimer)
        }
    }
    
    // MARK: - Status Bar Content
    @ViewBuilder
    private func statusBarContent(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            // Invisible overlay for status bar area
            Color.clear
                .frame(height: max(50, safeAreaTopInset + 10))
                .allowsHitTesting(false)
            
            // Content container
            HStack(spacing: 12) {
                // Leading items
                leadingContent
                
                Spacer(minLength: 0)
                
                // Center items
                centerContent
                
                Spacer(minLength: 0)
                
                // Trailing items
                trailingContent
            }
            .padding(.horizontal, 16)
            .padding(.top, max(8, safeAreaTopInset - 35))
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : (animationType == "scale" ? 0.8 : 1))
            .offset(y: isVisible ? 0 : (animationType == "slide" ? -20 : 0))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - Content Sections
    @ViewBuilder
    private var leadingContent: some View {
        HStack(spacing: 8) {
            if showTime && getAlignment(for: timeAlignment) == .leading {
                timeView
            }
            if showCustomText && !customText.isEmpty && getAlignment(for: textAlignment) == .leading {
                styledText(customText)
            }
            if showSFSymbol && !sfSymbol.isEmpty && getAlignment(for: sfSymbolAlignment) == .leading {
                styledSymbol(sfSymbol)
            }
            if showBattery && getAlignment(for: batteryAlignment) == .leading {
                batteryView
            }
            if showNetworkStatus {
                networkStatusView
            }
        }
    }
    
    @ViewBuilder
    private var centerContent: some View {
        HStack(spacing: 8) {
            if showTime && getAlignment(for: timeAlignment) == .center {
                timeView
            }
            if showCustomText && !customText.isEmpty && getAlignment(for: textAlignment) == .center {
                styledText(customText)
            }
            if showSFSymbol && !sfSymbol.isEmpty && getAlignment(for: sfSymbolAlignment) == .center {
                styledSymbol(sfSymbol)
            }
            if showBattery && getAlignment(for: batteryAlignment) == .center {
                batteryView
            }
            if showMemoryUsage {
                memoryUsageView
            }
            if widgetType != .none {
                buildWidget()
            }
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        HStack(spacing: 8) {
            if showTime && getAlignment(for: timeAlignment) == .trailing {
                timeView
            }
            if showCustomText && !customText.isEmpty && getAlignment(for: textAlignment) == .trailing {
                styledText(customText)
            }
            if showSFSymbol && !sfSymbol.isEmpty && getAlignment(for: sfSymbolAlignment) == .trailing {
                styledSymbol(sfSymbol)
            }
            if showBattery && getAlignment(for: batteryAlignment) == .trailing {
                batteryView
            }
        }
    }
    
    // MARK: - Individual Views
    @ViewBuilder
    private var timeView: some View {
        styledText(timeString)
            .animation(timeAnimation, value: timeString)
            .padding(.leading, timeLeftPadding)
            .padding(.trailing, timeRightPadding)
            .padding(.top, timeTopPadding)
            .padding(.bottom, timeBottomPadding)
    }
    
    @ViewBuilder
    private var batteryView: some View {
        HStack(spacing: 4) {
            if batteryStyle == "icon" || batteryStyle == "both" {
                Image(systemName: batteryIconName)
                    .font(.system(size: fontSize * 0.9, weight: isBold ? .semibold : .regular))
            }
            if batteryStyle == "percentage" || batteryStyle == "both" {
                Text("\(Int(batteryLevel * 100))%")
                    .font(.system(size: fontSize * 0.85, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
            }
        }
        .foregroundStyle(getBatteryColor())
        .padding(.leading, batteryLeftPadding)
        .padding(.trailing, batteryRightPadding)
        .padding(.top, batteryTopPadding)
        .padding(.bottom, batteryBottomPadding)
    }
    
    // MARK: - Network Status View
    @ViewBuilder
    private var networkStatusView: some View {
        let color = Color(hex: colorHex)
        
        Group {
            switch networkIconStyle {
            case "bars":
                Image(systemName: isConnected ? "wifi" : "wifi.slash")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(isConnected ? color : .red)
            case "dot":
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            case "text":
                Text(isConnected ? "Online" : "Offline")
                    .font(.system(size: fontSize * 0.8, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
                    .foregroundStyle(isConnected ? color : .red)
            default:
                Image(systemName: "wifi")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(color)
            }
        }
    }
    
    // MARK: - Memory Usage View
    @ViewBuilder
    private var memoryUsageView: some View {
        let color = Color(hex: colorHex)
        
        Group {
            switch memoryDisplayStyle {
            case "percentage":
                Text("\(Int(memoryUsage))%")
                    .font(.system(size: fontSize * 0.9, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
                    .foregroundStyle(color)
            case "mb":
                Text("\(Int(getMemoryMB())) MB")
                    .font(.system(size: fontSize * 0.9, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
                    .foregroundStyle(color)
            case "both":
                HStack(spacing: 4) {
                    Text("\(Int(memoryUsage))%")
                    Text("·")
                    Text("\(Int(getMemoryMB())) MB")
                }
                .font(.system(size: fontSize * 0.8, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
                .foregroundStyle(color)
            default:
                Text("\(Int(memoryUsage))%")
                    .font(.system(size: fontSize * 0.9, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
                    .foregroundStyle(color)
            }
        }
    }
    
    // MARK: - Lifecycle Methods
    private func setupOnAppear() {
        currentTime = Date()
        if showBattery {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
            batteryState = UIDevice.current.batteryState
        }
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
    
    private func cleanupOnDisappear() {
        if showBattery {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }
    
    private func updateOnTimer(_ time: Date) {
        currentTime = time
        if showBattery {
            batteryLevel = UIDevice.current.batteryLevel
            batteryState = UIDevice.current.batteryState
        }
        if showMemoryUsage {
            updateMemoryUsage()
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
    
    // MARK: - Widget Builder
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
    
    // MARK: - Styled Text
    @ViewBuilder
    private func styledText(_ text: String) -> some View {
        let baseText = Text(text)
            .font(.system(size: fontSize, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
            .lineLimit(1)
        
        if useGradientText {
            baseText
                .foregroundStyle(textGradient)
                .modifier(GlowModifier(enabled: enableGlow, color: Color(hex: glowColorHex), intensity: glowIntensity, radius: glowRadius))
        } else {
            baseText
                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                .modifier(GlowModifier(enabled: enableGlow, color: Color(hex: glowColorHex), intensity: glowIntensity, radius: glowRadius))
        }
    }
    
    // MARK: - Styled Symbol
    @ViewBuilder
    private func styledSymbol(_ symbolName: String) -> some View {
        let baseSymbol = Image(systemName: symbolName)
            .font(.system(size: fontSize, weight: isBold ? .semibold : .medium, design: selectedFontDesign))
        
        if useGradientText {
            baseSymbol
                .foregroundStyle(textGradient)
                .modifier(GlowModifier(enabled: enableGlow, color: Color(hex: glowColorHex), intensity: glowIntensity, radius: glowRadius))
        } else {
            baseSymbol
                .foregroundStyle(SwiftUI.Color(hex: colorHex))
                .modifier(GlowModifier(enabled: enableGlow, color: Color(hex: glowColorHex), intensity: glowIntensity, radius: glowRadius))
        }
    }
}

// MARK: - Glow Modifier
private struct GlowModifier: ViewModifier {
    let enabled: Bool
    let color: Color
    let intensity: Double
    let radius: Double
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
                .shadow(color: color.opacity(intensity * 0.5), radius: radius * 1.5, x: 0, y: 0)
        } else {
            content
        }
    }
}
