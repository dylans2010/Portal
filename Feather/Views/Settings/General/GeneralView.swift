import SwiftUI
import NimbleViews

struct GeneralView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @StateObject private var hideManager = SettingsHideManager.shared
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @AppStorage("feature_useAnimationPairing") private var useAnimationPairing = false
    @AppStorage("Feather.cacheDataOnStart") private var cacheDataOnStart = false
    @AppStorage("Feather.cacheDataDuration") private var cacheDataDuration = CacheDataDuration.everyDay.rawValue
    @State private var navigateToCheckForUpdates = false
    @State private var showPairingView = false
    @Environment(\.navigateToUpdates) private var navigateToUpdates

    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }

    var body: some View {
        List {
            headerSection

            signingSection

            notificationsSection

            dataSection

            backgroundRefreshSection

            exportSection

            systemSection

            resourcesSection
        }
        .onChange(of: navigateToUpdates.wrappedValue) { shouldNavigate in
            if shouldNavigate {
                navigateToCheckForUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToUpdates.wrappedValue = false
                }
            }
        }
        .globalTheme()
        .listStyle(.insetGrouped)
        .navigationTitle(.localized("General"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPairingView) {
            if useAnimationPairing {
                PairingView()
            } else {
                PairingMPCView()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Group {
            if showHeaderViews {
                Section {
                    GeneralHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            if !hideManager.isHidden("settings.notifications") {
                SettingsRow(icon: "bell.badge.fill", title: String.localized("Notifications & Live Activities"), color: themeManager.accentColor, destination: NotificationsView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Notifications & Live Activities"), icon: "bell.fill")
        }
    }

    private var signingSection: some View {
        Section {
            if !hideManager.isHidden("settings.certificates") {
                SettingsRow(icon: "person.badge.key.fill", title: String.localized("Certificates"), color: themeManager.accentColor, destination: CertificatesView())
            }
            if !hideManager.isHidden("settings.signing") {
                SettingsRow(icon: "signature", title: String.localized("Signing"), color: themeManager.accentColor, destination: ConfigurationView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Signing & Services"), icon: "shield.lefthalf.filled.badge.checkmark")
        }
    }

    private var dataSection: some View {
        Section {
            if !isEnterprise && !hideManager.isHidden("settings.storage") {
                SettingsRow(icon: "externaldrive.fill.badge.person.crop", title: String.localized("Storage"), color: themeManager.accentColor, destination: ManageStorageView())
            }
            if !hideManager.isHidden("settings.backupRestore") {
                SettingsRow(icon: "externaldrive.fill.badge.timemachine", title: String.localized("Backup & Restore"), color: themeManager.accentColor, destination: SelfBackupRestoreView())
            }
            if !hideManager.isHidden("settings.pairing") {
                Button {
                    showPairingView = true
                } label: {
                    SettingsRowContent(icon: "iphone.motion", title: String.localized("Pairing"), color: themeManager.accentColor)
                }
            }
            if !hideManager.isHidden("settings.logs") {
                SettingsRow(icon: "ecg.text.page", title: String.localized("Logs"), color: themeManager.accentColor, destination: AppLogsView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Data & Maintenance"), icon: "externaldrive.fill")
        }
    }

    @State private var _isExportPickerPresenting = false
    @AppStorage("Feather.exportLocationBookmark") private var _exportLocationBookmark: Data?
    @State private var _exportLocationPath: String = ""

    private var exportSection: some View {
        Section {
            Toggle(isOn: AppStorage(wrappedValue: false, "Feather.continueDownloadInApp").projectedValue) {
                SettingsRowContent(icon: "arrow.down.circle", title: String.localized("Continue App Download In App"), color: themeManager.accentColor)
            }
            .themedAccent()
            .padding(.trailing, 16)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SettingsRowContent(icon: "square.and.arrow.up", title: String.localized("Save Exported Apps"), color: themeManager.accentColor)
                    Spacer()
                    Button(action: { _isExportPickerPresenting = true }) {
                        Text(_exportLocationPath.isEmpty ? .localized("Set Location") : .localized("Change"))
                            .font(.subheadline.bold())
                    }
                }

                if !_exportLocationPath.isEmpty {
                    Text(_exportLocationPath)
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
            }
            .padding(.trailing, 16)
        } header: {
            SettingsSectionHeader(title: String.localized("Export & Downloads"), icon: "square.and.arrow.up")
        } footer: {
            Text(.localized("Set a default location for exported .ipa files and enable background downloads within the app."))
        }
        .sheet(isPresented: $_isExportPickerPresenting) {
            FolderPickerView(onFolderPicked: { url in
                _saveBookmark(for: url)
            })
        }
        .onAppear {
            _loadBookmarkPath()
        }
    }

    private func _saveBookmark(for url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            _exportLocationBookmark = bookmarkData
            _exportLocationPath = url.path
        } catch {
            AppLogManager.shared.error("Failed to save bookmark: \(error.localizedDescription)", category: "Settings")
        }
    }

    private func _loadBookmarkPath() {
        guard let data = _exportLocationBookmark else { return }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                _saveBookmark(for: url)
            }
            _exportLocationPath = url.path
        } catch {
            _exportLocationPath = ""
        }
    }

    private var backgroundRefreshSection: some View {
        Section {
            Toggle(isOn: AppStorage(wrappedValue: false, "Feather.useBackgroundRefresh").projectedValue) {
                SettingsRowContent(icon: "arrow.triangle.2.circlepath", title: String.localized("Use Background Refresh"), color: themeManager.accentColor)
            }
            .themedAccent()
            .padding(.trailing, 16)
            .onChange(of: UserDefaults.standard.bool(forKey: "Feather.useBackgroundRefresh")) { newValue in
                if newValue {
                    BackgroundRefreshManager.shared.scheduleBackgroundRefresh()
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SettingsRowContent(icon: "wifi", title: String.localized("Connection Preference"), color: themeManager.accentColor)

                Picker(selection: AppStorage(wrappedValue: 0, "Feather.backgroundRefreshConnection").projectedValue) {
                    Label(.localized("Both"), systemImage: "arrow.up.left.and.arrow.down.right").tag(0)
                    Label(.localized("WiFi"), systemImage: "wifi").tag(1)
                    Label(.localized("Cellular"), systemImage: "antenna.radiowaves.left.and.right").tag(2)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
            }
            .padding(.trailing, 16)

            Button {
                if let url = URL(string: "App-Prefs:root=General&path=Background_App_Refresh") {
                    UIApplication.shared.open(url)
                }
            } label: {
                SettingsRowContent(icon: "gearshape.fill", title: String.localized("Open Background Refresh Settings"), color: themeManager.accentColor)
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Background Refresh"), icon: "arrow.clockwise")
        } footer: {
            Text(.localized("Automatically refreshes sources and checks for updates in the background. Respects your connection preference."))
        }
    }

    private var systemSection: some View {
        Section {
            SettingsRow(icon: "link", title: String.localized("URL Schemes"), color: themeManager.accentColor, destination: URLSchemeView())
            if !hideManager.isHidden("settings.language") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    SettingsRowContent(icon: "translate", title: String.localized("Language"), color: themeManager.accentColor)
                }
            }
            if !isEnterprise && !hideManager.isHidden("settings.updates") {
                Button {
                    navigateToCheckForUpdates = true
                } label: {
                    SettingsRowContent(icon: "arrow.triangle.2.circlepath", title: String.localized("Check For Updates"), color: themeManager.accentColor)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 2.0)
                        .onEnded { _ in
                            ToastManager.shared.show("🚀 Turbo Updates Enabled! (Just kidding)", type: .info)
                            HapticsManager.shared.success()
                        }
                )

                Toggle(isOn: AppStorage(wrappedValue: true, "Feather.autoCheckUpdates").projectedValue) {
                    SettingsRowContent(icon: "bolt.badge.clock.fill", title: String.localized("Check for Updates on Launch"), color: themeManager.accentColor)
                }
                .themedAccent()
                .padding(.trailing, 16)
                .navigationDestination(isPresented: $navigateToCheckForUpdates) {
                    CheckForUpdatesView()
                }
            }

            Toggle(isOn: $cacheDataOnStart) {
                SettingsRowContent(icon: "externaldrive.badge.timemachine", title: "Cache Data On Start", color: themeManager.accentColor)
            }
            .themedAccent()
            .padding(.trailing, 16)

            Picker(selection: $cacheDataDuration) {
                Text("Every Hour").tag(CacheDataDuration.everyHour.rawValue)
                Text("Every 6 Hours").tag(CacheDataDuration.every6Hours.rawValue)
                Text("Every Day").tag(CacheDataDuration.everyDay.rawValue)
                Text("Every Week").tag(CacheDataDuration.everyWeek.rawValue)
            } label: {
                SettingsRowContent(icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", title: "Cache Duration", color: themeManager.accentColor)
            }
        } header: {
            SettingsSectionHeader(title: String.localized("System"), icon: "iphone")
        }
    }

    private var resourcesSection: some View {
        Section {
            SettingsRow(icon: "square.stack.3d.up", title: String.localized("Shortcuts Guide"), color: themeManager.accentColor, destination: PortalShortcutsGuideView())
            if !hideManager.isHidden("settings.credits") {
                SettingsRow(icon: "person.crop.circle.fill.badge.checkmark", title: String.localized("Credits"), color: themeManager.accentColor, destination: CreditsView())
            }
            if !hideManager.isHidden("settings.feedback") {
                SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: String.localized("Feedback"), color: themeManager.accentColor, destination: FeedbackView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Resources"), icon: "books.vertical.fill")
        }
    }
}

#Preview {
    GeneralView()
}
