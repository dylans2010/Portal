import SwiftUI
import NimbleViews

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let bg: String
    let ui: String
    let text: String
    let tint: String
    var secondaryText: String?
    var cardRadius: Double?
    var fontDesign: String?

    // New fields
    var navBarColor: String?
    var tabBarColor: String?
    var dividerColor: String?
    var sheetBackgroundColor: String?
    var successColor: String?
    var warningColor: String?
    var errorColor: String?
    var glowIntensity: Double?
    var borderWidth: Double?
    var cardOpacity: Double?
}

struct ColorCustomizationView: View {
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @AppStorage("Feather.animateBackground") private var animateBackground: Bool = false

    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex: String = "#8E8E93"
    @AppStorage(UserDefaults.Keys.cardCornerRadius) private var cardCornerRadius: Double = 16.0
    @AppStorage(UserDefaults.Keys.buttonCornerRadius) private var buttonCornerRadius: Double = 12.0
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.shadowIntensity) private var shadowIntensity: Double = 5.0
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity: Double = 1.0
    @AppStorage(UserDefaults.Keys.navBarColor) private var navBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.tabBarColor) private var tabBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.dividerColor) private var dividerColorHex: String = "#E5E5EA"
    @AppStorage(UserDefaults.Keys.sheetBackgroundColor) private var sheetBackgroundColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.successColor) private var successColorHex: String = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor) private var warningColorHex: String = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor) private var errorColorHex: String = "#FF3B30"
    @AppStorage(UserDefaults.Keys.glowIntensity) private var glowIntensity: Double = 10.0
    @AppStorage(UserDefaults.Keys.borderWidth) private var borderWidth: Double = 0.0
    @AppStorage(UserDefaults.Keys.cardOpacity) private var cardOpacity: Double = 1.0
    @AppStorage("Feather.userTintColor") private var tintColorHex: String = "#0077BE"
    @AppStorage("Feather.userThemes") private var userThemesData: Data = Data()
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true

    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black
    @State private var secondaryTextColor: Color = .gray
    @State private var tintColor: Color = .blue

    @State private var navBarColor: Color = .white
    @State private var tabBarColor: Color = .white
    @State private var dividerColor: Color = .gray
    @State private var sheetBackgroundColor: Color = .white
    @State private var successColor: Color = .green
    @State private var warningColor: Color = .orange
    @State private var errorColor: Color = .red

    @State private var showAllThemes = false
    @State private var themeName: String = ""
    @State private var showSaveAlert = false
    @State private var showResetAlert = false
    @ObservedObject private var appState = AppStateManager.shared
    @Environment(\.colorScheme) var colorScheme

    private let presetThemes: [ColorTheme] = [
        ColorTheme(name: "Classic", bg: "#F2F2F7", ui: "#007AFF", text: "#000000", tint: "#007AFF", secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Midnight", bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF", tint: "#0A84FF", secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "rounded"),
        ColorTheme(name: "OLED Black", bg: "#000000", ui: "#30D158", text: "#FFFFFF", tint: "#30D158", secondaryText: "#A1A1A1", cardRadius: 12, fontDesign: "monospaced"),
        ColorTheme(name: "Nordic", bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4", tint: "#88C0D0", secondaryText: "#D8DEE9", cardRadius: 8, fontDesign: "default"),
        ColorTheme(name: "Forest", bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC", tint: "#74C69D", secondaryText: "#95D5B2", cardRadius: 20, fontDesign: "serif"),
        ColorTheme(name: "Crimson", bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6", tint: "#FF453A", secondaryText: "#FFBABA", cardRadius: 14, fontDesign: "default"),
        ColorTheme(name: "Vibrant", bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC", tint: "#F43F5E", secondaryText: "#E2E8F0", cardRadius: 18, fontDesign: "rounded"),
        ColorTheme(name: "Sepia", bg: "#F4ECD8", ui: "#8B4513", text: "#433422", tint: "#8B4513", secondaryText: "#5D4037", cardRadius: 4, fontDesign: "serif"),
        ColorTheme(name: "Lavender", bg: "#F3E5F5", ui: "#9C27B0", text: "#4A148C", tint: "#9C27B0", secondaryText: "#7B1FA2", cardRadius: 24, fontDesign: "rounded"),
        ColorTheme(name: "Ocean", bg: "#E0F7FA", ui: "#00BCD4", text: "#006064", tint: "#00BCD4", secondaryText: "#00838F", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Rose Gold", bg: "#FFF1F0", ui: "#FF85C0", text: "#5C0011", tint: "#FF85C0", secondaryText: "#9E1068", cardRadius: 30, fontDesign: "serif"),
        ColorTheme(name: "Slate", bg: "#263238", ui: "#90A4AE", text: "#ECEFF1", tint: "#90A4AE", secondaryText: "#B0BEC5", cardRadius: 0, fontDesign: "monospaced"),
        ColorTheme(name: "Mint", bg: "#E8F5E9", ui: "#4CAF50", text: "#1B5E20", tint: "#4CAF50", secondaryText: "#2E7D32", cardRadius: 16, fontDesign: "rounded")
    ]

    private var userThemes: [ColorTheme] {
        get {
            guard let themes = try? JSONDecoder().decode([ColorTheme].self, from: userThemesData) else { return [] }
            return themes
        }
        nonmutating set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userThemesData = encoded
            }
        }
    }

    private var allThemes: [ColorTheme] {
        presetThemes + userThemes
    }

    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    ColorHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // MARK: - Theme Gallery
            Section {
                themeGallerySection
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                Text("Theme Gallery")
            }

            // MARK: - Custom Colors
            Section {
                colorPickerRow(title: "Background", subtext: "Main app background color", color: $backgroundManager.baseColor, icon: "square.fill")
                colorPickerRow(title: "UI Elements", subtext: "Cards and buttons color", color: $uiElementColor, icon: "app.fill")
                colorPickerRow(title: "Primary Text", subtext: "Titles and body text color", color: $textColor, icon: "textformat")
                colorPickerRow(title: "Secondary Text", subtext: "Descriptions and hints color", color: $secondaryTextColor, icon: "textformat.size")
                colorPickerRow(title: "Accent", subtext: "Interactive elements highlights", color: $tintColor, icon: "sparkles")
                colorPickerRow(title: "Nav Bar", subtext: "Navigation bar color", color: $navBarColor, icon: "menubar.rectangle")
                colorPickerRow(title: "Tab Bar", subtext: "Tab bar color", color: $tabBarColor, icon: "dock.rectangle")
                colorPickerRow(title: "Divider", subtext: "Lines color", color: $dividerColor, icon: "minus")
                colorPickerRow(title: "Sheet BG", subtext: "Sheet background color", color: $sheetBackgroundColor, icon: "square.stack")
                colorPickerRow(title: "Success", subtext: "Success indicators color", color: $successColor, icon: "checkmark.circle")
                colorPickerRow(title: "Warning", subtext: "Warning alerts color", color: $warningColor, icon: "exclamationmark.triangle")
                colorPickerRow(title: "Error", subtext: "Error messages color", color: $errorColor, icon: "xmark.circle")
            } header: {
                Text("Custom Colors")
            }

            // MARK: - Advanced Styling
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Fonts", systemImage: "text.cursor")
                        Spacer()
                        Picker("Design", selection: $fontDesign) {
                            Text("Default").tag("default")
                            Text("Rounded").tag("rounded")
                            Text("Serif").tag("serif")
                            Text("Monospaced").tag("monospaced")
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.vertical, 4)

                advancedSliderRow(title: "Card Corners", value: $cardCornerRadius, range: 0...40, step: 2, unit: "pt", icon: "square.dashed")
                advancedSliderRow(title: "Button Corners", value: $buttonCornerRadius, range: 0...20, step: 1, unit: "pt", icon: "rectangle.roundedbottom")
                advancedSliderRow(title: "Shadow Intensity", value: $shadowIntensity, range: 0...20, step: 1, icon: "shadow")
                advancedSliderRow(title: "Blur Opacity", value: $blurOpacity, range: 0...1, step: 0.05, isPercent: true, icon: "drop.halffull")
                advancedSliderRow(title: "Glow Intensity", value: $glowIntensity, range: 0...30, step: 1, icon: "sun.max.fill")
                advancedSliderRow(title: "Border Width", value: $borderWidth, range: 0...5, step: 0.5, unit: "pt", icon: "square.and.line.vertical.and.square")
                advancedSliderRow(title: "Card Opacity", value: $cardOpacity, range: 0.1...1, step: 0.05, isPercent: true, icon: "square.stack.3d.down.right")

                Toggle(isOn: $animateBackground) {
                    Label("Animate Background", systemImage: "sparkles")
                }
            } header: {
                Text("Advanced Styling")
            }

            // MARK: - Actions
            Section {
                Button {
                    showSaveAlert = true
                } label: {
                    Label("Save Current Style", systemImage: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(appState.isSigning)

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Reset To Defaults", systemImage: "arrow.counterclockwise")
                }
                .disabled(appState.isSigning)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAllThemes = true
                } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .onAppear {
            loadColors()
        }
        .sheet(isPresented: $showAllThemes) {
            ThemeLibraryView(themes: allThemes) { theme in
                applyTheme(theme)
                showAllThemes = false
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Save Theme", isPresented: $showSaveAlert) {
            TextField("Theme Name", text: $themeName)
            Button("Save") {
                saveStyle()
                themeName = ""
            }
            Button("Cancel", role: .cancel) {
                themeName = ""
            }
        } message: {
            Text("Enter a name for your custom theme.")
        }
        .alert("Reset Appearance", isPresented: $showResetAlert) {
            Button("Reset Everything", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all colors to their original system defaults. Your saved custom themes will not be deleted.")
        }
        .onChange(of: uiElementColor) { newValue in uiElementColorHex = newValue.toHex() ?? Color.defaultUIElement }
        .onChange(of: textColor) { newValue in textColorHex = newValue.toHex() ?? Color.defaultText }
        .onChange(of: secondaryTextColor) { newValue in secondaryTextColorHex = newValue.toHex() ?? "#8E8E93" }
        .onChange(of: tintColor) { newValue in tintColorHex = newValue.toHex() ?? "#0077BE" }
        .onChange(of: navBarColor) { newValue in navBarColorHex = newValue.toHex() ?? "#FFFFFF" }
        .onChange(of: tabBarColor) { newValue in tabBarColorHex = newValue.toHex() ?? "#FFFFFF" }
        .onChange(of: dividerColor) { newValue in dividerColorHex = newValue.toHex() ?? "#E5E5EA" }
        .onChange(of: sheetBackgroundColor) { newValue in sheetBackgroundColorHex = newValue.toHex() ?? "#FFFFFF" }
        .onChange(of: successColor) { newValue in successColorHex = newValue.toHex() ?? "#34C759" }
        .onChange(of: warningColor) { newValue in warningColorHex = newValue.toHex() ?? "#FF9500" }
        .onChange(of: errorColor) { newValue in errorColorHex = newValue.toHex() ?? "#FF3B30" }
    }

    // MARK: - Component Views

    private var themeGallerySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(allThemes.prefix(8)) { theme in
                    ModernThemeCard(theme: theme) {
                        if !appState.isSigning {
                            applyTheme(theme)
                        }
                    }
                    .disabled(appState.isSigning)
                    .opacity(appState.isSigning ? 0.6 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func colorPickerRow(title: String, subtext: String, color: Binding<Color>, icon: String) -> some View {
        ColorPicker(selection: color, supportsOpacity: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.wrappedValue.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color.wrappedValue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(subtext)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func advancedSliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String = "", isPercent: Bool = false, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(isPercent ? "\(Int(value.wrappedValue * 100))%" : "\(Int(value.wrappedValue))\(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.vertical, 8)
    }

    private var selectedDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    // MARK: - Helper Methods

    private func loadColors() {
        uiElementColor = Color(hex: uiElementColorHex)

        // Handle dark mode default text color specifically in UI
        if colorScheme == .dark && (textColorHex == Color.defaultText || textColorHex == "#000000") {
            textColor = .white
        } else {
            textColor = Color(hex: textColorHex)
        }

        secondaryTextColor = Color(hex: secondaryTextColorHex)
        tintColor = Color(hex: tintColorHex)

        navBarColor = Color(hex: navBarColorHex)
        tabBarColor = Color(hex: tabBarColorHex)
        dividerColor = Color(hex: dividerColorHex)
        sheetBackgroundColor = Color(hex: sheetBackgroundColorHex)
        successColor = Color(hex: successColorHex)
        warningColor = Color(hex: warningColorHex)
        errorColor = Color(hex: errorColorHex)
    }

    private func applyTheme(_ theme: ColorTheme) {
        backgroundManager.baseColor = Color(hex: theme.bg)
        uiElementColorHex = theme.ui
        textColorHex = theme.text
        tintColorHex = theme.tint

        if let st = theme.secondaryText { secondaryTextColorHex = st }
        if let cr = theme.cardRadius { cardCornerRadius = cr }
        if let fd = theme.fontDesign { fontDesign = fd }

        if let nb = theme.navBarColor { navBarColorHex = nb }
        if let tb = theme.tabBarColor { tabBarColorHex = tb }
        if let dc = theme.dividerColor { dividerColorHex = dc }
        if let sb = theme.sheetBackgroundColor { sheetBackgroundColorHex = sb }
        if let sc = theme.successColor { successColorHex = sc }
        if let wc = theme.warningColor { warningColorHex = wc }
        if let ec = theme.errorColor { errorColorHex = ec }
        if let gi = theme.glowIntensity { glowIntensity = gi }
        if let bw = theme.borderWidth { borderWidth = bw }
        if let co = theme.cardOpacity { cardOpacity = co }

        loadColors()
        HapticsManager.shared.success()
    }

    private func saveStyle() {
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: backgroundManager.baseColor.toHex() ?? Color.defaultBackground,
            ui: uiElementColor.toHex() ?? Color.defaultUIElement,
            text: textColor.toHex() ?? Color.defaultText,
            tint: tintColor.toHex() ?? "#0077BE",
            secondaryText: secondaryTextColor.toHex() ?? "#8E8E93",
            cardRadius: cardCornerRadius,
            fontDesign: fontDesign,
            navBarColor: navBarColor.toHex(),
            tabBarColor: tabBarColor.toHex(),
            dividerColor: dividerColor.toHex(),
            sheetBackgroundColor: sheetBackgroundColor.toHex(),
            successColor: successColor.toHex(),
            warningColor: warningColor.toHex(),
            errorColor: errorColor.toHex(),
            glowIntensity: glowIntensity,
            borderWidth: borderWidth,
            cardOpacity: cardOpacity
        )
        var updatedThemes = userThemes
        updatedThemes.append(newTheme)
        userThemes = updatedThemes
        HapticsManager.shared.success()
    }

    private func resetToDefaults() {
        backgroundManager.baseColor = Color(hex: Color.defaultBackground)
        uiElementColorHex = Color.defaultUIElement
        textColorHex = Color.defaultText
        secondaryTextColorHex = "#8E8E93"
        cardCornerRadius = 16.0
        buttonCornerRadius = 12.0
        fontDesign = "default"
        shadowIntensity = 5.0
        blurOpacity = 1.0
        navBarColorHex = "#F2F2F7"
        tabBarColorHex = "#F2F2F7"
        dividerColorHex = "#E5E5EA"
        sheetBackgroundColorHex = "#F2F2F7"
        successColorHex = "#34C759"
        warningColorHex = "#FF9500"
        errorColorHex = "#FF3B30"
        glowIntensity = 10.0
        borderWidth = 0.0
        cardOpacity = 1.0
        tintColorHex = "#0077BE"
        loadColors()
        HapticsManager.shared.success()
    }
}

// MARK: - Modern Theme Card

struct ModernThemeCard: View {
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(width: 130, height: 90)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: theme.ui))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color(hex: theme.tint))
                                .frame(width: 16, height: 16)
                        }

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: theme.text))
                            .frame(width: 50, height: 6)
                    }
                }

                Text(theme.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Library View

struct ThemeLibraryView: View {
    @Environment(\.dismiss) var dismiss
    let themes: [ColorTheme]
    let onSelect: (ColorTheme) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(themes) { theme in
                        ModernThemeCard(theme: theme) {
                            onSelect(theme)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("All Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .background(Color.clear)
        }
    }
}
