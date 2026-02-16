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
    @State private var _isFetchingFullData = false
    @State private var _showAddSource = false
    @State private var showDeveloperConfirmation = false
    @State private var navigateToCheckForUpdates = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @StateObject private var hideManager = SettingsHideManager.shared
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
        .fullScreenCover(isPresented: $_showAddSource) {
            SourcesAddView()
        }
        .alert(String.localized("Enable Developer Mode"), isPresented: $showDeveloperConfirmation) {
            Button(String.localized("Cancel"), role: .cancel) { developerTapCount = 0 }
            Button(String.localized("Enable")) {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
            }
        } message: {
            Text(String.localized("Developer Mode provides advanced debugging tools for app developers. This is NOT recommended for regular users as it may cause instability and crashes. Use at your own risk."))
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
            if !hideManager.isHidden("settings.home") {
                SettingsRow(icon: "house.fill", title: String.localized("Home"), color: .accentColor, destination: HomeSettingsView())
            }
            if !hideManager.isHidden("settings.appearance") {
                SettingsRow(icon: "paintbrush.fill", title: String.localized("Appearance"), color: .accentColor, destination: AppearanceView())
            }
            if !hideManager.isHidden("settings.liveActivities") {
                SettingsRow(icon: "widget.small.badge.plus", title: String.localized("Live Activities"), color: .accentColor, destination: LiveActivitySettingsView())
            }

            if !hideManager.isHidden("settings.language") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    SettingsRowContent(icon: "translate", title: String.localized("Language"), color: .accentColor)
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Customizations"), icon: "slider.horizontal.3")
        }
    }
    
    private var signingSection: some View {
        Section {
            if !hideManager.isHidden("settings.certificates") {
                SettingsRow(icon: "person.badge.key.fill", title: String.localized("Certificates"), color: .accentColor, destination: CertificatesView())
            }
            if !hideManager.isHidden("settings.signing") {
                SettingsRow(icon: "signature", title: String.localized("Signing"), color: .accentColor, destination: ConfigurationView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Signing"), icon: "shield.lefthalf.filled.badge.checkmark")
        }
    }
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var _sources: FetchedResults<AltSource>

    private var dataSection: some View {
        Section {
            if !hideManager.isHidden("settings.files") {
                SettingsRow(icon: "folder.fill", title: String.localized("Files"), color: .accentColor, destination: FilesSettingsView())
            }
            if !hideManager.isHidden("settings.addSource") {
                SettingsActionRow(icon: "plus.circle.fill", title: String.localized("Add Sources"), color: .accentColor) {
                    _showAddSource = true
                }
            }
            if !isEnterprise && !hideManager.isHidden("settings.storage") {
                SettingsRow(icon: "externaldrive.fill.badge.person.crop", title: String.localized("Storage"), color: .accentColor, destination: ManageStorageView())
            }
            if !hideManager.isHidden("settings.backupRestore") {
                SettingsRow(icon: "externaldrive.fill.badge.timemachine", title: String.localized("Backup & Restore"), color: .accentColor, destination: BackupRestoreView())
            }
            if !hideManager.isHidden("settings.logs") {
                SettingsRow(icon: "terminal.fill", title: String.localized("Logs"), color: .accentColor, destination: AppLogsView())
            }

            if !hideManager.isHidden("settings.fetchData") {
                SettingsActionRow(icon: "arrow.clockwise.circle.fill", title: _isFetchingFullData ? String.localized("Fetching Source Data...") : String.localized("Fetch Full Data"), color: Color("AccentColor"), isLoading: _isFetchingFullData) {
                    Task {
                        _isFetchingFullData = true
                        // Fetch both manager's data
                        await SourcesViewModel.shared.forceFetchAllSources(Array(_sources))
                        await AppUpdateTrackingManager.shared.manualFetchAllSources()
                        _isFetchingFullData = false
                        HapticsManager.shared.success()
                    }
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("App Management"), icon: "externaldrive.fill")
        }
    }
    
    private var resourcesSection: some View {
        Section {
            if !hideManager.isHidden("settings.guides") {
                SettingsRow(icon: "apple.intelligence", title: String.localized("Guides With AI"), color: .accentColor, destination: GuidesSettingsView())
            }
            if !hideManager.isHidden("settings.credits") {
                SettingsRow(icon: "person.crop.circle.fill.badge.checkmark", title: String.localized("Credits"), color: .accentColor, destination: CreditsView())
            }
            if !hideManager.isHidden("settings.feedback") {
                SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: String.localized("Feedback"), color: .accentColor, destination: FeedbackView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Resources"), icon: "books.vertical.fill")
        }
    }
    
    private var appSection: some View {
        Section {
            if !hideManager.isHidden("settings.appIcons") {
                SettingsRow(icon: "app.badge.fill", title: String.localized("App Icons"), color: .accentColor, destination: AppIconView())
            }
            if !hideManager.isHidden("settings.updates") {
                Button {
                    navigateToCheckForUpdates = true
                } label: {
                    SettingsRowContent(icon: "arrow.triangle.2.circlepath", title: String.localized("Check For Updates"), color: .accentColor)
                }
                .navigationDestination(isPresented: $navigateToCheckForUpdates) {
                    CheckForUpdatesView()
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("App"), icon: "app.fill")
        }
    }
    
    private var developerSection: some View {
        Section {
            if !hideManager.isHidden("settings.debug") {
                SettingsRow(icon: "person.2.badge.gearshape.fill", title: String.localized("Debug"), color: .red, destination: DeveloperView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Internal"), icon: "wrench.and.screwdriver.fill")
        }
    }

    // MARK: - Developer Mode
    
    private func handleDeveloperModeTap() {
        let now = Date()
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 3.0 {
            developerTapCount = 0
        }
        lastTapTime = now
        developerTapCount += 1
        if developerTapCount >= 7 && developerTapCount < 15 {
            HapticsManager.shared.softImpact()
        }
        if developerTapCount >= 15 {
            showDeveloperConfirmation = true
        }
    }
}

// MARK: - Settings Row Components

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                SettingsRowContent(icon: icon, title: title, color: color)
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(isLoading)
    }
}

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
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.secondary)
    }
}
