import SwiftUI

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

extension View {
    @ViewBuilder
    func sheetBackgroundColorModifier(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
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
