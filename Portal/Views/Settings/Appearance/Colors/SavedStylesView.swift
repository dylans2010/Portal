import SwiftUI

// MARK: - Saved Style Model
struct StatusBarStyle: Codable, Identifiable {
    let id: UUID
    var name: String
    
    // Content
    var customText: String
    var showCustomText: Bool
    var sfSymbol: String
    var showSFSymbol: Bool
    
    // Styling
    var isBold: Bool
    var colorHex: String
    var fontSize: Double
    var fontDesign: String
    
    // Background
    var showBackground: Bool
    var backgroundColorHex: String
    var backgroundOpacity: Double
    var blurBackground: Bool
    var cornerRadius: Double
    var borderWidth: Double
    var borderColorHex: String
    
    // Shadow
    var shadowEnabled: Bool
    var shadowColorHex: String
    var shadowRadius: Double
    
    // Layout
    var alignment: String
    var leftPadding: Double
    var rightPadding: Double
    var topPadding: Double
    var bottomPadding: Double
    
    // Text Layout
    var textAlignment: String
    var textLeftPadding: Double
    var textRightPadding: Double
    var textTopPadding: Double
    var textBottomPadding: Double
    
    // SF Symbol Layout
    var sfSymbolAlignment: String
    var sfSymbolLeftPadding: Double
    var sfSymbolRightPadding: Double
    var sfSymbolTopPadding: Double
    var sfSymbolBottomPadding: Double
    
    // Time
    var showTime: Bool
    var showSeconds: Bool
    var use24HourClock: Bool
    var timeAlignment: String
    var timeAccentColored: Bool
    var timeColorHex: String
    var timeLeftPadding: Double
    var timeRightPadding: Double
    var timeTopPadding: Double
    var timeBottomPadding: Double
    
    // Battery
    var showBattery: Bool
    var batteryAlignment: String
    var batteryAccentColored: Bool
    var batteryUseAutoColor: Bool
    var batteryColorHex: String
    var batteryStyle: String
    var batteryLeftPadding: Double
    var batteryRightPadding: Double
    var batteryTopPadding: Double
    var batteryBottomPadding: Double
    
    init(name: String, viewModel: StatusBarViewModel) {
        self.id = UUID()
        self.name = name
        
        // Copy all properties from view model
        self.customText = viewModel.customText
        self.showCustomText = viewModel.showCustomText
        self.sfSymbol = viewModel.sfSymbol
        self.showSFSymbol = viewModel.showSFSymbol
        
        self.isBold = viewModel.isBold
        self.colorHex = viewModel.colorHex
        self.fontSize = viewModel.fontSize
        self.fontDesign = viewModel.fontDesign
        
        self.showBackground = viewModel.showBackground
        self.backgroundColorHex = viewModel.backgroundColorHex
        self.backgroundOpacity = viewModel.backgroundOpacity
        self.blurBackground = viewModel.blurBackground
        self.cornerRadius = viewModel.cornerRadius
        self.borderWidth = viewModel.borderWidth
        self.borderColorHex = viewModel.borderColorHex
        
        self.shadowEnabled = viewModel.shadowEnabled
        self.shadowColorHex = viewModel.shadowColorHex
        self.shadowRadius = viewModel.shadowRadius
        
        self.alignment = viewModel.alignment
        self.leftPadding = viewModel.leftPadding
        self.rightPadding = viewModel.rightPadding
        self.topPadding = viewModel.topPadding
        self.bottomPadding = viewModel.bottomPadding
        
        self.textAlignment = viewModel.textAlignment
        self.textLeftPadding = viewModel.textLeftPadding
        self.textRightPadding = viewModel.textRightPadding
        self.textTopPadding = viewModel.textTopPadding
        self.textBottomPadding = viewModel.textBottomPadding
        
        self.sfSymbolAlignment = viewModel.sfSymbolAlignment
        self.sfSymbolLeftPadding = viewModel.sfSymbolLeftPadding
        self.sfSymbolRightPadding = viewModel.sfSymbolRightPadding
        self.sfSymbolTopPadding = viewModel.sfSymbolTopPadding
        self.sfSymbolBottomPadding = viewModel.sfSymbolBottomPadding
        
        self.showTime = viewModel.showTime
        self.showSeconds = viewModel.showSeconds
        self.use24HourClock = viewModel.use24HourClock
        self.timeAlignment = viewModel.timeAlignment
        self.timeAccentColored = viewModel.timeAccentColored
        self.timeColorHex = viewModel.timeColorHex
        self.timeLeftPadding = viewModel.timeLeftPadding
        self.timeRightPadding = viewModel.timeRightPadding
        self.timeTopPadding = viewModel.timeTopPadding
        self.timeBottomPadding = viewModel.timeBottomPadding
        
        self.showBattery = viewModel.showBattery
        self.batteryAlignment = viewModel.batteryAlignment
        self.batteryAccentColored = viewModel.batteryAccentColored
        self.batteryUseAutoColor = viewModel.batteryUseAutoColor
        self.batteryColorHex = viewModel.batteryColorHex
        self.batteryStyle = viewModel.batteryStyle
        self.batteryLeftPadding = viewModel.batteryLeftPadding
        self.batteryRightPadding = viewModel.batteryRightPadding
        self.batteryTopPadding = viewModel.batteryTopPadding
        self.batteryBottomPadding = viewModel.batteryBottomPadding
    }
    
    func applyTo(viewModel: StatusBarViewModel) {
        viewModel.customText = customText
        viewModel.showCustomText = showCustomText
        viewModel.sfSymbol = sfSymbol
        viewModel.showSFSymbol = showSFSymbol
        
        viewModel.isBold = isBold
        viewModel.colorHex = colorHex
        viewModel.fontSize = fontSize
        viewModel.fontDesign = fontDesign
        
        viewModel.showBackground = showBackground
        viewModel.backgroundColorHex = backgroundColorHex
        viewModel.backgroundOpacity = backgroundOpacity
        viewModel.blurBackground = blurBackground
        viewModel.cornerRadius = cornerRadius
        viewModel.borderWidth = borderWidth
        viewModel.borderColorHex = borderColorHex
        
        viewModel.shadowEnabled = shadowEnabled
        viewModel.shadowColorHex = shadowColorHex
        viewModel.shadowRadius = shadowRadius
        
        viewModel.alignment = alignment
        viewModel.leftPadding = leftPadding
        viewModel.rightPadding = rightPadding
        viewModel.topPadding = topPadding
        viewModel.bottomPadding = bottomPadding
        
        viewModel.textAlignment = textAlignment
        viewModel.textLeftPadding = textLeftPadding
        viewModel.textRightPadding = textRightPadding
        viewModel.textTopPadding = textTopPadding
        viewModel.textBottomPadding = textBottomPadding
        
        viewModel.sfSymbolAlignment = sfSymbolAlignment
        viewModel.sfSymbolLeftPadding = sfSymbolLeftPadding
        viewModel.sfSymbolRightPadding = sfSymbolRightPadding
        viewModel.sfSymbolTopPadding = sfSymbolTopPadding
        viewModel.sfSymbolBottomPadding = sfSymbolBottomPadding
        
        viewModel.showTime = showTime
        viewModel.showSeconds = showSeconds
        viewModel.use24HourClock = use24HourClock
        viewModel.timeAlignment = timeAlignment
        viewModel.timeAccentColored = timeAccentColored
        viewModel.timeColorHex = timeColorHex
        viewModel.timeLeftPadding = timeLeftPadding
        viewModel.timeRightPadding = timeRightPadding
        viewModel.timeTopPadding = timeTopPadding
        viewModel.timeBottomPadding = timeBottomPadding
        
        viewModel.showBattery = showBattery
        viewModel.batteryAlignment = batteryAlignment
        viewModel.batteryAccentColored = batteryAccentColored
        viewModel.batteryUseAutoColor = batteryUseAutoColor
        viewModel.batteryColorHex = batteryColorHex
        viewModel.batteryStyle = batteryStyle
        viewModel.batteryLeftPadding = batteryLeftPadding
        viewModel.batteryRightPadding = batteryRightPadding
        viewModel.batteryTopPadding = batteryTopPadding
        viewModel.batteryBottomPadding = batteryBottomPadding
        
        // Update color pickers
        viewModel.selectedColor = Color(hex: colorHex)
        viewModel.selectedBackgroundColor = Color(hex: backgroundColorHex)
        viewModel.selectedShadowColor = Color(hex: shadowColorHex)
        viewModel.selectedBorderColor = Color(hex: borderColorHex)
        viewModel.selectedTimeColor = Color(hex: timeColorHex)
        viewModel.selectedBatteryColor = Color(hex: batteryColorHex)
    }
}

// MARK: - Saved Styles Manager
class SavedStylesManager: ObservableObject {
    @Published var savedStyles: [StatusBarStyle] = []
    
    private let userDefaultsKey = "statusBar.savedStyles"
    
    init() {
        loadStyles()
    }
    
    func loadStyles() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([StatusBarStyle].self, from: data) {
            savedStyles = decoded
        }
    }
    
    func saveStyles() {
        if let encoded = try? JSONEncoder().encode(savedStyles) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addStyle(_ style: StatusBarStyle) {
        savedStyles.append(style)
        saveStyles()
    }
    
    func deleteStyle(at offsets: IndexSet) {
        savedStyles.remove(atOffsets: offsets)
        saveStyles()
    }
    
    func deleteStyle(_ style: StatusBarStyle) {
        savedStyles.removeAll { $0.id == style.id }
        saveStyles()
    }
}

// MARK: - Saved Styles View
struct SavedStylesView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @StateObject private var stylesManager = SavedStylesManager()
    @State private var showSaveDialog = false
    @State private var newStyleName = ""
    @State private var showDeleteConfirmation = false
    @State private var styleToDelete: StatusBarStyle?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Style")) {
                    Button {
                        showSaveDialog = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Save Current Style")
                            Spacer()
                        }
                    }
                }
                
                if !stylesManager.savedStyles.isEmpty {
                    Section(header: Text("Saved Styles")) {
                        ForEach(stylesManager.savedStyles) { style in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(style.name)
                                        .font(.headline)
                                    
                                    HStack(spacing: 8) {
                                        if style.showCustomText {
                                            Label("Text", systemImage: "textformat")
                                                .font(.caption)
                                        }
                                        if style.showSFSymbol {
                                            Label("Symbol", systemImage: "circle.fill")
                                                .font(.caption)
                                        }
                                        if style.showTime {
                                            Label("Time", systemImage: "clock.fill")
                                                .font(.caption)
                                        }
                                        if style.showBattery {
                                            Label("Battery", systemImage: "battery.100")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button {
                                        applyStyle(style)
                                    } label: {
                                        Text("Apply")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.accentColor)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        styleToDelete = style
                                        showDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("No Saved Styles")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Save your current status bar configuration to quickly switch between different styles.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Saved Styles")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Save Style", isPresented: $showSaveDialog) {
                TextField("Style Name", text: $newStyleName)
                Button("Cancel", role: .cancel) {
                    newStyleName = ""
                }
                Button("Save") {
                    saveCurrentStyle()
                }
            } message: {
                Text("Enter a name for this style")
            }
            .alert("Delete Style", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let style = styleToDelete {
                        stylesManager.deleteStyle(style)
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(styleToDelete?.name ?? "")'?")
            }
        }
    }
    
    private func saveCurrentStyle() {
        let trimmedName = newStyleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check for duplicate names
        if stylesManager.savedStyles.contains(where: { $0.name == trimmedName }) {
            // Could show an alert here, but for now just skip
            newStyleName = ""
            return
        }
        
        let style = StatusBarStyle(name: trimmedName, viewModel: viewModel)
        stylesManager.addStyle(style)
        newStyleName = ""
    }
    
    private func applyStyle(_ style: StatusBarStyle) {
        style.applyTo(viewModel: viewModel)
    }
}

// MARK: - Preview
#Preview {
    SavedStylesView(viewModel: StatusBarViewModel())
}
