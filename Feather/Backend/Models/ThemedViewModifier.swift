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
            .background(Color(hex: themeManager.resolvedColors.cardBackground))
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
        case .primary: return Color(hex: themeManager.resolvedColors.primaryText)
        case .secondary: return Color(hex: themeManager.resolvedColors.secondaryText)
        case .header: return Color(hex: themeManager.resolvedColors.headerText)
        case .badge: return Color(hex: themeManager.resolvedColors.badgeText)
        }
    }
}

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var themeVersion: Int = 0

    func body(content: Content) -> some View {
        content
            .background(Color(hex: themeManager.resolvedColors.appBackground).ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color(hex: themeManager.resolvedColors.navigationBar), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(hex: themeManager.resolvedColors.tabBar), for: .tabBar)
            .tint(themeManager.accentColor)
            .accentColor(themeManager.accentColor)
            .id(themeVersion)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppWideThemeDidChange"))) { _ in
                themeVersion += 1
            }
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(Color(hex: themeManager.resolvedColors.appBackground).ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color(hex: themeManager.resolvedColors.navigationBar), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct ThemedListRowModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(Color(hex: themeManager.resolvedColors.cardBackground))
            .foregroundStyle(Color(hex: themeManager.resolvedColors.primaryText))
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
}
