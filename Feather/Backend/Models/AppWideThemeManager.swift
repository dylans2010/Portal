import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case darkNavy = "darkNavy"
    case midnight = "midnight"
    case graphite = "graphite"
    case oceanDeep = "oceanDeep"
    case warmBlack = "warmBlack"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkNavy: return "Dark Navy"
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .oceanDeep: return "Ocean Deep"
        case .warmBlack: return "Warm Black"
        }
    }

    var previewHex: String {
        switch self {
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

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

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

    // MARK: - UIKit Color Helpers
    var accentUIColor: UIColor { UIColor(hex: resolvedColors.accent) }
    var separatorUIColor: UIColor { UIColor(hex: resolvedColors.separator) }
    var primaryTextUIColor: UIColor { UIColor(hex: resolvedColors.primaryText) }
    var cardBackgroundUIColor: UIColor { UIColor(hex: resolvedColors.cardBackground) }

    private init() {
        let themeRaw = UserDefaults.standard.string(forKey: "app.selectedTheme") ?? AppTheme.darkNavy.rawValue
        self.currentTheme = AppTheme(rawValue: themeRaw) ?? .darkNavy

        if let data = UserDefaults.standard.data(forKey: "app.appWideColors") {
            self.appWideColors = try? JSONDecoder().decode(AppWideColors.self, from: data)
        }

        applyUIKitAppearance()
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        appWideColors = nil
        applyUIKitAppearance()
    }

    func updateColor(keyPath: WritableKeyPath<AppWideColors, String>, hex: String) {
        var newColors = resolvedColors
        newColors[keyPath: keyPath] = hex
        appWideColors = newColors
        applyUIKitAppearance()
    }

    func resetToThemeDefaults() {
        appWideColors = nil
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

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = appBackgroundColor
                window.tintColor = accentUIColor
            }
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = navigationBarColor
        nav.titleTextAttributes = [.foregroundColor: primaryTextColor]
        nav.largeTitleTextAttributes = [.foregroundColor: primaryTextColor]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = accentUIColor

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = tabBarColor

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = accentUIColor
        UITabBar.appearance().unselectedItemTintColor = secondaryTextColor

        UITableView.appearance().backgroundColor = appBackgroundColor
        UITableViewCell.appearance().backgroundColor = cardBackgroundColor
        UITableView.appearance().separatorColor = separatorColor
        UICollectionView.appearance().backgroundColor = appBackgroundColor

        UISwitch.appearance().onTintColor = switchTintColor

        NotificationCenter.default.post(name: Notification.Name("AppWideThemeDidChange"), object: nil)
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
