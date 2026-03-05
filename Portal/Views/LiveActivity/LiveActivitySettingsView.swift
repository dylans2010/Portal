import SwiftUI
import NimbleViews
import ActivityKit

/// Settings view for customizing Live Activity appearance and behavior
struct LiveActivitySettingsView: View {
    @AppStorage("Feather.liveActivityEnabled") private var liveActivityEnabled: Bool = true
    
    // Live Activity settings managed by LiveActivityManager
    @State private var settings: LiveActivitySettings = LiveActivitySettings.default
    @State private var showColorPicker = false
    @State private var showBorderColorPicker = false
    @State private var showShadowColorPicker = false
    @State private var showTextColorPicker = false
    @State private var showGradientColorPicker = false
    @State private var selectedGradientColorIndex = 0
    @State private var isShowingMockActivity = false
    
    var body: some View {
        NBNavigationView("Live Activities") {
            List {
                enabledSection
                appearanceSection
                advancedStylingSection
                progressSection
                detailsSection
                infoSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showGradientColorPicker) {
            if var colors = settings.gradientSettings.colors, selectedGradientColorIndex < colors.count {
                ColorPickerView(selectedColor: Binding(
                    get: { colors[selectedGradientColorIndex] },
                    set: {
                        colors[selectedGradientColorIndex] = $0
                        settings.gradientSettings.colors = colors
                    }
                ), title: "Gradient Color \(selectedGradientColorIndex + 1)", onDismiss: saveSettings)
            }
        }
        .sheet(isPresented: $showBorderColorPicker) {
            ColorPickerView(selectedColor: Binding(
                get: { settings.borderColor ?? settings.accentColor },
                set: { settings.borderColor = $0 }
            ), title: "Border Color", onDismiss: saveSettings)
        }
        .sheet(isPresented: $showShadowColorPicker) {
            ColorPickerView(selectedColor: Binding(
                get: { settings.shadowColor ?? CodableColor(red: 0, green: 0, blue: 0, opacity: 0.2) },
                set: { settings.shadowColor = $0 }
            ), title: "Shadow Color", onDismiss: saveSettings)
        }
        .sheet(isPresented: $showTextColorPicker) {
            ColorPickerView(selectedColor: Binding(
                get: { settings.textColor ?? CodableColor(red: 1, green: 1, blue: 1) },
                set: { settings.textColor = $0 }
            ), title: "Text Color", onDismiss: saveSettings)
        }
    }
    
    // MARK: - Load/Save Settings
    
    private func loadSettings() {
        if #available(iOS 16.2, *) {
            settings = LiveActivityManager.shared.loadSettings()
            if settings.backgroundTexture == .gradient && settings.gradientSettings.colors == nil {
                 settings.gradientSettings.colors = [settings.accentColor, CodableColor(red: 0.639, green: 0.286, blue: 0.639)]
            }
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
            Text("Status")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            if #available(iOS 16.2, *) {
                Text("Show Live Activities to track down your app download process, signing, and installation.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Live Activities are not available on this iOS version. Requires iOS 16.2+ so please update your device then come back here.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            // Accent Color / Gradient Colors Summary
            if settings.backgroundTexture == .gradient {
                HStack {
                    Label("Gradient Colors", systemImage: "paintpalette.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: -8) {
                        ForEach(0..<min(settings.gradientSettings.colorCount, 5), id: \.self) { index in
                            if let colors = settings.gradientSettings.colors, index < colors.count {
                                Circle()
                                    .fill(colors[index].color)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            }
                        }
                    }
                }
            } else {
                Button {
                    showColorPicker = true
                    HapticsManager.shared.light()
                } label: {
                    HStack {
                        Label("Accent Color", systemImage: "paintpalette.fill")
                        Spacer()
                        Circle()
                            .fill(settings.accentColor.color)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    }
                }
                .foregroundStyle(.primary)
            }

            // Background Texture
            Picker(selection: $settings.backgroundTexture) {
                ForEach(LiveActivitySettings.BackgroundTexture.allCases, id: \.self) { texture in
                    Text(texture.rawValue).tag(texture)
                }
            } label: {
                Label("Background", systemImage: "square.3.layers.3d")
            }
            .onChange(of: settings.backgroundTexture) { _ in saveSettings() }
            
            if settings.backgroundTexture == .glass {
                glassSettingsSubSection
            } else if settings.backgroundTexture == .gradient {
                gradientSettingsSubSection
            }

            // Font Family
            Picker(selection: $settings.fontFamily) {
                ForEach(LiveActivitySettings.FontFamily.allCases, id: \.self) { family in
                    Text(family.rawValue).tag(family)
                }
            } label: {
                Label("Font", systemImage: "textformat")
            }
            .onChange(of: settings.fontFamily) { _ in saveSettings() }
            
            // Font Weight
            Picker(selection: $settings.fontWeight) {
                ForEach(LiveActivitySettings.FontWeightOption.allCases, id: \.self) { weight in
                    Text(weight.rawValue).tag(weight)
                }
            } label: {
                Label("Font Weight", systemImage: "bold")
            }
            .onChange(of: settings.fontWeight) { _ in saveSettings() }
            
            // Text Color
            Button {
                showTextColorPicker = true
            } label: {
                HStack {
                    Label("Text Color", systemImage: "pencil.tip.crop.circle.fill")
                    Spacer()
                    Circle()
                        .fill(settings.textColor?.color ?? .primary)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                }
            }
            .foregroundStyle(.primary)

        } header: {
            Text("Appearance")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Customize how the style of Live Activities render in your Lock Screen and Dynamic Island.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $settings.accentColor, title: "Accent Color", onDismiss: saveSettings)
        }
    }

    private var advancedStylingSection: some View {
        Section {
            // Corner Radius
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Corner Radius", systemImage: "square.and.line.vertical.and.square")
                    Spacer()
                    Text("\(Int(settings.cornerRadius))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.cornerRadius, in: 0...40, step: 1) { _ in saveSettings() }
            }

            // Background Opacity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Opacity", systemImage: "square.stack.3d.up.fill")
                    Spacer()
                    Text("\(Int(settings.backgroundOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.backgroundOpacity, in: 0...1, step: 0.05) { _ in saveSettings() }
            }

            // Border Width
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Border Width", systemImage: "square.dashed")
                    Spacer()
                    Text("\(String(format: "%.1f", settings.borderWidth))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.borderWidth, in: 0...5, step: 0.5) { _ in saveSettings() }
            }

            if settings.borderWidth > 0 {
                Button {
                    showBorderColorPicker = true
                } label: {
                    HStack {
                        Label("Border Color", systemImage: "paintpalette")
                        Spacer()
                        Circle()
                            .fill(settings.borderColor?.color ?? settings.accentColor.color)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.leading, 12)
            }

            // Shadow Radius
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Shadow Radius", systemImage: "shadow")
                    Spacer()
                    Text("\(Int(settings.shadowRadius))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.shadowRadius, in: 0...30, step: 1) { _ in saveSettings() }
            }

            if settings.shadowRadius > 0 {
                Button {
                    showShadowColorPicker = true
                } label: {
                    HStack {
                        Label("Shadow Color", systemImage: "paintpalette")
                        Spacer()
                        Circle()
                            .fill(settings.shadowColor?.color ?? Color.black.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.leading, 12)
            }

        } header: {
            Text("Styling")
                .font(.system(size: 11, weight: .semibold))
        }
    }

    @ViewBuilder
    private var glassSettingsSubSection: some View {
        Toggle(isOn: $settings.glassSettings.isTinted) {
            Label("Tinted Glass", systemImage: "drop.fill")
        }
        .onChange(of: settings.glassSettings.isTinted) { _ in saveSettings() }
        .padding(.leading, 12)

        VStack(alignment: .leading, spacing: 8) {
            Label("Intensity (\(Int(settings.glassSettings.intensity * 100))%)", systemImage: "slider.horizontal.3")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $settings.glassSettings.intensity, in: 0...1) { _ in
                saveSettings()
            }
        }
        .padding(.leading, 12)

        VStack(alignment: .leading, spacing: 8) {
            Label("Glass Effect Amount (\(Int(settings.glassSettings.glassEffectAmount * 100))%)", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $settings.glassSettings.glassEffectAmount, in: 0...1) { _ in
                saveSettings()
            }
        }
        .padding(.leading, 12)
    }

    @ViewBuilder
    private var gradientSettingsSubSection: some View {
        Stepper(value: $settings.gradientSettings.colorCount, in: 2...10) {
            Label("Colors: \(settings.gradientSettings.colorCount)", systemImage: "paintpalette")
        }
        .onChange(of: settings.gradientSettings.colorCount) { newValue in
            if settings.gradientSettings.colors == nil {
                settings.gradientSettings.colors = [settings.accentColor]
            }
            while settings.gradientSettings.colors!.count < newValue {
                settings.gradientSettings.colors!.append(CodableColor(color: .blue))
            }
            saveSettings()
        }
        .padding(.leading, 12)

        ForEach(0..<settings.gradientSettings.colorCount, id: \.self) { index in
            Button {
                selectedGradientColorIndex = index
                showGradientColorPicker = true
                HapticsManager.shared.light()
            } label: {
                HStack {
                    Label("Color \(index + 1)", systemImage: "paintpalette.fill")
                    Spacer()
                    if let colors = settings.gradientSettings.colors, index < colors.count {
                        Circle()
                            .fill(colors[index].color)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    }
                }
            }
            .foregroundStyle(.primary)
            .padding(.leading, 24)
        }

        Picker(selection: $settings.gradientSettings.direction) {
            ForEach(LiveActivitySettings.GradientDirection.allCases, id: \.self) { dir in
                Text(dir.rawValue).tag(dir)
            }
        } label: {
            Label("Direction", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
        }
        .onChange(of: settings.gradientSettings.direction) { _ in saveSettings() }
        .padding(.leading, 12)

        Picker(selection: $settings.gradientSettings.pattern) {
            ForEach(LiveActivitySettings.GradientPattern.allCases, id: \.self) { pattern in
                Text(pattern.rawValue).tag(pattern)
            }
        } label: {
            Label("Pattern", systemImage: "circle.grid.2x2")
        }
        .onChange(of: settings.gradientSettings.pattern) { _ in saveSettings() }
        .padding(.leading, 12)
    }
    
    private func isSameColor(_ color1: Color, _ color2: Color) -> Bool {
        // Simple comparison for predefined colors
        color1 == color2
    }

    private var progressSection: some View {
        Section {
            // Progress Bar Style
            Picker(selection: $settings.progressBarStyle) {
                ForEach(LiveActivitySettings.ProgressBarStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            } label: {
                Label("Progress Style", systemImage: "progressbar.fill")
            }
            .onChange(of: settings.progressBarStyle) { _ in saveSettings() }
            
            // Icon Size
            Picker(selection: $settings.iconSize) {
                ForEach(LiveActivitySettings.IconSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            } label: {
                Label("Icon Size", systemImage: "app.dashed")
            }
            .onChange(of: settings.iconSize) { _ in saveSettings() }
            
            // Animation Style
            Picker(selection: $settings.animationStyle) {
                ForEach(LiveActivitySettings.AnimationStyle.allCases, id: \.self) { animation in
                    Text(animation.rawValue).tag(animation)
                }
            } label: {
                Label("Animation", systemImage: "wand.and.stars")
            }
            .onChange(of: settings.animationStyle) { _ in saveSettings() }

            // New Customization Toggles
            Toggle(isOn: $settings.showEstimatedTime) {
                Label("Show Estimated Time", systemImage: "clock.fill")
            }
            .onChange(of: settings.showEstimatedTime) { _ in saveSettings() }

            Toggle(isOn: $settings.highFrequencyUpdates) {
                Label("High Frequency Updates", systemImage: "bolt.horizontal.fill")
            }
            .onChange(of: settings.highFrequencyUpdates) { _ in saveSettings() }

        } header: {
            Text("Progress Display")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Configure how progress is displayed and updated throught the process.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        Section {
            // Detail Density
            Picker(selection: $settings.detailDensity) {
                ForEach(LiveActivitySettings.DetailDensity.allCases, id: \.self) { density in
                    Text(density.rawValue).tag(density)
                }
            } label: {
                Label("Detail Level", systemImage: "list.bullet.indent")
            }
            .onChange(of: settings.detailDensity) { _ in saveSettings() }
        } header: {
            Text("Details")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Control how much information is shown. Less details may improve performance on older devices.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    
    private var infoSection: some View {
        Section {
            LiveActivityInfoRow(
                icon: "iphone",
                title: "Dynamic Island",
                description: "On iPhone 14 Pro and later, Live Activities also appear in the Dynamic Island."
            )
            
            LiveActivityInfoRow(
                icon: "lock.fill",
                title: "Lock Screen",
                description: "Live Activities also appear on the Lock Screen for all supported devices running iOS 16.2+."
            )
            
            LiveActivityInfoRow(
                icon: "app.badge.fill",
                title: "Background Updates",
                description: "Live Activities can be updated even when Portal is in the background."
            )
        } header: {
            Text("About Live Activities")
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
    
    private let presetColors: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .cyan, .indigo, .gray]

    let title: String

    init(selectedColor: Binding<CodableColor>, title: String = "Accent Color", onDismiss: @escaping () -> Void) {
        self._selectedColor = selectedColor
        self.title = title
        self.onDismiss = onDismiss
        self._color = State(initialValue: selectedColor.wrappedValue.color)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ColorPicker("Custom Color", selection: $color, supportsOpacity: false)
                } header: {
                    Text("Custom")
                }
                
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(presetColors, id: \.self) { presetColor in
                            ZStack {
                                Circle()
                                    .fill(presetColor)
                                    .frame(width: 38, height: 38)
                                    .onTapGesture {
                                        color = presetColor
                                        HapticsManager.shared.light()
                                    }

                                if color == presetColor {
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Presets")
                }
                
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading) {
                            Text("Preview")
                                .foregroundColor(color)
                                .font(.headline)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedColor = CodableColor(color: color)
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
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
