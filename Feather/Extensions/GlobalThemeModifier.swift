import SwiftUI

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager

    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.dividerColor) private var dividerColorHex: String = "#E5E5EA"
    @AppStorage(UserDefaults.Keys.successColor) private var successColorHex: String = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor) private var warningColorHex: String = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor) private var errorColorHex: String = "#FF3B30"
    @AppStorage(UserDefaults.Keys.glowIntensity) private var glowIntensity: Double = 10.0
    @AppStorage(UserDefaults.Keys.borderWidth) private var borderWidth: Double = 0.0
    @AppStorage(UserDefaults.Keys.cardOpacity) private var cardOpacity: Double = 1.0

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    func body(content: Content) -> some View {
        let uiColor = Color(hex: uiElementColorHex)
        let textColor = Color(hex: textColorHex)

        return ZStack {
            backgroundManager.resolvedColor
                .ignoresSafeArea()

            content
                .foregroundStyle(textColor)
                .tint(uiColor)
                .accentColor(uiColor)
                .applyFontDesign(selectedFontDesign)
                .environment(\.dividerColor, Color(hex: dividerColorHex))
                .environment(\.successColor, Color(hex: successColorHex))
                .environment(\.warningColor, Color(hex: warningColorHex))
                .environment(\.errorColor, Color(hex: errorColorHex))
                .environment(\.glowIntensity, glowIntensity)
                .environment(\.borderWidth, borderWidth)
                .environment(\.cardOpacity, cardOpacity)
        }
        .applySheetTransparency()
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }

    @ViewBuilder
    func applySheetTransparency() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(.clear)
        } else {
            self
        }
    }
}
