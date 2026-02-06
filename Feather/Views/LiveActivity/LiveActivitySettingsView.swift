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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
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
            HStack(spacing: 12) {
                Image(systemName: "rectangle.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.indigo)
                    .frame(width: 28, height: 28)
                
                Picker("Background", selection: $settings.backgroundTexture) {
                    ForEach(LiveActivitySettings.BackgroundTexture.allCases, id: \.self) { texture in
                        Text(texture.rawValue).tag(texture)
                    }
                }
            }
            .onChange(of: settings.backgroundTexture) { _ in saveSettings() }
            
            // Font Family
            HStack(spacing: 12) {
                Image(systemName: "textformat")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.orange)
                    .frame(width: 28, height: 28)
                
                Picker("Font", selection: $settings.fontFamily) {
                    ForEach(LiveActivitySettings.FontFamily.allCases, id: \.self) { family in
                        Text(family.rawValue).tag(family)
                    }
                }
            }
            .onChange(of: settings.fontFamily) { _ in saveSettings() }
            
            // Font Weight
            HStack(spacing: 12) {
                Image(systemName: "bold")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.pink)
                    .frame(width: 28, height: 28)
                
                Picker("Font Weight", selection: $settings.fontWeight) {
                    ForEach(LiveActivitySettings.FontWeightOption.allCases, id: \.self) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
            }
            .onChange(of: settings.fontWeight) { _ in saveSettings() }
            
            // Accent Color Button
            Button {
                showColorPicker = true
                HapticsManager.shared.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(settings.accentColor.color)
                        .frame(width: 28, height: 28)
                    
                    Text("Accent Color")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(settings.accentColor.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Appearance")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondary)
        } footer: {
            Text("Customize the visual style of Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            AccentColorPickerView(selectedColor: $settings.accentColor, onDismiss: saveSettings)
        }
    }
    
    private var progressSection: some View {
        Section {
            // Progress Bar Style
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.green)
                    .frame(width: 28, height: 28)
                
                Picker("Progress Style", selection: $settings.progressBarStyle) {
                    ForEach(LiveActivitySettings.ProgressBarStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }
            .onChange(of: settings.progressBarStyle) { _ in saveSettings() }
            
            // Icon Size
            HStack(spacing: 12) {
                Image(systemName: "app.badge")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                
                Picker("Icon Size", selection: $settings.iconSize) {
                    ForEach(LiveActivitySettings.IconSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            }
            .onChange(of: settings.iconSize) { _ in saveSettings() }
            
            // Animation Style
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.yellow)
                    .frame(width: 28, height: 28)
                
                Picker("Animation", selection: $settings.animationStyle) {
                    ForEach(LiveActivitySettings.AnimationStyle.allCases, id: \.self) { animation in
                        Text(animation.rawValue).tag(animation)
                    }
                }
            }
            .onChange(of: settings.animationStyle) { _ in saveSettings() }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 10, weight: .semibold))
                Text("Progress Display")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
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
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.teal)
                    .frame(width: 28, height: 28)
                
                Picker("Detail Level", selection: $settings.detailDensity) {
                    ForEach(LiveActivitySettings.DetailDensity.allCases, id: \.self) { density in
                        Text(density.rawValue).tag(density)
                    }
                }
            }
            .onChange(of: settings.detailDensity) { _ in saveSettings() }
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Details")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Accent Color Picker View

struct AccentColorPickerView: View {
    @Binding var selectedColor: CodableColor
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var color: Color
    
    // Popular preset colors
    private let presetColors: [(name: String, color: Color)] = [
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Mint", .mint),
        ("Brown", .brown)
    ]
    
    init(selectedColor: Binding<CodableColor>, onDismiss: @escaping () -> Void) {
        self._selectedColor = selectedColor
        self.onDismiss = onDismiss
        self._color = State(initialValue: selectedColor.wrappedValue.color)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Color Presets Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(presetColors, id: \.name) { preset in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 2)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isSimilarColor(preset.color, to: color) ? Color.accentColor : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .onTapGesture {
                                        color = preset.color
                                        HapticsManager.shared.light()
                                    }
                                
                                Text(preset.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Presets")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Custom Color Section
                Section {
                    ColorPicker("Custom Color", selection: $color, supportsOpacity: false)
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "eyedropper.halffull")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Custom")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Preview Section
                Section {
                    VStack(spacing: 20) {
                        Circle()
                            .fill(color)
                            .frame(width: 80, height: 80)
                            .shadow(color: color.opacity(0.4), radius: 15, x: 0, y: 8)
                        
                        VStack(spacing: 8) {
                            Text("Sample Text")
                                .foregroundColor(color)
                                .font(.headline)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(height: 8)
                                .frame(maxWidth: 200)
                            
                            HStack(spacing: 12) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } header: {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Preview")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedColor = CodableColor(color: color)
                        onDismiss()
                        HapticsManager.shared.success()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Done")
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // Helper to check if colors are similar
    private func isSimilarColor(_ color1: Color, to color2: Color) -> Bool {
        // Simple comparison - in production you might want UIColor comparison
        return color1.description == color2.description
    }
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
