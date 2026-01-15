import SwiftUI
import UIKit

/// A view that displays the system battery level and charging state with proper indicators
struct SystemBatteryView: View {
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var isLowPowerMode: Bool = false
    @State private var pulseAnimation: Bool = false
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            // Battery icon with proper state indication
            ZStack {
                Image(systemName: batteryIconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(batteryColor)
                
                // Charging bolt overlay for charging state
                if batteryState == .charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.yellow)
                        .offset(x: -1)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                }
            }
            
            // Battery percentage with state indicator
            HStack(spacing: 2) {
                Text("\(Int(max(0, batteryLevel) * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                
                // State indicators
                if batteryState == .full {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                }
                
                if isLowPowerMode {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .onAppear {
            enableBatteryMonitoring()
            updateBatteryInfo()
            startChargingAnimation()
        }
        .onDisappear {
            disableBatteryMonitoring()
        }
        .onReceive(timer) { _ in
            updateBatteryInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            updateBatteryInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            updateBatteryInfo()
            startChargingAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)) { _ in
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
    
    private var batteryIconName: String {
        // Handle unknown/simulator state
        if batteryLevel < 0 {
            return "battery.100"
        }
        
        switch batteryState {
        case .charging:
            // Show appropriate charging icon based on level
            if batteryLevel >= 0.95 {
                return "battery.100"
            } else if batteryLevel >= 0.75 {
                return "battery.75"
            } else if batteryLevel >= 0.50 {
                return "battery.50"
            } else if batteryLevel >= 0.25 {
                return "battery.25"
            } else {
                return "battery.25"
            }
        case .full:
            return "battery.100"
        case .unplugged:
            if batteryLevel >= 0.95 {
                return "battery.100"
            } else if batteryLevel >= 0.75 {
                return "battery.75"
            } else if batteryLevel >= 0.50 {
                return "battery.50"
            } else if batteryLevel >= 0.25 {
                return "battery.25"
            } else if batteryLevel >= 0.10 {
                return "battery.25"
            } else {
                return "battery.0"
            }
        default:
            return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        // Handle unknown/simulator state
        if batteryLevel < 0 {
            return .primary
        }
        
        switch batteryState {
        case .charging:
            return .green
        case .full:
            return .green
        case .unplugged:
            if batteryLevel <= 0.10 {
                return .red
            } else if batteryLevel <= 0.20 {
                return .orange
            } else if batteryLevel <= 0.40 {
                return .yellow
            } else {
                return .primary
            }
        default:
            return .primary
        }
    }
    
    private func enableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    private func disableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private func startChargingAnimation() {
        if batteryState == .charging {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        } else {
            pulseAnimation = false
        }
    }
}

// MARK: - Enhanced Battery View with More Details
struct EnhancedBatteryView: View {
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var isLowPowerMode: Bool = false
    @State private var chargingAnimation: Bool = false
    
    var showPercentage: Bool = true
    var showStateText: Bool = false
    var style: BatteryDisplayStyle = .compact
    
    enum BatteryDisplayStyle {
        case compact
        case detailed
        case iconOnly
    }
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: style == .detailed ? 8 : 4) {
            // Battery visual
            batteryVisual
            
            if style != .iconOnly {
                VStack(alignment: .leading, spacing: 1) {
                    if showPercentage {
                        Text("\(Int(max(0, batteryLevel) * 100))%")
                            .font(.system(size: style == .detailed ? 14 : 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    
                    if showStateText && style == .detailed {
                        Text(stateText)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBatteryInfo()
            startAnimations()
        }
        .onDisappear {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
        .onReceive(timer) { _ in
            updateBatteryInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            updateBatteryInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            updateBatteryInfo()
            startAnimations()
        }
    }
    
    @ViewBuilder
    private var batteryVisual: some View {
        ZStack {
            // Battery outline
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(batteryColor.opacity(0.5), lineWidth: 1.5)
                .frame(width: 24, height: 12)
            
            // Battery fill
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(batteryColor)
                    .frame(width: max(0, CGFloat(batteryLevel) * 20), height: 8)
                Spacer(minLength: 0)
            }
            .frame(width: 20, height: 8)
            
            // Battery cap
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(batteryColor.opacity(0.5))
                .frame(width: 2, height: 5)
                .offset(x: 13)
            
            // Charging indicator
            if batteryState == .charging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(chargingAnimation ? 1.1 : 0.9)
            }
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel < 0 { return .primary }
        
        switch batteryState {
        case .charging, .full:
            return .green
        case .unplugged:
            if batteryLevel <= 0.10 { return .red }
            else if batteryLevel <= 0.20 { return .orange }
            else if batteryLevel <= 0.40 { return .yellow }
            else { return .green }
        default:
            return .primary
        }
    }
    
    private var stateText: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Fully Charged"
        case .unplugged:
            if isLowPowerMode { return "Low Power Mode" }
            return "On Battery"
        default: return "Unknown"
        }
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private func startAnimations() {
        if batteryState == .charging {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                chargingAnimation = true
            }
        } else {
            chargingAnimation = false
        }
    }
}
