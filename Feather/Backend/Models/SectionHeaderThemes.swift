import SwiftUI

struct SectionHeaderTheme {
    var background: Color
    var textColor: Color
    var iconColor: Color
    var dividerColor: Color
}

struct PersistedSectionHeaderTheme: Codable, Equatable {
    var background: String
    var textColor: String
    var iconColor: String
    var dividerColor: String
}

extension SectionHeaderTheme {
    init(persisted: PersistedSectionHeaderTheme) {
        self.background = Color(hex: persisted.background)
        self.textColor = Color(hex: persisted.textColor)
        self.iconColor = Color(hex: persisted.iconColor)
        self.dividerColor = Color(hex: persisted.dividerColor)
    }

    var persistedValue: PersistedSectionHeaderTheme {
        PersistedSectionHeaderTheme(
            background: background.toHex() ?? "#000000",
            textColor: textColor.toHex() ?? "#FFFFFF",
            iconColor: iconColor.toHex() ?? "#FFFFFF",
            dividerColor: dividerColor.toHex() ?? "#FFFFFF"
        )
    }

    static func `default`(for colors: AppWideColors) -> SectionHeaderTheme {
        SectionHeaderTheme(
            background: Color.clear,
            textColor: Color(hex: colors.headerText),
            iconColor: Color(hex: colors.accent),
            dividerColor: Color(hex: colors.separator)
        )
    }

    func resolvedTextColor(style: SectionStyle, defaultColor: Color) -> Color {
        style == .colorMatch ? textColor : defaultColor
    }

    func resolvedIconColor(style: SectionStyle, defaultColor: Color) -> Color {
        style == .colorMatch ? iconColor : defaultColor
    }

    func resolvedBackgroundColor(style: SectionStyle) -> Color {
        style == .colorMatch ? background : .clear
    }

    func resolvedDividerColor(style: SectionStyle, defaultColor: Color) -> Color {
        style == .colorMatch ? dividerColor : defaultColor
    }
}
