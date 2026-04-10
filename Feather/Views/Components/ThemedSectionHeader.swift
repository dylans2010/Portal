import SwiftUI

struct ThemedSectionHeader: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    var title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.sectionHeaderTheme.resolvedIconColor(style: styleManager.currentStyle, defaultColor: themeManager.accentColor))
            }

            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(themeManager.sectionHeaderTheme.resolvedTextColor(style: styleManager.currentStyle, defaultColor: themeManager.headerTextColor))
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
