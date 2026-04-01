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
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.separator.opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
    }
}

struct ThemedAccentModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        content
            .tint(themeManager.accent)
            .accentColor(themeManager.accent)
    }
}

struct ThemedTextModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    let role: TextRole

    func body(content: Content) -> some View {
        content
            .foregroundStyle(textColor)
    }

    private var textColor: Color {
        switch role {
        case .primary: themeManager.primaryText
        case .secondary: themeManager.secondaryText
        case .header: themeManager.headerText
        case .badge: themeManager.badgeText
        }
    }
}

struct GlobalThemeModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        ZStack {
            themeManager.background
                .ignoresSafeArea()

            content
                .scrollContentBackground(.hidden)
        }
        .background(themeManager.background)
        .toolbarBackground(themeManager.navigationBar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(themeManager.tabBar, for: .tabBar)
        .tint(themeManager.accent)
        .accentColor(themeManager.accent)
        .foregroundStyle(themeManager.primaryText)
        .buttonStyle(.plain)
        .preferredColorScheme(nil)
        .animation(.easeInOut(duration: 0.25), value: themeManager.currentThemeID)
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(themeManager.navigationBar, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct ThemedListRowModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        content
            .background(themeManager.surface)
            .foregroundStyle(themeManager.primaryText)
    }
}

struct ThemedSectionHeaderModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(themeManager.headerText)
            .textCase(.uppercase)
            .tracking(0.5)
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
}
