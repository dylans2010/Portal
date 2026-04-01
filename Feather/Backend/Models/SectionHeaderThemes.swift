import SwiftUI

// MARK: - SectionHeaderTheme

/// Runtime color values used by section headers throughout the app.
struct SectionHeaderTheme: Equatable {
    var background: Color
    var textColor: Color
    var iconColor: Color
    var dividerColor: Color

    // MARK: Defaults

    static func `default`(for colors: AppWideColors) -> SectionHeaderTheme {
        SectionHeaderTheme(
            background: Color.clear,
            textColor: Color(hex: colors.headerText),
            iconColor: Color(hex: colors.iconTint),
            dividerColor: Color(hex: colors.separator)
        )
    }

    static func == (lhs: SectionHeaderTheme, rhs: SectionHeaderTheme) -> Bool {
        lhs.background.toHex() == rhs.background.toHex() &&
        lhs.textColor.toHex() == rhs.textColor.toHex() &&
        lhs.iconColor.toHex() == rhs.iconColor.toHex() &&
        lhs.dividerColor.toHex() == rhs.dividerColor.toHex()
    }
}

// MARK: - Codable Persistence

/// Codable mirror of `SectionHeaderTheme` that stores hex strings.
struct PersistedSectionHeaderTheme: Codable, Equatable {
    var background: String
    var textColor: String
    var iconColor: String
    var dividerColor: String
}

extension SectionHeaderTheme {
    init(persisted: PersistedSectionHeaderTheme) {
        background  = Color(hex: persisted.background)
        textColor   = Color(hex: persisted.textColor)
        iconColor   = Color(hex: persisted.iconColor)
        dividerColor = Color(hex: persisted.dividerColor)
    }

    var persistedValue: PersistedSectionHeaderTheme {
        PersistedSectionHeaderTheme(
            background:   background.toHex()   ?? "#000000",
            textColor:    textColor.toHex()    ?? "#FFFFFF",
            iconColor:    iconColor.toHex()    ?? "#FFFFFF",
            dividerColor: dividerColor.toHex() ?? "#FFFFFF"
        )
    }
}
