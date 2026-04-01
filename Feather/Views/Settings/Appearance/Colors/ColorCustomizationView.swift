import SwiftUI
import NimbleViews

// MARK: - Color Theme Model

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
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @EnvironmentObject private var styleManager: SectionStyleManager
    @ObservedObject private var appState = AppStateManager.shared
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("Feather.animateBackground") private var animateBackground = false
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex = "#8E8E93"
    @AppStorage(UserDefaults.Keys.cardCornerRadius) private var cardCornerRadius = 16.0
    @AppStorage(UserDefaults.Keys.buttonCornerRadius) private var buttonCornerRadius = 12.0
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign = "default"
    @AppStorage(UserDefaults.Keys.shadowIntensity) private var shadowIntensity = 5.0
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity = 1.0
    @AppStorage(UserDefaults.Keys.navBarColor) private var navBarColorHex = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.tabBarColor) private var tabBarColorHex = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.dividerColor) private var dividerColorHex = "#E5E5EA"
    @AppStorage(UserDefaults.Keys.sheetBackgroundColor) private var sheetBackgroundColorHex = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.successColor) private var successColorHex = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor) private var warningColorHex = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor) private var errorColorHex = "#FF3B30"
    @AppStorage(UserDefaults.Keys.glowIntensity) private var glowIntensity = 10.0
    @AppStorage(UserDefaults.Keys.borderWidth) private var borderWidth = 0.0
    @AppStorage(UserDefaults.Keys.cardOpacity) private var cardOpacity = 1.0
    @AppStorage("Feather.userTintColor") private var tintColorHex = "#0077BE"
    @AppStorage("Feather.userThemes") private var userThemesData = Data()
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @AppStorage("Feather.appearance.contextTheming") private var contextTheming = false
    @AppStorage("Feather.appearance.lowPowerTheme") private var lowPowerThemeId = ""
    @AppStorage("Feather.appearance.focusTheme") private var focusThemeId = ""
    @AppStorage("Feather.appearance.timeBasedTheming") private var timeBasedTheming = false
    @AppStorage("Feather.appearance.morningTheme") private var morningThemeId = ""
    @AppStorage("Feather.appearance.sunsetTheme") private var sunsetThemeId = ""
    @AppStorage("Feather.appearance.nightTheme") private var nightThemeId = ""
    @AppStorage("Feather.appearance.highContrast") private var highContrast = false
    @AppStorage("Feather.appearance.colorBlindnessFilter") private var colorBlindnessFilter = 0
    @AppStorage("Feather.appearance.autoContrastCorrection") private var autoContrastCorrection = true
    @AppStorage("Feather.appearance.hapticIntensity") private var hapticIntensity = 0.5
    @AppStorage("Feather.appearance.visualFeedbackStrength") private var visualFeedbackStrength = 0.5
    @AppStorage("Feather.appearance.layerBlendMode") private var layerBlendMode = 0
    @AppStorage("Feather.appearance.parallaxEnabled") private var parallaxEnabled = false
    @AppStorage("Feather.appearance.motionGradients") private var motionGradients = true
    @AppStorage("Feather.appearance.performanceMode") private var performanceMode = false
    @AppStorage("Feather.appearance.screenOverride") private var screenOverride: [String: String] = [:]

    @State private var themeName = ""
    @State private var showSaveAlert = false
    @State private var showResetAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAppWideColorPicker = false
    @State private var selectedTab: CustomizationTab = .overview

    enum CustomizationTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case themes = "Themes"
        case intelligent = "Smart"
        case advanced = "Advanced"
        case sections = "Sections"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: "paintpalette.fill"
            case .themes: "square.grid.2x2.fill"
            case .intelligent: "sparkles"
            case .advanced: "slider.horizontal.3"
            case .sections: "rectangle.split.3x1"
            }
        }
    }

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
            (try? JSONDecoder().decode([ColorTheme].self, from: userThemesData)) ?? []
        }
        nonmutating set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userThemesData = encoded
            }
        }
    }

    private var allThemes: [ColorTheme] { presetThemes + userThemes }

    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Segmented control for tab selection
                Picker("Mode", selection: $selectedTab) {
                    ForEach(CustomizationTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        if showHeaderViews {
                            ColorHeaderView()
                        }

                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .themes:
                            themesContent
                        case .intelligent:
                            intelligentContent
                        case .advanced:
                            advancedContent
                        case .sections:
                            sectionsContent
                        }

                        actionsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Visual Design")
        .appWideHeaderTitle(displayMode: .inline)
        .sheet(isPresented: $showingAppWideColorPicker) {
            AppWideColorPickerSheet()
                .environment(themeManager)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                let palette = WallpaperColorExtractor.shared.extractDominantColors(from: image)
                backgroundManager.baseColor = palette.primary
                HapticsManager.shared.success()
            }
        }
        .alert("Save Theme", isPresented: $showSaveAlert) {
            TextField("Theme Name", text: $themeName)
            Button("Save") {
                saveTheme()
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
    }

    // MARK: - Content Views

    private var overviewContent: some View {
        VStack(spacing: 16) {
            appWideButton

            VStack(alignment: .leading, spacing: 8) {
                Text("Built-In Themes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(themeManager.sectionHeaderTheme.textColor)

                ForEach(AppTheme.allCases.prefix(3)) { theme in
                    themeCard(for: theme)
                }
            }

            sectionStyleCard
        }
    }

    private var themesContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("System Themes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(themeManager.headerText)

                ForEach(AppTheme.allCases) { theme in
                    themeCard(for: theme)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Preset Themes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(themeManager.headerText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presetThemes) { theme in
                        presetThemeCard(theme: theme)
                    }
                }
            }
        }
    }

    private var intelligentContent: some View {
        VStack(spacing: 16) {
            IntelligentThemeFeaturesView(
                contextTheming: $contextTheming,
                lowPowerThemeId: $lowPowerThemeId,
                focusThemeId: $focusThemeId,
                timeBasedTheming: $timeBasedTheming,
                morningThemeId: $morningThemeId,
                sunsetThemeId: $sunsetThemeId,
                nightThemeId: $nightThemeId,
                showImagePicker: $showImagePicker,
                allThemes: allThemes
            )
        }
    }

    private var advancedContent: some View {
        VStack(spacing: 16) {
            AdvancedThemeFeaturesView(
                highContrast: $highContrast,
                autoContrastCorrection: $autoContrastCorrection,
                colorBlindnessFilter: $colorBlindnessFilter,
                hapticIntensity: $hapticIntensity,
                visualFeedbackStrength: $visualFeedbackStrength,
                layerBlendMode: $layerBlendMode,
                parallaxEnabled: $parallaxEnabled,
                motionGradients: $motionGradients,
                performanceMode: $performanceMode,
                advancedSliderRow: { title, value, range, step, unit, isPercent, icon in
                    AnyView(advancedSliderRow(
                        title: title,
                        value: value,
                        range: range,
                        step: step,
                        unit: unit,
                        isPercent: isPercent,
                        icon: icon
                    ))
                },
                onExportTheme: exportTheme,
                onImportTheme: importTheme
            )
        }
    }

    private var sectionsContent: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: AllAppsCustomizationView()) {
                Label("All Apps", systemImage: "square.grid.2x2.fill")
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }
            Divider().background(themeManager.sectionHeaderTheme.dividerColor)
            NavigationLink(destination: AppHideElementsView()) {
                Label("Hide UI Elements", systemImage: "eye.slash.fill")
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }
            Divider().background(themeManager.sectionHeaderTheme.dividerColor)
            NavigationLink(destination: StatusBarCustomizationView()) {
                Label("Status Bar", systemImage: "rectangle.topthird.inset.filled")
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }
            Divider().background(themeManager.sectionHeaderTheme.dividerColor)
            NavigationLink(destination: TabBarCustomizationView()) {
                Label("Tab Bar", systemImage: "dock.rectangle")
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                Divider().background(themeManager.sectionHeaderTheme.dividerColor)
                NavigationLink(destination: KeyboardCustomizationView()) {
                    Label("Keyboard Backdrop", systemImage: "keyboard")
                        .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
                }
            }
            Divider().background(themeManager.sectionHeaderTheme.dividerColor)
            NavigationLink(destination: TopViewAppearance()) {
                Label("Top View", systemImage: "uiwindow.split.2x1")
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }
        }
        .padding(12)
        .background(themeManager.sectionHeaderTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Component Views

    private var appWideButton: some View {
        Button {
            showingAppWideColorPicker = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("App Wide Colors")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.primaryText)
                    Text("Customize all app colors")
                        .font(.system(size: 11))
                        .foregroundStyle(themeManager.secondaryText)
                }

                Spacer()

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.background)
                        .frame(width: 12, height: 24)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.navigationBar)
                        .frame(width: 12, height: 24)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.accent)
                        .frame(width: 12, height: 24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                if themeManager.isCustomTheme {
                    Button {
                        themeManager.resetToThemeDefaults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(themeManager.secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.secondaryText)
            }
            .padding()
            .background(themeManager.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func themeCard(for theme: AppTheme) -> some View {
        let colors = AppWideColors.default(for: theme)
        return Button {
            themeManager.applyTheme(theme)
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: colors.appBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(theme.displayName)
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(Color(hex: colors.primaryText))
                            Spacer()
                            if themeManager.currentTheme == theme && !themeManager.isCustomTheme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: colors.accent))
                            }
                        }

                        HStack(spacing: 6) {
                            ForEach([colors.accent, colors.cardBackground, colors.primaryText, colors.secondaryText, colors.iconTint, colors.buttonBackground, colors.badgeBackground, colors.switchTint], id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color(hex: colors.separator), lineWidth: 1))
                            }
                        }

                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colors.cardBackground))
                                .frame(width: 80, height: 36)
                                .overlay(
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: colors.iconTint))
                                            .frame(width: 10, height: 10)
                                        Rectangle()
                                            .fill(Color(hex: colors.primaryText).opacity(0.7))
                                            .frame(width: 36, height: 7)
                                            .cornerRadius(3)
                                    }
                                )

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colors.buttonBackground))
                                .frame(width: 52, height: 36)
                                .overlay(
                                    Rectangle()
                                        .fill(Color(hex: colors.buttonText).opacity(0.9))
                                        .frame(width: 28, height: 7)
                                        .cornerRadius(3)
                                )

                            Capsule()
                                .fill(Color(hex: colors.badgeBackground))
                                .frame(width: 40, height: 20)
                                .overlay(
                                    Rectangle()
                                        .fill(Color(hex: colors.badgeText).opacity(0.9))
                                        .frame(width: 22, height: 5)
                                        .cornerRadius(2)
                                )
                        }
                    }
                    .padding(14)
                )
        }
        .buttonStyle(.plain)
    }

    private func presetThemeCard(theme: ColorTheme) -> some View {
        Button {
            applyTheme(theme)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(height: 90)
                        .shadow(color: themeManager.background.opacity(0.05), radius: 5, y: 2)

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

    private var sectionStyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Section Style", systemImage: "rectangle.3.group")
                    .foregroundStyle(themeManager.primaryText)
                Spacer()
                Picker("", selection: Binding(
                    get: { styleManager.currentStyle },
                    set: { styleManager.setStyle($0) }
                )) {
                    ForEach(SectionStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .tint(themeManager.accent)
            }

            Text(styleManager.currentStyle.description)
                .font(.caption)
                .foregroundStyle(themeManager.secondaryText)
        }
        .padding()
        .background(themeManager.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(themeManager.headerText)

            VStack(spacing: 0) {
                if themeManager.isCustomTheme {
                    Button {
                        showSaveAlert = true
                    } label: {
                        Label("Save Current Style", systemImage: "plus.circle.fill")
                            .foregroundStyle(themeManager.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .disabled(appState.isSigning)
                    Divider().background(themeManager.separator)
                }

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Reset To Defaults", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(appState.isSigning)
            }
            .padding(12)
            .background(themeManager.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func advancedSliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String = "", isPercent: Bool = false, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(themeManager.primaryText)
                Spacer()
                Text(isPercent ? "\(Int(value.wrappedValue * 100))%" : "\(String(format: value.wrappedValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value.wrappedValue))\(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(themeManager.secondaryText)
            }
            Slider(value: value, in: range, step: step)
                .tint(themeManager.accent)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func applyTheme(_ theme: ColorTheme) {
        backgroundManager.baseColor = Color(hex: theme.bg)
        if let cr = theme.cardRadius { cardCornerRadius = cr }
        if let fd = theme.fontDesign { fontDesign = fd }
        syncThemeManagerColors()
        HapticsManager.shared.success()
    }

    private func saveTheme() {
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: backgroundManager.baseColor.toHex() ?? Color.defaultBackground,
            ui: themeManager.colors.cardBackground,
            text: themeManager.colors.primaryText,
            tint: themeManager.colors.accent,
            secondaryText: themeManager.colors.secondaryText,
            cardRadius: cardCornerRadius,
            fontDesign: fontDesign
        )
        var updatedThemes = userThemes
        updatedThemes.append(newTheme)
        userThemes = updatedThemes
        HapticsManager.shared.success()
    }

    private func exportTheme() {
        let theme = ColorTheme(
            name: "Exported Theme",
            bg: backgroundManager.baseColor.toHex() ?? Color.defaultBackground,
            ui: themeManager.colors.cardBackground,
            text: themeManager.colors.primaryText,
            tint: themeManager.colors.accent,
            secondaryText: themeManager.colors.secondaryText,
            cardRadius: cardCornerRadius,
            fontDesign: fontDesign
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(theme),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = json
            ToastManager.shared.show("Theme exported to clipboard", type: .success)
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
        applyTheme(theme)
    }

    private func resetToDefaults() {
        backgroundManager.baseColor = Color(hex: Color.defaultBackground)
        cardCornerRadius = 16.0
        buttonCornerRadius = 12.0
        fontDesign = "default"
        shadowIntensity = 5.0
        blurOpacity = 1.0
        glowIntensity = 10.0
        borderWidth = 0.0
        cardOpacity = 1.0
        themeManager.resetToThemeDefaults()
        HapticsManager.shared.success()
    }

    private func syncThemeManagerColors() {
        var colors = themeManager.colors
        colors.appBackground = backgroundManager.baseColor.toHex() ?? Color.defaultBackground
        themeManager.customColors = colors
        themeManager.sectionHeaderTheme = .default(for: colors)
        themeManager.applyUIKitAppearance()
    }
}

// MARK: - App Wide Color Picker Sheet

private struct AppWideColorPickerSheet: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) var dismiss
    @State private var draft: AppWideColors
    @State private var initialSectionHeaderTheme: SectionHeaderTheme

    init() {
        _draft = State(initialValue: ThemeManager.shared.colors)
        _initialSectionHeaderTheme = State(initialValue: ThemeManager.shared.sectionHeaderTheme)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("BACKGROUNDS") {
                    ColorPickerRow(label: "App Background", color: $draft.appBackground)
                    ColorPickerRow(label: "Navigation Bar", color: $draft.navigationBar)
                    ColorPickerRow(label: "Tab Bar", color: $draft.tabBar)
                    ColorPickerRow(label: "Card / Row", color: $draft.cardBackground)
                }

                Section("TEXT") {
                    ColorPickerRow(label: "Primary Text", color: $draft.primaryText)
                    ColorPickerRow(label: "Secondary Text", color: $draft.secondaryText)
                }

                Section("ACCENTS") {
                    ColorPickerRow(label: "Accent / Tint", color: $draft.accent)
                    ColorPickerRow(label: "Separator", color: $draft.separator)
                    ColorPickerRow(label: "Destructive", color: $draft.destructive)
                }

                Section("BUTTONS") {
                    ColorPickerRow(label: "Button Background", color: $draft.buttonBackground)
                    ColorPickerRow(label: "Button Text", color: $draft.buttonText)
                }

                Section("ICONS & INDICATORS") {
                    ColorPickerRow(label: "Icon Tint", color: $draft.iconTint)
                    ColorPickerRow(label: "Switch Tint", color: $draft.switchTint)
                    ColorPickerRow(label: "Selection / Check", color: $draft.selectionIndicator)
                }

                Section("SURFACE STATES") {
                    ColorPickerRow(label: "Cell Highlight", color: $draft.cellHighlight)
                }

                Section("RESET") {
                    Button(role: .destructive) {
                        themeManager.resetToThemeDefaults()
                        draft = themeManager.colors
                    } label: {
                        Text("Reset to Theme Defaults")
                    }
                }
            }
            .navigationTitle("App Wide Colors")
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
                    Button {
                        themeManager.updateColor(keyPath: \.appBackground, hex: draft.appBackground)
                        themeManager.updateColor(keyPath: \.navigationBar, hex: draft.navigationBar)
                        themeManager.updateColor(keyPath: \.tabBar, hex: draft.tabBar)
                        themeManager.updateColor(keyPath: \.cardBackground, hex: draft.cardBackground)
                        themeManager.updateColor(keyPath: \.primaryText, hex: draft.primaryText)
                        themeManager.updateColor(keyPath: \.secondaryText, hex: draft.secondaryText)
                        themeManager.updateColor(keyPath: \.accent, hex: draft.accent)
                        themeManager.updateColor(keyPath: \.separator, hex: draft.separator)
                        themeManager.updateColor(keyPath: \.cellHighlight, hex: draft.cellHighlight)
                        themeManager.updateColor(keyPath: \.destructive, hex: draft.destructive)
                        themeManager.updateColor(keyPath: \.buttonBackground, hex: draft.buttonBackground)
                        themeManager.updateColor(keyPath: \.buttonText, hex: draft.buttonText)
                        themeManager.updateColor(keyPath: \.iconTint, hex: draft.iconTint)
                        themeManager.updateColor(keyPath: \.switchTint, hex: draft.switchTint)
                        themeManager.updateColor(keyPath: \.selectionIndicator, hex: draft.selectionIndicator)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

// MARK: - Color Picker Row

private struct ColorPickerRow: View {
    @Environment(ThemeManager.self) private var themeManager
    let label: String
    @Binding var color: String
    @State private var showingPicker = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: color))
                .frame(width: 28, height: 28)
                .onTapGesture {
                    showingPicker = true
                }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                VStack {
                    ColorPicker(label, selection: Binding(
                        get: { Color(hex: color) },
                        set: { color = $0.hexString }
                    ), supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(3)
                    .padding()
                }
                .navigationTitle(label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingPicker = false }
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
    }
}
