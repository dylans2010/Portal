import SwiftUI

// MARK: - Right Panel: Appearance & Content
struct AppearanceContentPanel: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showColorPicker = false
    @State private var showBackgroundColorPicker = false
    @State private var showShadowColorPicker = false
    @State private var showBorderColorPicker = false
    @State private var showSymbolPicker = false
    @State private var showTimeColorPicker = false
    @State private var showBatteryColorPicker = false
    @State private var showGradientStartColorPicker = false
    @State private var showGradientEndColorPicker = false
    @State private var showGlowColorPicker = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        List {
            // MARK: - Content Configuration
            contentConfigurationSection
            
            // MARK: - Text Styling
            textStylingSection
            
            // MARK: - Effects
            effectsSection
            
            // MARK: - Widget Display
            widgetDisplaySection
            
            // MARK: - Behavior
            behaviorSection
            
            // MARK: - Visual Style
            visualStyleSection
            
            // MARK: - Reset
            resetSection
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedColor, colorHex: $viewModel.colorHex)
        }
        .sheet(isPresented: $showBackgroundColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBackgroundColor, colorHex: $viewModel.backgroundColorHex)
        }
        .sheet(isPresented: $showShadowColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedShadowColor, colorHex: $viewModel.shadowColorHex)
        }
        .sheet(isPresented: $showBorderColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBorderColor, colorHex: $viewModel.borderColorHex)
        }
        .sheet(isPresented: $showTimeColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedTimeColor, colorHex: $viewModel.timeColorHex)
        }
        .sheet(isPresented: $showBatteryColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBatteryColor, colorHex: $viewModel.batteryColorHex)
        }
        .sheet(isPresented: $showGradientStartColorPicker) {
            GradientColorPickerSheet(colorHex: $viewModel.gradientStartColorHex, title: "Start Color")
        }
        .sheet(isPresented: $showGradientEndColorPicker) {
            GradientColorPickerSheet(colorHex: $viewModel.gradientEndColorHex, title: "End Color")
        }
        .sheet(isPresented: $showGlowColorPicker) {
            GradientColorPickerSheet(colorHex: $viewModel.glowColorHex, title: "Glow Color")
        }
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolsPickerView(viewModel: viewModel)
        }
        .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text("This will reset all Status Bar customizations to their default values. This action cannot be undone.")
        }
    }
    
    // MARK: - Content Configuration Section
    @ViewBuilder
    private var contentConfigurationSection: some View {
        if viewModel.showCustomText {
            Section {
                TextField("Enter Custom Text", text: $viewModel.customText)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Label("Custom Text", systemImage: "textformat")
            }
        }
        
        if viewModel.showSFSymbol {
            Section {
                HStack {
                    Text("Selected Symbol")
                    Spacer()
                    Image(systemName: viewModel.sfSymbol)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text(viewModel.sfSymbol)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                Button {
                    showSymbolPicker = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Browse Symbols")
                    }
                }
                
                HStack {
                    Text("Icon Size")
                    Spacer()
                    Text("\(Int(viewModel.iconSize)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.iconSize, in: 10...32, step: 1)
                
                Picker("Icon Weight", selection: $viewModel.iconWeight) {
                    Text("Ultralight").tag("ultralight")
                    Text("Thin").tag("thin")
                    Text("Light").tag("light")
                    Text("Regular").tag("regular")
                    Text("Medium").tag("medium")
                    Text("Semibold").tag("semibold")
                    Text("Bold").tag("bold")
                    Text("Heavy").tag("heavy")
                    Text("Black").tag("black")
                }
            } header: {
                Label("SF Symbol", systemImage: "star.fill")
            }
        }
    }
    
    // MARK: - Text Styling Section
    @ViewBuilder
    private var textStylingSection: some View {
        Section {
            Toggle(isOn: $viewModel.isBold) {
                Label("Bold", systemImage: "bold")
            }
            
            Picker(selection: $viewModel.fontDesign) {
                Text("Default").tag("default")
                Text("Monospaced").tag("monospaced")
                Text("Rounded").tag("rounded")
                Text("Serif").tag("serif")
            } label: {
                Label("Font Design", systemImage: "textformat.abc")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Font Size", systemImage: "textformat.size")
                    Spacer()
                    Text("\(Int(viewModel.fontSize)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $viewModel.fontSize, in: 8...24, step: 1)
            }
            
            Button {
                showColorPicker = true
            } label: {
                HStack {
                    Label("Text Color", systemImage: "paintpalette")
                    Spacer()
                    Circle()
                        .fill(Color(hex: viewModel.colorHex))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                }
            }
        } header: {
            Label("Typography", systemImage: "textformat")
        }
    }
    
    // MARK: - Effects Section
    @ViewBuilder
    private var effectsSection: some View {
        Section {
            Toggle(isOn: $viewModel.useGradientText) {
                Label("Gradient Text", systemImage: "paintbrush.pointed")
            }
            
            if viewModel.useGradientText {
                Button {
                    showGradientStartColorPicker = true
                } label: {
                    HStack {
                        Text("Start Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.gradientStartColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                Button {
                    showGradientEndColorPicker = true
                } label: {
                    HStack {
                        Text("End Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.gradientEndColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gradient Angle")
                        Spacer()
                        Text("\(Int(viewModel.gradientAngle))°")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.gradientAngle, in: 0...360, step: 15)
                }
            }
        } header: {
            Label("Gradient", systemImage: "paintbrush.pointed.fill")
        }
        
        Section {
            Toggle(isOn: $viewModel.enableGlow) {
                Label("Enable Glow", systemImage: "sparkle")
            }
            
            if viewModel.enableGlow {
                Button {
                    showGlowColorPicker = true
                } label: {
                    HStack {
                        Text("Glow Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.glowColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Glow Radius")
                        Spacer()
                        Text("\(Int(viewModel.glowRadius)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.glowRadius, in: 1...20, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Glow Intensity")
                        Spacer()
                        Text("\(Int(viewModel.glowIntensity * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.glowIntensity, in: 0.1...1.0, step: 0.1)
                }
            }
        } header: {
            Label("Glow Effect", systemImage: "sparkles")
        }
    }
    
    // MARK: - Widget Display Section
    @ViewBuilder
    private var widgetDisplaySection: some View {
        // Time Display
        if viewModel.showTime {
            Section {
                Toggle(isOn: $viewModel.showSeconds) {
                    Label("Show Seconds", systemImage: "clock.badge")
                }
                
                Toggle(isOn: $viewModel.use24HourClock) {
                    Label("24 Hour Clock", systemImage: "clock")
                }
                
                Toggle(isOn: $viewModel.animateTime) {
                    Label("Animate Changes", systemImage: "wand.and.stars")
                }
                
                Toggle(isOn: $viewModel.timeAccentColored) {
                    Label("Use Accent Color", systemImage: "paintpalette")
                }
                
                if !viewModel.timeAccentColored {
                    Button {
                        showTimeColorPicker = true
                    } label: {
                        HStack {
                            Text("Time Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.timeColorHex))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            } header: {
                Label("Time Display", systemImage: "clock.fill")
            }
        }
        
        // Date Display
        Section {
            Toggle(isOn: $viewModel.showDate) {
                Label("Show Date", systemImage: "calendar")
            }
            
            if viewModel.showDate {
                Toggle(isOn: $viewModel.showWeekday) {
                    Label("Show Weekday", systemImage: "calendar.day.timeline.left")
                }
                
                Picker(selection: $viewModel.dateFormat) {
                    Text("Short (1/14)").tag("short")
                    Text("Medium (Jan 14)").tag("medium")
                    Text("Long (January 14)").tag("long")
                    Text("Custom").tag("custom")
                } label: {
                    Label("Date Format", systemImage: "textformat.123")
                }
                
                if viewModel.dateFormat == "custom" {
                    TextField("Custom Format (e.g., MMM d)", text: $viewModel.customDateFormat)
                        .textFieldStyle(.roundedBorder)
                    Text("Use: MMM (month), d (day), yyyy (year), E (weekday)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Date Display", systemImage: "calendar")
        }
        
        // Battery Display
        if viewModel.showBattery {
            Section {
                Picker(selection: $viewModel.batteryStyle) {
                    Text("Icon Only").tag("icon")
                    Text("Percentage Only").tag("percentage")
                    Text("Both").tag("both")
                } label: {
                    Label("Battery Style", systemImage: "battery.100")
                }
                
                Toggle(isOn: $viewModel.batteryUseAutoColor) {
                    Label("Auto Color (By Level)", systemImage: "paintbrush.fill")
                }
                
                if !viewModel.batteryUseAutoColor {
                    Toggle(isOn: $viewModel.batteryAccentColored) {
                        Label("Use Accent Color", systemImage: "paintpalette")
                    }
                    
                    if !viewModel.batteryAccentColored {
                        Button {
                            showBatteryColorPicker = true
                        } label: {
                            HStack {
                                Text("Battery Color")
                                Spacer()
                                Circle()
                                    .fill(Color(hex: viewModel.batteryColorHex))
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                } else {
                    Text("Battery color changes based on level: Red (≤20%), Yellow (≤50%), Green (≤80%), White (>80%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Battery Display", systemImage: "battery.100.bolt")
            }
        }
        
        // Network Status Display
        if viewModel.showNetworkStatus {
            Section {
                Picker(selection: $viewModel.networkIconStyle) {
                    Text("Signal Bars").tag("bars")
                    Text("Dot Indicator").tag("dot")
                    Text("Text Label").tag("text")
                } label: {
                    Label("Display Style", systemImage: "antenna.radiowaves.left.and.right")
                }
            } header: {
                Label("Network Status", systemImage: "wifi")
            } footer: {
                Text("Shows current network connectivity status.")
            }
        }
        
        // Memory Usage Display
        if viewModel.showMemoryUsage {
            Section {
                Picker(selection: $viewModel.memoryDisplayStyle) {
                    Text("Percentage").tag("percentage")
                    Text("MB Used").tag("mb")
                    Text("Both").tag("both")
                } label: {
                    Label("Display Style", systemImage: "chart.bar")
                }
            } header: {
                Label("Memory Usage", systemImage: "memorychip")
            } footer: {
                Text("Shows current app memory usage.")
            }
        }
    }
    
    // MARK: - Behavior Section
    @ViewBuilder
    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $viewModel.enableAnimation) {
                Label("Enable Animation", systemImage: "wand.and.stars")
            }
            
            if viewModel.enableAnimation {
                Picker(selection: $viewModel.animationType) {
                    Text("Bounce").tag("bounce")
                    Text("Fade").tag("fade")
                    Text("Scale").tag("scale")
                    Text("Slide").tag("slide")
                    Text("Spring").tag("spring")
                } label: {
                    Label("Animation Type", systemImage: "sparkles.rectangle.stack")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.animationDuration))s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.animationDuration, in: 0.1...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Delay")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.animationDelay))s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.animationDelay, in: 0...2.0, step: 0.1)
                }
            }
        } header: {
            Label("Animation", systemImage: "sparkles")
        }
        
        Section {
            Toggle(isOn: $viewModel.autoHide) {
                Label("Auto-hide Status Bar", systemImage: "eye.slash")
            }
            
            if viewModel.autoHide {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hide After")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.autoHideDelay))s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.autoHideDelay, in: 1.0...10.0, step: 0.5)
                }
                
                Toggle(isOn: $viewModel.showOnTap) {
                    Label("Show on Tap", systemImage: "hand.tap")
                }
            }
        } header: {
            Label("Auto-hide", systemImage: "eye.slash.fill")
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Item Spacing", systemImage: "arrow.left.and.right")
                    Spacer()
                    Text("\(Int(viewModel.itemSpacing)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $viewModel.itemSpacing, in: 0...24, step: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Vertical Offset", systemImage: "arrow.up.and.down")
                    Spacer()
                    Text("\(Int(viewModel.verticalOffset)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $viewModel.verticalOffset, in: -20...20, step: 1)
            }
        } header: {
            Label("Spacing & Layout", systemImage: "ruler")
        }
    }
    
    // MARK: - Visual Style Section
    @ViewBuilder
    private var visualStyleSection: some View {
        Section {
            Toggle(isOn: $viewModel.showBackground) {
                Label("Show Background", systemImage: "rectangle.fill")
            }
            
            if viewModel.showBackground {
                Toggle(isOn: $viewModel.blurBackground) {
                    Label("Blur Background", systemImage: "drop.fill")
                }
                
                if viewModel.blurBackground {
                    Picker(selection: $viewModel.blurStyle) {
                        Text("Regular").tag("regular")
                        Text("Thin").tag("thin")
                        Text("Thick").tag("thick")
                        Text("Chrome").tag("chrome")
                        Text("Material").tag("material")
                    } label: {
                        Label("Blur Style", systemImage: "drop.halffull")
                    }
                }
                
                Button {
                    showBackgroundColorPicker = true
                } label: {
                    HStack {
                        Label("Background Color", systemImage: "paintpalette")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.backgroundColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(viewModel.backgroundOpacity * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.backgroundOpacity, in: 0...1, step: 0.05)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(viewModel.cornerRadius)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.cornerRadius, in: 0...30, step: 1)
                }
            }
        } header: {
            Label("Background", systemImage: "rectangle.fill")
        }
        
        Section {
            Toggle(isOn: $viewModel.shadowEnabled) {
                Label("Enable Shadow", systemImage: "shadow")
            }
            
            if viewModel.shadowEnabled {
                Button {
                    showShadowColorPicker = true
                } label: {
                    HStack {
                        Text("Shadow Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.shadowColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shadow Radius")
                        Spacer()
                        Text("\(Int(viewModel.shadowRadius)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.shadowRadius, in: 0...20, step: 1)
                }
            }
        } header: {
            Label("Shadow", systemImage: "shadow")
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Border Width", systemImage: "square.dashed")
                    Spacer()
                    Text("\(Int(viewModel.borderWidth)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $viewModel.borderWidth, in: 0...5, step: 0.5)
            }
            
            if viewModel.borderWidth > 0 {
                Button {
                    showBorderColorPicker = true
                } label: {
                    HStack {
                        Text("Border Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.borderColorHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        } header: {
            Label("Border", systemImage: "square.dashed")
        }
    }
    
    // MARK: - Reset Section
    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    Spacer()
                }
            }
        } footer: {
            Text("This will reset all Status Bar customizations to their default values.")
                .font(.caption)
        }
    }
}

// MARK: - Gradient Color Picker Sheet
struct GradientColorPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var colorHex: String
    let title: String
    
    @State private var tempColor: Color = .blue
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
        .gray, .black, .white
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ColorPicker("Select Color", selection: $tempColor, supportsOpacity: false)
                }
                
                Section("Presets") {
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
                        colorHex = tempColor.toHex() ?? "#007AFF"
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempColor = Color(hex: colorHex)
            }
        }
    }
}
