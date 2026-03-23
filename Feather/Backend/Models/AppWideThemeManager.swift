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

    // New slots
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
                secondaryText: "#A0AEC0",
                cardBackground: "#1A202C",
                accent: "#4299E1",
                separator: "#2D3748",
                cellHighlight: "#2D3748",
                destructive: "#FF3B30",
                buttonBackground: "#4299E1",
                buttonText: "#FFFFFF",
                iconTint: "#4299E1",
                groupedBackground: "#0D0F1A",
                headerText: "#A0AEC0",
                badgeBackground: "#4299E1",
                badgeText: "#FFFFFF",
                switchTint: "#4299E1",
                selectionIndicator: "#4299E1"
            )
        case .midnight:
            return AppWideColors(
                appBackground: "#000000",
                navigationBar: "#121212",
                tabBar: "#121212",
                primaryText: "#FFFFFF",
                secondaryText: "#8E8E93",
                cardBackground: "#1C1C1E",
                accent: "#0A84FF",
                separator: "#38383A",
                cellHighlight: "#38383A",
                destructive: "#FF3B30",
                buttonBackground: "#0A84FF",
                buttonText: "#FFFFFF",
                iconTint: "#0A84FF",
                groupedBackground: "#000000",
                headerText: "#8E8E93",
                badgeBackground: "#0A84FF",
                badgeText: "#FFFFFF",
                switchTint: "#0A84FF",
                selectionIndicator: "#0A84FF"
            )
        case .graphite:
            return AppWideColors(
                appBackground: "#1C1C1E",
                navigationBar: "#2C2C2E",
                tabBar: "#2C2C2E",
                primaryText: "#FFFFFF",
                secondaryText: "#AEAEB2",
                cardBackground: "#3A3A3C",
                accent: "#FF9F0A",
                separator: "#48484A",
                cellHighlight: "#48484A",
                destructive: "#FF3B30",
                buttonBackground: "#FF9F0A",
                buttonText: "#000000",
                iconTint: "#FF9F0A",
                groupedBackground: "#1C1C1E",
                headerText: "#AEAEB2",
                badgeBackground: "#FF9F0A",
                badgeText: "#000000",
                switchTint: "#FF9F0A",
                selectionIndicator: "#FF9F0A"
            )
        case .oceanDeep:
            return AppWideColors(
                appBackground: "#0A1628",
                navigationBar: "#0F223D",
                tabBar: "#0F223D",
                primaryText: "#E2E8F0",
                secondaryText: "#94A3B8",
                cardBackground: "#1E293B",
                accent: "#38BDF8",
                separator: "#334155",
                cellHighlight: "#334155",
                destructive: "#FF3B30",
                buttonBackground: "#38BDF8",
                buttonText: "#000000",
                iconTint: "#38BDF8",
                groupedBackground: "#0A1628",
                headerText: "#94A3B8",
                badgeBackground: "#38BDF8",
                badgeText: "#000000",
                switchTint: "#38BDF8",
                selectionIndicator: "#38BDF8"
            )
        case .warmBlack:
            return AppWideColors(
                appBackground: "#12100E",
                navigationBar: "#1C1917",
                tabBar: "#1C1917",
                primaryText: "#F5F5F4",
                secondaryText: "#A8A29E",
                cardBackground: "#292524",
                accent: "#F59E0B",
                separator: "#44403C",
                cellHighlight: "#44403C",
                destructive: "#FF3B30",
                buttonBackground: "#F59E0B",
                buttonText: "#000000",
                iconTint: "#F59E0B",
                groupedBackground: "#12100E",
                headerText: "#A8A29E",
                badgeBackground: "#F59E0B",
                badgeText: "#000000",
                switchTint: "#F59E0B",
                selectionIndicator: "#F59E0B"
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

    var accentColor: Color {
        Color(hex: resolvedColors.accent)
    }

    var accentUIColor: UIColor {
        UIColor(hex: resolvedColors.accent)
    }

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
        let colors = resolvedColors

        let bgColor = UIColor(hex: colors.appBackground)
        let navBarColor = UIColor(hex: colors.navigationBar)
        let tabBarColor = UIColor(hex: colors.tabBar)
        let cardColor = UIColor(hex: colors.cardBackground)
        let primaryTextColor = UIColor(hex: colors.primaryText)
        let separatorColor = UIColor(hex: colors.separator)

        let accentColor = UIColor(hex: colors.accent)
        let iconTint = UIColor(hex: colors.iconTint)
        let groupedBg = UIColor(hex: colors.groupedBackground)
        let headerTextColor = UIColor(hex: colors.headerText)
        let buttonBgColor = UIColor(hex: colors.buttonBackground)
        let buttonTextColor = UIColor(hex: colors.buttonText)
        let switchTintColor = UIColor(hex: colors.switchTint)
        let badgeBgColor = UIColor(hex: colors.badgeBackground)

        // Window background & Tint
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = bgColor
                window.tintColor = iconTint
            }
        }

        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = navBarColor
        navAppearance.titleTextAttributes = [.foregroundColor: primaryTextColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: primaryTextColor]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = accentColor

        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = tabBarColor

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = accentColor

        // Lists/Cards
        UITableView.appearance().backgroundColor = cardColor
        UITableViewCell.appearance().backgroundColor = cardColor
        UICollectionView.appearance().backgroundColor = cardColor

        // Grouped Lists
        UITableView.appearance(whenContainedInInstancesOf: [UIViewController.self]).backgroundColor = groupedBg

        // Cell Tint & Highlight
        UIView.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = accentColor

        // Section Headers
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = headerTextColor

        // Primary Text
        UILabel.appearance().textColor = primaryTextColor

        // Badges (Manual tagging needed)
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).backgroundColor = badgeBgColor

        // Separator
        UITableView.appearance().separatorColor = separatorColor

        // Switches
        UISwitch.appearance().onTintColor = switchTintColor

        // Sliders
        UISlider.appearance().minimumTrackTintColor = accentColor

        // Progress Views
        UIProgressView.appearance().progressTintColor = accentColor

        // Page Control
        UIPageControl.appearance().currentPageIndicatorTintColor = accentColor

        // Segmented Control
        UISegmentedControl.appearance().selectedSegmentTintColor = accentColor

        // Buttons
        UIButton.appearance().tintColor = accentColor
        UIButton.appearance().backgroundColor = buttonBgColor
        UIButton.appearance().setTitleColor(buttonTextColor, for: .normal)

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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
