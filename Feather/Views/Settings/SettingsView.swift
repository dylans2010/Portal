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
    @EnvironmentObject var themeManager: AppWideThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var _isFetchingFullData = false
    @State private var _showAddSource = false
    @State private var showDeveloperConfirmation = false
    @State private var navigateToCheckForUpdates = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.devModeUnlocked") private var isDeveloperModeUnlocked = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @AppStorage("Feather.saveDataToDevice") private var saveDataToDevice = false
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
    @StateObject private var hideManager = SettingsHideManager.shared
    @Environment(\.navigateToUpdates) private var navigateToUpdates
    @State private var _searchText = ""
    
    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }
    private var shouldShowDeveloperTools: Bool { isDeveloperModeEnabled || isDeveloperModeUnlocked }
    
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                headerSection
                fetchProgressSection

                if !_searchText.isEmpty {
                    searchSuggestionsSection
                }

                generalSection
                preferencesSection
                dataSection
                saveDataSection
                resourcesSection
                if shouldShowDeveloperTools { developerSection }
            }
            .globalTheme()
            .listStyle(.insetGrouped)
            .searchable(text: $_searchText, prompt: .localized("Search Settings"))
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
        .onChange(of: greetingsName) { newValue in
            if newValue == "42" {
                ToastManager.shared.show("🌌 The meaning of life, the universe, and everything.", type: .info)
                HapticsManager.shared.success()
            }
        }
        .onChange(of: navigateToUpdates.wrappedValue) { shouldNavigate in
            if shouldNavigate {
                navigateToCheckForUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToUpdates.wrappedValue = false
                }
            }
        }
        .navigationDestination(isPresented: $navigateToCheckForUpdates) {
            CheckForUpdatesView()
                .environmentObject(themeManager)
                .environmentObject(styleManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sectionStyleDidChange)) { _ in }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        Section {
            CoreSignHeaderView(hideAboutButton: true)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    @ObservedObject private var sourcesViewModel = SourcesViewModel.shared
    @ObservedObject private var updateManager = AppUpdateTrackingManager.shared

    private var fetchProgressSection: some View {
        Group {
            if _isFetchingFullData {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 38, height: 38)

                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.accentColor)
                                    .rotationEffect(.degrees(_isFetchingFullData ? 360 : 0))
                                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: _isFetchingFullData)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Refreshing Sources")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .themedText(.primary)

                                Text(sourcesViewModel.fetchProgress < 1.0 ? "Downloading Repository Data..." : "Finalizing Updates...")
                                    .font(.system(size: 12))
                                    .themedText(.secondary)
                            }

                            Spacer()

                            Text("\(Int(sourcesViewModel.fetchProgress * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .themedText(.primary)
                        }

                        ProgressView(value: sourcesViewModel.fetchProgress)
                            .themedAccent()
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            .clipShape(Capsule())

                        HStack {
                            Label("\(sourcesViewModel.sources.count) Loaded", systemImage: "tray.full.fill")
                            Spacer()
                            if sourcesViewModel.fetchProgress < 1.0 {
                                Text("Step \(Int(sourcesViewModel.fetchProgress * Double(_sources.count))) Of \(_sources.count)")
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .themedText(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var generalSection: some View {
        Section {
            SettingsRow(icon: "gearshape.fill", title: String.localized("General"), color: .accentColor, destination: GeneralView())
            SettingsRow(icon: "bolt.circle.fill", title: String.localized("JIT Enabling"), color: .accentColor, destination: JITSettingsView())
        }
    }

    private var preferencesSection: some View {
        Section {
            if showDashboard && !hideManager.isHidden("settings.home") {
                SettingsRow(icon: "house.fill", title: String.localized("Home"), color: .accentColor, destination: HomeSettingsView())
            }
            if !hideManager.isHidden("settings.appearance") {
                SettingsRow(icon: "gear.badge", title: String.localized("Display & Interface"), color: .accentColor, destination: AppearanceView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Customizations"), icon: "slider.horizontal.3")
                .onLongPressGesture(minimumDuration: 2.0) {
                    ToastManager.shared.show("🤫 Hidden Credits: Portal was crafted with ❤️ by Dylan and the WSF Team.", type: .info)
                    HapticsManager.shared.success()
                }
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
                SettingsActionRow(icon: "binoculars.circle.fill", title: String.localized("Sources"), color: .accentColor) {
                    _showAddSource = true
                }
            }

            if !hideManager.isHidden("settings.repoBuilder") {
                SettingsRow(icon: "list.star", title: String.localized("Repository Builder"), color: .accentColor, destination: RepoBuilder())
            }

            if !hideManager.isHidden("settings.fetchData") {
                SettingsActionRow(icon: "arrow.clockwise.circle.fill", title: _isFetchingFullData ? String.localized("Fetching Source Data...") : String.localized("Fetch Full Data"), color: .accentColor, isLoading: _isFetchingFullData) {
                    Task {
                        _isFetchingFullData = true
                        BackgroundAudioManager.shared.start()
                        // Fetch both manager's data
                        await SourcesViewModel.shared.forceFetchAllSources(Array(_sources))
                        await AppUpdateTrackingManager.shared.manualFetchAllSources()
                        BackgroundAudioManager.shared.stop()
                        _isFetchingFullData = false
                        HapticsManager.shared.success()
                        NotificationManager.shared.sendDataFetchedNotification()
                    }
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("App Management"), icon: "externaldrive.fill")
        }
    }
    
    private var saveDataSection: some View {
        Section {
            Toggle(isOn: $saveDataToDevice) {
                HStack(spacing: 8) {
                    SettingsRowContent(icon: "person.text.rectangle.fill", title: String.localized("Save Data To Device"), color: themeManager.accentColor)

                    Text("Beta")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(hex: themeManager.resolvedColors.badgeText))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: themeManager.resolvedColors.badgeBackground))
                        .clipShape(Capsule())
                }
            }
            .themedAccent()
        } footer: {
            Text(.localized("Generates a unique persistent ID on your device to recover your saved data and certificates even after app reinstallation or Bundle ID changes."))
        }
    }

    private var resourcesSection: some View {
        Section {
            if !hideManager.isHidden("settings.guides") {
                SettingsRow(icon: "apple.intelligence", title: String.localized("Guides With AI"), color: themeManager.accentColor, destination: GuidesSettingsView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Resources"), icon: "books.vertical.fill")
        }
    }
    
    
    private var developerSection: some View {
        Section {
            if !hideManager.isHidden("settings.debug") {
                SettingsRow(icon: "person.2.badge.gearshape.fill", title: String.localized("Debug"), color: themeManager.destructiveColor, destination: DeveloperView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Internal"), icon: "wrench.and.screwdriver.fill")
        }
    }

    private var searchSuggestionsSection: some View {
        Section {
            ForEach(allSettingsItems.filter { item in
                item.title.localizedCaseInsensitiveContains(_searchText)
            }) { item in
                NavigationLink(destination: item.destination) {
                    SettingsRowContent(icon: item.icon, title: item.title, color: item.color)
                }
            }
        } header: {
            SettingsSectionHeader(title: .localized("Suggestions"), icon: "sparkles")
        }
    }

    private struct SettingsItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
        let destination: AnyView
    }

    private var allSettingsItems: [SettingsItem] {
        var items: [SettingsItem] = [
            // Main settings
            SettingsItem(title: .localized("General"), icon: "gearshape.fill", color: .accentColor, destination: AnyView(GeneralView())),
            SettingsItem(title: .localized("JIT Enabling"), icon: "bolt.circle.fill", color: .accentColor, destination: AnyView(JITSettingsView())),
            SettingsItem(title: .localized("Display & Interface"), icon: "gear.badge", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Files"), icon: "folder.fill", color: .accentColor, destination: AnyView(FilesSettingsView())),
            SettingsItem(title: .localized("Repository Builder"), icon: "list.star", color: .accentColor, destination: AnyView(RepoBuilder())),
            SettingsItem(title: .localized("Guides With AI"), icon: "apple.intelligence", color: .accentColor, destination: AnyView(GuidesSettingsView())),

            // Items within General
            SettingsItem(title: .localized("Notifications"), icon: "bell.badge.fill", color: .accentColor, destination: AnyView(NotificationsView())),
            SettingsItem(title: .localized("Live Activities"), icon: "widget.small.badge.plus", color: .accentColor, destination: AnyView(LiveActivitySettingsView())),
            SettingsItem(title: .localized("Certificates"), icon: "person.badge.key.fill", color: .accentColor, destination: AnyView(CertificatesView())),
            SettingsItem(title: .localized("Signing"), icon: "signature", color: .accentColor, destination: AnyView(ConfigurationView())),
            SettingsItem(title: .localized("Storage"), icon: "externaldrive.fill.badge.person.crop", color: .accentColor, destination: AnyView(ManageStorageView())),
            SettingsItem(title: .localized("Backup & Restore"), icon: "externaldrive.fill.badge.timemachine", color: .accentColor, destination: AnyView(BackupRestoreView())),
            SettingsItem(title: .localized("Logs"), icon: "ecg.text.page", color: .accentColor, destination: AnyView(AppLogsView())),
            SettingsItem(title: .localized("Credits"), icon: "person.crop.circle.fill.badge.checkmark", color: .accentColor, destination: AnyView(CreditsView())),
            SettingsItem(title: .localized("Feedback"), icon: "bubble.left.and.bubble.right.fill", color: .accentColor, destination: AnyView(FeedbackView())),
            SettingsItem(title: .localized("Check For Updates"), icon: "arrow.triangle.2.circlepath", color: .accentColor, destination: AnyView(CheckForUpdatesView())),

            // Appearance sub-options
            SettingsItem(title: .localized("Color Customization"), icon: "paintpalette.fill", color: .purple, destination: AnyView(ColorCustomizationView())),
            SettingsItem(title: .localized("All Apps"), icon: "square.grid.2x2.fill", color: .accentColor, destination: AnyView(AllAppsCustomizationView())),
            SettingsItem(title: .localized("Hide UI Elements"), icon: "eye.slash.fill", color: .accentColor, destination: AnyView(AppHideElementsView())),
            SettingsItem(title: .localized("Status Bar"), icon: "rectangle.topthird.inset.filled", color: .accentColor, destination: AnyView(StatusBarCustomizationView())),
            SettingsItem(title: .localized("Tab Bar"), icon: "dock.rectangle", color: .accentColor, destination: AnyView(TabBarCustomizationView())),
            SettingsItem(title: .localized("Gestures"), icon: "hand.tap.fill", color: .accentColor, destination: AnyView(AppearanceView())),

            // Signing sub-options
            SettingsItem(title: .localized("Installation Options"), icon: "arrow.down.app.fill", color: .accentColor, destination: AnyView(ConfigurationView())),
            SettingsItem(title: .localized("Default Frameworks"), icon: "shippingbox.fill", color: .accentColor, destination: AnyView(ConfigurationView())),

            // Reset
            SettingsItem(title: .localized("Reset"), icon: "arrow.counterclockwise.circle.fill", color: .red, destination: AnyView(ManageStorageView())),

            // Pairing
            SettingsItem(title: .localized("Pair Devices"), icon: "link.circle.fill", color: .cyan, destination: AnyView(PairingView())),

            // File Settings sub-options
            SettingsItem(title: .localized("Show Hidden Files"), icon: "eye.fill", color: .accentColor, destination: AnyView(FilesSettingsView())),
            SettingsItem(title: .localized("File Extensions"), icon: "doc.text.fill", color: .accentColor, destination: AnyView(FilesSettingsView())),

            // Notification sub-options
            SettingsItem(title: .localized("App Downloaded"), icon: "arrow.down.circle.fill", color: .accentColor, destination: AnyView(NotificationsView())),
            SettingsItem(title: .localized("Signing Failed"), icon: "exclamationmark.triangle.fill", color: .orange, destination: AnyView(NotificationsView())),
            SettingsItem(title: .localized("App Updates"), icon: "arrow.triangle.2.circlepath.circle.fill", color: .accentColor, destination: AnyView(NotificationsView())),
            SettingsItem(title: .localized("Certificate Expiry"), icon: "calendar.badge.exclamationmark", color: .orange, destination: AnyView(NotificationsView())),
            SettingsItem(title: .localized("Security Alerts"), icon: "lock.shield.fill", color: .red, destination: AnyView(NotificationsView())),

            // Appearance toggles
            SettingsItem(title: .localized("Theme"), icon: "paintbrush.fill", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Tint App Icons"), icon: "paintpalette", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Enable Haptics"), icon: "iphone.radiowaves.left.and.right", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Show News"), icon: "newspaper", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Show Header Views"), icon: "dock.rectangle", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Liquid Glass"), icon: "sparkles", color: .accentColor, destination: AnyView(AppearanceView())),
            SettingsItem(title: .localized("Personalization"), icon: "person.crop.circle.fill", color: .accentColor, destination: AnyView(AppearanceView())),

            // Storage sub-options
            SettingsItem(title: .localized("Clear Network Cache"), icon: "xmark.icloud.fill", color: .accentColor, destination: AnyView(ManageStorageView())),
            SettingsItem(title: .localized("Clear Work Cache"), icon: "trash.fill", color: .accentColor, destination: AnyView(ManageStorageView())),
            SettingsItem(title: .localized("Storage Analyzer"), icon: "chart.bar.fill", color: .accentColor, destination: AnyView(ManageStorageView())),

            // Signing toggles
            SettingsItem(title: .localized("PPQ Protection"), icon: "shield.fill", color: .accentColor, destination: AnyView(ConfigurationView())),
            SettingsItem(title: .localized("File Sharing"), icon: "doc.on.doc.fill", color: .accentColor, destination: AnyView(ConfigurationView())),
            SettingsItem(title: .localized("Pro Motion"), icon: "gauge.with.dots.needle.67percent", color: .accentColor, destination: AnyView(ConfigurationView())),
            SettingsItem(title: .localized("Game Mode"), icon: "gamecontroller.fill", color: .accentColor, destination: AnyView(ConfigurationView())),

            // Backup sub-options
            SettingsItem(title: .localized("Automatic Backups"), icon: "clock.arrow.circlepath", color: .accentColor, destination: AnyView(BackupRestoreView())),
            SettingsItem(title: .localized("Nearby Transfer"), icon: "antenna.radiowaves.left.and.right", color: .accentColor, destination: AnyView(BackupRestoreView())),
        ]

        if showDashboard {
            items.append(SettingsItem(title: .localized("Home"), icon: "house.fill", color: .accentColor, destination: AnyView(HomeSettingsView())))
        }

        if !isEnterprise {
            items.append(SettingsItem(title: .localized("App Icons"), icon: "app.badge.fill", color: .accentColor, destination: AnyView(AppIconView())))
        }

        if shouldShowDeveloperTools {
            items.append(SettingsItem(title: .localized("Debug"), icon: "person.2.badge.gearshape.fill", color: .red, destination: AnyView(DeveloperView())))
        }

        return items
    }
}
