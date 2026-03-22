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
    private enum EditorSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case colors = "Colors"
        case styling = "Styling"
        case sections = "Sections"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "sparkles"
            case .colors: return "paintpalette.fill"
            case .styling: return "slider.horizontal.3"
            case .sections: return "square.grid.2x2.fill"
            }
        }
    }

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
    @State private var selectedSection: EditorSection = .overview
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

    private var allThemes: [ColorTheme] { presetThemes + userThemes }

    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    ColorHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Picker("Section", selection: $selectedSection) {
                    ForEach(EditorSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.icon).tag(section)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch selectedSection {
            case .overview:
                overviewSection
            case .colors:
                paletteSection
                semanticColorsSection
            case .styling:
                stylingSection
                advancedEffectsSection
            case .sections:
                customizationLinksSection
            }

            actionsSection
        }
        .navigationTitle("Visual Design")
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
        .onAppear(perform: loadColors)
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
        .onChange(of: uiElementColor) { uiElementColorHex = $0.toHex() ?? Color.defaultUIElement }
        .onChange(of: textColor) { textColorHex = $0.toHex() ?? Color.defaultText }
        .onChange(of: secondaryTextColor) { secondaryTextColorHex = $0.toHex() ?? "#8E8E93" }
        .onChange(of: tintColor) { tintColorHex = $0.toHex() ?? "#0077BE" }
        .onChange(of: navBarColor) { navBarColorHex = $0.toHex() ?? "#FFFFFF" }
        .onChange(of: tabBarColor) { tabBarColorHex = $0.toHex() ?? "#FFFFFF" }
        .onChange(of: dividerColor) { dividerColorHex = $0.toHex() ?? "#E5E5EA" }
        .onChange(of: sheetBackgroundColor) { sheetBackgroundColorHex = $0.toHex() ?? "#FFFFFF" }
        .onChange(of: successColor) { successColorHex = $0.toHex() ?? "#34C759" }
        .onChange(of: warningColor) { warningColorHex = $0.toHex() ?? "#FF9500" }
        .onChange(of: errorColor) { errorColorHex = $0.toHex() ?? "#FF3B30" }
    }

    private var overviewSection: some View {
        Group {
            Section {
                appearancePreviewCard
                quickActionsRow
            } header: {
                Text("Live Preview")
            } footer: {
                Text("Use the quick actions to instantly sync surfaces, soften the interface, or add a more vivid look without leaving this screen.")
            }

            Section {
                themeGallerySection
            } header: {
                Text("Theme Shortcuts")
            }
        }
    }

    private var paletteSection: some View {
        Section {
            colorPickerRow(title: "Background", subtext: "Main app background color", color: $backgroundManager.baseColor, icon: "square.fill")
            colorPickerRow(title: "UI Elements", subtext: "Cards, panels, and controls", color: $uiElementColor, icon: "app.fill")
            colorPickerRow(title: "Primary Text", subtext: "Titles and body text", color: $textColor, icon: "textformat")
            colorPickerRow(title: "Secondary Text", subtext: "Descriptions and helper labels", color: $secondaryTextColor, icon: "textformat.size")
            colorPickerRow(title: "Accent", subtext: "Interactive highlights and focus", color: $tintColor, icon: "sparkles")
        } header: {
            Text("Core Palette")
        }
    }

    private var semanticColorsSection: some View {
        Section {
            colorPickerRow(title: "Navigation Bar", subtext: "Top navigation chrome", color: $navBarColor, icon: "menubar.rectangle")
            colorPickerRow(title: "Tab Bar", subtext: "Bottom tab bar surface", color: $tabBarColor, icon: "dock.rectangle")
            colorPickerRow(title: "Sheet Background", subtext: "Presented sheets and popovers", color: $sheetBackgroundColor, icon: "square.stack")
            colorPickerRow(title: "Divider", subtext: "Lines and separators", color: $dividerColor, icon: "minus")
            colorPickerRow(title: "Success", subtext: "Positive states and confirmations", color: $successColor, icon: "checkmark.circle")
            colorPickerRow(title: "Warning", subtext: "Caution states and prompts", color: $warningColor, icon: "exclamationmark.triangle")
            colorPickerRow(title: "Error", subtext: "Errors and destructive alerts", color: $errorColor, icon: "xmark.circle")
        } header: {
            Text("Semantic Colors")
        }
    }

    private var stylingSection: some View {
        Section {
            Picker("Font Design", selection: $fontDesign) {
                Text("Default").tag("default")
                Text("Rounded").tag("rounded")
                Text("Serif").tag("serif")
                Text("Monospaced").tag("monospaced")
            }
            advancedSliderRow(title: "Card Corners", value: $cardCornerRadius, range: 0...40, step: 2, unit: "pt", icon: "square.dashed")
            advancedSliderRow(title: "Button Corners", value: $buttonCornerRadius, range: 0...24, step: 1, unit: "pt", icon: "button.programmable")
            advancedSliderRow(title: "Card Opacity", value: $cardOpacity, range: 0.1...1.0, step: 0.05, isPercent: true, icon: "square.stack.3d.down.right")
            advancedSliderRow(title: "Border Width", value: $borderWidth, range: 0...5, step: 0.5, unit: "pt", icon: "square.and.line.vertical.and.square")
            advancedSliderRow(title: "Shadow Intensity", value: $shadowIntensity, range: 0...20, step: 1, icon: "shadow")
        } header: {
            Text("Surfaces & Typography")
        }
    }

    private var advancedEffectsSection: some View {
        Section {
            advancedSliderRow(title: "Blur Opacity", value: $blurOpacity, range: 0...1, step: 0.05, isPercent: true, icon: "drop.halffull")
            advancedSliderRow(title: "Glow Intensity", value: $glowIntensity, range: 0...30, step: 1, icon: "sun.max.fill")
            Toggle(isOn: $animateBackground) {
                Label("Animate Background", systemImage: "sparkles")
            }
            Button {
                syncBarsWithBackground()
            } label: {
                Label("Match Navigation + Tab Bars", systemImage: "arrow.triangle.2.circlepath")
            }
            Button {
                applyHighContrastPreset()
            } label: {
                Label("Apply High Contrast Boost", systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text("Effects & Shortcuts")
        }
    }

    private var customizationLinksSection: some View {
        Section {
            NavigationLink(destination: AllAppsCustomizationView()) {
                Label("All Apps", systemImage: "square.grid.2x2.fill")
                    .foregroundStyle(Color.accentColor)
            }
            NavigationLink(destination: AppHideElementsView()) {
                Label("Hide UI Elements", systemImage: "eye.slash.fill")
                    .foregroundStyle(Color.accentColor)
            }
            NavigationLink(destination: StatusBarCustomizationView()) {
                Label("Status Bar", systemImage: "rectangle.topthird.inset.filled")
                    .foregroundStyle(Color.accentColor)
            }
            NavigationLink(destination: TabBarCustomizationView()) {
                Label("Tab Bar", systemImage: "dock.rectangle")
                    .foregroundStyle(Color.accentColor)
            }
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                NavigationLink(destination: KeyboardCustomizationView()) {
                    Label("Keyboard Backdrop", systemImage: "keyboard")
                        .foregroundStyle(Color.accentColor)
                }
            }
            NavigationLink(destination: TopViewAppearance()) {
                Label("Top View", systemImage: "uiwindow.split.2x1")
                    .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Customization", systemImage: "slider.horizontal.3")
        }
    }

    private var actionsSection: some View {
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

    private var appearancePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Portal Preview")
                        .font(.system(size: 20, weight: .bold, design: selectedDesign))
                        .foregroundStyle(textColor)
                    Text("See your palette, card styling, and semantic colors together before you save it.")
                        .font(.system(size: 12, design: selectedDesign))
                        .foregroundStyle(secondaryTextColor)
                }
                Spacer()
                Circle()
                    .fill(tintColor)
                    .frame(width: 14, height: 14)
                    .shadow(color: tintColor.opacity(0.5), radius: glowIntensity / 6)
            }

            HStack(spacing: 12) {
                previewPill(title: "Success", color: successColor, icon: "checkmark")
                previewPill(title: "Warn", color: warningColor, icon: "exclamationmark")
                previewPill(title: "Error", color: errorColor, icon: "xmark")
            }

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(uiElementColor.opacity(cardOpacity))
                    .overlay(
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Main Card")
                                    .font(.system(size: 16, weight: .semibold, design: selectedDesign))
                                    .foregroundStyle(textColor)
                                Text("Buttons, cards, and content containers will follow this styling.")
                                    .font(.system(size: 11, design: selectedDesign))
                                    .foregroundStyle(secondaryTextColor)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous)
                                .fill(tintColor)
                                .frame(width: 74, height: 34)
                                .overlay {
                                    Text("Action")
                                        .font(.system(size: 12, weight: .bold, design: selectedDesign))
                                        .foregroundStyle(Color.white)
                                }
                        }
                        .padding(14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(dividerColor.opacity(max(0.2, borderWidth / 5)), lineWidth: max(1, borderWidth))
                    )
                    .shadow(color: .black.opacity(shadowIntensity / 40), radius: shadowIntensity, y: 4)
                    .frame(height: 110)

                HStack(spacing: 10) {
                    previewBar(title: "Nav", color: navBarColor)
                    previewBar(title: "Tab", color: tabBarColor)
                    previewBar(title: "Sheet", color: sheetBackgroundColor)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundManager.baseColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(dividerColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionButton(title: "Sync Bars", icon: "rectangle.2.swap", tint: navBarColor) {
                    syncBarsWithBackground()
                }
                quickActionButton(title: "Soft Glass", icon: "drop", tint: sheetBackgroundColor) {
                    blurOpacity = 0.75
                    cardOpacity = 0.88
                    borderWidth = max(borderWidth, 1)
                }
                quickActionButton(title: "Pop Accent", icon: "sparkles", tint: tintColor) {
                    glowIntensity = min(30, glowIntensity + 6)
                    shadowIntensity = min(20, shadowIntensity + 2)
                }
                quickActionButton(title: "Contrast", icon: "circle.lefthalf.filled", tint: textColor) {
                    applyHighContrastPreset()
                }
            }
            .padding(.vertical, 4)
        }
    }

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
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    private func colorPickerRow(title: String, subtext: String, color: Binding<Color>, icon: String) -> some View {
        ColorPicker(selection: color, supportsOpacity: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.wrappedValue.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color.wrappedValue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(subtext)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(color.wrappedValue.toHex() ?? "—")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func advancedSliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String = "", isPercent: Bool = false, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(isPercent ? "\(Int(value.wrappedValue * 100))%" : "\(String(format: value.wrappedValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value.wrappedValue))\(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.vertical, 4)
    }

    private func quickActionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 88, alignment: .leading)
            .padding(12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func previewPill(title: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 12, weight: .semibold, design: selectedDesign))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: Capsule())
    }

    private func previewBar(title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(dividerColor.opacity(0.25), lineWidth: 1)
                )
            Text(title)
                .font(.system(size: 11, weight: .medium, design: selectedDesign))
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var selectedDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    private func syncBarsWithBackground() {
        navBarColor = backgroundManager.baseColor
        tabBarColor = backgroundManager.baseColor
        sheetBackgroundColor = backgroundManager.baseColor
        dividerColor = uiElementColor.opacity(0.6)
        HapticsManager.shared.softImpact()
    }

    private func applyHighContrastPreset() {
        textColor = colorScheme == .dark ? .white : .black
        secondaryTextColor = colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.62)
        borderWidth = max(borderWidth, 1)
        shadowIntensity = max(shadowIntensity, 8)
        glowIntensity = min(max(glowIntensity, 8), 20)
        HapticsManager.shared.success()
    }

    private func loadColors() {
        uiElementColor = Color(hex: uiElementColorHex)
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
                            Circle().fill(Color(hex: theme.ui)).frame(width: 16, height: 16)
                            Circle().fill(Color(hex: theme.tint)).frame(width: 16, height: 16)
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
