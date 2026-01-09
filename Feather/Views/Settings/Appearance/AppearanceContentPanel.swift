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
            
            // Battery Section (standalone, not a widget)
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
