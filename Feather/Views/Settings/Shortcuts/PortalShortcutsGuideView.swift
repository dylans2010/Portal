import SwiftUI
import NimbleViews

struct PortalShortcutsGuideView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewCard
                howToCreateCard
                recommendedShortcutsCard
                availableActionsCard
                automationIdeasCard
            }
            .padding()
        }
        .background(Color.clear)
        .navigationTitle(String.localized("Shortcuts Guide"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "square.stack.3d.up")
                        .font(.title3)
                        .foregroundStyle(themeManager.buttonTextColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shortcuts Integration")
                        .font(.headline)
                    Text("Automate Portal with the Shortcuts app")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
                Spacer()
            }

            Text("Portal supports full automation through the Apple Shortcuts app. You can install apps, refresh sources, update apps, manage downloads, and navigate Portal entirely through automated shortcuts and Siri commands — no manual interaction required.")
                .font(.subheadline)
                .foregroundStyle(themeManager.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                FeaturePill(icon: "square.and.arrow.down", text: "Install Apps")
                FeaturePill(icon: "arrow.clockwise", text: "Refresh Sources")
                FeaturePill(icon: "arrow.triangle.2.circlepath", text: "Update Apps")
            }
            HStack(spacing: 8) {
                FeaturePill(icon: "arrow.down.circle", text: "Downloads")
                FeaturePill(icon: "map", text: "Navigate")
            }
        }
        .padding(20)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - How to Create Card

    private var howToCreateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundStyle(themeManager.accentColor)
                Text("How to Create a Shortcut")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                PortalShortcutStepRow(
                    number: "1",
                    title: "Open the Shortcuts App",
                    description: "Find the Shortcuts app on your Home Screen or in the App Library."
                )
                PortalShortcutStepRow(
                    number: "2",
                    title: "Create a New Shortcut",
                    description: "Tap the '+' button in the top-right corner to start a new shortcut."
                )
                PortalShortcutStepRow(
                    number: "3",
                    title: "Search for Portal Actions",
                    description: "Tap 'Add Action', then search for 'Portal' to see all available actions."
                )
                PortalShortcutStepRow(
                    number: "4",
                    title: "Add a Portal Action",
                    description: "Select the action you want, such as 'Install Portal App' or 'Refresh Portal Sources'."
                )
                PortalShortcutStepRow(
                    number: "5",
                    title: "Configure Parameters",
                    description: "Fill in any required fields, like an App ID or Source URL, to configure the action."
                )
                PortalShortcutStepRow(
                    number: "6",
                    title: "Run or Automate",
                    description: "Tap the play button to test your shortcut, or add it to an automation to run automatically."
                )
            }
        }
        .padding(20)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Recommended Shortcuts Card

    private var recommendedShortcutsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(themeManager.accentColor)
                Text("Recommended Shortcuts")
                    .font(.headline)
            }

            VStack(spacing: 10) {
                RecommendedShortcutRow(
                    icon: "moon.stars.fill",
                    iconColor: .indigo,
                    title: "Nightly App Updates",
                    description: "Run 'Update All Portal Apps' automatically every night to keep apps current."
                )
                RecommendedShortcutRow(
                    icon: "sunrise.fill",
                    iconColor: .orange,
                    title: "Morning Source Refresh",
                    description: "Schedule 'Refresh Portal Sources' each morning to load the latest app listings."
                )
                RecommendedShortcutRow(
                    icon: "square.and.arrow.down.fill",
                    iconColor: .blue,
                    title: "Quick App Install",
                    description: "Create a shortcut with 'Install Portal App' for one-tap installation of your favourite apps."
                )
                RecommendedShortcutRow(
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    title: "Update Notification",
                    description: "Use 'Check Portal Updates' followed by a notification action to get daily update alerts."
                )
                RecommendedShortcutRow(
                    icon: "arrow.down.circle.fill",
                    iconColor: .green,
                    title: "Download Without Installing",
                    description: "Use 'Download Portal App' to save an IPA to your library without immediately installing."
                )
            }
        }
        .padding(20)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Available Actions Card

    private var availableActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(themeManager.accentColor)
                Text("Available Portal Actions")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                ForEach(PortalIntentCategory.allCases, id: \.rawValue) { category in
                    CategorySection(category: category)
                }
            }
        }
        .padding(20)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Automation Ideas Card

    private var automationIdeasCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundStyle(themeManager.accentColor)
                Text("Automation Ideas")
                    .font(.headline)
            }

            VStack(spacing: 10) {
                AutomationIdeaRow(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: "Scheduled Update Checks",
                    description: "Set a daily automation at 9 AM using 'Check Portal Updates' to get a summary of what needs updating."
                )
                AutomationIdeaRow(
                    icon: "wave.3.right.circle",
                    iconColor: .cyan,
                    title: "NFC-Triggered Installs",
                    description: "Write a portal:// URL to an NFC tag and trigger 'Install Portal App' by tapping your phone to it."
                )
                AutomationIdeaRow(
                    icon: "app.badge",
                    iconColor: .red,
                    title: "Install When Opening Another App",
                    description: "Use the 'When App Opens' trigger in Automations to run a Portal install action when you open a specific app."
                )
                AutomationIdeaRow(
                    icon: "link.circle",
                    iconColor: .green,
                    title: "Install from Shared Links",
                    description: "Add 'Install Portal App from URL' to your share sheet to install IPA files directly from Safari or Files."
                )
                AutomationIdeaRow(
                    icon: "clock.badge.checkmark",
                    iconColor: .orange,
                    title: "Weekly Source Cleanup",
                    description: "Schedule 'Refresh Portal Sources' and 'Clear Portal Cache' weekly to keep Portal running smoothly."
                )
                AutomationIdeaRow(
                    icon: "iphone.badge.play",
                    iconColor: .purple,
                    title: "Focus Mode App Setup",
                    description: "Automatically install work or gaming app bundles when switching Focus modes using 'Bulk Install Portal Apps'."
                )
            }
        }
        .padding(20)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views

private struct FeaturePill: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.accentColor.opacity(0.12))
        .foregroundStyle(themeManager.accentColor)
        .clipShape(Capsule())
    }
}

private struct PortalShortcutStepRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.buttonTextColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

private struct RecommendedShortcutRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

private struct CategorySection: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let category: PortalIntentCategory
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .font(.subheadline)
                        .foregroundStyle(themeManager.accentColor)
                        .frame(width: 20)
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.primaryTextColor)
                    Spacer()
                    Text("\(category.intents.count)")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(themeManager.secondaryTextColor.opacity(0.15))
                        .clipShape(Capsule())
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(12)
                .background(themeManager.primaryTextColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(category.intents, id: \.self) { intentName in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(themeManager.accentColor)
                            Text(intentName)
                                .font(.caption)
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
        }
    }
}

private struct AutomationIdeaRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PortalShortcutsGuideView()
    }
    .environmentObject(AppWideThemeManager.shared)
}
