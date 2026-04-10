import SwiftUI
import NimbleViews

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

    // Context-Aware & Time-Based
    var appearanceMode: Int? = 0 // 0: Auto, 1: Light, 2: Dark
    var scheduleMode: Int? = 0 // 0: None, 1: Morning, 2: Sunset, 3: Night

    // Accessibility
    var highContrast: Bool? = false
    var colorBlindnessFilter: Int? = 0 // 0: None, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia
    var autoContrastCorrection: Bool? = true

    // Feedback
    var hapticIntensity: Double? = 0.5
    var visualFeedbackStrength: Double? = 0.5

    // Experimental & Blending
    var layerBlendMode: Int? = 0 // 0: Normal, 1: Overlay, 2: Multiply, 3: Screen
    var parallaxEnabled: Bool? = false
    var motionGradients: Bool? = true
    var dynamicLighting: Bool? = false
}

struct ColorCustomizationView: View {
    enum DisplayMode {
        case overview
        case intelligent
        case advanced
        case sections
    }

    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @EnvironmentObject private var themeManager: AppWideThemeManager
    @EnvironmentObject private var styleManager: SectionStyleManager
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

    // Per-Screen Override
    @AppStorage("Feather.appearance.screenOverride") private var screenOverride: [String: String] = [:]

    // Context-Aware
    @AppStorage("Feather.appearance.contextTheming") private var contextTheming: Bool = false
    @AppStorage("Feather.appearance.lowPowerTheme") private var lowPowerThemeId: String = ""
    @AppStorage("Feather.appearance.focusTheme") private var focusThemeId: String = ""

    // Time-Based
    @AppStorage("Feather.appearance.timeBasedTheming") private var timeBasedTheming: Bool = false
    @AppStorage("Feather.appearance.morningTheme") private var morningThemeId: String = ""
    @AppStorage("Feather.appearance.sunsetTheme") private var sunsetThemeId: String = ""
    @AppStorage("Feather.appearance.nightTheme") private var nightThemeId: String = ""

    // Accessibility
    @AppStorage("Feather.appearance.highContrast") private var highContrast: Bool = false
    @AppStorage("Feather.appearance.colorBlindnessFilter") private var colorBlindnessFilter: Int = 0
    @AppStorage("Feather.appearance.autoContrastCorrection") private var autoContrastCorrection: Bool = true

    // Feedback
    @AppStorage("Feather.appearance.hapticIntensity") private var hapticIntensity: Double = 0.5
    @AppStorage("Feather.appearance.visualFeedbackStrength") private var visualFeedbackStrength: Double = 0.5

    // Experimental
    @AppStorage("Feather.appearance.layerBlendMode") private var layerBlendMode: Int = 0
    @AppStorage("Feather.appearance.parallaxEnabled") private var parallaxEnabled: Bool = false
    @AppStorage("Feather.appearance.motionGradients") private var motionGradients: Bool = true
    @AppStorage("Feather.appearance.performanceMode") private var performanceMode: Bool = false

    @State private var uiElementColor: Color = Color(hex: "#007AFF")
    @State private var textColor: Color = Color(hex: "#000000")
    @State private var secondaryTextColor: Color = Color(hex: "#8E8E93")
    @State private var tintColor: Color = Color(hex: "#0077BE")
    @State private var navBarColor: Color = Color(hex: "#F2F2F7")
    @State private var tabBarColor: Color = Color(hex: "#F2F2F7")
    @State private var dividerColor: Color = Color(hex: "#E5E5EA")
    @State private var sheetBackgroundColor: Color = Color(hex: "#F2F2F7")
    @State private var successColor: Color = Color(hex: "#34C759")
    @State private var warningColor: Color = Color(hex: "#FF9500")
    @State private var errorColor: Color = Color(hex: "#FF3B30")
    @State private var themeName: String = ""
    @State private var showSaveAlert = false
    @State private var showResetAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAppWideColorPicker: Bool = false
    @ObservedObject private var appState = AppStateManager.shared
    @Environment(\.colorScheme) var colorScheme
    private let displayMode: DisplayMode

    init(displayMode: DisplayMode = .overview) {
        self.displayMode = displayMode
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
        ZStack {
            themeManager.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if showHeaderViews {
                        ColorHeaderView()
                    }

                    switch displayMode {
                    case .overview:
                        overviewSection
                    case .intelligent:
                        intelligentThemeFeaturesSection
                    case .advanced:
                        advancedThemeFeaturesSection
                    case .sections:
                        customizationLinksSection
                    }

                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Visual Design")
        .appWideHeaderTitle(displayMode: .inline)
        .id(themeManager.currentThemeID)
        .onAppear {
            loadColors()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                let palette = WallpaperColorExtractor.shared.extractDominantColors(from: image)
                backgroundManager.baseColor = palette.primary
                uiElementColor = palette.secondary
                tintColor = palette.accent
                syncThemeManagerColors()
                HapticsManager.shared.success()
            }
        }
        .alert(String.localized("Save Theme"), isPresented: $showSaveAlert) {
            TextField(String.localized("Theme Name"), text: $themeName)
            Button(String.localized("Save")) {
                saveStyle()
                themeName = ""
            }
            Button(String.localized("Cancel"), role: .cancel) {
                themeName = ""
            }
        } message: {
            Text(String.localized("Enter a name for your custom theme."))
        }
        .alert(String.localized("Reset Appearance"), isPresented: $showResetAlert) {
            Button(String.localized("Reset Everything"), role: .destructive) {
                resetToDefaults()
            }
            Button(String.localized("Cancel"), role: .cancel) { }
        } message: {
            Text(String.localized("This will restore all colors to their original system defaults. Your saved custom themes will not be deleted."))
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
        .onReceive(NotificationCenter.default.publisher(for: .sectionStyleDidChange)) { _ in }
    }

    private var overviewSection: some View {
        VStack(spacing: 16) {
            appWideButton
            appWideThemesSection
        }
    }

    private var intelligentThemeFeaturesSection: some View {
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

    private var advancedThemeFeaturesSection: some View {
        VStack(spacing: 16) {
            intelligentThemeFeaturesSection
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
                    AnyView(
                        advancedSliderRow(
                            title: title,
                            value: value,
                            range: range,
                            step: step,
                            unit: unit,
                            isPercent: isPercent,
                            icon: icon
                        )
                    )
                },
                onExportTheme: exportTheme,
                onImportTheme: importTheme
            )
        }
    }

    private var appWideThemesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localized("Built In Themes"))
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(themeManager.sectionHeaderTheme.textColor)

            ForEach(AppTheme.allCases) { theme in
                let colors = AppWideColors.default(for: theme)
                Button {
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
                                    if themeManager.currentTheme == theme && themeManager.appWideColors == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: colors.accent))
                                    }
                                }

                                HStack(spacing: 6) {
                                    ForEach([
                                        colors.accent,
                                        colors.cardBackground,
                                        colors.primaryText,
                                        colors.secondaryText,
                                        colors.iconTint,
                                        colors.buttonBackground,
                                        colors.badgeBackground,
                                        colors.switchTint
                                    ], id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color(hex: colors.separator), lineWidth: 1)
                                            )
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
        }
    }

    private var paletteSection: some View {
        Section {
            ThemedSection("APPEARANCE", symbol: "paintpalette") {
                HStack(spacing: 14) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.iconTintColor)
                        .frame(width: 28, height: 28)
                        .background(themeManager.iconTintColor.opacity(0.12))
                        .cornerRadius(7)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Section Style")
                            .foregroundStyle(themeManager.primaryTextColor)
                            .font(.body)
                        Text(styleManager.currentStyle.description)
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .font(.caption)
                    }

                    Spacer()

                    Picker("", selection: Binding(
                        get: { styleManager.currentStyle },
                        set: { styleManager.setStyle($0) }
                    )) {
                        ForEach(SectionStyle.allCases) { style in
                            HStack {
                                Image(systemName: style.sfSymbol)
                                Text(style.displayName)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(themeManager.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(themeManager.cardBackgroundColor)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(themeManager.separatorColor)
                        .frame(height: 0.5)
                        .padding(.leading, 58)
                }

                sectionStylePreviewCard

            }
            .environmentObject(themeManager)
            .environmentObject(styleManager)
            .listRowBackground(Color.clear)
        }
    }

    private var appWideButton: some View {
        Button {
            showingAppWideColorPicker = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(String.localized("App Wide"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.primaryTextColor)
                    Text(String.localized("Customize all app colors"))
                        .font(.system(size: 11))
                        .foregroundStyle(themeManager.secondaryTextColor)
                }

                Spacer()

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.appBackgroundColor)
                        .frame(width: 12, height: 24)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.navigationBarColor)
                        .frame(width: 12, height: 24)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(themeManager.accentColor)
                        .frame(width: 12, height: 24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                if themeManager.appWideColors != nil {
                    Button {
                        themeManager.resetToThemeDefaults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(themeManager.sectionHeaderTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAppWideColorPicker) {
            AppWideColorPickerSheet()
        }
    }


    private var sectionStylePreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREVIEW")
                .font(.caption2)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(themeManager.secondaryTextColor)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "internaldrive")
                        .font(.caption)
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.headerTextColor : Color(.secondaryLabel)
                        )
                    Text("DATA & MAINTENANCE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.headerTextColor : Color(.secondaryLabel)
                        )
                }

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor.opacity(0.15) : Color.clear
                            )
                            .frame(width: 24, height: 24)
                            .overlay(Image(systemName: "internaldrive.fill")
                                .font(.caption2)
                                .foregroundStyle(
                                    styleManager.currentStyle == .colorMatch
                                        ? themeManager.iconTintColor : Color.accentColor
                                ))
                        Text("Storage")
                            .font(.subheadline)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.primaryTextColor : Color(.label)
                            )
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.secondaryTextColor : Color(.tertiaryLabel)
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.cardBackgroundColor
                            : Color(.secondarySystemGroupedBackground)
                    )

                    Rectangle()
                        .fill(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.separatorColor : Color(.separator)
                        )
                        .frame(height: 0.5)
                        .padding(.leading, 46)

                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor.opacity(0.15) : Color.clear
                            )
                            .frame(width: 24, height: 24)
                            .overlay(Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundStyle(
                                    styleManager.currentStyle == .colorMatch
                                        ? themeManager.iconTintColor : Color.accentColor
                                ))
                        Text("Background Refresh")
                            .font(.subheadline)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.primaryTextColor : Color(.label)
                            )
                        Spacer()
                        Capsule()
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.switchTintColor : themeManager.accentColor
                            )
                            .frame(width: 36, height: 22)
                            .overlay(
                                Circle()
                                    .fill(themeManager.buttonTextColor)
                                    .frame(width: 18, height: 18)
                                    .offset(x: 7)
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.cardBackgroundColor
                            : Color(.secondarySystemGroupedBackground)
                    )
                }
                .cornerRadius(styleManager.currentStyle == .colorMatch ? 14 : 10)
                .overlay(
                    RoundedRectangle(cornerRadius: styleManager.currentStyle == .colorMatch ? 14 : 10)
                        .stroke(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.borderColor : Color(.separator),
                            lineWidth: 0.5
                        )
                )
            }
        }
        .padding(16)
        .background(themeManager.groupedBackgroundColor)
        .cornerRadius(16)
        .animation(.easeInOut(duration: 0.25), value: styleManager.currentStyle)
    }


    private var semanticColorsSection: some View {
        Section {
            colorPickerRow(title: String.localized("Navigation Bar"), subtext: String.localized("Top navigation chrome"), color: $navBarColor, icon: "menubar.rectangle")
            colorPickerRow(title: String.localized("Tab Bar"), subtext: String.localized("Bottom tab bar surface"), color: $tabBarColor, icon: "dock.rectangle")
            colorPickerRow(title: String.localized("Sheet Background"), subtext: String.localized("Presented sheets and popovers"), color: $sheetBackgroundColor, icon: "square.stack")
            colorPickerRow(title: String.localized("Divider"), subtext: String.localized("Lines and separators"), color: $dividerColor, icon: "minus")
            colorPickerRow(title: String.localized("Success"), subtext: String.localized("Positive states and confirmations"), color: $successColor, icon: "checkmark.circle")
            colorPickerRow(title: String.localized("Warning"), subtext: String.localized("Caution states and prompts"), color: $warningColor, icon: "exclamationmark.triangle")
            colorPickerRow(title: String.localized("Error"), subtext: String.localized("Errors and destructive alerts"), color: $errorColor, icon: "xmark.circle")
        } header: {
            Text(String.localized("Semantic Colors"))
        }
    }

    private var stylingSection: some View {
        Section {
            Picker(String.localized("Font Design"), selection: $fontDesign) {
                Text(String.localized("Default")).tag("default")
                Text(String.localized("Rounded")).tag("rounded")
                Text(String.localized("Serif")).tag("serif")
                Text(String.localized("Monospaced")).tag("monospaced")
            }
            advancedSliderRow(title: String.localized("Card Corners"), value: $cardCornerRadius, range: 0...40, step: 2, unit: "pt", icon: "square.dashed")
            advancedSliderRow(title: String.localized("Button Corners"), value: $buttonCornerRadius, range: 0...24, step: 1, unit: "pt", icon: "button.programmable")
            advancedSliderRow(title: String.localized("Card Opacity"), value: $cardOpacity, range: 0.1...1.0, step: 0.05, isPercent: true, icon: "square.stack.3d.down.right")
            advancedSliderRow(title: String.localized("Border Width"), value: $borderWidth, range: 0...5, step: 0.5, unit: "pt", icon: "square.and.line.vertical.and.square")
            advancedSliderRow(title: String.localized("Shadow Intensity"), value: $shadowIntensity, range: 0...20, step: 1, icon: "shadow")
        } header: {
            Text(String.localized("Surfaces & Typography"))
        }
    }

    private var advancedEffectsSection: some View {
        Section {
            advancedSliderRow(title: String.localized("Blur Opacity"), value: $blurOpacity, range: 0...1, step: 0.05, isPercent: true, icon: "drop.halffull")
            advancedSliderRow(title: String.localized("Glow Intensity"), value: $glowIntensity, range: 0...30, step: 1, icon: "sun.max.fill")
            Toggle(isOn: $animateBackground) {
                Label(String.localized("Animate Background"), systemImage: "sparkles")
            }
            Button {
                syncBarsWithBackground()
            } label: {
                Label(String.localized("Match Navigation + Tab Bars"), systemImage: "arrow.triangle.2.circlepath")
            }
            Button {
                applyHighContrastPreset()
            } label: {
                Label(String.localized("Apply High Contrast Boost"), systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text(String.localized("Effects & Shortcuts"))
        }
    }

    private var customizationLinksSection: some View {
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
        }
        .padding(12)
        .background(themeManager.sectionHeaderTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var contextAwareSection: some View {
        Section {
            Toggle(isOn: $contextTheming) {
                Label(String.localized("Context-Aware Theming"), systemImage: "bolt.badge.automatic.fill")
            }

            if contextTheming {
                Picker(String.localized("Low Power Theme"), selection: $lowPowerThemeId) {
                    Text(String.localized("None")).tag("")
                    ForEach(allThemes) { theme in
                        Text(theme.name).tag(theme.id.uuidString)
                    }
                }

                Picker(String.localized("Focus Theme"), selection: $focusThemeId) {
                    Text(String.localized("None")).tag("")
                    ForEach(allThemes) { theme in
                        Text(theme.name).tag(theme.id.uuidString)
                    }
                }
            }
        } header: {
            Text(String.localized("System Integration"))
        } footer: {
            Text(String.localized("Automatically switch themes based on Low Power Mode or Focus filters."))
        }
    }

    private var timeBasedSection: some View {
        Section {
            Toggle(isOn: $timeBasedTheming) {
                Label(String.localized("Schedule Themes"), systemImage: "clock.fill")
            }

            if timeBasedTheming {
                Picker(String.localized("Morning Theme"), selection: $morningThemeId) {
                    ForEach(allThemes) { theme in
                        Text(theme.name).tag(theme.id.uuidString)
                    }
                }
                Picker(String.localized("Sunset Theme"), selection: $sunsetThemeId) {
                    ForEach(allThemes) { theme in
                        Text(theme.name).tag(theme.id.uuidString)
                    }
                }
                Picker(String.localized("Night Theme"), selection: $nightThemeId) {
                    ForEach(allThemes) { theme in
                        Text(theme.name).tag(theme.id.uuidString)
                    }
                }
            }
        } header: {
            Text(String.localized("Time-Based Theming"))
        }
    }

    private var accessibilitySection: some View {
        Section {
            Toggle(String.localized("High Contrast Mode"), isOn: $highContrast)
            Toggle(String.localized("Auto Contrast Correction"), isOn: $autoContrastCorrection)

            Picker(String.localized("Color Blindness Filter"), selection: $colorBlindnessFilter) {
                Text(String.localized("None")).tag(0)
                Text(String.localized("Protanopia")).tag(1)
                Text(String.localized("Deuteranopia")).tag(2)
                Text(String.localized("Tritanopia")).tag(3)
            }
        } header: {
            Text(String.localized("Accessibility"))
        }
    }

    private var feedbackSection: some View {
        Section {
            advancedSliderRow(title: String.localized("Haptic Intensity"), value: $hapticIntensity, range: 0...1, step: 0.1, isPercent: true, icon: "waveform")
            advancedSliderRow(title: String.localized("Visual Feedback"), value: $visualFeedbackStrength, range: 0...1, step: 0.1, isPercent: true, icon: "sparkles")
        } header: {
            Text(String.localized("Haptic & Visual Feedback"))
        }
    }

    private var experimentalSection: some View {
        Section {
            Picker(String.localized("Layer Blending"), selection: $layerBlendMode) {
                Text(String.localized("Normal")).tag(0)
                Text(String.localized("Overlay")).tag(1)
                Text(String.localized("Multiply")).tag(2)
                Text(String.localized("Screen")).tag(3)
            }
            Toggle(String.localized("Parallax Depth Effect"), isOn: $parallaxEnabled)
            Toggle(String.localized("Motion Gradients"), isOn: $motionGradients)
            Toggle(String.localized("Performance Mode"), isOn: $performanceMode)
        } header: {
            Text(String.localized("Experimental Effects"))
        } footer: {
            Text(String.localized("Performance mode reduces heavy blurs and shadows to save battery and increase responsiveness."))
        }
    }

    private var sharingSection: some View {
        Section {
            Button {
                exportTheme()
            } label: {
                Label(String.localized("Export Current Theme Code"), systemImage: "square.and.arrow.up")
            }

            Button {
                importTheme()
            } label: {
                Label(String.localized("Import Theme From Clipboard"), systemImage: "square.and.arrow.down")
            }
        } header: {
            Text(String.localized("Theme Sharing"))
        }
    }

    private var wallpaperIntegrationSection: some View {
        Section {
            Button {
                showImagePicker = true
            } label: {
                Label(String.localized("Generate From Image"), systemImage: "photo.on.rectangle.angled")
            }
        } header: {
            Text(String.localized("Dynamic Wallpaper Integration"))
        } footer: {
            Text(String.localized("Auto-generate a theme palette from your favorite wallpaper or image."))
        }
    }

    private var perScreenSection: some View {
        Section {
            NavigationLink {
                PerScreenThemeView(allThemes: allThemes)
            } label: {
                Label(String.localized("Per-Screen Overrides"), systemImage: "rectangle.3.group")
            }
        } header: {
            Text(String.localized("View Overrides"))
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(themeManager.sectionHeaderTheme.textColor)

            VStack(spacing: 0) {
                if themeManager.isCustomTheme {
                    Button {
                        showSaveAlert = true
                    } label: {
                        Label("Save Current Style", systemImage: "plus.circle.fill")
                            .foregroundStyle(themeManager.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .disabled(appState.isSigning)
                    Divider().background(themeManager.sectionHeaderTheme.dividerColor)
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
            .background(themeManager.sectionHeaderTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var appearancePreviewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundManager.baseColor)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 16) {
                // Header Mock
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                Text(String.localized("Portal Home"))
                            .font(.system(size: 20, weight: .bold, design: selectedDesign))
                            .foregroundStyle(textColor)
                Text(String.localized("Preview Mode"))
                            .font(.system(size: 12, weight: .medium, design: selectedDesign))
                            .foregroundStyle(secondaryTextColor)
                    }
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(tintColor)
                        .shadow(color: tintColor.opacity(0.3), radius: glowIntensity / 4)
                }

                // Interactive-like Content
                VStack(spacing: 12) {
                    // Card Mock
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .fill(uiElementColor.opacity(cardOpacity))
                        .overlay {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(String.localized("App Container"))
                                        .font(.system(size: 14, weight: .semibold, design: selectedDesign))
                                        .foregroundStyle(textColor)
                                    Spacer()
                                    Toggle("", isOn: .constant(true)).labelsHidden()
                                        .tint(tintColor)
                                        .scaleEffect(0.7)
                                }

                                Text(String.localized("This is how your cards and content will look across the app."))
                                    .font(.system(size: 11, design: selectedDesign))
                                    .foregroundStyle(secondaryTextColor)
                                    .lineLimit(2)

                                HStack {
                                    Spacer()
                                    Button {} label: {
                                        Text(String.localized("Action"))
                                            .font(.system(size: 12, weight: .bold, design: selectedDesign))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(tintColor, in: RoundedRectangle(cornerRadius: buttonCornerRadius))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(12)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                                .stroke(dividerColor.opacity(max(0.2, borderWidth / 5)), lineWidth: max(0.5, borderWidth))
                        }
                        .shadow(color: .black.opacity(shadowIntensity / 50), radius: shadowIntensity, y: 4)
                        .frame(height: 120)

                    // Semantic Row
                    HStack(spacing: 10) {
                        previewPill(title: "Success", color: successColor, icon: "checkmark.circle.fill")
                        previewPill(title: "Warning", color: warningColor, icon: "exclamationmark.triangle.fill")
                        Spacer()
                    }
                }

                // Bottom Bar Mock
                HStack(spacing: 20) {
                    Image(systemName: "house.fill").foregroundStyle(tintColor)
                    Image(systemName: "square.grid.2x2").foregroundStyle(secondaryTextColor)
                    Image(systemName: "gearshape").foregroundStyle(secondaryTextColor)
                    Spacer()
                }
                .font(.system(size: 18))
                .padding(.top, 4)
            }
            .padding(20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                        .foregroundStyle(themeManager.primaryTextColor)
                    Text(subtext)
                        .font(.system(size: 11))
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }
                Spacer()
                Text(color.wrappedValue.toHex() ?? "—")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func advancedSliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String = "", isPercent: Bool = false, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(themeManager.primaryTextColor)
                Spacer()
                Text(isPercent ? "\(Int(value.wrappedValue * 100))%" : "\(String(format: value.wrappedValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value.wrappedValue))\(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            Slider(value: value, in: range, step: step)
                .tint(themeManager.accentColor)
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
                    .foregroundStyle(themeManager.primaryTextColor)
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
        if let sectionBackground = theme.sectionHeaderBackground,
           let sectionTextColor = theme.sectionHeaderTextColor,
           let sectionIconColor = theme.sectionHeaderIconColor,
           let sectionDividerColor = theme.sectionHeaderDividerColor {
            themeManager.sectionHeaderTheme = SectionHeaderTheme(
                background: Color(hex: sectionBackground),
                textColor: Color(hex: sectionTextColor),
                iconColor: Color(hex: sectionIconColor),
                dividerColor: Color(hex: sectionDividerColor)
            )
        }
        loadColors()
        syncThemeManagerColors()
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
            cardOpacity: cardOpacity,
            sectionHeaderBackground: themeManager.sectionHeaderTheme.background.toHex(),
            sectionHeaderTextColor: themeManager.sectionHeaderTheme.textColor.toHex(),
            sectionHeaderIconColor: themeManager.sectionHeaderTheme.iconColor.toHex(),
            sectionHeaderDividerColor: themeManager.sectionHeaderTheme.dividerColor.toHex()
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
            cardOpacity: cardOpacity,
            sectionHeaderBackground: themeManager.sectionHeaderTheme.background.toHex(),
            sectionHeaderTextColor: themeManager.sectionHeaderTheme.textColor.toHex(),
            sectionHeaderIconColor: themeManager.sectionHeaderTheme.iconColor.toHex(),
            sectionHeaderDividerColor: themeManager.sectionHeaderTheme.dividerColor.toHex(),
            appearanceMode: 0,
            scheduleMode: 0,
            highContrast: highContrast,
            colorBlindnessFilter: colorBlindnessFilter,
            autoContrastCorrection: autoContrastCorrection,
            hapticIntensity: hapticIntensity,
            visualFeedbackStrength: visualFeedbackStrength,
            layerBlendMode: layerBlendMode,
            parallaxEnabled: parallaxEnabled,
            motionGradients: motionGradients,
            dynamicLighting: false
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(theme),
           let json = String(data: data, encoding: .utf8) {
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

        applyTheme(theme)
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
        syncThemeManagerColors()
        HapticsManager.shared.success()
    }

    private func syncThemeManagerColors() {
        var colors = themeManager.resolvedColors
        colors.appBackground = backgroundManager.baseColor.toHex() ?? Color.defaultBackground
        colors.navigationBar = navBarColor.toHex() ?? navBarColorHex
        colors.tabBar = tabBarColor.toHex() ?? tabBarColorHex
        colors.primaryText = textColor.toHex() ?? textColorHex
        colors.secondaryText = secondaryTextColor.toHex() ?? secondaryTextColorHex
        colors.cardBackground = uiElementColor.toHex() ?? uiElementColorHex
        colors.accent = tintColor.toHex() ?? tintColorHex
        colors.separator = dividerColor.toHex() ?? dividerColorHex
        colors.buttonBackground = tintColor.toHex() ?? tintColorHex
        colors.buttonText = textColor.toHex() ?? textColorHex
        colors.iconTint = tintColor.toHex() ?? tintColorHex
        colors.headerText = secondaryTextColor.toHex() ?? secondaryTextColorHex
        colors.switchTint = tintColor.toHex() ?? tintColorHex
        colors.selectionIndicator = tintColor.toHex() ?? tintColorHex
        themeManager.appWideColors = colors
        themeManager.sectionHeaderTheme = SectionHeaderTheme.default(for: colors)
        themeManager.applyUIKitAppearance()
    }
}

struct ModernThemeCard: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(width: 130, height: 90)
                        .shadow(color: themeManager.appBackgroundColor.opacity(0.05), radius: 5, x: 0, y: 2)

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
                    .foregroundStyle(themeManager.primaryTextColor)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PerScreenThemeView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @AppStorage("Feather.appearance.screenOverride") private var screenOverride: [String: String] = [:]
    let allThemes: [ColorTheme]

    private let screens = [
        ("Library", "LibraryView"),
        ("Sources", "SourcesView"),
        ("Guides", "GuidesView"),
        ("Settings", "SettingsView"),
        ("Signer", "SigningView")
    ]

    var body: some View {
        List {
            Section {
                ForEach(screens, id: \.1) { screen in
                    Picker(screen.0, selection: Binding(
                        get: { screenOverride[screen.1] ?? "" },
                        set: { screenOverride[screen.1] = $0.isEmpty ? nil : $0 }
                    )) {
                        Text(String.localized("Default")).tag("")
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                }
            } header: {
                Text(String.localized("Select Theme Per Screen"))
            } footer: {
                Text(String.localized("Override the global theme for specific areas of the app."))
            }
        }
        .navigationTitle("Per-Screen Themes")
    }
}

struct ThemeLibraryView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
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

private struct AppWideColorPickerSheet: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @Environment(\.dismiss) var dismiss
    @State private var draft: AppWideColors
    @State private var initialSectionHeaderTheme: SectionHeaderTheme
    @State private var initialSectionStyle: SectionStyle

    init() {
        _draft = State(initialValue: ThemeManager.shared.resolvedColors)
        _initialSectionHeaderTheme = State(initialValue: ThemeManager.shared.sectionHeaderTheme)
        _initialSectionStyle = State(initialValue: SectionStyleManager.shared.currentStyle)
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
                    ColorPickerRow(label: "Button Background",  color: $draft.buttonBackground)
                    ColorPickerRow(label: "Button Text",        color: $draft.buttonText)
                }

                Section("ICONS & INDICATORS") {
                    ColorPickerRow(label: "Icon Tint",          color: $draft.iconTint)
                    ColorPickerRow(label: "Switch Tint",        color: $draft.switchTint)
                    ColorPickerRow(label: "Selection / Check",  color: $draft.selectionIndicator)
                }

                Section("SURFACE STATES") {
                    ColorPickerRow(label: "Cell Highlight",     color: $draft.cellHighlight)
                }

                Section {
                    Toggle("Replace Section Styles", isOn: Binding(
                        get: { styleManager.isReplacingSectionStyles },
                        set: { styleManager.setReplaceSectionStyles($0) }
                    ))
                } header: {
                    Text("Sections")
                } footer: {
                    Text("Fully replaces default SwiftUI section visuals with app-wide themed section styling.")
                }

                Section("PREVIEW") {
                    VStack(spacing: 16) {
                        // Card Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: draft.appBackground))
                                .frame(height: 220)

                            VStack(spacing: 12) {
                                // Row with icon and toggle
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: draft.cardBackground))
                                    .frame(height: 70)
                                    .overlay(
                                        HStack(spacing: 12) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(Color(hex: draft.iconTint))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Settings Row")
                                                    .font(.headline)
                                                    .foregroundStyle(Color(hex: draft.primaryText))
                                                Text("Subtitle description")
                                                    .font(.caption)
                                                    .foregroundStyle(Color(hex: draft.secondaryText))
                                            }

                                            Spacer()

                                            Toggle("", isOn: .constant(true))
                                                .labelsHidden()
                                                .tint(Color(hex: draft.switchTint))
                                                .scaleEffect(0.8)
                                        }
                                        .padding()
                                    )
                                    .padding(.horizontal)

                                // Row with status and indicator
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: draft.cellHighlight))
                                    .frame(height: 50)
                                    .overlay(
                                        HStack {
                                            Text("Status Item")
                                                .font(.subheadline)
                                                .foregroundStyle(Color(hex: draft.primaryText))

                                            Spacer()

                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color(hex: draft.selectionIndicator))
                                        }
                                        .padding(.horizontal)
                                    )
                                    .padding(.horizontal)

                                // Filled Button
                                Button {} label: {
                                    Text("Action Button")
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: draft.buttonBackground))
                                        .foregroundStyle(Color(hex: draft.buttonText))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        }

                        Text("Preview reflects your app-wide overrides")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("RESET") {
                    Button(role: .destructive) {
                        themeManager.resetToThemeDefaults()
                        draft = themeManager.resolvedColors
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
                        styleManager.setStyle(initialSectionStyle)
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

                        // New slots
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

private struct ColorPickerRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
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
