import SwiftUI

struct EntitlementsSplashView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) var dismiss
    @AppStorage("Feather.showEntitlementsSplash") private var showSplash = true

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(themeManager.accentColor)
                }

                Text("Entitlements Guide")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Understand and manage app permissions")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.secondaryTextColor)
            }

            // Steps
            VStack(alignment: .leading, spacing: 24) {
                SplashStepRow(
                    icon: "key.fill",
                    color: .blue,
                    title: "What are Entitlements?",
                    description: "Entitlements are key-value pairs that grant an app specific capabilities, like iCloud access or Push Notifications."
                )

                SplashStepRow(
                    icon: "link",
                    color: .green,
                    title: "Certificate Harmony",
                    description: "Your signing certificate must support the entitlements you select for the app to function correctly."
                )

                SplashStepRow(
                    icon: "doc.text.fill",
                    color: .purple,
                    title: "Customization",
                    description: "You can load existing .entitlements files or create your own with our built-in editor."
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Actions
            VStack(spacing: 16) {
                Button {
                    showSplash = false
                    dismiss()
                } label: {
                    Text("Continue")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentColor)
                        .foregroundStyle(themeManager.buttonTextColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    showSplash = false
                    dismiss()
                } label: {
                    Text("Don’t show again")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(themeManager.appBackgroundColor)
    }
}

struct SplashStepRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
