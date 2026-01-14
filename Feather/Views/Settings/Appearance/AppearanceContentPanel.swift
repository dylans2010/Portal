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
            // Content Section
            if viewModel.showCustomText {
                Section(header: Text("Custom Text")) {
                    TextField("Enter Custom Text", text: $viewModel.customText)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            if viewModel.showSFSymbol {
                Section(header: Text("SF Symbol")) {
                    HStack {
                        Text("Selected Symbol")
                        Spacer()
                        Image(systemName: viewModel.sfSymbol)
                            .font(.title2)
                        Text(viewModel.sfSymbol)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    Button {
                        showSymbolPicker = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Browse Symbols")
                            Image(systemName: "magnifyingglass")
                            Spacer()
                        }
                    }
                    
                    // Icon customization
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
                }
            }
            
            // Styling Section
            Section(header: Text("Text Styling")) {
                Toggle("Bold", isOn: $viewModel.isBold)
                
                Picker("Font Design", selection: $viewModel.fontDesign) {
                    Text("Default").tag("default")
                    Text("Monospaced").tag("monospaced")
                    Text("Rounded").tag("rounded")
                    Text("Serif").tag("serif")
                }
                
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(viewModel.fontSize)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.fontSize, in: 8...24, step: 1)
                
                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Text("Text Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.colorHex))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            
            // Gradient Text Section
            Section(header: Text("Gradient Text")) {
                Toggle("Use Gradient Text", isOn: $viewModel.useGradientText)
                
                if viewModel.useGradientText {
                    Button {
                        showGradientStartColorPicker = true
                    } label: {
                        HStack {
                            Text("Start Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.gradientStartColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
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
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Gradient Angle")
                        Spacer()
                        Text("\(Int(viewModel.gradientAngle))°")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.gradientAngle, in: 0...360, step: 15)
                }
            }
            
            // Glow Effect Section
            Section(header: Text("Glow Effect")) {
                Toggle("Enable Glow", isOn: $viewModel.enableGlow)
                
                if viewModel.enableGlow {
                    Button {
                        showGlowColorPicker = true
                    } label: {
                        HStack {
                            Text("Glow Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.glowColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Glow Radius")
                        Spacer()
                        Text("\(Int(viewModel.glowRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.glowRadius, in: 1...20, step: 1)
                    
                    HStack {
                        Text("Glow Intensity")
                        Spacer()
                        Text("\(Int(viewModel.glowIntensity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.glowIntensity, in: 0.1...1.0, step: 0.1)
                }
            }
            
            // Time Section
            Section(header: Text("Time Display")) {
                Toggle("Show Time", isOn: $viewModel.showTime)
                
                if viewModel.showTime {
                    Toggle("Show Seconds", isOn: $viewModel.showSeconds)
                    Toggle("24 Hour Clock", isOn: $viewModel.use24HourClock)
                    Toggle("Animate Time Changes", isOn: $viewModel.animateTime)
                    Toggle("Use Accent Color", isOn: $viewModel.timeAccentColored)
                    
                    if !viewModel.timeAccentColored {
                        Button {
                            showTimeColorPicker = true
                        } label: {
                            HStack {
                                Text("Time Color")
                                Spacer()
                                Circle()
                                    .fill(Color(hex: viewModel.timeColorHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            
            // Date Section
            Section(header: Text("Date Display")) {
                Toggle("Show Date", isOn: $viewModel.showDate)
                
                if viewModel.showDate {
                    Toggle("Show Weekday", isOn: $viewModel.showWeekday)
                    
                    Picker("Date Format", selection: $viewModel.dateFormat) {
                        Text("Short (1/14)").tag("short")
                        Text("Medium (Jan 14)").tag("medium")
                        Text("Long (January 14)").tag("long")
                        Text("Custom").tag("custom")
                    }
                    
                    if viewModel.dateFormat == "custom" {
                        TextField("Custom Format (e.g., MMM d)", text: $viewModel.customDateFormat)
                            .textFieldStyle(.roundedBorder)
                        Text("Use: MMM (month), d (day), yyyy (year), E (weekday)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Battery Section
            Section(header: Text("Battery Display")) {
                Toggle("Show Battery", isOn: $viewModel.showBattery)
                
                if viewModel.showBattery {
                    Picker("Battery Style", selection: $viewModel.batteryStyle) {
                        Text("Icon Only").tag("icon")
                        Text("Percentage Only").tag("percentage")
                        Text("Both").tag("both")
                    }
                    
                    Toggle("Auto Color (By Level)", isOn: $viewModel.batteryUseAutoColor)
                    
                    if !viewModel.batteryUseAutoColor {
                        Toggle("Use Accent Color", isOn: $viewModel.batteryAccentColored)
                        
                        if !viewModel.batteryAccentColored {
                            Button {
                                showBatteryColorPicker = true
                            } label: {
                                HStack {
                                    Text("Battery Color")
                                    Spacer()
                                    Circle()
                                        .fill(Color(hex: viewModel.batteryColorHex))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    } else {
                        Text("Battery color changes based on level: Red (≤20%), Yellow (≤50%), Green (≤80%), White (>80%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Animation Section
            Section(header: Text("Animation")) {
                Toggle("Enable Animation", isOn: $viewModel.enableAnimation)
                
                if viewModel.enableAnimation {
                    Picker("Animation Type", selection: $viewModel.animationType) {
                        Text("Bounce").tag("bounce")
                        Text("Fade").tag("fade")
                        Text("Scale").tag("scale")
                        Text("Slide").tag("slide")
                        Text("Spring").tag("spring")
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.animationDuration))s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.animationDuration, in: 0.1...2.0, step: 0.1)
                    
                    HStack {
                        Text("Delay")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.animationDelay))s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.animationDelay, in: 0...2.0, step: 0.1)
                }
            }
            
            // Auto-hide Section
            Section(header: Text("Auto-hide")) {
                Toggle("Auto-hide Status Bar", isOn: $viewModel.autoHide)
                
                if viewModel.autoHide {
                    HStack {
                        Text("Hide After")
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.autoHideDelay))s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.autoHideDelay, in: 1.0...10.0, step: 0.5)
                    
                    Toggle("Show on Tap", isOn: $viewModel.showOnTap)
                }
            }
            
            // Spacing Section
            Section(header: Text("Spacing & Layout")) {
                HStack {
                    Text("Item Spacing")
                    Spacer()
                    Text("\(Int(viewModel.itemSpacing)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.itemSpacing, in: 0...24, step: 2)
                
                HStack {
                    Text("Vertical Offset")
                    Spacer()
                    Text("\(Int(viewModel.verticalOffset)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.verticalOffset, in: -20...20, step: 1)
            }
            
            // Background Section
            Section(header: Text("Background")) {
                Toggle("Show Background", isOn: $viewModel.showBackground)
                
                if viewModel.showBackground {
                    Toggle("Blur Background", isOn: $viewModel.blurBackground)
                    
                    if viewModel.blurBackground {
                        Picker("Blur Style", selection: $viewModel.blurStyle) {
                            Text("Regular").tag("regular")
                            Text("Thin").tag("thin")
                            Text("Thick").tag("thick")
                            Text("Chrome").tag("chrome")
                            Text("Material").tag("material")
                        }
                    }
                    
                    Button {
                        showBackgroundColorPicker = true
                    } label: {
                        HStack {
                            Text("Background Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.backgroundColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(viewModel.backgroundOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.backgroundOpacity, in: 0...1, step: 0.05)
                    
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(viewModel.cornerRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.cornerRadius, in: 0...30, step: 1)
                }
            }
            
            // Shadow Section
            Section(header: Text("Shadow")) {
                Toggle("Enable Shadow", isOn: $viewModel.shadowEnabled)
                
                if viewModel.shadowEnabled {
                    Button {
                        showShadowColorPicker = true
                    } label: {
                        HStack {
                            Text("Shadow Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.shadowColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Shadow Radius")
                        Spacer()
                        Text("\(Int(viewModel.shadowRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.shadowRadius, in: 0...20, step: 1)
                }
            }
            
            // Border Section
            Section(header: Text("Border")) {
                HStack {
                    Text("Border Width")
                    Spacer()
                    Text("\(Int(viewModel.borderWidth)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.borderWidth, in: 0...5, step: 0.5)
                
                if viewModel.borderWidth > 0 {
                    Button {
                        showBorderColorPicker = true
                    } label: {
                        HStack {
                            Text("Border Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.borderColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Reset Section
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Defaults")
                        Spacer()
                    }
                }
            }
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
