import SwiftUI

// MARK: - Text Role

enum TextRole {
    case primary
    case secondary
    case header
    case badge
}

// MARK: - View Modifiers

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(themeManager.separatorColor.opacity(0.5), lineWidth: 0.5)
            }
    }
}

struct ThemedAccentModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .tint(themeManager.accent)
            .accentColor(themeManager.accent)
    }
}

struct ThemedTextModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let role: TextRole

    func body(content: Content) -> some View {
        content.foregroundStyle(color)
    }

    private var color: Color {
        switch role {
        case .primary:   return themeManager.primaryTextColor
        case .secondary: return themeManager.secondaryTextColor
        case .header:    return themeManager.headerTextColor
        case .badge:     return themeManager.badgeTextColor
        }
    }
}

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        ZStack {
            themeManager.background.ignoresSafeArea()
            content
                .scrollContentBackground(.hidden)
        }
        .animation(.easeInOut, value: themeManager.currentThemeID)
        .background(themeManager.background)
        .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(themeManager.tabBarColor, for: .tabBar)
        .tint(themeManager.accent)
        .accentColor(themeManager.accent)
        .foregroundStyle(themeManager.primaryText)
        .buttonStyle(.plain)
        .preferredColorScheme(nil)
        .id(themeManager.currentThemeID)
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct ThemedListRowModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.surface)
            .foregroundStyle(themeManager.primaryText)
    }
}

struct ThemedSectionHeaderModifier: ViewModifier {
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

/// Applies the navigation bar color and tint from the theme.
struct ThemedNavigationBarModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(themeManager.accent)
    }
}

/// Applies a themed sheet / presented-view background.
struct ThemedSheetModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 16.4, *) {
                content
                    .background(themeManager.background)
                    .presentationBackground(themeManager.background)
                    .tint(themeManager.accent)
            } else {
                content
                    .background(themeManager.background)
                    .tint(themeManager.accent)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func globalTheme() -> some View {
        modifier(GlobalThemeModifier())
    }

    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedAccent() -> some View {
        modifier(ThemedAccentModifier())
    }

    func themedText(_ role: TextRole) -> some View {
        modifier(ThemedTextModifier(role: role))
    }

    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }

    func themedListRow() -> some View {
        modifier(ThemedListRowModifier())
    }

    func themedSectionHeader() -> some View {
        modifier(ThemedSectionHeaderModifier())
    }

    func themedNavigationBar() -> some View {
        modifier(ThemedNavigationBarModifier())
    }

    func themedSheet() -> some View {
        modifier(ThemedSheetModifier())
    }
}
