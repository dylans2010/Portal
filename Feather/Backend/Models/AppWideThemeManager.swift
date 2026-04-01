import SwiftUI
import UIKit
import Observation

// MARK: - Theme Definition

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case light, dark, amoled, highContrast, pastel, neon
    case darkNavy, midnight, graphite, oceanDeep, warmBlack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .amoled: "AMOLED"
        case .highContrast: "High Contrast"
        case .pastel: "Pastel"
        case .neon: "Neon"
        case .darkNavy: "Dark Navy"
        case .midnight: "Midnight"
        case .graphite: "Graphite"
        case .oceanDeep: "Ocean Deep"
        case .warmBlack: "Warm Black"
        }
    }

    var backgroundColor: Color {
        Color(hex: previewHex)
    }

    var uiBackgroundColor: UIColor {
        UIColor(hex: previewHex)
    }

    private var previewHex: String {
        switch self {
        case .light: "#F5F7FB"
        case .dark: "#111318"
        case .amoled: "#000000"
        case .highContrast: "#000000"
        case .pastel: "#FFF4FA"
        case .neon: "#0A0014"
        case .darkNavy: "#0D0F1A"
        case .midnight: "#000000"
        case .graphite: "#1C1C1E"
        case .oceanDeep: "#0A1628"
        case .warmBlack: "#12100E"
        }
    }
}

// MARK: - Color Palette

struct AppWideColors: Codable, Equatable, Hashable {
    var appBackground: String
    var navigationBar: String
    var tabBar: String
    var primaryText: String
    var secondaryText: String
    var cardBackground: String
    var accent: String
    var separator: String
    var cellHighlight: String
    var destructive: String
    var buttonBackground: String
    var buttonText: String
    var iconTint: String
    var groupedBackground: String
    var headerText: String
    var badgeBackground: String
    var badgeText: String
    var switchTint: String
    var selectionIndicator: String

    static func `default`(for theme: AppTheme) -> AppWideColors {
        switch theme {
        case .light:
            return AppWideColors(
                appBackground: "#F5F7FB",
                navigationBar: "#FFFFFF",
                tabBar: "#FFFFFF",
                primaryText: "#111827",
                secondaryText: "#6B7280",
                cardBackground: "#FFFFFF",
                accent: "#2563EB",
                separator: "#E5E7EB",
                cellHighlight: "#EEF2FF",
                destructive: "#DC2626",
                buttonBackground: "#2563EB",
                buttonText: "#FFFFFF",
                iconTint: "#2563EB",
                groupedBackground: "#F3F4F6",
                headerText: "#4B5563",
                badgeBackground: "#DBEAFE",
                badgeText: "#1E40AF",
                switchTint: "#2563EB",
                selectionIndicator: "#2563EB"
            )
        case .dark:
            return AppWideColors(
                appBackground: "#111318",
                navigationBar: "#171A21",
                tabBar: "#171A21",
                primaryText: "#F9FAFB",
                secondaryText: "#9CA3AF",
                cardBackground: "#1F2430",
                accent: "#60A5FA",
                separator: "#303744",
                cellHighlight: "#253047",
                destructive: "#F87171",
                buttonBackground: "#60A5FA",
                buttonText: "#08111F",
                iconTint: "#60A5FA",
                groupedBackground: "#111318",
                headerText: "#9CA3AF",
                badgeBackground: "#1E3A8A",
                badgeText: "#DBEAFE",
                switchTint: "#60A5FA",
                selectionIndicator: "#60A5FA"
            )
        case .amoled:
            return AppWideColors(
                appBackground: "#000000",
                navigationBar: "#000000",
                tabBar: "#000000",
                primaryText: "#FFFFFF",
                secondaryText: "#A3A3A3",
                cardBackground: "#0B0B0B",
                accent: "#30D158",
                separator: "#1C1C1E",
                cellHighlight: "#151515",
                destructive: "#FF453A",
                buttonBackground: "#30D158",
                buttonText: "#001B09",
                iconTint: "#30D158",
                groupedBackground: "#000000",
                headerText: "#A3A3A3",
                badgeBackground: "#13351E",
                badgeText: "#9FFFC0",
                switchTint: "#30D158",
                selectionIndicator: "#30D158"
            )
        case .highContrast:
            return AppWideColors(
                appBackground: "#000000",
                navigationBar: "#000000",
                tabBar: "#000000",
                primaryText: "#FFFFFF",
                secondaryText: "#FFD60A",
                cardBackground: "#111111",
                accent: "#0A84FF",
                separator: "#FFFFFF",
                cellHighlight: "#1F1F1F",
                destructive: "#FF453A",
                buttonBackground: "#FFD60A",
                buttonText: "#000000",
                iconTint: "#FFD60A",
                groupedBackground: "#000000",
                headerText: "#FFD60A",
                badgeBackground: "#FFFFFF",
                badgeText: "#000000",
                switchTint: "#FFD60A",
                selectionIndicator: "#FFD60A"
            )
        case .pastel:
            return AppWideColors(
                appBackground: "#FFF4FA",
                navigationBar: "#FFF9F3",
                tabBar: "#FFF9F3",
                primaryText: "#4A3A4F",
                secondaryText: "#8A6D90",
                cardBackground: "#FFFFFF",
                accent: "#B28DFF",
                separator: "#F0DFF8",
                cellHighlight: "#F9EDFF",
                destructive: "#FF6B9E",
                buttonBackground: "#B28DFF",
                buttonText: "#FFFFFF",
                iconTint: "#B28DFF",
                groupedBackground: "#FFF4FA",
                headerText: "#8A6D90",
                badgeBackground: "#F3E8FF",
                badgeText: "#6B21A8",
                switchTint: "#B28DFF",
                selectionIndicator: "#B28DFF"
            )
        case .neon:
            return AppWideColors(
                appBackground: "#0A0014",
                navigationBar: "#120022",
                tabBar: "#120022",
                primaryText: "#E8FFFD",
                secondaryText: "#9BE7FF",
                cardBackground: "#1B0033",
                accent: "#00F5FF",
                separator: "#2E1A40",
                cellHighlight: "#250A3D",
                destructive: "#FF2D95",
                buttonBackground: "#00F5FF",
                buttonText: "#001217",
                iconTint: "#39FF14",
                groupedBackground: "#0A0014",
                headerText: "#00F5FF",
                badgeBackground: "#31124A",
                badgeText: "#A8FFE2",
                switchTint: "#39FF14",
                selectionIndicator: "#00F5FF"
            )
        case .darkNavy:
            return AppWideColors(
                appBackground: "#0D0F1A",
                navigationBar: "#161B2E",
                tabBar: "#161B2E",
                primaryText: "#FFFFFF",
                secondaryText: "#8A9BBE",
                cardBackground: "#1A2133",
                accent: "#3B8FE8",
                separator: "#252D44",
                cellHighlight: "#1F2840",
                destructive: "#FF3B30",
                buttonBackground: "#3B8FE8",
                buttonText: "#FFFFFF",
                iconTint: "#3B8FE8",
                groupedBackground: "#0D0F1A",
                headerText: "#8A9BBE",
                badgeBackground: "#3B8FE8",
                badgeText: "#FFFFFF",
                switchTint: "#3B8FE8",
                selectionIndicator: "#3B8FE8"
            )
        case .midnight:
            return AppWideColors(
                appBackground: "#000000",
                navigationBar: "#0A0A0A",
                tabBar: "#0A0A0A",
                primaryText: "#FFFFFF",
                secondaryText: "#8E8E93",
                cardBackground: "#111111",
                accent: "#3B8FE8",
                separator: "#1C1C1E",
                cellHighlight: "#1A1A1A",
                destructive: "#FF3B30",
                buttonBackground: "#3B8FE8",
                buttonText: "#FFFFFF",
                iconTint: "#3B8FE8",
                groupedBackground: "#000000",
                headerText: "#8E8E93",
                badgeBackground: "#3B8FE8",
                badgeText: "#FFFFFF",
                switchTint: "#3B8FE8",
                selectionIndicator: "#3B8FE8"
            )
        case .graphite:
            return AppWideColors(
                appBackground: "#1C1C1E",
                navigationBar: "#2C2C2E",
                tabBar: "#2C2C2E",
                primaryText: "#FFFFFF",
                secondaryText: "#AEAEB2",
                cardBackground: "#2C2C2E",
                accent: "#636366",
                separator: "#3A3A3C",
                cellHighlight: "#323234",
                destructive: "#FF3B30",
                buttonBackground: "#636366",
                buttonText: "#FFFFFF",
                iconTint: "#AEAEB2",
                groupedBackground: "#1C1C1E",
                headerText: "#AEAEB2",
                badgeBackground: "#636366",
                badgeText: "#FFFFFF",
                switchTint: "#636366",
                selectionIndicator: "#636366"
            )
        case .oceanDeep:
            return AppWideColors(
                appBackground: "#0A1628",
                navigationBar: "#0D1E38",
                tabBar: "#0D1E38",
                primaryText: "#E2E8F0",
                secondaryText: "#7A92B0",
                cardBackground: "#0F2137",
                accent: "#0A84FF",
                separator: "#1A3050",
                cellHighlight: "#142840",
                destructive: "#FF3B30",
                buttonBackground: "#0A84FF",
                buttonText: "#FFFFFF",
                iconTint: "#0A84FF",
                groupedBackground: "#0A1628",
                headerText: "#7A92B0",
                badgeBackground: "#0A84FF",
                badgeText: "#FFFFFF",
                switchTint: "#0A84FF",
                selectionIndicator: "#0A84FF"
            )
        case .warmBlack:
            return AppWideColors(
                appBackground: "#12100E",
                navigationBar: "#1A1713",
                tabBar: "#1A1713",
                primaryText: "#FFFFFF",
                secondaryText: "#8A7560",
                cardBackground: "#1C1A17",
                accent: "#FF9F0A",
                separator: "#2A2520",
                cellHighlight: "#252119",
                destructive: "#FF3B30",
                buttonBackground: "#FF9F0A",
                buttonText: "#000000",
                iconTint: "#FF9F0A",
                groupedBackground: "#0E0C09",
                headerText: "#FF9F0A",
                badgeBackground: "#2A2520",
                badgeText: "#FF9F0A",
                switchTint: "#FF9F0A",
                selectionIndicator: "#FF9F0A"
            )
        }
    }
}

// MARK: - Typography Configuration

struct AppWideTypography {
    let titleFont: UIFont
    let largeTitleFont: UIFont
    let headerAlignment: TextAlignment
    let horizontalPadding: CGFloat
    let topSafeAreaSpacing: CGFloat

    static let `default` = AppWideTypography(
        titleFont: .systemFont(ofSize: 17, weight: .semibold),
        largeTitleFont: .systemFont(ofSize: 34, weight: .bold),
        headerAlignment: .leading,
        horizontalPadding: 16,
        topSafeAreaSpacing: 8
    )
}

// MARK: - Theme Manager

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let userDefaults = UserDefaults.standard
    private let themeKey = "app.selectedTheme"
    private let colorsKey = "app.appWideColors"
    private let sectionHeaderKey = "app.sectionHeaderTheme"

    var currentTheme: AppTheme {
        didSet {
            userDefaults.set(currentTheme.rawValue, forKey: themeKey)
            applyUIKitAppearance()
        }
    }

    var customColors: AppWideColors? {
        didSet {
            if let colors = customColors {
                if let data = try? JSONEncoder().encode(colors) {
                    userDefaults.set(data, forKey: colorsKey)
                }
            } else {
                userDefaults.removeObject(forKey: colorsKey)
            }
            applyUIKitAppearance()
        }
    }

    var sectionHeaderTheme: SectionHeaderTheme {
        didSet {
            if let data = try? JSONEncoder().encode(sectionHeaderTheme.persisted) {
                userDefaults.set(data, forKey: sectionHeaderKey)
            }
        }
    }

    // MARK: - Computed Properties

    var isCustomTheme: Bool {
        customColors != nil
    }

    var colors: AppWideColors {
        customColors ?? .default(for: currentTheme)
    }

    var typography: AppWideTypography {
        .default
    }

    // MARK: - SwiftUI Color Accessors

    var accent: Color { Color(hex: colors.accent) }
    var primaryText: Color { Color(hex: colors.primaryText) }
    var secondaryText: Color { Color(hex: colors.secondaryText) }
    var background: Color { Color(hex: colors.appBackground) }
    var surface: Color { Color(hex: colors.cardBackground) }
    var navigationBar: Color { Color(hex: colors.navigationBar) }
    var tabBar: Color { Color(hex: colors.tabBar) }
    var separator: Color { Color(hex: colors.separator) }
    var cellHighlight: Color { Color(hex: colors.cellHighlight) }
    var destructive: Color { Color(hex: colors.destructive) }
    var buttonBackground: Color { Color(hex: colors.buttonBackground) }
    var buttonText: Color { Color(hex: colors.buttonText) }
    var iconTint: Color { Color(hex: colors.iconTint) }
    var groupedBackground: Color { Color(hex: colors.groupedBackground) }
    var headerText: Color { Color(hex: colors.headerText) }
    var badgeBackground: Color { Color(hex: colors.badgeBackground) }
    var badgeText: Color { Color(hex: colors.badgeText) }
    var switchTint: Color { Color(hex: colors.switchTint) }
    var selection: Color { Color(hex: colors.selectionIndicator) }
    var warning: Color { .orange }

    // Legacy aliases for compatibility
    var accentColor: Color { accent }
    var primaryTextColor: Color { primaryText }
    var secondaryTextColor: Color { secondaryText }
    var appBackgroundColor: Color { background }
    var cardBackgroundColor: Color { surface }
    var navigationBarColor: Color { navigationBar }
    var tabBarColor: Color { tabBar }
    var separatorColor: Color { separator }
    var cellHighlightColor: Color { cellHighlight }
    var destructiveColor: Color { destructive }
    var buttonBackgroundColor: Color { buttonBackground }
    var buttonTextColor: Color { buttonText }
    var iconTintColor: Color { iconTint }
    var groupedBackgroundColor: Color { groupedBackground }
    var headerTextColor: Color { headerText }
    var badgeBackgroundColor: Color { badgeBackground }
    var badgeTextColor: Color { badgeText }
    var switchTintColor: Color { switchTint }
    var selectionColor: Color { selection }
    var warningColor: Color { warning }
    var borderColor: Color { separator }
    var segmentedSelectedColor: Color { selection }
    var segmentedBackgroundColor: Color { surface }
    var sliderTintColor: Color { accent }
    var progressTintColor: Color { accent }

    // MARK: - UIKit Color Accessors

    var accentUIColor: UIColor { UIColor(hex: colors.accent) }
    var primaryTextUIColor: UIColor { UIColor(hex: colors.primaryText) }
    var secondaryTextUIColor: UIColor { UIColor(hex: colors.secondaryText) }
    var appBackgroundUIColor: UIColor { UIColor(hex: colors.appBackground) }
    var cardBackgroundUIColor: UIColor { UIColor(hex: colors.cardBackground) }
    var separatorUIColor: UIColor { UIColor(hex: colors.separator) }
    var switchTintUIColor: UIColor { UIColor(hex: colors.switchTint) }
    var cellHighlightUIColor: UIColor { UIColor(hex: colors.cellHighlight) }
    var headerTextUIColor: UIColor { UIColor(headerText) }
    var borderUIColor: UIColor { UIColor(separator) }
    var segmentedSelectedUIColor: UIColor { UIColor(selection) }
    var segmentedBackgroundUIColor: UIColor { UIColor(surface) }
    var sliderTintUIColor: UIColor { UIColor(accent) }
    var progressTintUIColor: UIColor { UIColor(accent) }

    // Theme ID for view invalidation (used sparingly)
    var currentThemeID: String {
        "\(currentTheme.rawValue)-\(colors.hashValue)-\(sectionHeaderTheme.hashValue)"
    }

    // Legacy compatibility
    var appWideColors: AppWideColors? {
        get { customColors }
        set { customColors = newValue }
    }

    var resolvedColors: AppWideColors {
        colors
    }

    // MARK: - Initialization

    init() {
        let themeRaw = userDefaults.string(forKey: themeKey) ?? AppTheme.darkNavy.rawValue
        self.currentTheme = AppTheme(rawValue: themeRaw) ?? .darkNavy

        if let data = userDefaults.data(forKey: colorsKey),
           let decoded = try? JSONDecoder().decode(AppWideColors.self, from: data) {
            self.customColors = decoded
        } else {
            self.customColors = nil
        }

        if let data = userDefaults.data(forKey: sectionHeaderKey),
           let decoded = try? JSONDecoder().decode(PersistedSectionHeaderTheme.self, from: data) {
            self.sectionHeaderTheme = SectionHeaderTheme(persisted: decoded)
        } else {
            self.sectionHeaderTheme = .default(for: colors)
        }

        applyUIKitAppearance()
    }

    // MARK: - Public Methods

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        customColors = nil
        sectionHeaderTheme = .default(for: colors)
    }

    func applyTheme(_ theme: AppTheme) {
        setTheme(theme)
    }

    func updateColor(keyPath: WritableKeyPath<AppWideColors, String>, hex: String) {
        var updatedColors = colors
        updatedColors[keyPath: keyPath] = hex
        customColors = updatedColors
    }

    func resetToThemeDefaults() {
        customColors = nil
        sectionHeaderTheme = .default(for: colors)
    }

    // MARK: - UIKit Appearance Application

    func applyUIKitAppearance() {
        let appBg = UIColor(hex: colors.appBackground)
        let navBar = UIColor(hex: colors.navigationBar)
        let tabBarBg = UIColor(hex: colors.tabBar)
        let accentUI = UIColor(hex: colors.accent)
        let primaryTxt = UIColor(hex: colors.primaryText)
        let secondaryTxt = UIColor(hex: colors.secondaryText)
        let sep = UIColor(hex: colors.separator)
        let switchUI = UIColor(hex: colors.switchTint)
        let cardBg = UIColor(hex: colors.cardBackground)

        // Apply window appearance
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = appBg
                window.tintColor = accentUI
            }
        }

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = navBar
        navAppearance.titleTextAttributes = [
            .foregroundColor: primaryTxt,
            .font: typography.titleFont
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: primaryTxt,
            .font: typography.largeTitleFont
        ]
        navAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = accentUI

        // Search bar appearance
        UISearchBar.appearance().tintColor = accentUI

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = tabBarBg

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = accentUI
        UITabBar.appearance().unselectedItemTintColor = secondaryTxt

        // Table and collection views
        UITableView.appearance().backgroundColor = appBg
        UITableViewCell.appearance().backgroundColor = cardBg
        UITableView.appearance().separatorColor = sep
        UICollectionView.appearance().backgroundColor = appBg

        // Controls
        UISwitch.appearance().onTintColor = switchUI

        // Apply section styling via manager
        SectionStyleManager.shared.applyGlobalUIKitStyle(themeManager: self)

        // Post notification for UIKit views to refresh
        NotificationCenter.default.post(name: .init("AppWideThemeDidChange"), object: nil)
    }
}

// MARK: - Type Alias for Compatibility

typealias AppWideThemeManager = ThemeManager

// MARK: - Navigation Title Modifier

struct AppWideHeaderTitleModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    let displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(themeManager.navigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func appWideHeaderTitle(displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        modifier(AppWideHeaderTitleModifier(displayMode: displayMode))
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
