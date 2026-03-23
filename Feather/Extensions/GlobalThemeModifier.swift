import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @AppStorage("Feather.animateBackground") private var animateBackground: Bool = false

    // Experimental & Advanced
    @AppStorage("Feather.appearance.highContrast") private var highContrast: Bool = false
    @AppStorage("Feather.appearance.performanceMode") private var performanceMode: Bool = false
    @AppStorage("Feather.appearance.parallaxEnabled") private var parallaxEnabled: Bool = false
    @AppStorage("Feather.appearance.motionGradients") private var motionGradients: Bool = true
    @AppStorage("Feather.appearance.layerBlendMode") private var layerBlendMode: Int = 0
    @AppStorage("Feather.appearance.autoContrastCorrection") private var autoContrastCorrection: Bool = true

    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex: String = "#8E8E93"
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity: Double = 1.0
    @AppStorage(UserDefaults.Keys.navBarColor) private var navBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.tabBarColor) private var tabBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.dividerColor) private var dividerColorHex: String = "#E5E5EA"
    @AppStorage(UserDefaults.Keys.sheetBackgroundColor) private var sheetBackgroundColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.successColor) private var successColorHex: String = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor) private var warningColorHex: String = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor) private var errorColorHex: String = "#FF3B30"
    @AppStorage(UserDefaults.Keys.glowIntensity) private var glowIntensity: Double = 10.0
    @AppStorage(UserDefaults.Keys.borderWidth) private var borderWidth: Double = 0.0
    @AppStorage(UserDefaults.Keys.cardOpacity) private var cardOpacity: Double = 1.0

    @ObservedObject private var appState = AppStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    func body(content: Content) -> some View {
        // UI Elements logic
        let uiColor = Color(hex: uiElementColorHex)

        // Text color logic: removed ColorScheme dependency
        var textColor = highContrast ? (colorScheme == .dark ? .white : .black) : Color(hex: textColorHex)

        // Adaptive UI Intelligence: Auto-adjust colors based on background luminance
        if autoContrastCorrection && !highContrast {
            let bgLuminance = backgroundManager.resolvedColor.brightness
            let textLuminance = textColor.brightness
            let diff = abs(bgLuminance - textLuminance)

            if diff < 0.3 {
                textColor = bgLuminance > 0.5 ? .black : .white
            }
        }

        let navBarColor = Color(hex: navBarColorHex)
        let tabBarColor = Color(hex: tabBarColorHex)
        let sheetColor = Color(hex: sheetBackgroundColorHex)

        let blendMode: BlendMode = {
            switch layerBlendMode {
            case 1: return .overlay
            case 2: return .multiply
            case 3: return .screen
            default: return .normal
            }
        }()

        return ZStack {
            backgroundManager.resolvedColor
                .ignoresSafeArea()

            if animateBackground && !performanceMode {
                AnimatedBackgroundView()
                    .opacity(motionGradients ? 1.0 : 0.5)
            }

            content
                .blendMode(blendMode)
                .foregroundStyle(textColor)
                .tint(uiColor)
                .accentColor(uiColor)
                .applyFontDesign(selectedFontDesign)
                .applyToolbarBackground(navBarColor, for: .navigationBar)
                .applyToolbarBackground(tabBarColor, for: .tabBar)
                .environment(\.dividerColor, Color(hex: dividerColorHex))
                .environment(\.successColor, Color(hex: successColorHex))
                .environment(\.warningColor, Color(hex: warningColorHex))
                .environment(\.errorColor, Color(hex: errorColorHex))
                .environment(\.glowIntensity, performanceMode ? 0 : glowIntensity)
                .environment(\.borderWidth, highContrast ? max(borderWidth, 1.5) : borderWidth)
                .environment(\.cardOpacity, performanceMode ? 1.0 : cardOpacity)
                .sheetBackgroundColorModifier(sheetColor)
                .parallaxModifier(parallaxEnabled && !performanceMode)
        }
        .onAppear {
            _applyDefaultDarkThemeIfNeeded()
        }
    }

    private func _applyDefaultDarkThemeIfNeeded() {
        // Only apply Midnight theme automatically if:
        // 1. The system is in Dark Mode
        // 2. The user has not manually selected a theme yet (no stored uiElement key)
        guard colorScheme == .dark else { return }
        guard UserDefaults.standard.object(forKey: UserDefaults.Keys.uiElement) == nil else { return }

        // Apply the Midnight preset theme values
        backgroundManager.baseColor = Color(hex: "#1C1C1E")
        uiElementColorHex = "#0A84FF"
        textColorHex = "#FFFFFF"
        secondaryTextColorHex = "#8E8E93"
        fontDesign = "rounded"
    }
}

private struct DividerColorKey: EnvironmentKey {
    static let defaultValue: Color = Color(UIColor.separator)
}

private struct SuccessColorKey: EnvironmentKey {
    static let defaultValue: Color = .green
}

private struct WarningColorKey: EnvironmentKey {
    static let defaultValue: Color = .orange
}

private struct ErrorColorKey: EnvironmentKey {
    static let defaultValue: Color = .red
}

private struct GlowIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 10.0
}

private struct BorderWidthKey: EnvironmentKey {
    static let defaultValue: Double = 0.0
}

private struct CardOpacityKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var dividerColor: Color {
        get { self[DividerColorKey.self] }
        set { self[DividerColorKey.self] = newValue }
    }

    var successColor: Color {
        get { self[SuccessColorKey.self] }
        set { self[SuccessColorKey.self] = newValue }
    }

    var warningColor: Color {
        get { self[WarningColorKey.self] }
        set { self[WarningColorKey.self] = newValue }
    }

    var errorColor: Color {
        get { self[ErrorColorKey.self] }
        set { self[ErrorColorKey.self] = newValue }
    }

    var glowIntensity: Double {
        get { self[GlowIntensityKey.self] }
        set { self[GlowIntensityKey.self] = newValue }
    }

    var borderWidth: Double {
        get { self[BorderWidthKey.self] }
        set { self[BorderWidthKey.self] = newValue }
    }

    var cardOpacity: Double {
        get { self[CardOpacityKey.self] }
        set { self[CardOpacityKey.self] = newValue }
    }
}

struct ParallaxModifier: ViewModifier {
    let enabled: Bool
    @State private var offset: CGSize = .zero

    func body(content: Content) -> some View {
        if enabled {
            content
                .offset(offset)
                .onAppear {
                    // Simple tilt simulation or real CoreMotion can be added here
                    // For now, we use a basic animation to show the effect
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        offset = CGSize(width: 10, height: 10)
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func parallaxModifier(_ enabled: Bool) -> some View {
        self.modifier(ParallaxModifier(enabled: enabled))
    }

    @ViewBuilder
    func sheetBackgroundColorModifier(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }

    /// Conditionally applies the font design modifier if available (iOS 16.1+).
    @ViewBuilder
    func applyFontDesign(_ design: Font.Design) -> some View {
        if #available(iOS 16.1, *) {
            self.fontDesign(design)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyToolbarBackground(_ color: Color, for placement: ToolbarPlacement) -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarBackground(color, for: placement)
        } else {
            self
        }
    }
}
