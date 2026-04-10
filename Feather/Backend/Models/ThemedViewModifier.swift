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
            .background(themeManager.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.separatorColor.opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
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
        ZStack {
            themeManager.background
                .ignoresSafeArea()

            content
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
        }
        .animation(.easeInOut, value: themeManager.currentThemeID)
        .background(themeManager.background)
        .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(themeManager.tabBarColor, for: .tabBar)
        .tint(themeManager.accent)
        .accentColor(themeManager.accent)
        .foregroundStyle(themeManager.primaryText)
        .preferredColorScheme(themeManager.currentTheme == .light ? .light : .dark)
        .id(themeManager.currentThemeID)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppWideThemeDidChange"))) { _ in
            // SwiftUI will re-render automatically via @EnvironmentObject publish
            // This onReceive ensures UIKit-backed views also refresh
        }
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
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppWideThemeDidChange"))) { _ in
                // SwiftUI will re-render automatically via @EnvironmentObject publish
                // This onReceive ensures UIKit-backed views also refresh
            }
    }
}


struct ThemedSectionHeaderModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(themeManager.sectionHeaderTheme.resolvedTextColor(style: styleManager.currentStyle, defaultColor: themeManager.headerTextColor))
            .textCase(.uppercase)
            .tracking(1.0)
            .padding(.leading, 8)
            .padding(.bottom, 4)
            .background(themeManager.sectionHeaderTheme.resolvedBackgroundColor(style: styleManager.currentStyle))
    }
}

struct ThemedListModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.background)
    }
}

struct ThemedListRowBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .listRowBackground(themeManager.surface)
            .listRowSeparatorTint(themeManager.separatorColor)
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

    func themedSectionHeader() -> some View {
        self.modifier(ThemedSectionHeaderModifier())
    }

    func themedList() -> some View {
        self.modifier(ThemedListModifier())
    }

    func themedListRow() -> some View {
        self.modifier(ThemedListRowBackgroundModifier())
    }
}
