import SwiftUI

enum TextRole {
    case primary
    case secondary
    case header
    case badge
}

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .clipped()
    }
}

struct ThemedAccentModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .tint(themeManager.accentColor)
            .accentColor(themeManager.accentColor)
    }
}

struct ThemedTextModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let role: TextRole

    func body(content: Content) -> some View {
        content
            .foregroundStyle(textColor)
    }

    private var textColor: Color {
        switch role {
        case .primary: return themeManager.primaryTextColor
        case .secondary: return themeManager.secondaryTextColor
        case .header: return themeManager.headerTextColor
        case .badge: return themeManager.badgeTextColor
        }
    }
}

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.appBackgroundColor.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(hex: themeManager.resolvedColors.tabBar), for: .tabBar)
            .tint(themeManager.accentColor)
            .accentColor(themeManager.accentColor)
            .foregroundStyle(themeManager.primaryTextColor)
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.appBackgroundColor.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct ThemedListRowModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.cardBackgroundColor)
            .foregroundStyle(themeManager.primaryTextColor)
    }
}

struct ThemedSectionHeader: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(themeManager.headerTextColor)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

extension View {
    func globalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }

    func themedCard() -> some View {
        self.modifier(ThemedCardModifier())
    }

    func themedAccent() -> some View {
        self.modifier(ThemedAccentModifier())
    }

    func themedText(_ role: TextRole) -> some View {
        self.modifier(ThemedTextModifier(role: role))
    }

    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }

    func themedListRow() -> some View {
        self.modifier(ThemedListRowModifier())
    }

    func themedSectionHeader() -> some View {
        self.modifier(ThemedSectionHeader())
    }
}
