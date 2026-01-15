import SwiftUI

// MARK: - Configure Layouts View (Splash Screen Style)
struct ConfigureLayoutsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var selectedLayout: LayoutType = .text
    @State private var floatingAnimation = false
    
    enum LayoutType: String, CaseIterable {
        case text = "Text"
        case sfSymbol = "SF Symbol"
        case time = "Time"
        case battery = "Battery"
        case network = "Network"
        case memory = "Memory"
        case date = "Date"
        case cpu = "CPU"
        
        var icon: String {
            switch self {
            case .text: return "textformat"
            case .sfSymbol: return "star.fill"
            case .time: return "clock.fill"
            case .battery: return "battery.100"
            case .network: return "wifi"
            case .memory: return "memorychip.fill"
            case .date: return "calendar"
            case .cpu: return "cpu.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .blue
            case .sfSymbol: return .purple
            case .time: return .orange
            case .battery: return .green
            case .network: return .cyan
            case .memory: return .pink
            case .date: return .indigo
            case .cpu: return .red
            }
        }
        
        var description: String {
            switch self {
            case .text: return "Custom text display"
            case .sfSymbol: return "SF Symbol icons"
            case .time: return "Current time"
            case .battery: return "Battery status"
            case .network: return "Network connectivity"
            case .memory: return "Memory usage"
            case .date: return "Current date"
            case .cpu: return "CPU performance"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern animated background
                modernBackground
                
                VStack(spacing: 0) {
                    // Top section with icon grid
                    modernLayoutSelector
                        .padding(.top, 16)
                    
                    // Bottom section with controls
                    ScrollView {
                        VStack(spacing: 20) {
                            // Info card
                            infoCard
                            
                            // Layout controls
                            layoutControls
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Configure Layouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }
    
    // MARK: - Modern Background
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.12),
                    Color.accentColor.opacity(0.05),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [selectedLayout.color.opacity(0.2), selectedLayout.color.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Modern Layout Selector
    @ViewBuilder
    private var modernLayoutSelector: some View {
        VStack(spacing: 16) {
            Text("Choose Widget Type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Two rows of widgets
            VStack(spacing: 12) {
                // First row
                HStack(spacing: 12) {
                    ForEach(Array(LayoutType.allCases.prefix(4)), id: \.rawValue) { layout in
                        modernLayoutButton(layout: layout)
                    }
                }
                
                // Second row
                HStack(spacing: 12) {
                    ForEach(Array(LayoutType.allCases.suffix(4)), id: \.rawValue) { layout in
                        modernLayoutButton(layout: layout)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func modernLayoutButton(layout: LayoutType) -> some View {
        let isSelected = selectedLayout == layout
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedLayout = layout
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Glow effect for selected
                    if isSelected {
                        Circle()
                            .fill(layout.color.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                    }
                    
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [layout.color, layout.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(uiColor: .secondarySystemGroupedBackground), Color(uiColor: .secondarySystemGroupedBackground)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ?
                                    LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [.clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: isSelected ? layout.color.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: layout.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .modifier(ConfigureBounceEffectModifier(trigger: isSelected))
                }
                
                Text(layout.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Info Card
    @ViewBuilder
    private var infoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [selectedLayout.color.opacity(0.3), selectedLayout.color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(selectedLayout.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedLayout.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(selectedLayout.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Layout Controls
    private var layoutControls: some View {
        VStack(spacing: 20) {
            // Alignment picker with modern design
            modernAlignmentSection
            
            // Padding controls with modern design
            modernPaddingSection
            
            // Widget-specific options
            widgetSpecificOptions
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - Modern Alignment Section
    @ViewBuilder
    private var modernAlignmentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedLayout.color)
                Text("Alignment")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            let availablePositions = viewModel.getAvailablePositions(for: selectedLayout.rawValue)
            let allAlignments = [StatusBarAlignment.left, StatusBarAlignment.center, StatusBarAlignment.right]
            
            HStack(spacing: 10) {
                ForEach(allAlignments, id: \.rawValue) { alignment in
                    let position = alignment.rawValue
                    let isAvailable = availablePositions.contains(position)
                    let isSelected = getAlignment() == position
                    
                    Button {
                        if isAvailable {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                setAlignment(position)
                            }
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: alignmentIcon(for: position))
                                .font(.system(size: 16, weight: .semibold))
                            Text(position.capitalized)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(isAvailable ? (isSelected ? .white : .primary) : .secondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    isSelected ?
                                    LinearGradient(colors: [selectedLayout.color, selectedLayout.color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(uiColor: .tertiarySystemGroupedBackground), Color(uiColor: .tertiarySystemGroupedBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? selectedLayout.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isAvailable)
                }
            }
            
            if !availablePositions.contains("center") && getAlignment() != "center" {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Center position is occupied by another widget")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    private func alignmentIcon(for position: String) -> String {
        switch position {
        case "left": return "text.alignleft"
        case "center": return "text.aligncenter"
        case "right": return "text.alignright"
        default: return "text.aligncenter"
        }
    }
    
    // MARK: - Modern Padding Section
    @ViewBuilder
    private var modernPaddingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedLayout.color)
                Text("Padding")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            VStack(spacing: 12) {
                modernPaddingControl(title: "Left", icon: "arrow.left", value: leftPaddingBinding)
                modernPaddingControl(title: "Right", icon: "arrow.right", value: rightPaddingBinding)
                modernPaddingControl(title: "Top", icon: "arrow.up", value: topPaddingBinding)
                modernPaddingControl(title: "Bottom", icon: "arrow.down", value: bottomPaddingBinding)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private func modernPaddingControl(title: String, icon: String, value: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(selectedLayout.color)
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(value.wrappedValue)) pt")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )
            }
            
            Slider(value: value, in: 0...100, step: 1)
                .tint(selectedLayout.color)
        }
    }
    
    // MARK: - Widget Specific Options
    @ViewBuilder
    private var widgetSpecificOptions: some View {
        switch selectedLayout {
        case .network:
            networkOptions
        case .memory:
            memoryOptions
        case .battery:
            batteryOptions
        case .date:
            dateOptions
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var networkOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("Network Options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Toggle(isOn: $viewModel.showNetworkStatus) {
                HStack {
                    Text("Show Network Status")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .tint(.cyan)
            
            if viewModel.showNetworkStatus {
                Picker("Display Style", selection: $viewModel.networkIconStyle) {
                    Text("Bars").tag("bars")
                    Text("Dot").tag("dot")
                    Text("Text").tag("text")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private var memoryOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.pink)
                Text("Memory Options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Toggle(isOn: $viewModel.showMemoryUsage) {
                HStack {
                    Text("Show Memory Usage")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .tint(.pink)
            
            if viewModel.showMemoryUsage {
                Picker("Display Style", selection: $viewModel.memoryDisplayStyle) {
                    Text("Percentage").tag("percentage")
                    Text("MB").tag("mb")
                    Text("Both").tag("both")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private var batteryOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "battery.100")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
                Text("Battery Options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Toggle(isOn: $viewModel.showBattery) {
                HStack {
                    Text("Show Battery")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .tint(.green)
            
            if viewModel.showBattery {
                Picker("Display Style", selection: $viewModel.batteryStyle) {
                    Text("Icon").tag("icon")
                    Text("Percentage").tag("percentage")
                    Text("Both").tag("both")
                }
                .pickerStyle(.segmented)
                
                Toggle(isOn: $viewModel.batteryUseAutoColor) {
                    Text("Auto Color Based on Level")
                        .font(.subheadline)
                }
                .tint(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private var dateOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.indigo)
                Text("Date Options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Toggle(isOn: $viewModel.showDate) {
                HStack {
                    Text("Show Date")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .tint(.indigo)
            
            if viewModel.showDate {
                Toggle(isOn: $viewModel.showWeekday) {
                    Text("Show Weekday")
                        .font(.subheadline)
                }
                .tint(.indigo)
                
                Picker("Date Format", selection: $viewModel.dateFormat) {
                    Text("Short").tag("short")
                    Text("Medium").tag("medium")
                    Text("Long").tag("long")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Padding Bindings
    private var leftPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textLeftPadding
        case .sfSymbol: return $viewModel.sfSymbolLeftPadding
        case .time: return $viewModel.timeLeftPadding
        case .battery, .network, .memory, .date, .cpu: return $viewModel.batteryLeftPadding
        }
    }
    
    private var rightPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textRightPadding
        case .sfSymbol: return $viewModel.sfSymbolRightPadding
        case .time: return $viewModel.timeRightPadding
        case .battery, .network, .memory, .date, .cpu: return $viewModel.batteryRightPadding
        }
    }
    
    private var topPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textTopPadding
        case .sfSymbol: return $viewModel.sfSymbolTopPadding
        case .time: return $viewModel.timeTopPadding
        case .battery, .network, .memory, .date, .cpu: return $viewModel.batteryTopPadding
        }
    }
    
    private var bottomPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textBottomPadding
        case .sfSymbol: return $viewModel.sfSymbolBottomPadding
        case .time: return $viewModel.timeBottomPadding
        case .battery, .network, .memory, .date, .cpu: return $viewModel.batteryBottomPadding
        }
    }
    
    // Helper methods for alignment
    private func getAlignment() -> String {
        switch selectedLayout {
        case .text: return viewModel.textAlignment
        case .sfSymbol: return viewModel.sfSymbolAlignment
        case .time: return viewModel.timeAlignment
        case .battery, .network, .memory, .date, .cpu: return viewModel.batteryAlignment
        }
    }
    
    private func setAlignment(_ position: String) {
        switch selectedLayout {
        case .text: viewModel.textAlignment = position
        case .sfSymbol: viewModel.sfSymbolAlignment = position
        case .time: viewModel.timeAlignment = position
        case .battery, .network, .memory, .date, .cpu: viewModel.batteryAlignment = position
        }
    }
}

// MARK: - iOS 17 Symbol Effect Compatibility Modifier
struct ConfigureBounceEffectModifier: ViewModifier {
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
    }
}

// MARK: - Preview
#Preview {
    ConfigureLayoutsView(viewModel: StatusBarViewModel())
}
