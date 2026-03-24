import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case darkNavy
    case midnight
    case graphite
    case oceanDeep
    case warmBlack

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

    static let slotCount = 19

    var border: String { separator }

    static func `default`(for theme: AppTheme) -> AppWideColors {
        switch theme {
        case .darkNavy:
            return AppWideColors(appBackground: "#0D0F1A", navigationBar: "#161B2E", tabBar: "#161B2E", primaryText: "#FFFFFF", secondaryText: "#8A9BBE", cardBackground: "#1A2133", accent: "#3B8FE8", separator: "#252D44", cellHighlight: "#1F2840", destructive: "#FF3B30", buttonBackground: "#3B8FE8", buttonText: "#FFFFFF", iconTint: "#3B8FE8", groupedBackground: "#0D0F1A", headerText: "#8A9BBE", badgeBackground: "#3B8FE8", badgeText: "#FFFFFF", switchTint: "#3B8FE8", selectionIndicator: "#3B8FE8")
        case .midnight:
            return AppWideColors(appBackground: "#000000", navigationBar: "#0A0A0A", tabBar: "#0A0A0A", primaryText: "#FFFFFF", secondaryText: "#8E8E93", cardBackground: "#111111", accent: "#3B8FE8", separator: "#1C1C1E", cellHighlight: "#1A1A1A", destructive: "#FF3B30", buttonBackground: "#3B8FE8", buttonText: "#FFFFFF", iconTint: "#3B8FE8", groupedBackground: "#000000", headerText: "#8E8E93", badgeBackground: "#3B8FE8", badgeText: "#FFFFFF", switchTint: "#3B8FE8", selectionIndicator: "#3B8FE8")
        case .graphite:
            return AppWideColors(appBackground: "#1C1C1E", navigationBar: "#2C2C2E", tabBar: "#2C2C2E", primaryText: "#FFFFFF", secondaryText: "#AEAEB2", cardBackground: "#2C2C2E", accent: "#636366", separator: "#3A3A3C", cellHighlight: "#323234", destructive: "#FF3B30", buttonBackground: "#636366", buttonText: "#FFFFFF", iconTint: "#AEAEB2", groupedBackground: "#1C1C1E", headerText: "#AEAEB2", badgeBackground: "#636366", badgeText: "#FFFFFF", switchTint: "#636366", selectionIndicator: "#636366")
        case .oceanDeep:
            return AppWideColors(appBackground: "#0A1628", navigationBar: "#0D1E38", tabBar: "#0D1E38", primaryText: "#E2E8F0", secondaryText: "#7A92B0", cardBackground: "#0F2137", accent: "#0A84FF", separator: "#1A3050", cellHighlight: "#142840", destructive: "#FF3B30", buttonBackground: "#0A84FF", buttonText: "#FFFFFF", iconTint: "#0A84FF", groupedBackground: "#0A1628", headerText: "#7A92B0", badgeBackground: "#0A84FF", badgeText: "#FFFFFF", switchTint: "#0A84FF", selectionIndicator: "#0A84FF")
        case .warmBlack:
            return AppWideColors(appBackground: "#12100E", navigationBar: "#1A1713", tabBar: "#1A1713", primaryText: "#FFFFFF", secondaryText: "#8A7560", cardBackground: "#1C1A17", accent: "#FF9F0A", separator: "#2A2520", cellHighlight: "#252119", destructive: "#FF3B30", buttonBackground: "#FF9F0A", buttonText: "#000000", iconTint: "#FF9F0A", groupedBackground: "#0E0C09", headerText: "#FF9F0A", badgeBackground: "#2A2520", badgeText: "#FF9F0A", switchTint: "#FF9F0A", selectionIndicator: "#FF9F0A")
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: "app.selectedTheme") }
    }

    @Published var appWideColors: AppWideColors? {
        didSet {
            if let appWideColors, let encoded = try? JSONEncoder().encode(appWideColors) {
                UserDefaults.standard.set(encoded, forKey: "app.appWideColors")
            } else {
                UserDefaults.standard.removeObject(forKey: "app.appWideColors")
            }
        }
    }

    var resolvedColors: AppWideColors { appWideColors ?? AppWideColors.default(for: currentTheme) }

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

    var appBackgroundUIColor: UIColor { UIColor(appBackgroundColor) }
    var navigationBarUIColor: UIColor { UIColor(navigationBarColor) }
    var tabBarUIColor: UIColor { UIColor(tabBarColor) }
    var primaryTextUIColor: UIColor { UIColor(primaryTextColor) }
    var secondaryTextUIColor: UIColor { UIColor(secondaryTextColor) }
    var cardBackgroundUIColor: UIColor { UIColor(cardBackgroundColor) }
    var accentUIColor: UIColor { UIColor(accentColor) }
    var separatorUIColor: UIColor { UIColor(separatorColor) }
    var cellHighlightUIColor: UIColor { UIColor(cellHighlightColor) }
    var destructiveUIColor: UIColor { UIColor(destructiveColor) }
    var buttonBackgroundUIColor: UIColor { UIColor(buttonBackgroundColor) }
    var buttonTextUIColor: UIColor { UIColor(buttonTextColor) }
    var iconTintUIColor: UIColor { UIColor(iconTintColor) }
    var groupedBackgroundUIColor: UIColor { UIColor(groupedBackgroundColor) }
    var headerTextUIColor: UIColor { UIColor(headerTextColor) }
    var badgeBackgroundUIColor: UIColor { UIColor(badgeBackgroundColor) }
    var badgeTextUIColor: UIColor { UIColor(badgeTextColor) }
    var switchTintUIColor: UIColor { UIColor(switchTintColor) }
    var selectionUIColor: UIColor { UIColor(selectionColor) }
    var borderUIColor: UIColor { UIColor(borderColor) }
    var segmentedSelectedUIColor: UIColor { UIColor(segmentedSelectedColor) }
    var segmentedBackgroundUIColor: UIColor { UIColor(segmentedBackgroundColor) }
    var sliderTintUIColor: UIColor { UIColor(sliderTintColor) }
    var progressTintUIColor: UIColor { UIColor(progressTintColor) }

    private init() {
        let themeRaw = UserDefaults.standard.string(forKey: "app.selectedTheme") ?? AppTheme.darkNavy.rawValue
        currentTheme = AppTheme(rawValue: themeRaw) ?? .darkNavy
        if let data = UserDefaults.standard.data(forKey: "app.appWideColors") {
            appWideColors = try? JSONDecoder().decode(AppWideColors.self, from: data)
        } else {
            appWideColors = nil
        }

        DispatchQueue.main.async { [weak self] in
            self?.applyUIKitAppearance()
        }
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
        let appBackground = appBackgroundUIColor
        let navigationBar = navigationBarUIColor
        let tabBar = tabBarUIColor
        let accent = accentUIColor
        let primaryText = primaryTextUIColor
        let secondaryText = secondaryTextUIColor
        let separator = separatorUIColor

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = appBackground
                window.tintColor = accent
            }
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = navigationBar
        nav.titleTextAttributes = [.foregroundColor: primaryText]
        nav.largeTitleTextAttributes = [.foregroundColor: primaryText]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = accent

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = tabBar

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = secondaryText

        UITableView.appearance().backgroundColor = appBackground
        UITableViewCell.appearance().backgroundColor = cardBackgroundUIColor
        UITableView.appearance().separatorColor = separator
        UICollectionView.appearance().backgroundColor = appBackground
        UISwitch.appearance().onTintColor = switchTintUIColor

        SectionStyleManager.shared.applyGlobalUIKitStyle()
        NotificationCenter.default.post(name: Notification.Name("AppWideThemeDidChange"), object: nil)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self.init(white: 0, alpha: 0)
            return
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
