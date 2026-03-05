import SwiftUI

// MARK: - Status Bar Preview (Read-Only)
struct StatusBarPreviewView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var currentTime = Date()
    @State private var batteryLevel: Float = 0.0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var selectedFontDesign: Font.Design {
        switch viewModel.fontDesign {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }
    
    private var selectedAlignment: Alignment {
        switch viewModel.alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with gradient
            VStack(spacing: 8) {
                Text("Status Bar Preview")
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("See how your customizations look on different devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Display device model
            Text(viewModel.selectedDeviceType.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            
            // Device selection with improved styling
            HStack(spacing: 12) {
                Menu {
                    ForEach(DeviceType.allCases) { device in
                        Button {
                            viewModel.selectedDeviceType = device
                        } label: {
                            HStack {
                                Text(device.rawValue)
                                if viewModel.selectedDeviceType == device {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "iphone")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Device")
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                Menu {
                    ForEach(DeviceColor.allCases) { color in
                        Button {
                            viewModel.selectedDeviceColor = color
                        } label: {
                            HStack {
                                Circle()
                                    .fill(color.colorValue)
                                    .frame(width: 16, height: 16)
                                Text(color.rawValue)
                                if viewModel.selectedDeviceColor == color {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.selectedDeviceColor.colorValue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        Text("Color")
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            
            Divider()
                .padding(.horizontal)
            
            // iPhone mockup container with dynamic device
            ZStack {
                // iPhone shape with dynamic color
                RoundedRectangle(cornerRadius: viewModel.selectedDeviceType.cornerRadius)
                    .fill(viewModel.selectedDeviceColor.colorValue)
                    .overlay(
                        RoundedRectangle(cornerRadius: viewModel.selectedDeviceType.cornerRadius)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    )
                    .frame(width: viewModel.selectedDeviceType.dimensions.width, 
                           height: viewModel.selectedDeviceType.dimensions.height)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                
                VStack(spacing: 0) {
                    // Status bar area with notch
                    statusBarContent
                    
                    // iPhone content area
                    Rectangle()
                        .fill(Color.clear.opacity(0.5))
                    
                    // Bottom safe area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 30)
                }
                .frame(width: viewModel.selectedDeviceType.dimensions.width - 20, 
                       height: viewModel.selectedDeviceType.dimensions.height - 20)
                .clipShape(RoundedRectangle(cornerRadius: viewModel.selectedDeviceType.cornerRadius - 5))
            }
            .padding(.vertical, 8)
            .allowsHitTesting(false) // Disable hit testing on the preview
            
            // Info footer
            Text("This is a live preview of your Status Bar customizations")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            BatteryMonitoringService.shared.startMonitoring()
            updateBatteryInfo()
        }
        .onDisappear {
            BatteryMonitoringService.shared.stopMonitoring()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateBatteryInfo()
        }
    }
    
    // MARK: - Status Bar Content
    private var statusBarContent: some View {
        ZStack(alignment: selectedAlignment) {
            // Notch background
            Color.clear
                .frame(height: 50)
            
            // Background with shadow for better visibility
            if viewModel.showBackground {
                Group {
                    if viewModel.blurBackground {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .fill(Color(hex: viewModel.backgroundColorHex).opacity(viewModel.backgroundOpacity))
                            )
                    } else {
                        Capsule()
                            .fill(Color(hex: viewModel.backgroundColorHex).opacity(viewModel.backgroundOpacity))
                    }
                }
                .frame(width: 200)
                .cornerRadius(viewModel.cornerRadius)
                .overlay(
                    Capsule()
                        .stroke(Color(hex: viewModel.borderColorHex), lineWidth: viewModel.borderWidth)
                        .cornerRadius(viewModel.cornerRadius)
                )
            }
            
            statusBarWidgets
                .padding(.horizontal, viewModel.showBackground ? 12 : 0)
                .padding(.vertical, viewModel.showBackground ? 6 : 0)
                .padding(.leading, viewModel.leftPadding / 2)
                .padding(.trailing, viewModel.rightPadding / 2)
                .padding(.top, viewModel.topPadding / 2)
                .padding(.bottom, viewModel.bottomPadding / 2)
                .frame(maxWidth: .infinity, alignment: selectedAlignment)
        }
        .frame(height: 50)
    }
    
    // MARK: - Status Bar Widgets
    private var statusBarWidgets: some View {
        HStack(spacing: 0) {
            // Left-aligned widgets
            HStack(spacing: 8) {
                if viewModel.showTime && viewModel.timeAlignment == "left" {
                    timeWidget
                }
                if viewModel.showCustomText && !viewModel.customText.isEmpty && viewModel.textAlignment == "left" {
                    customTextWidget
                }
                if viewModel.showSFSymbol && !viewModel.sfSymbol.isEmpty && viewModel.sfSymbolAlignment == "left" {
                    sfSymbolWidget
                }
                if viewModel.showBattery && viewModel.batteryAlignment == "left" {
                    batteryWidget
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Center-aligned widgets
            HStack(spacing: 8) {
                if viewModel.showTime && viewModel.timeAlignment == "center" {
                    timeWidget
                }
                if viewModel.showCustomText && !viewModel.customText.isEmpty && viewModel.textAlignment == "center" {
                    customTextWidget
                }
                if viewModel.showSFSymbol && !viewModel.sfSymbol.isEmpty && viewModel.sfSymbolAlignment == "center" {
                    sfSymbolWidget
                }
                if viewModel.showBattery && viewModel.batteryAlignment == "center" {
                    batteryWidget
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Right-aligned widgets
            HStack(spacing: 8) {
                if viewModel.showTime && viewModel.timeAlignment == "right" {
                    timeWidget
                }
                if viewModel.showCustomText && !viewModel.customText.isEmpty && viewModel.textAlignment == "right" {
                    customTextWidget
                }
                if viewModel.showSFSymbol && !viewModel.sfSymbol.isEmpty && viewModel.sfSymbolAlignment == "right" {
                    sfSymbolWidget
                }
                if viewModel.showBattery && viewModel.batteryAlignment == "right" {
                    batteryWidget
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var timeWidget: some View {
        Text(timeString)
            .font(.system(size: viewModel.fontSize * 0.8, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
            .foregroundStyle(viewModel.timeAccentColored ? Color.accentColor : Color(hex: viewModel.timeColorHex))
            .lineLimit(1)
    }
    
    private var customTextWidget: some View {
        Text(viewModel.customText)
            .font(.system(size: viewModel.fontSize, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
            .foregroundStyle(Color(hex: viewModel.colorHex))
            .lineLimit(1)
    }
    
    private var sfSymbolWidget: some View {
        Image(systemName: viewModel.sfSymbol)
            .font(.system(size: viewModel.fontSize, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
            .foregroundStyle(Color(hex: viewModel.colorHex))
    }
    
    private var batteryWidget: some View {
        HStack(spacing: 2) {
            if viewModel.batteryStyle == "icon" || viewModel.batteryStyle == "both" {
                Image(systemName: batteryIconName)
                    .font(.system(size: viewModel.fontSize * 0.9))
            }
            if viewModel.batteryStyle == "percentage" || viewModel.batteryStyle == "both" {
                Text("\(Int(batteryLevel * 100))%")
                    .font(.system(size: viewModel.fontSize * 0.8, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
            }
        }
        .foregroundStyle(viewModel.getBatteryColor(level: batteryLevel, charging: batteryState == .charging || batteryState == .full))
    }
    
    private func getWidgetAlignment(_ alignment: String) -> Alignment {
        switch alignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        if viewModel.use24HourClock {
            formatter.dateFormat = viewModel.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.timeStyle = viewModel.showSeconds ? .medium : .short
        }
        return formatter.string(from: currentTime)
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
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }
}

// MARK: - Battery Monitoring Service
// Shared service to manage battery monitoring across multiple views
class BatteryMonitoringService {
    static let shared = BatteryMonitoringService()
    private var monitoringCount = 0
    
    private init() {}
    
    func startMonitoring() {
        monitoringCount += 1
        if monitoringCount == 1 {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }
    
    func stopMonitoring() {
        monitoringCount = max(0, monitoringCount - 1)
        if monitoringCount == 0 {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }
}
