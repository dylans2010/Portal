import SwiftUI

// MARK: - Configure Layouts View (Simplified & Modern)
struct ConfigureLayoutsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var selectedLayout: LayoutType = .text
    
    enum LayoutType: String, CaseIterable {
        case text = "Text"
        case sfSymbol = "SF Symbol"
        case time = "Time"
        case battery = "Battery"
        case network = "Network"
        case memory = "Memory"
        case date = "Date"
        
        var icon: String {
            switch self {
            case .text: return "textformat"
            case .sfSymbol: return "star.fill"
            case .time: return "clock.fill"
            case .battery: return "battery.100"
            case .network: return "wifi"
            case .memory: return "memorychip.fill"
            case .date: return "calendar"
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
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Widget Type Selector
                    widgetTypeSelector
                    
                    // Selected Widget Info
                    selectedWidgetInfo
                    
                    // Position Settings
                    positionSettingsCard
                    
                    // Widget-specific options
                    widgetSpecificOptions
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Configure Layouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Widget Type Selector
    private var widgetTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Widget Type", icon: "square.grid.2x2.fill", color: .accentColor)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(LayoutType.allCases, id: \.rawValue) { layout in
                    widgetTypeButton(layout)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private func widgetTypeButton(_ layout: LayoutType) -> some View {
        let isSelected = selectedLayout == layout
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLayout = layout
                HapticsManager.shared.softImpact()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? layout.color : Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: layout.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                
                Text(layout.rawValue)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Selected Widget Info
    private var selectedWidgetInfo: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(selectedLayout.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: selectedLayout.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedLayout.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedLayout.rawValue)
                    .font(.subheadline.weight(.semibold))
                Text(selectedLayout.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(cardBackground)
    }
    
    // MARK: - Position Settings Card
    private var positionSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Position", icon: "arrow.left.and.right", color: selectedLayout.color)
            
            // Alignment Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Alignment")
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 8) {
                    ForEach(["left", "center", "right"], id: \.self) { position in
                        alignmentButton(position)
                    }
                }
            }
            
            Divider()
            
            // Padding Controls
            VStack(spacing: 12) {
                paddingRow(title: "Left", icon: "arrow.left", value: leftPaddingBinding)
                paddingRow(title: "Right", icon: "arrow.right", value: rightPaddingBinding)
                paddingRow(title: "Top", icon: "arrow.up", value: topPaddingBinding)
                paddingRow(title: "Bottom", icon: "arrow.down", value: bottomPaddingBinding)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private func alignmentButton(_ position: String) -> some View {
        let isSelected = getAlignment() == position
        let icon = position == "left" ? "text.alignleft" : (position == "center" ? "text.aligncenter" : "text.alignright")
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                setAlignment(position)
                HapticsManager.shared.softImpact()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(position.capitalized)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? selectedLayout.color : Color(UIColor.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func paddingRow(title: String, icon: String, value: Binding<Double>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedLayout.color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Slider(value: value, in: 0...50, step: 1)
                .tint(selectedLayout.color)
            
            Text("\(Int(value.wrappedValue))")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30)
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    // MARK: - Padding Bindings
    private var leftPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textLeftPadding
        case .sfSymbol: return $viewModel.sfSymbolLeftPadding
        case .time: return $viewModel.timeLeftPadding
        case .battery: return $viewModel.batteryLeftPadding
        default: return $viewModel.leftPadding
        }
    }
    
    private var rightPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textRightPadding
        case .sfSymbol: return $viewModel.sfSymbolRightPadding
        case .time: return $viewModel.timeRightPadding
        case .battery: return $viewModel.batteryRightPadding
        default: return $viewModel.rightPadding
        }
    }
    
    private var topPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textTopPadding
        case .sfSymbol: return $viewModel.sfSymbolTopPadding
        case .time: return $viewModel.timeTopPadding
        case .battery: return $viewModel.batteryTopPadding
        default: return $viewModel.topPadding
        }
    }
    
    private var bottomPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text: return $viewModel.textBottomPadding
        case .sfSymbol: return $viewModel.sfSymbolBottomPadding
        case .time: return $viewModel.timeBottomPadding
        case .battery: return $viewModel.batteryBottomPadding
        default: return $viewModel.bottomPadding
        }
    }
    
    // MARK: - Alignment Helpers
    private func getAlignment() -> String {
        switch selectedLayout {
        case .text: return viewModel.textAlignment
        case .sfSymbol: return viewModel.sfSymbolAlignment
        case .time: return viewModel.timeAlignment
        case .battery: return viewModel.batteryAlignment
        default: return viewModel.alignment
        }
    }
    
    private func setAlignment(_ value: String) {
        switch selectedLayout {
        case .text: viewModel.textAlignment = value
        case .sfSymbol: viewModel.sfSymbolAlignment = value
        case .time: viewModel.timeAlignment = value
        case .battery: viewModel.batteryAlignment = value
        default: viewModel.alignment = value
        }
    }
    
    // MARK: - Widget Specific Options
    @ViewBuilder
    private var widgetSpecificOptions: some View {
        switch selectedLayout {
        case .text:
            textOptions
        case .sfSymbol:
            symbolOptions
        case .time:
            timeOptions
        case .battery:
            batteryOptions
        case .network:
            networkOptions
        case .memory:
            memoryOptions
        case .date:
            dateOptions
        }
    }
    
    private var textOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Text Options", icon: "textformat", color: .blue)
            
            TextField("Enter custom text", text: $viewModel.customText)
                .textFieldStyle(.roundedBorder)
            
            Toggle("Enable Custom Text", isOn: $viewModel.showCustomText)
                .tint(.blue)
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var symbolOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Symbol Options", icon: "star.fill", color: .purple)
            
            HStack {
                Text("Current Symbol")
                Spacer()
                Image(systemName: viewModel.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            
            Toggle("Enable SF Symbol", isOn: $viewModel.showSFSymbol)
                .tint(.purple)
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var timeOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Time Options", icon: "clock.fill", color: .orange)
            
            Toggle("Enable Time Display", isOn: $viewModel.showTime)
                .tint(.orange)
            
            if viewModel.showTime {
                Toggle("Show Seconds", isOn: $viewModel.showSeconds)
                Toggle("24-Hour Format", isOn: $viewModel.use24HourClock)
                Toggle("Animate Changes", isOn: $viewModel.animateTime)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var batteryOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Battery Options", icon: "battery.100", color: .green)
            
            Toggle("Enable Battery Display", isOn: $viewModel.showBattery)
                .tint(.green)
            
            if viewModel.showBattery {
                Picker("Style", selection: $viewModel.batteryStyle) {
                    Text("Icon").tag("icon")
                    Text("Percentage").tag("percentage")
                    Text("Both").tag("both")
                }
                .pickerStyle(.segmented)
                
                Toggle("Auto Color by Level", isOn: $viewModel.batteryUseAutoColor)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var networkOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Network Options", icon: "wifi", color: .cyan)
            
            Toggle("Enable Network Status", isOn: $viewModel.showNetworkStatus)
                .tint(.cyan)
            
            if viewModel.showNetworkStatus {
                Picker("Style", selection: $viewModel.networkIconStyle) {
                    Text("Bars").tag("bars")
                    Text("Dot").tag("dot")
                    Text("Text").tag("text")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var memoryOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Memory Options", icon: "memorychip.fill", color: .pink)
            
            Toggle("Enable Memory Display", isOn: $viewModel.showMemoryUsage)
                .tint(.pink)
            
            if viewModel.showMemoryUsage {
                Picker("Style", selection: $viewModel.memoryDisplayStyle) {
                    Text("Percentage").tag("percentage")
                    Text("MB").tag("mb")
                    Text("Both").tag("both")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var dateOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Date Options", icon: "calendar", color: .indigo)
            
            Toggle("Enable Date Display", isOn: $viewModel.showDate)
                .tint(.indigo)
            
            if viewModel.showDate {
                Toggle("Show Weekday", isOn: $viewModel.showWeekday)
                
                Picker("Format", selection: $viewModel.dateFormat) {
                    Text("Short").tag("short")
                    Text("Medium").tag("medium")
                    Text("Long").tag("long")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(cardBackground)
    }
}

// MARK: - Bounce Effect Modifier
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
