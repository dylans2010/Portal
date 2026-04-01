import SwiftUI

// MARK: - Section Header Theme

struct SectionHeaderTheme: Hashable, Equatable {
    var background: Color
    var textColor: Color
    var iconColor: Color
    var dividerColor: Color

    static func `default`(for colors: AppWideColors) -> SectionHeaderTheme {
        SectionHeaderTheme(
            background: .clear,
            textColor: Color(hex: colors.headerText),
            iconColor: Color(hex: colors.iconTint),
            dividerColor: Color(hex: colors.separator)
        )
    }
}

// MARK: - Persistence

struct PersistedSectionHeaderTheme: Codable, Equatable {
    var background: String
    var textColor: String
    var iconColor: String
    var dividerColor: String
}

// MARK: - Conversion Extensions

extension SectionHeaderTheme {
    init(persisted: PersistedSectionHeaderTheme) {
        self.background = Color(hex: persisted.background)
        self.textColor = Color(hex: persisted.textColor)
        self.iconColor = Color(hex: persisted.iconColor)
        self.dividerColor = Color(hex: persisted.dividerColor)
    }

    var persisted: PersistedSectionHeaderTheme {
        PersistedSectionHeaderTheme(
            background: background.toHex() ?? "00000000",
            textColor: textColor.toHex() ?? "#FFFFFF",
            iconColor: iconColor.toHex() ?? "#FFFFFF",
            dividerColor: dividerColor.toHex() ?? "#FFFFFF"
        )
    }
}
