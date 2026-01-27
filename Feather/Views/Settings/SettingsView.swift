import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - Certificate Experience Type
enum CertificateExperience: String, CaseIterable {
    case developer = "Developer"
    case enterprise = "Enterprise"
    
    var displayName: String { rawValue }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var showDeveloperConfirmation = false
    @State private var navigateToCheckForUpdates = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @Environment(\.navigateToUpdates) private var navigateToUpdates
    
    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }
    
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                headerSection
                preferencesSection
                signingSection
                dataSection
                resourcesSection
                if !isEnterprise { appSection }
                if isDeveloperModeEnabled { developerSection }
            }
            .listStyle(.insetGrouped)
        }
        .alert("Enable Developer Mode", isPresented: $showDeveloperConfirmation) {
            Button("Cancel", role: .cancel) { developerTapCount = 0 }
            Button("Enable") {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
            }
        } message: {
            Text("Developer mode provides advanced tools for developers. This can make the app crash and is NOT intended for regular users.")
        }
        .onChange(of: navigateToUpdates.wrappedValue) { shouldNavigate in
            if shouldNavigate {
                navigateToCheckForUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToUpdates.wrappedValue = false
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        Section {
            CoreSignHeaderView(hideAboutButton: true)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .onTapGesture { handleDeveloperModeTap() }
        }
    }
    
    private var preferencesSection: some View {
        Section {
            SettingsRow(icon: "house.fill", title: "Customize Home", color: .blue, destination: HomeSettingsView())
            SettingsRow(icon: "paintbrush.fill", title: "Appearance", color: .pink, destination: AppearanceView())
        } header: {
            SettingsSectionHeader(title: "Preferences", icon: "slider.horizontal.3")
        }
    }
    
    private var signingSection: some View {
        Section {
            SettingsRow(icon: "checkmark.seal.fill", title: "Certificates", color: .green, destination: CertificatesView())
            SettingsRow(icon: "signature", title: "Signing Options", color: .orange, destination: ConfigurationView())
        } header: {
            SettingsSectionHeader(title: "Signing", icon: "lock.shield.fill")
        }
    }
    
    private var dataSection: some View {
        Section {
            SettingsRow(icon: "folder.fill", title: "Files", color: .blue, destination: FilesSettingsView())
            if !isEnterprise {
                SettingsRow(icon: "internaldrive.fill", title: "Storage", color: .gray, destination: ManageStorageView())
            }
        } header: {
            SettingsSectionHeader(title: "Data & Storage", icon: "externaldrive.fill")
        }
    }
    
    private var resourcesSection: some View {
        Section {
            SettingsRow(icon: "book.fill", title: "Guides & AI", color: .orange, destination: GuidesSettingsView())
            SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Feedback", color: .purple, destination: FeedbackView())
        } header: {
            SettingsSectionHeader(title: "Resources", icon: "books.vertical.fill")
        }
    }
    
    private var appSection: some View {
        Section {
            SettingsRow(icon: "app.badge.fill", title: "App Icons", color: .pink, destination: AppIconView())
            NavigationLink(destination: CheckForUpdatesView(), isActive: $navigateToCheckForUpdates) {
                SettingsRowContent(icon: "arrow.triangle.2.circlepath", title: "Updates", color: .green)
            }
        } header: {
            SettingsSectionHeader(title: "App", icon: "app.fill")
        }
    }
    
    private var developerSection: some View {
        Section {
            SettingsRow(icon: "hammer.fill", title: "Developer Tools", color: .yellow, destination: DeveloperView())
        } header: {
            SettingsSectionHeader(title: "Developer", icon: "wrench.and.screwdriver.fill")
        }
    }
    
    // MARK: - Developer Mode
    
    private func handleDeveloperModeTap() {
        let now = Date()
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 5.0 {
            developerTapCount = 0
        }
        lastTapTime = now
        developerTapCount += 1
        if developerTapCount >= 5 && developerTapCount < 10 {
            HapticsManager.shared.softImpact()
        }
        if developerTapCount >= 10 {
            showDeveloperConfirmation = true
        }
    }
}

// MARK: - Settings Row Components

private struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            SettingsRowContent(icon: icon, title: title, color: color)
        }
    }
}

private struct SettingsRowContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

private struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.secondary)
    }
}
