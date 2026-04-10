import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case amoled = "amoled"
    case highContrast = "highContrast"
    case pastel = "pastel"
    case neon = "neon"
    case darkNavy = "darkNavy"
    case midnight = "midnight"
    case graphite = "graphite"
    case oceanDeep = "oceanDeep"
    case warmBlack = "warmBlack"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .amoled: return "AMOLED"
        case .highContrast: return "High Contrast"
        case .pastel: return "Pastel"
        case .neon: return "Neon"
        case .darkNavy: return "Dark Navy"
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .oceanDeep: return "Ocean Deep"
        case .warmBlack: return "Warm Black"
        }
    }

    var previewHex: String {
        switch self {
        case .light: return "#F5F7FB"
        case .dark: return "#111318"
        case .amoled: return "#000000"
        case .highContrast: return "#000000"
        case .pastel: return "#FFF4FA"
        case .neon: return "#0A0014"
        case .darkNavy: return "#0D0F1A"
        case .midnight: return "#000000"
        case .graphite: return "#1C1C1E"
        case .oceanDeep: return "#0A1628"
        case .warmBlack: return "#12100E"
        }
    }

    var backgroundColor: Color {
        Color(hex: previewHex)
    }

    var uiBackgroundColor: UIColor {
        UIColor(hex: previewHex)
    }
}

struct AppWideColors: Codable, Equatable {
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

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private let sectionHeaderThemeKey = "app.sectionHeaderTheme"

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app.selectedTheme")
        }
    }

    @Published var appWideColors: AppWideColors? {
        didSet {
            if let colors = appWideColors {
                if let encoded = try? JSONEncoder().encode(colors) {
                    UserDefaults.standard.set(encoded, forKey: "app.appWideColors")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "app.appWideColors")
            }
        }
    }

    @Published var sectionHeaderTheme: SectionHeaderTheme {
        didSet {
            if let encoded = try? JSONEncoder().encode(sectionHeaderTheme.persistedValue) {
                UserDefaults.standard.set(encoded, forKey: sectionHeaderThemeKey)
            }
        }
    }

    var isCustomTheme: Bool { appWideColors != nil }

    var resolvedColors: AppWideColors {
        appWideColors ?? AppWideColors.default(for: currentTheme)
    }

    // MARK: - SwiftUI Color Helpers
    var accentColor: Color { Color(hex: resolvedColors.accent) }
    var primaryTextColor: Color { Color(hex: resolvedColors.primaryText) }
    var secondaryTextColor: Color { Color(hex: resolvedColors.secondaryText) }
    var cardBackgroundColor: Color { Color(hex: resolvedColors.cardBackground) }
    var appBackgroundColor: Color { Color(hex: resolvedColors.appBackground) }
    var iconTintColor: Color { Color(hex: resolvedColors.iconTint) }
    var headerTextColor: Color { Color(hex: resolvedColors.headerText) }
    var buttonBackgroundColor: Color { Color(hex: resolvedColors.buttonBackground) }
    var buttonTextColor: Color { Color(hex: resolvedColors.buttonText) }
    var badgeBackgroundColor: Color { Color(hex: resolvedColors.badgeBackground) }
    var badgeTextColor: Color { Color(hex: resolvedColors.badgeText) }
    var separatorColor: Color { Color(hex: resolvedColors.separator) }
    var switchTintColor: Color { Color(hex: resolvedColors.switchTint) }
    var selectionColor: Color { Color(hex: resolvedColors.selectionIndicator) }
    var cellHighlightColor: Color { Color(hex: resolvedColors.cellHighlight) }
    var destructiveColor: Color { Color(hex: resolvedColors.destructive) }
    var navigationBarColor: Color { Color(hex: resolvedColors.navigationBar) }
    var tabBarColor: Color { Color(hex: resolvedColors.tabBar) }
    var groupedBackgroundColor: Color { Color(hex: resolvedColors.groupedBackground) }
    var borderColor: Color { separatorColor }
    var segmentedSelectedColor: Color { selectionColor }
    var segmentedBackgroundColor: Color { cardBackgroundColor }
    var sliderTintColor: Color { accentColor }
    var progressTintColor: Color { accentColor }
    var warningColor: Color { .orange }
    var typography: AppWideTypography { .default }

    // Strict theme aliases used across themed views
    var accent: Color { accentColor }
    var primaryText: Color { primaryTextColor }
    var secondaryText: Color { secondaryTextColor }
    var background: Color { appBackgroundColor }
    var surface: Color { cardBackgroundColor }
    var currentThemeID: String {
        "\(currentTheme.rawValue)-\(resolvedColors.appBackground)-\(resolvedColors.cardBackground)-\(resolvedColors.accent)-\(sectionHeaderTheme.background.toHex() ?? "")-\(sectionHeaderTheme.textColor.toHex() ?? "")-\(sectionHeaderTheme.iconColor.toHex() ?? "")-\(sectionHeaderTheme.dividerColor.toHex() ?? "")"
    }

    // MARK: - UIKit Color Helpers
    var accentUIColor: UIColor { UIColor(hex: resolvedColors.accent) }
    var separatorUIColor: UIColor { UIColor(hex: resolvedColors.separator) }
    var primaryTextUIColor: UIColor { UIColor(hex: resolvedColors.primaryText) }
    var cardBackgroundUIColor: UIColor { UIColor(hex: resolvedColors.cardBackground) }
    var appBackgroundUIColor: UIColor { UIColor(hex: resolvedColors.appBackground) }
    var headerTextUIColor: UIColor { UIColor(headerTextColor) }
    var segmentedSelectedUIColor: UIColor { UIColor(selectionColor) }
    var segmentedBackgroundUIColor: UIColor { UIColor(cardBackgroundColor) }
    var sliderTintUIColor: UIColor { UIColor(accentColor) }
    var progressTintUIColor: UIColor { UIColor(accentColor) }
    var switchTintUIColor: UIColor { UIColor(switchTintColor) }
    var cellHighlightUIColor: UIColor { UIColor(cellHighlightColor) }
    var borderUIColor: UIColor { UIColor(borderColor) }
    var secondaryTextUIColor: UIColor { UIColor(secondaryTextColor) }

    init() {
        let themeRaw = UserDefaults.standard.string(forKey: "app.selectedTheme") ?? AppTheme.darkNavy.rawValue
        let theme = AppTheme(rawValue: themeRaw) ?? .darkNavy
        self.currentTheme = theme

        var loadedAppWideColors: AppWideColors?
        if let data = UserDefaults.standard.data(forKey: "app.appWideColors") {
            loadedAppWideColors = try? JSONDecoder().decode(AppWideColors.self, from: data)
        }
        self.appWideColors = loadedAppWideColors

        if let data = UserDefaults.standard.data(forKey: sectionHeaderThemeKey),
           let persisted = try? JSONDecoder().decode(PersistedSectionHeaderTheme.self, from: data) {
            self.sectionHeaderTheme = SectionHeaderTheme(persisted: persisted)
        } else {
            self.sectionHeaderTheme = SectionHeaderTheme.default(for: loadedAppWideColors ?? AppWideColors.default(for: theme))
        }

        applyUIKitAppearance()
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        appWideColors = nil
        sectionHeaderTheme = SectionHeaderTheme.default(for: AppWideColors.default(for: theme))
        applyUIKitAppearance()
    }

    func applyTheme(_ theme: AppTheme) {
        setTheme(theme)
    }

    func updateColor(keyPath: WritableKeyPath<AppWideColors, String>, hex: String) {
        var newColors = resolvedColors
        newColors[keyPath: keyPath] = hex
        appWideColors = newColors
        applyUIKitAppearance()
    }

    func resetToThemeDefaults() {
        appWideColors = nil
        sectionHeaderTheme = SectionHeaderTheme.default(for: AppWideColors.default(for: currentTheme))
        applyUIKitAppearance()
    }

    func applyUIKitAppearance() {
        let appBackgroundColor = UIColor(hex: resolvedColors.appBackground)
        let navigationBarColor = UIColor(hex: resolvedColors.navigationBar)
        let tabBarColor = UIColor(hex: resolvedColors.tabBar)
        let accentUIColor = UIColor(hex: resolvedColors.accent)
        let primaryTextColor = UIColor(hex: resolvedColors.primaryText)
        let secondaryTextColor = UIColor(hex: resolvedColors.secondaryText)
        let separatorColor = UIColor(hex: resolvedColors.separator)
        let switchTintColor = UIColor(hex: resolvedColors.switchTint)
        let cardBackgroundColor = UIColor(hex: resolvedColors.cardBackground)
        let cellHighlightColor = UIColor(hex: resolvedColors.cellHighlight)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = appBackgroundColor
                window.tintColor = accentUIColor
            }
        }

        // Navigation Bar
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = navigationBarColor
        nav.titleTextAttributes = [
            .foregroundColor: primaryTextColor,
            .font: typography.titleFont
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: primaryTextColor,
            .font: typography.largeTitleFont
        ]
        nav.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = accentUIColor

        // Search Bar
        UISearchBar.appearance().tintColor = accentUIColor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = accentUIColor

        // Tab Bar
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = tabBarColor

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = accentUIColor
        UITabBar.appearance().unselectedItemTintColor = secondaryTextColor

        // Tables & Lists
        UITableView.appearance().backgroundColor = appBackgroundColor
        UITableView.appearance().separatorColor = separatorColor
        UITableViewCell.appearance().backgroundColor = cardBackgroundColor

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = cellHighlightColor
        UITableViewCell.appearance().selectedBackgroundView = selectedBackgroundView

        // Collection Views
        UICollectionView.appearance().backgroundColor = appBackgroundColor

        // Controls
        UISwitch.appearance().onTintColor = switchTintColor
        UISlider.appearance().minimumTrackTintColor = accentUIColor
        UIProgressView.appearance().progressTintColor = accentUIColor

        // Buttons
        UIButton.appearance().tintColor = accentUIColor

        // Avoid recursively touching ThemeManager.shared while this singleton is initializing.
        SectionStyleManager.shared.applyGlobalUIKitStyle(themeManager: self)
        NotificationCenter.default.post(name: Notification.Name("AppWideThemeDidChange"), object: nil)
    }
}

typealias AppWideThemeManager = ThemeManager

struct AppWideHeaderTitleModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    let displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func appWideHeaderTitle(displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        modifier(AppWideHeaderTitleModifier(displayMode: displayMode))
    }
}

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
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
