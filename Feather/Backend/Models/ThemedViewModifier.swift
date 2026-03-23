import SwiftUI

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
    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }

    func themedListRow() -> some View {
        self.modifier(ThemedListRowModifier())
    }
}
