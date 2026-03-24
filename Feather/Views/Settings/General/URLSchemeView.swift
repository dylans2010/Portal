import SwiftUI

struct URLSchemeView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    var body: some View {
        List {
            schemeSection(
                title: String.localized("Core Actions"),
                icon: "bolt.fill",
                schemes: URLSchemeHandlerManager.coreActions
            )

            schemeSection(
                title: String.localized("Source Management"),
                icon: "globe.desk.fill",
                schemes: URLSchemeHandlerManager.sourceManagement
            )

            schemeSection(
                title: String.localized("App Management"),
                icon: "app.badge.fill",
                schemes: URLSchemeHandlerManager.appManagement
            )

            schemeSection(
                title: String.localized("Navigation"),
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                schemes: URLSchemeHandlerManager.navigation
            )

            schemeSection(
                title: String.localized("Advanced Utilities"),
                icon: "wrench.and.screwdriver.fill",
                schemes: URLSchemeHandlerManager.advancedUtilities
            )

            schemeSection(
                title: String.localized("Bulk Source Import"),
                icon: "square.stack.3d.up.fill",
                schemes: URLSchemeHandlerManager.bulkSourceImport
            )

            schemeSection(
                title: String.localized("External Integration"),
                icon: "square.and.arrow.up.fill",
                schemes: URLSchemeHandlerManager.externalIntegration
            )
        }
        .listStyle(.insetGrouped)
        .navigationTitle(.localized("URL Schemes"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section Builder

    private func schemeSection(title: String, icon: String, schemes: [URLSchemeHandlerManager.SchemeInfo]) -> some View {
        Section {
            ForEach(schemes) { info in
                VStack(alignment: .leading, spacing: 6) {
                    Text(info.scheme)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)

                    Text(info.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(info.example)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
        } header: {
            SettingsSectionHeader(title: title, icon: icon)
        }
    }
}

#Preview {
    NavigationView {
        URLSchemeView()
    }
}
