import SwiftUI

struct ThemedSectionHeader: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    var title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.sectionHeaderTheme.iconColor)
            }

            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(themeManager.sectionHeaderTheme.textColor)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
