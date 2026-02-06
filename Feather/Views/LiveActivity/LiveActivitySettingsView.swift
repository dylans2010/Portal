import SwiftUI
import NimbleViews
import ActivityKit

/// Settings view for customizing Live Activity appearance and behavior
struct LiveActivitySettingsView: View {
    @AppStorage("Feather.liveActivityEnabled") private var liveActivityEnabled: Bool = true
    
    // Live Activity settings managed by LiveActivityManager
    @State private var settings: LiveActivitySettings = LiveActivitySettings.default
    @State private var showColorPicker = false
    @State private var isShowingMockActivity = false
    
    var body: some View {
        NBNavigationView("Live Activity Settings") {
            List {
                enabledSection
                appearanceSection
                progressSection
                detailsSection
                testingSection
                infoSection
            }
            .listStyle(.insetGrouped)
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Load/Save Settings
    
    private func loadSettings() {
        if #available(iOS 16.2, *) {
            settings = LiveActivityManager.shared.loadSettings()
        }
    }
    
    private func saveSettings() {
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.saveSettings(settings)
        }
    }
    
    // MARK: - Sections
    
    private var enabledSection: some View {
        Section {
            Toggle(isOn: $liveActivityEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(liveActivityEnabled ? .green : .gray)
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Live Activities")
                            .font(.body)
                        
                        Text("Show installation progress in Dynamic Island and Lock Screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .semibold))
                Text("Status")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        } footer: {
            if #available(iOS 16.2, *) {
                Text("Live Activities require iOS 16.2 or later for Dynamic Island support.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Live Activities are not available on this iOS version. Requires iOS 16.2+")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            // Background Texture
            Picker("Background", selection: $settings.backgroundTexture) {
                ForEach(LiveActivitySettings.BackgroundTexture.allCases, id: \.self) { texture in
                    Text(texture.rawValue).tag(texture)
                }
            }
            .onChange(of: settings.backgroundTexture) { _ in saveSettings() }
            
            // Font Family
            Picker("Font", selection: $settings.fontFamily) {
                ForEach(LiveActivitySettings.FontFamily.allCases, id: \.self) { family in
                    Text(family.rawValue).tag(family)
                }
            }
            .onChange(of: settings.fontFamily) { _ in saveSettings() }
            
            // Font Weight
            Picker("Font Weight", selection: $settings.fontWeight) {
                ForEach(LiveActivitySettings.FontWeightOption.allCases, id: \.self) { weight in
                    Text(weight.rawValue).tag(weight)
                }
            }
            .onChange(of: settings.fontWeight) { _ in saveSettings() }
            
            // Accent Color Button
            Button {
                showColorPicker = true
                HapticsManager.shared.light()
            } label: {
                HStack {
                    Text("Accent Color")
                        .foregroundColor(.primary)
                    Spacer()
                    Circle()
                        .fill(settings.accentColor.color)
                        .frame(width: 24, height: 24)
                }
            }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Appearance")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        } footer: {
            Text("Customize the visual style of Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $settings.accentColor, onDismiss: saveSettings)
        }
    }
    
    private var progressSection: some View {
        Section {
            // Progress Bar Style
            Picker("Progress Style", selection: $settings.progressBarStyle) {
                ForEach(LiveActivitySettings.ProgressBarStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .onChange(of: settings.progressBarStyle) { _ in saveSettings() }
            
            // Icon Size
            Picker("Icon Size", selection: $settings.iconSize) {
                ForEach(LiveActivitySettings.IconSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .onChange(of: settings.iconSize) { _ in saveSettings() }
            
            // Animation Style
            Picker("Animation", selection: $settings.animationStyle) {
                ForEach(LiveActivitySettings.AnimationStyle.allCases, id: \.self) { animation in
                    Text(animation.rawValue).tag(animation)
                }
            }
            .onChange(of: settings.animationStyle) { _ in saveSettings() }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Progress Display")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        } footer: {
            Text("Configure how progress is displayed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        Section {
            // Detail Density
            Picker("Detail Level", selection: $settings.detailDensity) {
                ForEach(LiveActivitySettings.DetailDensity.allCases, id: \.self) { density in
                    Text(density.rawValue).tag(density)
                }
            }
            .onChange(of: settings.detailDensity) { _ in saveSettings() }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Details")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        } footer: {
            Text("Control how much information is shown")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var testingSection: some View {
        Section {
            if #available(iOS 16.2, *) {
                Button {
                    HapticsManager.shared.light()
                    isShowingMockActivity = true
                    LiveActivityManager.shared.startMockActivity()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Force Show Live Activity")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text("Test with mock installation data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isShowingMockActivity {
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(isShowingMockActivity)
            } else {
                Text("Testing requires iOS 16.2+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Testing")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        } footer: {
            Text("Test your Live Activity settings with a mock installation. The activity will automatically complete after a few seconds.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: isShowingMockActivity) { newValue in
            if newValue {
                // Reset after 12 seconds (mock takes ~11 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                    isShowingMockActivity = false
                }
            }
        }
    }
    
    private var infoSection: some View {
        Section {
            LiveActivityInfoRow(
                icon: "iphone",
                title: "Dynamic Island",
                description: "On iPhone 14 Pro and later, Live Activities appear in the Dynamic Island"
            )
            
            LiveActivityInfoRow(
                icon: "lock.fill",
                title: "Lock Screen",
                description: "Live Activities also appear on the Lock Screen for all supported devices"
            )
            
            LiveActivityInfoRow(
                icon: "app.badge.fill",
                title: "Background Updates",
                description: "Live Activities can be updated even when Portal is in the background"
            )
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("About Live Activities")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
                .font(.system(size: 11, weight: .semibold))
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Binding var selectedColor: CodableColor
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var color: Color
    @State private var selectedPreset: PresetColor?
    
    // Preset colors for quick selection
    private let presetColors: [PresetColor] = [
        PresetColor(name: "Blue", color: .blue),
        PresetColor(name: "Purple", color: .purple),
        PresetColor(name: "Pink", color: .pink),
        PresetColor(name: "Red", color: .red),
        PresetColor(name: "Orange", color: .orange),
        PresetColor(name: "Yellow", color: .yellow),
        PresetColor(name: "Green", color: .green),
        PresetColor(name: "Teal", color: .teal),
        PresetColor(name: "Cyan", color: .cyan),
        PresetColor(name: "Indigo", color: .indigo),
        PresetColor(name: "Mint", color: .mint),
        PresetColor(name: "Brown", color: .brown)
    ]
    
    init(selectedColor: Binding<CodableColor>, onDismiss: @escaping () -> Void) {
        self._selectedColor = selectedColor
        self.onDismiss = onDismiss
        self._color = State(initialValue: selectedColor.wrappedValue.color)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Preset Colors Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 70), spacing: 12)
                    ], spacing: 12) {
                        ForEach(presetColors) { preset in
                            Button {
                                color = preset.color
                                selectedPreset = preset
                                HapticsManager.shared.softImpact()
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(preset.color)
                                            .frame(width: 50, height: 50)
                                        
                                        if selectedPreset?.id == preset.id || colorMatches(color, preset.color) {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                    }
                                    
                                    Text(preset.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "swatchpalette.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Preset Colors")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Custom Color Picker Section
                Section {
                    ColorPicker("Custom Color", selection: $color, supportsOpacity: false)
                        .padding(.vertical, 4)
                        .onChange(of: color) { newColor in
                            // Clear preset selection when custom color is picked
                            selectedPreset = nil
                        }
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Custom Color")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Preview Section
                Section {
                    VStack(spacing: 16) {
                        // Color preview circle
                        Circle()
                            .fill(color)
                            .frame(width: 80, height: 80)
                            .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        // Sample UI elements
                        VStack(spacing: 8) {
                            Text("Sample Text")
                                .font(.headline)
                                .foregroundColor(color)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(height: 40)
                                .overlay(
                                    Text("Sample Button")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                )
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 12, height: 12)
                                Text("Progress Indicator")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Preview")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                } footer: {
                    Text("This is how your accent color will appear in Live Activities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedColor = CodableColor(color: color)
                        onDismiss()
                        HapticsManager.shared.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // Helper to check if colors match (approximate comparison)
    private func colorMatches(_ color1: Color, _ color2: Color) -> Bool {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let threshold: CGFloat = 0.1
        return abs(r1 - r2) < threshold && abs(g1 - g2) < threshold && abs(b1 - b2) < threshold
    }
}

// MARK: - Preset Color
private struct PresetColor: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

// MARK: - Supporting Views

private struct LiveActivityInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    LiveActivitySettingsView()
}
