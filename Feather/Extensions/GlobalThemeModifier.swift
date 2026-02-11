import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @ObservedObject private var appState = AppStateManager.shared

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let isDarkMode = colorScheme == .dark

        // Background Color
        let bgColor: Color
        if appState.isSigning {
            bgColor = Color(hex: bgColorHex)
        } else {
            if isDarkMode && (bgColorHex == Color.defaultBackground) {
                bgColor = .black
            } else {
                bgColor = Color(hex: bgColorHex)
            }
        }

        // UI Element / Tint Color
        let uiColor: Color
        if appState.isSigning {
            uiColor = Color(hex: uiElementColorHex)
        } else {
            // Default to white for better contrast in dark mode if using default blue
            if isDarkMode && (uiElementColorHex == Color.defaultUIElement) {
                uiColor = .white
            } else {
                uiColor = Color(hex: uiElementColorHex)
            }
        }

        // Text Color
        let textColor: Color
        if appState.isSigning {
            textColor = Color(hex: textColorHex)
        } else {
            // Force white text in dark mode if using default black text
            if isDarkMode && (textColorHex == Color.defaultText) {
                textColor = .white
            } else {
                textColor = Color(hex: textColorHex)
            }
        }

        return content
            .foregroundStyle(textColor)
            .tint(uiColor)
            .accentColor(uiColor)
            .background(bgColor.ignoresSafeArea())
            .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
