import SwiftUI

// MARK: - Configure Layouts View (Splash Screen Style)
struct ConfigureLayoutsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var selectedLayout: LayoutType = .text
    
    enum LayoutType: String, CaseIterable {
        case text = "Text"
        case sfSymbol = "SF Symbol"
        case time = "Time"
        case battery = "Battery"
        
        var icon: String {
            switch self {
            case .text: return "textformat"
            case .sfSymbol: return "circle.fill"
            case .time: return "clock.fill"
            case .battery: return "battery.100"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.15),
                        Color.accentColor.opacity(0.05),
                        Color(uiColor: .systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top section with icon grid
                    layoutSelector
                        .padding(.top, 20)
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    // Bottom section with controls
                    ScrollView {
                        layoutControls
                            .padding(.horizontal, 20)
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
    }
    
    // MARK: - Layout Selector
    private var layoutSelector: some View {
        VStack(spacing: 12) {
            Text("Choose Layout Type")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                ForEach(LayoutType.allCases, id: \.rawValue) { layout in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLayout = layout
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedLayout == layout ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: layout.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(selectedLayout == layout ? .white : .primary)
                            }
                            
                            Text(layout.rawValue)
                                .font(.caption)
                                .foregroundStyle(selectedLayout == layout ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Layout Controls
    private var layoutControls: some View {
        VStack(spacing: 24) {
            // Info card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text(layoutDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Alignment picker with availability check
            VStack(alignment: .leading, spacing: 12) {
                Text("Alignment")
                    .font(.headline)
                
                let availablePositions = viewModel.getAvailablePositions(for: selectedLayout.rawValue)
                
                let allAlignments = [StatusBarAlignment.left, StatusBarAlignment.center, StatusBarAlignment.right]
                
                HStack(spacing: 12) {
                    ForEach(allAlignments, id: \.rawValue) { alignment in
                        let position = alignment.rawValue
                        let isAvailable = availablePositions.contains(position)
                        Button {
                            if isAvailable {
                                setAlignment(position)
                            }
                        } label: {
                            Text(position.capitalized)
                                .font(.subheadline)
                                .fontWeight(getAlignment() == position ? .semibold : .regular)
                                .foregroundStyle(isAvailable ? (getAlignment() == position ? .white : .primary) : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(getAlignment() == position ? Color.accentColor : (isAvailable ? Color(uiColor: .secondarySystemGroupedBackground) : Color(uiColor: .tertiarySystemGroupedBackground)))
                                .cornerRadius(8)
                        }
                        .disabled(!isAvailable)
                    }
                }
                
                if !availablePositions.contains("center") && getAlignment() != "center" {
                    Text("Center position is occupied by another widget")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Padding controls
            VStack(alignment: .leading, spacing: 16) {
                Text("Padding")
                    .font(.headline)
                
                paddingControl(title: "Left", value: leftPaddingBinding)
                paddingControl(title: "Right", value: rightPaddingBinding)
                paddingControl(title: "Top", value: topPaddingBinding)
                paddingControl(title: "Bottom", value: bottomPaddingBinding)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            Spacer(minLength: 40)
        }
    }
    
    private func paddingControl(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue)) pt")
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
            }
            
            // Increased max padding values for better customization
            let maxValue: Double = 100.0
            
            Slider(value: value, in: 0...maxValue, step: 1)
                .tint(.accentColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var layoutDescription: String {
        switch selectedLayout {
        case .text:
            return "Configure layout settings for custom text display. These settings only affect text elements."
        case .sfSymbol:
            return "Configure layout settings for SF Symbol icons. These settings only affect symbol elements."
        case .time:
            return "Configure layout settings for time display. These settings only affect the time widget."
        case .battery:
            return "Configure layout settings for battery display. These settings only affect the battery widget."
        }
    }
    
    private var leftPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text:
            return $viewModel.textLeftPadding
        case .sfSymbol:
            return $viewModel.sfSymbolLeftPadding
        case .time:
            return $viewModel.timeLeftPadding
        case .battery:
            return $viewModel.batteryLeftPadding
        }
    }
    
    private var rightPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text:
            return $viewModel.textRightPadding
        case .sfSymbol:
            return $viewModel.sfSymbolRightPadding
        case .time:
            return $viewModel.timeRightPadding
        case .battery:
            return $viewModel.batteryRightPadding
        }
    }
    
    private var topPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text:
            return $viewModel.textTopPadding
        case .sfSymbol:
            return $viewModel.sfSymbolTopPadding
        case .time:
            return $viewModel.timeTopPadding
        case .battery:
            return $viewModel.batteryTopPadding
        }
    }
    
    private var bottomPaddingBinding: Binding<Double> {
        switch selectedLayout {
        case .text:
            return $viewModel.textBottomPadding
        case .sfSymbol:
            return $viewModel.sfSymbolBottomPadding
        case .time:
            return $viewModel.timeBottomPadding
        case .battery:
            return $viewModel.batteryBottomPadding
        }
    }
    
    // Helper methods for alignment
    private func getAlignment() -> String {
        switch selectedLayout {
        case .text:
            return viewModel.textAlignment
        case .sfSymbol:
            return viewModel.sfSymbolAlignment
        case .time:
            return viewModel.timeAlignment
        case .battery:
            return viewModel.batteryAlignment
        }
    }
    
    private func setAlignment(_ position: String) {
        switch selectedLayout {
        case .text:
            viewModel.textAlignment = position
        case .sfSymbol:
            viewModel.sfSymbolAlignment = position
        case .time:
            viewModel.timeAlignment = position
        case .battery:
            viewModel.batteryAlignment = position
        }
    }
}

// MARK: - Preview
#Preview {
    ConfigureLayoutsView(viewModel: StatusBarViewModel())
}
