import SwiftUI
import NimbleViews

// MARK: - ColorTheme (saved user / preset themes)

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bg: String
    var ui: String
    var text: String
    var tint: String
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
    var sectionHeaderBackground: String?
    var sectionHeaderTextColor: String?
    var sectionHeaderIconColor: String?
    var sectionHeaderDividerColor: String?
    var appearanceMode: Int? = 0
    var scheduleMode: Int? = 0
    var highContrast: Bool? = false
    var colorBlindnessFilter: Int? = 0
    var autoContrastCorrection: Bool? = true
    var hapticIntensity: Double? = 0.5
    var visualFeedbackStrength: Double? = 0.5
    var layerBlendMode: Int? = 0
    var parallaxEnabled: Bool? = false
    var motionGradients: Bool? = true
    var dynamicLighting: Bool? = false
}

// MARK: - Main View

struct ColorCustomizationView: View {
    @EnvironmentObject private var themeManager: AppWideThemeManager
    @EnvironmentObject private var styleManager: SectionStyleManager
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @AppStorage("Feather.userThemes") private var userThemesData: Data = Data()

    // Styling sliders
    @AppStorage(UserDefaults.Keys.cardCornerRadius)   private var cardCornerRadius: Double = 16
    @AppStorage(UserDefaults.Keys.buttonCornerRadius) private var buttonCornerRadius: Double = 12
    @AppStorage(UserDefaults.Keys.fontDesign)         private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.shadowIntensity)    private var shadowIntensity: Double = 5
    @AppStorage(UserDefaults.Keys.blurOpacity)        private var blurOpacity: Double = 1
    @AppStorage(UserDefaults.Keys.glowIntensity)      private var glowIntensity: Double = 10
    @AppStorage(UserDefaults.Keys.borderWidth)        private var borderWidth: Double = 0
    @AppStorage(UserDefaults.Keys.cardOpacity)        private var cardOpacity: Double = 1

    // Semantic / supplemental colors
    @AppStorage(UserDefaults.Keys.successColor)         private var successColorHex: String = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor)         private var warningColorHex: String = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor)           private var errorColorHex: String = "#FF3B30"
    @AppStorage(UserDefaults.Keys.sheetBackgroundColor) private var sheetBGHex: String = "#F2F2F7"

    // Accessibility
    @AppStorage("Feather.appearance.highContrast")           private var highContrast: Bool = false
    @AppStorage("Feather.appearance.autoContrastCorrection") private var autoContrastCorrection: Bool = true
    @AppStorage("Feather.appearance.colorBlindnessFilter")   private var colorBlindnessFilter: Int = 0

    // Feedback
    @AppStorage("Feather.appearance.hapticIntensity")        private var hapticIntensity: Double = 0.5
    @AppStorage("Feather.appearance.visualFeedbackStrength") private var visualFeedbackStrength: Double = 0.5

    // Experimental
    @AppStorage("Feather.appearance.layerBlendMode")  private var layerBlendMode: Int = 0
    @AppStorage("Feather.appearance.parallaxEnabled") private var parallaxEnabled: Bool = false
    @AppStorage("Feather.appearance.motionGradients") private var motionGradients: Bool = true
    @AppStorage("Feather.appearance.performanceMode") private var performanceMode: Bool = false
    @AppStorage("Feather.animateBackground")          private var animateBackground: Bool = false

    // Context-aware / time-based
    @AppStorage("Feather.appearance.contextTheming")   private var contextTheming: Bool = false
    @AppStorage("Feather.appearance.lowPowerTheme")    private var lowPowerThemeId: String = ""
    @AppStorage("Feather.appearance.focusTheme")       private var focusThemeId: String = ""
    @AppStorage("Feather.appearance.timeBasedTheming") private var timeBasedTheming: Bool = false
    @AppStorage("Feather.appearance.morningTheme")     private var morningThemeId: String = ""
    @AppStorage("Feather.appearance.sunsetTheme")      private var sunsetThemeId: String = ""
    @AppStorage("Feather.appearance.nightTheme")       private var nightThemeId: String = ""

    // UI state
    @State private var showingAppWideColorPicker = false
    @State private var showingSectionHeaderPicker = false
    @State private var showSaveAlert = false
    @State private var showResetAlert = false
    @State private var showImagePicker = false
    @State private var themeName = ""
    @State private var selectedImage: UIImage?
    @ObservedObject private var appState = AppStateManager.shared

    // MARK: - Preset themes

    private let presetThemes: [ColorTheme] = [
        ColorTheme(name: "Classic",   bg: "#F2F2F7", ui: "#007AFF", text: "#000000", tint: "#007AFF",  secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Midnight",  bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF", tint: "#0A84FF",  secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "rounded"),
        ColorTheme(name: "OLED",      bg: "#000000", ui: "#30D158", text: "#FFFFFF", tint: "#30D158",  secondaryText: "#A1A1A1", cardRadius: 12, fontDesign: "monospaced"),
        ColorTheme(name: "Nordic",    bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4", tint: "#88C0D0",  secondaryText: "#D8DEE9", cardRadius: 8,  fontDesign: "default"),
        ColorTheme(name: "Forest",    bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC", tint: "#74C69D",  secondaryText: "#95D5B2", cardRadius: 20, fontDesign: "serif"),
        ColorTheme(name: "Crimson",   bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6", tint: "#FF453A",  secondaryText: "#FFBABA", cardRadius: 14, fontDesign: "default"),
        ColorTheme(name: "Vibrant",   bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC", tint: "#F43F5E",  secondaryText: "#E2E8F0", cardRadius: 18, fontDesign: "rounded"),
        ColorTheme(name: "Sepia",     bg: "#F4ECD8", ui: "#8B4513", text: "#433422", tint: "#8B4513",  secondaryText: "#5D4037", cardRadius: 4,  fontDesign: "serif"),
        ColorTheme(name: "Lavender",  bg: "#F3E5F5", ui: "#9C27B0", text: "#4A148C", tint: "#9C27B0",  secondaryText: "#7B1FA2", cardRadius: 24, fontDesign: "rounded"),
        ColorTheme(name: "Ocean",     bg: "#E0F7FA", ui: "#00BCD4", text: "#006064", tint: "#00BCD4",  secondaryText: "#00838F", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Rose Gold", bg: "#FFF1F0", ui: "#FF85C0", text: "#5C0011", tint: "#FF85C0",  secondaryText: "#9E1068", cardRadius: 30, fontDesign: "serif"),
        ColorTheme(name: "Slate",     bg: "#263238", ui: "#90A4AE", text: "#ECEFF1", tint: "#90A4AE",  secondaryText: "#B0BEC5", cardRadius: 0,  fontDesign: "monospaced"),
        ColorTheme(name: "Mint",      bg: "#E8F5E9", ui: "#4CAF50", text: "#1B5E20", tint: "#4CAF50",  secondaryText: "#2E7D32", cardRadius: 16, fontDesign: "rounded"),
    ]

    private var userThemes: [ColorTheme] {
        get { (try? JSONDecoder().decode([ColorTheme].self, from: userThemesData)) ?? [] }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) { userThemesData = data }
        }
    }

    private var allThemes: [ColorTheme] { presetThemes + userThemes }

    // MARK: - Body

    var body: some View {
        List {
            if showHeaderViews {
                Section(header: Text(String.localized("Built-In Themes"))) {
                    ColorHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            builtInThemesSection
            appWideColorsSection
            sectionStyleSection
            typographySection
            shapeStylingSection
            semanticColorsSection
            sectionHeaderSection
            accessibilitySection
            feedbackSection
            experimentalSection
            intelligentThemingSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String.localized("Visual Design"))
        .appWideHeaderTitle(displayMode: .inline)
        .id(themeManager.currentThemeID)
        .sheet(isPresented: ) { AppWideColorPickerSheet() }
        .sheet(isPresented: ) { SectionHeaderColorPickerSheet() }
        .sheet(isPresented: ) { ImagePicker(image: ) }
        .onChange(of: selectedImage) { image in
            guard let image else { return }
            let palette = WallpaperColorExtractor.shared.extractDominantColors(from: image)
            backgroundManager.baseColor = palette.primary
            var colors = themeManager.resolvedColors
            colors.accent = palette.accent.hexString
            themeManager.applyColors(colors)
            HapticsManager.shared.success()
        }
        .alert(String.localized("Save Theme"), isPresented: ) {
            TextField(String.localized("Theme Name"), text: )
            Button(String.localized("Save")) { saveCurrentTheme(); themeName = "" }
            Button(String.localized("Cancel"), role: .cancel) { themeName = "" }
        } message: {
            Text(String.localized("Enter a name for your custom theme."))
        }
        .alert(String.localized("Reset Appearance"), isPresented: ) {
            Button(String.localized("Reset Everything"), role: .destructive) { resetToDefaults() }
            Button(String.localized("Cancel"), role: .cancel) {}
        } message: {
            Text(String.localized("This will restore all colors to their original theme defaults. Saved custom themes will not be deleted."))
        }
    }

    // MARK: - Sections

    private var builtInThemesSection: some View {
        Section(header: Text(String.localized("Built-In Themes"))) {
            ForEach(AppTheme.allCases) { theme in
                let colors = AppWideColors.default(for: theme)
                Button {
                    themeManager.applyTheme(theme)
                    HapticsManager.shared.softImpact()
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            ForEach([colors.appBackground, colors.accent, colors.cardBackground,
                                     colors.primaryText, colors.buttonBackground], id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().strokeBorder(Color(hex: colors.separator), lineWidth: 0.5))
                            }
                        }
                        Text(theme.displayName)
                            .font(.body)
                            .foregroundStyle(themeManager.primaryText)
                        Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(themeManager.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var appWideColorsSection: some View {
        Section(header: Text(String.localized("App Colors")), footer: Text(String.localized("Override every color in the app to create a fully custom look."))) {
            Button {
                showingAppWideColorPicker = true
            } label: {
                HStack {
                    Label(String.localized("Customize All Colors"), systemImage: "paintpalette.fill")
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach([themeManager.background, themeManager.navigationBarColor,
                                 themeManager.accent], id: \.self) { c in
                            c.frame(width: 14, height: 28)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeManager.secondaryText)
                }
            }
            if themeManager.isCustomTheme {
                Button(role: .destructive) {
                    themeManager.resetToThemeDefaults()
                } label: {
                    Label(String.localized("Reset App Colors"), systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    private var sectionStyleSection: some View {
        Section(header: Text(String.localized("Section Style")), footer: Text(styleManager.currentStyle.description)) {
            Picker(String.localized("Section Style"), selection: Binding(
                get: { styleManager.currentStyle },
                set: { styleManager.setStyle(bash) }
            )) {
                ForEach(SectionStyle.allCases) { style in
                    Label(style.displayName, systemImage: style.sfSymbol).tag(style)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var typographySection: some View {
        Section(header: Text(String.localized("Typography"))) {
            Picker(String.localized("Font Design"), selection: ) {
                Text(String.localized("Default")).tag("default")
                Text(String.localized("Rounded")).tag("rounded")
                Text(String.localized("Serif")).tag("serif")
                Text(String.localized("Monospaced")).tag("monospaced")
            }
        }
    }

    private var shapeStylingSection: some View {
        Section(header: Text(String.localized("Shape & Styling"))) {
            sliderRow(title: String.localized("Card Corner Radius"),   value: ,   range: 0...40,  step: 2,    unit: "pt", icon: "square.dashed")
            sliderRow(title: String.localized("Button Corner Radius"), value: , range: 0...24,  step: 1,    unit: "pt", icon: "button.programmable")
            sliderRow(title: String.localized("Card Opacity"),         value: ,        range: 0.1...1, step: 0.05, isPercent: true, icon: "square.stack.3d.down.right")
            sliderRow(title: String.localized("Border Width"),         value: ,        range: 0...5,   step: 0.5,  unit: "pt", icon: "square.and.line.vertical.and.square")
            sliderRow(title: String.localized("Shadow Intensity"),     value: ,    range: 0...20,  step: 1,    icon: "shadow")
            sliderRow(title: String.localized("Blur Opacity"),         value: ,        range: 0...1,   step: 0.05, isPercent: true, icon: "drop.halffull")
            sliderRow(title: String.localized("Glow Intensity"),       value: ,      range: 0...30,  step: 1,    icon: "sun.max.fill")
            Toggle(isOn: ) {
                Label(String.localized("Animate Background"), systemImage: "sparkles")
            }
        }
    }

    private var semanticColorsSection: some View {
        Section(header: Text(String.localized("Semantic Colors")), footer: Text(String.localized("Colors used for status indicators and presented sheets."))) {
            supplementalColorRow(title: String.localized("Success"),          hex: , icon: "checkmark.circle")
            supplementalColorRow(title: String.localized("Warning"),          hex: , icon: "exclamationmark.triangle")
            supplementalColorRow(title: String.localized("Error"),            hex: ,   icon: "xmark.circle")
            supplementalColorRow(title: String.localized("Sheet Background"), hex: ,      icon: "square.stack")
        }
    }

    private var sectionHeaderSection: some View {
        Section(header: Text(String.localized("Section Headers"))) {
            Button {
                showingSectionHeaderPicker = true
            } label: {
                HStack {
                    Label(String.localized("Section Header Colors"), systemImage: "text.append")
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach([themeManager.sectionHeaderTheme.background,
                                 themeManager.sectionHeaderTheme.textColor,
                                 themeManager.sectionHeaderTheme.iconColor,
                                 themeManager.sectionHeaderTheme.dividerColor], id: \.self) { c in
                            Circle()
                                .fill(c)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().strokeBorder(themeManager.separatorColor, lineWidth: 0.5))
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeManager.secondaryText)
                }
            }
        }
    }

    private var accessibilitySection: some View {
        Section(header: Text(String.localized("Accessibility"))) {
            Toggle(String.localized("High Contrast Mode"), isOn: )
            Toggle(String.localized("Auto Contrast Correction"), isOn: )
            Picker(String.localized("Color Blindness Filter"), selection: ) {
                Text(String.localized("None")).tag(0)
                Text(String.localized("Protanopia")).tag(1)
                Text(String.localized("Deuteranopia")).tag(2)
                Text(String.localized("Tritanopia")).tag(3)
            }
        }
    }

    private var feedbackSection: some View {
        Section(header: Text(String.localized("Haptic & Visual Feedback"))) {
            sliderRow(title: String.localized("Haptic Intensity"), value: ,        range: 0...1, step: 0.1, isPercent: true, icon: "waveform")
            sliderRow(title: String.localized("Visual Feedback"),  value: , range: 0...1, step: 0.1, isPercent: true, icon: "sparkles")
        }
    }

    private var experimentalSection: some View {
        Section(header: Text(String.localized("Experimental Effects")), footer: Text(String.localized("Performance mode reduces heavy blurs and shadows to save battery."))) {
            Picker(String.localized("Layer Blending"), selection: ) {
                Text(String.localized("Normal")).tag(0)
                Text(String.localized("Overlay")).tag(1)
                Text(String.localized("Multiply")).tag(2)
                Text(String.localized("Screen")).tag(3)
            }
            Toggle(String.localized("Parallax Depth Effect"), isOn: )
            Toggle(String.localized("Motion Gradients"), isOn: )
            Toggle(String.localized("Performance Mode"), isOn: )
        }
    }

    private var intelligentThemingSection: some View {
        Section(header: Text(String.localized("Intelligent Theming")), footer: Text(String.localized("Auto-switch themes based on Low Power Mode, Focus filters, or time of day."))) {
            Toggle(isOn: ) {
                Label(String.localized("Context-Aware Theming"), systemImage: "bolt.badge.automatic.fill")
            }
            if contextTheming {
                Picker(String.localized("Low Power Theme"), selection: ) {
                    Text(String.localized("None")).tag("")
                    ForEach(allThemes) { t in Text(t.name).tag(t.id.uuidString) }
                }
                Picker(String.localized("Focus Theme"), selection: ) {
                    Text(String.localized("None")).tag("")
                    ForEach(allThemes) { t in Text(t.name).tag(t.id.uuidString) }
                }
            }
            Toggle(isOn: ) {
                Label(String.localized("Schedule Themes"), systemImage: "clock.fill")
            }
            if timeBasedTheming {
                Picker(String.localized("Morning Theme"), selection: ) {
                    ForEach(allThemes) { t in Text(t.name).tag(t.id.uuidString) }
                }
                Picker(String.localized("Sunset Theme"), selection: ) {
                    ForEach(allThemes) { t in Text(t.name).tag(t.id.uuidString) }
                }
                Picker(String.localized("Night Theme"), selection: ) {
                    ForEach(allThemes) { t in Text(t.name).tag(t.id.uuidString) }
                }
            }
            Button {
                showImagePicker = true
            } label: {
                Label(String.localized("Generate From Wallpaper"), systemImage: "photo.on.rectangle.angled")
            }
            NavigationLink {
                PerScreenThemeView(allThemes: allThemes)
            } label: {
                Label(String.localized("Per-Screen Overrides"), systemImage: "rectangle.3.group")
            }
        }
    }

    private var actionsSection: some View {
        Section(header: Text(String.localized("Actions"))) {
            Button {
                exportTheme()
            } label: {
                Label(String.localized("Export Theme to Clipboard"), systemImage: "square.and.arrow.up")
            }
            Button {
                importTheme()
            } label: {
                Label(String.localized("Import Theme from Clipboard"), systemImage: "square.and.arrow.down")
            }
            if themeManager.isCustomTheme {
                Button {
                    showSaveAlert = true
                } label: {
                    Label(String.localized("Save Current Style"), systemImage: "plus.circle")
                }
                .disabled(appState.isSigning)
            }
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label(String.localized("Reset to Defaults"), systemImage: "arrow.counterclockwise")
            }
            .disabled(appState.isSigning)
        }
    }

    // MARK: - Row Helpers

    @ViewBuilder
    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String = "",
        isPercent: Bool = false,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(isPercent
                     ? "\(Int(value.wrappedValue * 100))%"
                     : "\(String(format: value.wrappedValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value.wrappedValue))\(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(themeManager.secondaryText)
            }
            Slider(value: value, in: range, step: step)
                .tint(themeManager.accent)
        }
        .padding(.vertical, 2)
    }

    private func supplementalColorRow(title: String, hex: Binding<String>, icon: String) -> some View {
        ColorPicker(selection: Binding(
            get: { Color(hex: hex.wrappedValue) },
            set: { hex.wrappedValue = bash.hexString }
        ), supportsOpacity: false) {
            Label(title, systemImage: icon)
        }
    }

    // MARK: - Logic

    private func saveCurrentTheme() {
        let c = themeManager.resolvedColors
        let sh = themeManager.sectionHeaderTheme
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: c.appBackground, ui: c.cardBackground, text: c.primaryText, tint: c.accent,
            secondaryText: c.secondaryText, cardRadius: cardCornerRadius, fontDesign: fontDesign,
            navBarColor: c.navigationBar, tabBarColor: c.tabBar,
            dividerColor: c.separator, sheetBackgroundColor: sheetBGHex,
            successColor: successColorHex, warningColor: warningColorHex, errorColor: errorColorHex,
            glowIntensity: glowIntensity, borderWidth: borderWidth, cardOpacity: cardOpacity,
            sectionHeaderBackground: sh.background.toHex(),
            sectionHeaderTextColor: sh.textColor.toHex(),
            sectionHeaderIconColor: sh.iconColor.toHex(),
            sectionHeaderDividerColor: sh.dividerColor.toHex()
        )
        var updated = userThemes
        updated.append(newTheme)
        userThemes = updated
        HapticsManager.shared.success()
    }

    private func exportTheme() {
        let c = themeManager.resolvedColors
        let sh = themeManager.sectionHeaderTheme
        let theme = ColorTheme(
            name: "Exported Theme",
            bg: c.appBackground, ui: c.cardBackground, text: c.primaryText, tint: c.accent,
            secondaryText: c.secondaryText, cardRadius: cardCornerRadius, fontDesign: fontDesign,
            navBarColor: c.navigationBar, tabBarColor: c.tabBar,
            dividerColor: c.separator, sheetBackgroundColor: sheetBGHex,
            successColor: successColorHex, warningColor: warningColorHex, errorColor: errorColorHex,
            glowIntensity: glowIntensity, borderWidth: borderWidth, cardOpacity: cardOpacity,
            sectionHeaderBackground: sh.background.toHex(),
            sectionHeaderTextColor: sh.textColor.toHex(),
            sectionHeaderIconColor: sh.iconColor.toHex(),
            sectionHeaderDividerColor: sh.dividerColor.toHex(),
            highContrast: highContrast, colorBlindnessFilter: colorBlindnessFilter,
            autoContrastCorrection: autoContrastCorrection,
            hapticIntensity: hapticIntensity, visualFeedbackStrength: visualFeedbackStrength,
            layerBlendMode: layerBlendMode, parallaxEnabled: parallaxEnabled,
            motionGradients: motionGradients
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(theme), let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = json
            ToastManager.shared.show(String.localized("Theme exported to clipboard"), type: .success)
            HapticsManager.shared.success()
        }
    }

    private func importTheme() {
        guard let json = UIPasteboard.general.string,
              let data = json.data(using: .utf8),
              let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) else {
            HapticsManager.shared.error()
            return
        }
        applyColorTheme(theme)
    }

    private func applyColorTheme(_ theme: ColorTheme) {
        var colors = themeManager.resolvedColors
        colors.appBackground  = theme.bg
        colors.cardBackground = theme.ui
        colors.primaryText    = theme.text
        colors.accent         = theme.tint
        if let st = theme.secondaryText { colors.secondaryText = st }
        if let nb = theme.navBarColor   { colors.navigationBar = nb }
        if let tb = theme.tabBarColor   { colors.tabBar = tb }
        if let dc = theme.dividerColor  { colors.separator = dc }
        colors.buttonBackground   = theme.tint
        colors.iconTint           = theme.tint
        colors.switchTint         = theme.tint
        colors.selectionIndicator = theme.tint
        if let fd = theme.fontDesign    { fontDesign = fd }
        if let cr = theme.cardRadius    { cardCornerRadius = cr }
        if let gi = theme.glowIntensity  { glowIntensity = gi }
        if let bw = theme.borderWidth    { borderWidth = bw }
        if let co = theme.cardOpacity    { cardOpacity = co }
        if let sc = theme.successColor   { successColorHex = sc }
        if let wc = theme.warningColor   { warningColorHex = wc }
        if let ec = theme.errorColor     { errorColorHex = ec }
        if let sb = theme.sheetBackgroundColor { sheetBGHex = sb }
        if let sectionBG   = theme.sectionHeaderBackground,
           let sectionText = theme.sectionHeaderTextColor,
           let sectionIcon = theme.sectionHeaderIconColor,
           let sectionDiv  = theme.sectionHeaderDividerColor {
            themeManager.sectionHeaderTheme = SectionHeaderTheme(
                background:   Color(hex: sectionBG),
                textColor:    Color(hex: sectionText),
                iconColor:    Color(hex: sectionIcon),
                dividerColor: Color(hex: sectionDiv)
            )
        }
        themeManager.applyColors(colors)
        HapticsManager.shared.success()
    }

    private func resetToDefaults() {
        themeManager.resetToThemeDefaults()
        cardCornerRadius = 16; buttonCornerRadius = 12; fontDesign = "default"
        shadowIntensity = 5; blurOpacity = 1; glowIntensity = 10; borderWidth = 0; cardOpacity = 1
        successColorHex = "#34C759"; warningColorHex = "#FF9500"; errorColorHex = "#FF3B30"
        sheetBGHex = "#F2F2F7"
        HapticsManager.shared.success()
    }
// MARK: - App-Wide Color Picker Sheet

private struct AppWideColorPickerSheet: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AppWideColors
    @State private var initialSectionHeaderTheme: SectionHeaderTheme

    init() {
        _draft = State(initialValue: ThemeManager.shared.resolvedColors)
        _initialSectionHeaderTheme = State(initialValue: ThemeManager.shared.sectionHeaderTheme)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppWideColorPreview(colors: draft)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Backgrounds") {
                    inlineColorRow("App Background",     color: .appBackground)
                    inlineColorRow("Navigation Bar",     color: .navigationBar)
                    inlineColorRow("Tab Bar",            color: .tabBar)
                    inlineColorRow("Grouped Background", color: .groupedBackground)
                    inlineColorRow("Card / Row",         color: .cardBackground)
                    inlineColorRow("Cell Highlight",     color: .cellHighlight)
                }

                Section("Text") {
                    inlineColorRow("Primary Text",   color: .primaryText)
                    inlineColorRow("Secondary Text", color: .secondaryText)
                    inlineColorRow("Header Text",    color: .headerText)
                }

                Section("Accents & Indicators") {
                    inlineColorRow("Accent / Tint",  color: .accent)
                    inlineColorRow("Separator",      color: .separator)
                    inlineColorRow("Destructive",    color: .destructive)
                    inlineColorRow("Selection",      color: .selectionIndicator)
                }

                Section("Buttons") {
                    inlineColorRow("Button Background", color: .buttonBackground)
                    inlineColorRow("Button Text",       color: .buttonText)
                }

                Section("Icons & Controls") {
                    inlineColorRow("Icon Tint",   color: .iconTint)
                    inlineColorRow("Switch Tint", color: .switchTint)
                }

                Section("Badges") {
                    inlineColorRow("Badge Background", color: .badgeBackground)
                    inlineColorRow("Badge Text",       color: .badgeText)
                }

                Section {
                    Button(role: .destructive) {
                        themeManager.resetToThemeDefaults()
                        draft = themeManager.resolvedColors
                    } label: {
                        Text(String.localized("Reset to Theme Defaults"))
                    }
                }
            }
            .navigationTitle(String.localized("App Wide Colors"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        themeManager.sectionHeaderTheme = initialSectionHeaderTheme
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String.localized("Apply")) {
                        themeManager.applyColors(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func inlineColorRow(_ label: String, color: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            ColorPicker(label, selection: Binding(
                get: { Color(hex: color.wrappedValue) },
                set: { color.wrappedValue = bash.hexString }
            ), supportsOpacity: false)
            .labelsHidden()
        }
    }
}

// MARK: - Section Header Color Picker Sheet

private struct SectionHeaderColorPickerSheet: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var background: Color
    @State private var textColor: Color
    @State private var iconColor: Color
    @State private var dividerColor: Color

    init() {
        let sh = ThemeManager.shared.sectionHeaderTheme
        _background   = State(initialValue: sh.background)
        _textColor    = State(initialValue: sh.textColor)
        _iconColor    = State(initialValue: sh.iconColor)
        _dividerColor = State(initialValue: sh.dividerColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 6) {
                        Image(systemName: "paintpalette")
                            .font(.caption)
                            .foregroundStyle(iconColor)
                        Text("SECTION HEADER PREVIEW")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(textColor)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(background)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Colors") {
                    ColorPicker("Background", selection: ,   supportsOpacity: false)
                    ColorPicker("Text",       selection: ,    supportsOpacity: false)
                    ColorPicker("Icon",       selection: ,    supportsOpacity: false)
                    ColorPicker("Divider",    selection: , supportsOpacity: false)
                }

                Section {
                    Button(String.localized("Reset to Theme Defaults")) {
                        let defaults = SectionHeaderTheme.default(for: themeManager.resolvedColors)
                        background   = defaults.background
                        textColor    = defaults.textColor
                        iconColor    = defaults.iconColor
                        dividerColor = defaults.dividerColor
                    }
                }
            }
            .navigationTitle(String.localized("Section Header"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String.localized("Apply")) {
                        themeManager.sectionHeaderTheme = SectionHeaderTheme(
                            background:   background,
                            textColor:    textColor,
                            iconColor:    iconColor,
                            dividerColor: dividerColor
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - App-Wide Color Preview Card

private struct AppWideColorPreview: View {
    let colors: AppWideColors

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Portal")
                    .font(.headline)
                    .foregroundStyle(Color(hex: colors.primaryText))
                Spacer()
                Image(systemName: "bell")
                    .foregroundStyle(Color(hex: colors.accent))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: colors.navigationBar))

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: colors.cardBackground))
                    .frame(height: 64)
                    .overlay(
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color(hex: colors.iconTint))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Settings Row")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color(hex: colors.primaryText))
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: colors.secondaryText))
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .tint(Color(hex: colors.switchTint))
                                .scaleEffect(0.8)
                        }
                        .padding(.horizontal, 14)
                    )
                    .padding(.horizontal, 16)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color(hex: colors.badgeBackground))
                        .frame(width: 60, height: 26)
                        .overlay(
                            Text("Badge")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color(hex: colors.badgeText))
                        )
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colors.buttonBackground))
                        .frame(width: 80, height: 32)
                        .overlay(
                            Text("Action")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: colors.buttonText))
                        )
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .background(Color(hex: colors.appBackground))

            HStack(spacing: 0) {
                ForEach(["house.fill", "square.grid.2x2", "gearshape.fill"], id: \.self) { icon in
                    Spacer()
                    Image(systemName: icon)
                        .foregroundStyle(icon == "house.fill"
                                         ? Color(hex: colors.accent)
                                         : Color(hex: colors.secondaryText))
                        .font(.system(size: 18))
                    Spacer()
                }
            }
            .padding(.vertical, 10)
            .background(Color(hex: colors.tabBar))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: colors.separator), lineWidth: 0.5)
        )
        .padding()
    }
}

// MARK: - Per-Screen Theme Override View

struct PerScreenThemeView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @AppStorage("Feather.appearance.screenOverride") private var screenOverride: [String: String] = [:]
    let allThemes: [ColorTheme]

    private let screens = [
        ("Library",  "LibraryView"),
        ("Sources",  "SourcesView"),
        ("Guides",   "GuidesView"),
        ("Settings", "SettingsView"),
        ("Signer",   "SigningView"),
    ]

    var body: some View {
        List {
            Section(header: Text(String.localized("Select Theme Per Screen")), footer: Text(String.localized("Override the global theme for specific areas of the app."))) {
                ForEach(screens, id: \.1) { name, key in
                    Picker(name, selection: Binding(
                        get: { screenOverride[key] ?? "" },
                        set: { screenOverride[key] = bash.isEmpty ? nil : bash }
                    )) {
                        Text(String.localized("Default")).tag("")
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                }
            }
        }
        .navigationTitle(String.localized("Per-Screen Themes"))
    }
}

// MARK: - Theme Library View

struct ThemeLibraryView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    let themes: [ColorTheme]
    let onSelect: (ColorTheme) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(themes) { theme in
                        ModernThemeCard(theme: theme) { onSelect(theme) }
                    }
                }
                .padding(20)
            }
            .navigationTitle(String.localized("All Themes"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String.localized("Done")) { dismiss() }.fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Theme Card

struct ModernThemeCard: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: theme.bg))
                    .frame(width: 130, height: 90)
                    .overlay {
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
                    .foregroundStyle(themeManager.primaryText)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}
