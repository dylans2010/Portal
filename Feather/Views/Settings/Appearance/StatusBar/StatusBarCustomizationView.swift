import SwiftUI

// MARK: - View
struct StatusBarCustomizationView: View {
    @StateObject private var viewModel = StatusBarViewModel()
    @State private var selectedPanel: Panel = .structure
    
    enum Panel {
        case structure
        case appearance
    }
    
    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: Two-panel layout
                HStack(spacing: 0) {
                    // Left Panel: Structure & Visibility
                    StructureVisibilityPanel(viewModel: viewModel)
                        .frame(width: geometry.size.width * 0.5)
                        .background(Color(uiColor: .systemBackground))
                    
                    Divider()
                    
                    // Right Panel: Appearance & Content
                    AppearanceContentPanel(viewModel: viewModel)
                        .frame(width: geometry.size.width * 0.5)
                        .background(Color(uiColor: .systemBackground))
                }
            } else {
                // iPhone: Tabbed layout
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        Button {
                            withAnimation {
                                selectedPanel = .structure
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                Text("Structure")
                                    .font(.caption)
                                Rectangle()
                                    .fill(selectedPanel == .structure ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            withAnimation {
                                selectedPanel = .appearance
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "paintbrush")
                                Text("Appearance")
                                    .font(.caption)
                                Rectangle()
                                    .fill(selectedPanel == .appearance ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(Color(uiColor: .systemBackground))
                    
                    Divider()
                    
                    // Panel content
                    Group {
                        switch selectedPanel {
                        case .structure:
                            StructureVisibilityPanel(viewModel: viewModel)
                        case .appearance:
                            AppearanceContentPanel(viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .navigationTitle("Status Bar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
@Environment(\.dismiss) var dismiss
@Binding var selectedColor: Color
@Binding var colorHex: String

@State private var tempColor: Color

init(selectedColor: Binding<Color>, colorHex: Binding<String>) {
self._selectedColor = selectedColor
self._colorHex = colorHex
self._tempColor = State(initialValue: selectedColor.wrappedValue)
}

// Preset colors
private let presetColors: [Color] = [
.red, .orange, .yellow, .green, .mint, .teal,
.cyan, .blue, .indigo, .purple, .pink, .brown,
.gray, .black, .white
]

var body: some View {
NavigationView {
Form {
Section {
ColorPicker(String.localized("Select Color"), selection: $tempColor, supportsOpacity: false)
}

Section(.localized("Presets")) {
LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
ForEach(presetColors.indices, id: \.self) { index in
Button {
tempColor = presetColors[index]
} label: {
Circle()
.fill(presetColors[index])
.frame(width: 50, height: 50)
.overlay(
Circle()
.stroke((tempColor.toHex() ?? "") == (presetColors[index].toHex() ?? "") ? Color.primary : Color.clear, lineWidth: 3)
)
}
.buttonStyle(.plain)
}
}
.padding(.vertical, 8)
}
}
.navigationTitle(.localized("Choose Color"))
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .cancellationAction) {
Button(.localized("Cancel")) {
dismiss()
}
}
ToolbarItem(placement: .confirmationAction) {
Button(.localized("Done")) {
selectedColor = tempColor
colorHex = tempColor.toHex() ?? "#000000"
dismiss()
}
}
}
}
}
}
