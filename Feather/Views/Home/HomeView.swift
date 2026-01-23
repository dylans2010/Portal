import SwiftUI
import CoreData
import NimbleViews

// MARK: - HomeView - Dashboard with Quick Actions, Status, and At A Glance
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.greetingsName") private var _greetingsName: String = ""
    @AppStorage("Feather.homeGreetingEnabled") private var _greetingEnabled = true
    @AppStorage("Feather.homeAnimationsEnabled") private var _animationsEnabled = true
    @AppStorage("Feather.homeCompactMode") private var _compactMode = false
    @AppStorage("Feather.homeShowAppIcon") private var _showAppIcon = true
    @AppStorage("Feather.useProfilePicture") private var _useProfilePicture = false
    @AppStorage("Feather.showAppUpdateBanner") private var _showAppUpdateBanner = true
    @AppStorage("Feather.devShowSimulatedUpdateBanner") private var _devShowSimulatedUpdateBanner = false
    
    @StateObject private var _settingsManager = HomeSettingsManager.shared
    @StateObject private var _networkMonitor = NetworkMonitor.shared
    @StateObject private var _profileManager = ProfilePictureManager.shared
    @StateObject private var _updateTrackingManager = AppUpdateTrackingManager.shared
    
    // Fetch requests for data
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var _certificates: FetchedResults<CertificatePair>
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var _sources: FetchedResults<AltSource>
    
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
    ) private var _importedApps: FetchedResults<Imported>
    
    @StateObject var viewModel = SourcesViewModel.shared
    
    // Sheet states
    @State private var _showAddCertificate = false
    @State private var _showAddSource = false
    @State private var _showSignApp = false
    @State private var _showImportApp = false
    @State private var _showSignAndInstallPicker = false
    @State private var _selectedAppForSigning: Imported? = nil
    @State private var _navigateToSigning = false
    @State private var _appearAnimation = false
    @State private var _currentTipIndex = 0
    @State private var _showAppUpdatesSheet = false
    @State private var _selectedUpdateForSigning: AppUpdateInfo? = nil
    
    // Tips for the Tips widget
    private let _tips = [
        "Tip: You can long-press on apps in the Library to access quick actions.",
        "Tip: Use developer certificates for better stability than enterprise certificates.",
        "Tip: Swipe down on the Sources tab to refresh all repositories.",
        "Tip: You can customize which widgets appear on this Home screen in Settings.",
        "Tip: Pin your favorite sources to keep them at the top of the list.",
        "Tip: Check certificate expiration dates regularly to avoid signing issues.",
        "Tip: Use the Files tab to manage your IPA files and tweaks.",
        "Tip: You can import apps by opening IPA files directly in Portal."
    ]
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        if hour >= 5 && hour < 12 {
            greeting = String.localized("Good Morning")
        } else if hour >= 12 && hour < 17 {
            greeting = String.localized("Good Afternoon")
        } else {
            greeting = String.localized("Good Night")
        }
        
        if _greetingsName.isEmpty {
            return greeting
        } else {
            return "\(greeting), \(_greetingsName)!"
        }
    }
    
    private var portalVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // App Update Banner
                    appUpdateBannerSection
                    
                    // Header (smaller in compact mode)
                    if _greetingEnabled {
                        headerSection
                    }
                    
                    VStack(spacing: _compactMode ? 8 : 24) {
                        // Dynamic widgets based on settings
                        ForEach(_settingsManager.enabledWidgets) { widget in
                            widgetView(for: widget.type)
                        }
                    }
                    .padding(.horizontal, _compactMode ? 16 : 20)
                    .padding(.top, _greetingEnabled ? 0 : (_compactMode ? 12 : 20))
                    .padding(.bottom, _compactMode ? 80 : 100)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $_showAddCertificate) {
                CertificatesAddView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $_showAddSource) {
                SourcesAddView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $_showImportApp) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.ipa, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        for url in urls {
                            let id = "FeatherManualDownload_\(UUID().uuidString)"
                            let dl = DownloadManager.shared.startArchive(from: url, id: id)
                            try? DownloadManager.shared.handlePachageFile(url: url, dl: dl)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_showSignAndInstallPicker) {
                SignAndInstallPickerView { importedApp in
                    _selectedAppForSigning = importedApp
                    _showSignAndInstallPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        _navigateToSigning = true
                    }
                }
            }
            .sheet(isPresented: $_showAppUpdatesSheet) {
                AppUpdatesListSheet(
                    updates: _updateTrackingManager.availableUpdates,
                    onSignApp: { update in
                        _selectedUpdateForSigning = update
                        _showAppUpdatesSheet = false
                        handleSignAppFromUpdate(update)
                    },
                    onDismissUpdate: { update in
                        _updateTrackingManager.dismissUpdate(for: update.bundleIdentifier, version: update.newVersion)
                    }
                )
            }
            .navigationDestination(isPresented: $_navigateToSigning) {
                if let app = _selectedAppForSigning {
                    ModernSigningView(app: app)
                }
            }
        }
        .onAppear {
            if _animationsEnabled {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    _appearAnimation = true
                }
            } else {
                _appearAnimation = true
            }
            // Rotate tip
            _currentTipIndex = Int.random(in: 0..<_tips.count)
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
            // Check for app updates after sources are loaded
            await _updateTrackingManager.checkForUpdates(sources: viewModel.sources)
        }
    }
    
    // MARK: - App Update Banner Section
    @ViewBuilder
    private var appUpdateBannerSection: some View {
        if _showAppUpdateBanner {
            // Show simulated banner for developer mode
            if _devShowSimulatedUpdateBanner {
                let simulatedUpdate = AppUpdateTrackingManager.createSimulatedUpdate()
                AppUpdateBannerView(
                    update: simulatedUpdate,
                    onDismiss: { },
                    onSignApp: { }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _devShowSimulatedUpdateBanner)
            }
            // Show real updates
            else if !_updateTrackingManager.availableUpdates.isEmpty {
                if _updateTrackingManager.availableUpdates.count == 1,
                   let update = _updateTrackingManager.availableUpdates.first {
                    AppUpdateBannerView(
                        update: update,
                        onDismiss: {
                            _updateTrackingManager.dismissUpdate(for: update.bundleIdentifier, version: update.newVersion)
                        },
                        onSignApp: {
                            handleSignAppFromUpdate(update)
                        }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _updateTrackingManager.availableUpdates.count)
                } else {
                    MultipleAppUpdatesBannerView(
                        updates: _updateTrackingManager.availableUpdates,
                        onDismiss: {
                            // Dismiss all updates
                            for update in _updateTrackingManager.availableUpdates {
                                _updateTrackingManager.dismissUpdate(for: update.bundleIdentifier, version: update.newVersion)
                            }
                        },
                        onViewAll: {
                            _showAppUpdatesSheet = true
                        }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _updateTrackingManager.availableUpdates.count)
                }
            }
        }
    }
    
    // MARK: - Handle Sign App From Update
    private func handleSignAppFromUpdate(_ update: AppUpdateInfo) {
        guard let downloadURLString = update.downloadURL,
              let downloadURL = URL(string: downloadURLString) else { return }
        
        // Start downloading the app
        let downloadId = "FeatherAppUpdate_\(UUID().uuidString)"
        _ = DownloadManager.shared.startDownload(from: downloadURL, id: downloadId)
        
        // Update the last known version
        _updateTrackingManager.updateLastKnownVersion(bundleIdentifier: update.bundleIdentifier, version: update.newVersion)
        
        HapticsManager.shared.impact()
    }
    
    // MARK: - Widget View Builder
    @ViewBuilder
    private func widgetView(for type: HomeWidgetType) -> some View {
        let size = _settingsManager.getWidgetSize(type)
        switch type {
        case .quickActions:
            quickActionsSection(size: size)
        case .status:
            statusSection(size: size)
        case .atAGlance:
            atAGlanceSection(size: size)
        case .recentApps:
            recentAppsSection(size: size)
        case .storageInfo:
            storageInfoSection(size: size)
        case .certificateStatus:
            certificateStatusSection(size: size)
        case .sourcesOverview:
            sourcesOverviewSection(size: size)
        case .networkStatus:
            networkStatusSection(size: size)
        case .tips:
            tipsSection(size: size)
        case .deviceInfo:
            deviceInfoSection(size: size)
        case .appStats:
            appStatsSection(size: size)
        case .favoriteApps:
            favoriteAppsSection(size: size)
        case .signingHistory:
            signingHistorySection(size: size)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: _compactMode ? 12 : 16) {
            VStack(alignment: .leading, spacing: _compactMode ? 1 : 2) {
                Text(greetingText)
                    .font(.system(size: _compactMode ? 18 : 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !_compactMode {
                    Text("Portal Dashboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Profile Picture or App Icon
            if _useProfilePicture, let profileImage = _profileManager.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: _compactMode ? 32 : 44, height: _compactMode ? 32 : 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: _compactMode ? 1 : 2)
                    )
            } else if _showAppIcon,
               let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: _compactMode ? 32 : 44, height: _compactMode ? 32 : 44)
                    .clipShape(RoundedRectangle(cornerRadius: _compactMode ? 7 : 10, style: .continuous))
            }
        }
        .padding(.horizontal, _compactMode ? 16 : 20)
        .padding(.top, _compactMode ? 10 : 16)
        .padding(.bottom, _compactMode ? 12 : 24)
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : -20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8) : .none, value: _appearAnimation)
    }
    
    // MARK: - Quick Actions Section
    @ViewBuilder
    private func quickActionsSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: size == .compact ? 8 : 16) {
            if size != .compact {
                sectionHeader("Quick Actions", icon: "bolt.fill")
            }
            
            if size == .compact {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CompactQuickActionButton(title: "Certificate", icon: "checkmark.seal.fill", color: .green) {
                            _showAddCertificate = true
                            HapticsManager.shared.softImpact()
                        }
                        CompactQuickActionButton(title: "Source", icon: "globe.desk.fill", color: .cyan) {
                            _showAddSource = true
                            HapticsManager.shared.softImpact()
                        }
                        CompactQuickActionButton(title: "Import", icon: "square.and.arrow.down.fill", color: .orange) {
                            _showImportApp = true
                            HapticsManager.shared.softImpact()
                        }
                        CompactQuickActionButton(title: "Sign", icon: "signature", color: .purple) {
                            _showSignAndInstallPicker = true
                            HapticsManager.shared.softImpact()
                        }
                    }
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    HomeQuickActionCard(
                        title: "Add Certificate",
                        icon: "checkmark.seal.fill",
                        color: .green,
                        isLarge: size == .large
                    ) {
                        _showAddCertificate = true
                        HapticsManager.shared.softImpact()
                    }
                    
                    HomeQuickActionCard(
                        title: "Add Source",
                        icon: "globe.desk.fill",
                        color: .cyan,
                        isLarge: size == .large
                    ) {
                        _showAddSource = true
                        HapticsManager.shared.softImpact()
                    }
                    
                    HomeQuickActionCard(
                        title: "Import App",
                        icon: "square.and.arrow.down.fill",
                        color: .orange,
                        isLarge: size == .large
                    ) {
                        _showImportApp = true
                        HapticsManager.shared.softImpact()
                    }
                    
                    HomeQuickActionCard(
                        title: "Sign & Install",
                        icon: "signature",
                        color: .purple,
                        isLarge: size == .large
                    ) {
                        _showSignAndInstallPicker = true
                        HapticsManager.shared.softImpact()
                    }
                }
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: _appearAnimation)
    }
    
    private var noAppsToSignView: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Apps To Sign")
                .font(.title2.bold())
            
            Text("Import an app first to sign and install it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Sign App")
    }
    
    // MARK: - Status Section
    @ViewBuilder
    private func statusSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: size == .compact ? 8 : 16) {
            if size != .compact {
                sectionHeader("Status", icon: "chart.bar.fill")
            }
            
            if size == .compact {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CompactStatusPill(title: "v\(portalVersion)", icon: "app.badge.checkmark.fill", color: .blue)
                        CompactStatusPill(title: "\(_sources.count) Sources", icon: "globe.desk.fill", color: .cyan)
                        CompactStatusPill(title: "\(_certificates.count) Certs", icon: "checkmark.seal.fill", color: .green)
                        CompactStatusPill(title: "\(_signedApps.count) Signed", icon: "signature", color: .purple)
                    }
                }
            } else {
                VStack(spacing: size == .large ? 16 : 12) {
                    HStack(spacing: 12) {
                        StatusCard(
                            title: "Portal Version",
                            value: "v\(portalVersion)",
                            subtitle: "Build \(buildNumber)",
                            icon: "app.badge.checkmark.fill",
                            color: .blue,
                            isLarge: size == .large
                        )
                        
                        StatusCard(
                            title: "Sources",
                            value: "\(_sources.count)",
                            subtitle: _sources.count == 1 ? "Repository" : "Repositories",
                            icon: "globe.desk.fill",
                            color: .cyan,
                            isLarge: size == .large
                        )
                    }
                    
                    HStack(spacing: 12) {
                        StatusCard(
                            title: "Certificates",
                            value: "\(_certificates.count)",
                            subtitle: _certificates.count == 1 ? "Certificate" : "Certificates",
                            icon: "checkmark.seal.fill",
                            color: .green,
                            isLarge: size == .large
                        )
                        
                        StatusCard(
                            title: "Signed Apps",
                            value: "\(_signedApps.count)",
                            subtitle: _signedApps.count == 1 ? "App signed" : "Apps Signed",
                            icon: "signature",
                            color: .purple,
                            isLarge: size == .large
                        )
                    }
                }
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: _appearAnimation)
    }
    
    // MARK: - Signing History Section
    @ViewBuilder
    private func signingHistorySection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: size == .compact ? 8 : 16) {
            if size != .compact {
                sectionHeader("Signing History", icon: "clock.arrow.circlepath")
            }
            
            if _signedApps.isEmpty {
                emptyHistoryView(size: size)
            } else {
                let itemCount = size == .compact ? 3 : (size == .large ? 10 : 5)
                let recentApps = Array(_signedApps.prefix(itemCount))
                
                if size == .compact {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(recentApps, id: \.uuid) { app in
                                CompactHistoryItem(app: app)
                            }
                        }
                    }
                } else {
                    VStack(spacing: size == .large ? 12 : 8) {
                        ForEach(recentApps, id: \.uuid) { app in
                            SigningHistoryRow(app: app, isLarge: size == .large)
                        }
                    }
                    .padding(size == .large ? 20 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: _appearAnimation)
    }
    
    @ViewBuilder
    private func emptyHistoryView(size: WidgetSize) -> some View {
        if size == .compact {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("No Signing History")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemFill))
            .cornerRadius(8)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: size == .large ? 40 : 32))
                    .foregroundStyle(.secondary.opacity(0.6))
                Text("No Signing History")
                    .font(size == .large ? .headline : .subheadline)
                    .foregroundStyle(.secondary)
                Text("Apps you sign will appear here on this widget.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, size == .large ? 40 : 24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - At A Glance Section
    @ViewBuilder
    private func atAGlanceSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: size == .compact ? 8 : 16) {
            if size != .compact {
                sectionHeader("At A Glance", icon: "eye.fill")
            }
            
            if size == .compact {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CompactStatusPill(title: "\(totalAppsAvailable) Apps", icon: "app.badge.fill", color: .blue)
                        CompactStatusPill(title: "\(_signedApps.count + _importedApps.count) Library", icon: "square.grid.2x2.fill", color: .orange)
                        if let cert = getSelectedCertificate() {
                            CompactStatusPill(title: cert.nickname ?? "Cert", icon: "checkmark.shield.fill", color: cert.revoked ? .red : .green)
                        }
                    }
                }
            } else {
                VStack(spacing: size == .large ? 14 : 12) {
                    AtAGlanceRow(title: "Total Apps Available", value: "\(totalAppsAvailable)", icon: "app.badge.fill", color: .blue)
                    AtAGlanceRow(title: "Apps In Library", value: "\(_signedApps.count + _importedApps.count)", icon: "square.grid.2x2.fill", color: .orange)
                    
                    if let selectedCert = getSelectedCertificate() {
                        AtAGlanceRow(title: "Active Certificate", value: selectedCert.nickname ?? "Unknown", icon: "checkmark.shield.fill", color: selectedCert.revoked ? .red : .green)
                        if let expiration = selectedCert.expiration {
                            AtAGlanceRow(title: "Certificate Expires", value: formatExpirationDate(expiration), icon: "calendar.badge.clock", color: expirationColor(expiration))
                        }
                    } else {
                        AtAGlanceRow(title: "Certificate Status", value: "No Certificate Selected", icon: "exclamationmark.shield.fill", color: .orange)
                    }
                    
                    if let recentSigned = _signedApps.first {
                        AtAGlanceRow(title: "Last Signed App", value: recentSigned.name ?? "Unknown", icon: "clock.fill", color: .purple)
                    }
                    
                    if size == .large {
                        AtAGlanceRow(title: "Unsigned Apps", value: "\(_importedApps.count)", icon: "doc.badge.plus", color: .gray)
                    }
                }
                .padding(size == .large ? 20 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                )
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.3) : .none, value: _appearAnimation)
    }
    
    // MARK: - Recent Apps Section
    @ViewBuilder
    private func recentAppsSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: size == .compact ? 8 : 16) {
            if size != .compact {
                sectionHeader("Recent Apps", icon: "clock.fill")
            }
            
            if _signedApps.isEmpty && _importedApps.isEmpty {
                emptyRecentAppsView
            } else {
                VStack(spacing: 12) {
                    // Show up to 5 recent apps
                    let recentSigned = Array(_signedApps.prefix(3))
                    let recentImported = Array(_importedApps.prefix(2))
                    
                    ForEach(recentSigned, id: \.uuid) { app in
                        RecentAppRow(
                            name: app.name ?? "Unknown",
                            bundleId: app.identifier ?? "",
                            isSigned: true,
                            date: app.date
                        )
                    }
                    
                    ForEach(recentImported, id: \.uuid) { app in
                        RecentAppRow(
                            name: app.name ?? "Unknown",
                            bundleId: app.identifier ?? "",
                            isSigned: false,
                            date: app.date
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                )
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.35) : .none, value: _appearAnimation)
    }
    
    private var emptyRecentAppsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No Recent Apps")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            Text("Import or sign an app to see it here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Storage Info Section
    private func storageInfoSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Storage Info", icon: "internaldrive.fill")
            
            VStack(spacing: 12) {
                StorageInfoRow(
                    title: "Signed Apps",
                    count: _signedApps.count,
                    icon: "checkmark.seal.fill",
                    color: .blue
                )
                
                StorageInfoRow(
                    title: "Imported Apps",
                    count: _importedApps.count,
                    icon: "square.and.arrow.down.fill",
                    color: .orange
                )
                
                StorageInfoRow(
                    title: "Certificates",
                    count: _certificates.count,
                    icon: "person.text.rectangle.fill",
                    color: .green
                )
                
                StorageInfoRow(
                    title: "Sources",
                    count: _sources.count,
                    icon: "globe.desk.fill",
                    color: .cyan
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
            )
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.4) : .none, value: _appearAnimation)
    }
    
    // MARK: - Certificate Status Section
    private func certificateStatusSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Certificate Status", icon: "checkmark.seal.fill")
            
            if let cert = getSelectedCertificate() {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(cert.revoked ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: cert.revoked ? "xmark.seal.fill" : "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(cert.revoked ? .red : .green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cert.nickname ?? "Unknown Certificate")
                                .font(.headline)
                            
                            Text(cert.revoked ? "Revoked" : "Active")
                                .font(.subheadline)
                                .foregroundStyle(cert.revoked ? .red : .green)
                            
                            if let expiration = cert.expiration {
                                Text("Expires On \(formatExpirationDate(expiration))")
                                    .font(.caption)
                                    .foregroundStyle(expirationColor(expiration))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if let expiration = cert.expiration {
                        CertificateExpirationBar(expiration: expiration)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                )
            } else {
                noCertificateView
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.45) : .none, value: _appearAnimation)
    }
    
    private var noCertificateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            
            Text("No Certificate Selected")
                .font(.subheadline.bold())
            
            Button {
                _showAddCertificate = true
            } label: {
                Text("Add Certificate")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Sources Overview Section
    private func sourcesOverviewSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Sources Overview", icon: "globe.desk.fill")
            
            if _sources.isEmpty {
                emptySourcesView
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(_sources.prefix(4)), id: \.identifier) { source in
                        SourceOverviewRow(
                            name: source.name ?? "Unknown",
                            appCount: viewModel.sources[source]?.apps.count ?? 0,
                            iconURL: source.iconURL
                        )
                    }
                    
                    if _sources.count > 4 {
                        Text("+ \(_sources.count - 4) more sources")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                )
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.5) : .none, value: _appearAnimation)
    }
    
    private var emptySourcesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.desk.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No Sources Added")
                .font(.subheadline.bold())
            
            Button {
                _showAddSource = true
            } label: {
                Text("Add Source")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Network Status Section
    private func networkStatusSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Network Status", icon: "wifi")
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(_networkMonitor.isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: _networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(_networkMonitor.isConnected ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(_networkMonitor.isConnected ? "Connected" : "Disconnected")
                        .font(.headline)
                    
                    Text(_networkMonitor.isConnected ? "You're online and ready to go" : "Check your internet connection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
            )
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.55) : .none, value: _appearAnimation)
    }
    
    // MARK: - Tips Section
    private func tipsSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: _compactMode ? 8 : 16) {
            if !_compactMode {
                sectionHeader("Tips & Tricks", icon: "lightbulb.fill")
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.yellow)
                
                Text(_tips[_currentTipIndex])
                    .font(.system(size: _compactMode ? 13 : 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(_compactMode ? 12 : 16)
            .onTapGesture {
                withAnimation {
                    _currentTipIndex = (_currentTipIndex + 1) % _tips.count
                }
                HapticsManager.shared.softImpact()
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.6) : .none, value: _appearAnimation)
    }
    
    // MARK: - Device Info Section
    private func deviceInfoSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: _compactMode ? 8 : 16) {
            if !_compactMode {
                sectionHeader("Device Info", icon: "iphone")
            }
            
            VStack(spacing: 8) {
                DeviceInfoRow(title: "Device", value: UIDevice.current.name, icon: "iphone", color: .indigo)
                DeviceInfoRow(title: "iOS Version", value: UIDevice.current.systemVersion, icon: "gear", color: .blue)
                DeviceInfoRow(title: "Model", value: UIDevice.current.model, icon: "cpu", color: .purple)
            }
            .padding(_compactMode ? 12 : 16)
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.7) : .none, value: _appearAnimation)
    }
    
    // MARK: - App Stats Section
    private func appStatsSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: _compactMode ? 8 : 16) {
            if !_compactMode {
                sectionHeader("App Statistics", icon: "chart.pie.fill")
            }
            
            HStack(spacing: _compactMode ? 8 : 12) {
                AppStatCard(
                    title: "Signed",
                    value: "\(_signedApps.count)",
                    icon: "signature",
                    color: .purple,
                    compact: _compactMode
                )
                
                AppStatCard(
                    title: "Imported",
                    value: "\(_importedApps.count)",
                    icon: "square.and.arrow.down",
                    color: .orange,
                    compact: _compactMode
                )
                
                AppStatCard(
                    title: "Sources",
                    value: "\(_sources.count)",
                    icon: "globe.desk",
                    color: .cyan,
                    compact: _compactMode
                )
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.8) : .none, value: _appearAnimation)
    }
    
    // MARK: - Favorite Apps Section
    private func favoriteAppsSection(size: WidgetSize) -> some View {
        VStack(alignment: .leading, spacing: _compactMode ? 8 : 16) {
            if !_compactMode {
                sectionHeader("Favorite Apps", icon: "star.fill")
            }
            
            if _signedApps.isEmpty && _importedApps.isEmpty {
                HStack {
                    Image(systemName: "star")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    
                    Text("No apps yet. Import or sign an app to get started.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(_compactMode ? 12 : 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(_signedApps.prefix(5)) { app in
                            FavoriteAppCard(name: app.name ?? "Unknown", isSigned: true, compact: _compactMode)
                        }
                        ForEach(_importedApps.prefix(5)) { app in
                            FavoriteAppCard(name: app.name ?? "Unknown", isSigned: false, compact: _compactMode)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.9) : .none, value: _appearAnimation)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Helper Properties
    private var totalAppsAvailable: Int {
        _sources.reduce(0) { total, source in
            total + (viewModel.sources[source]?.apps.count ?? 0)
        }
    }
    
    private func getSelectedCertificate() -> CertificatePair? {
        let selectedIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        return Storage.shared.getCertificate(for: selectedIndex)
    }
    
    private func formatExpirationDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func expirationColor(_ date: Date) -> Color {
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysUntilExpiration < 0 {
            return .red
        } else if daysUntilExpiration < 7 {
            return .orange
        } else if daysUntilExpiration < 30 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Home Quick Action Card
struct HomeQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HomeQuickActionCardContent(title: title, icon: icon, color: color, isLarge: isLarge)
        }
        .buttonStyle(HomeCardButtonStyle())
    }
}

// MARK: - Home Card Button Style
struct HomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct HomeQuickActionCardContent: View {
    let title: String
    let icon: String
    let color: Color
    var isLarge: Bool = false
    
    var body: some View {
        VStack(spacing: isLarge ? 14 : 10) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 36 : 28, weight: .medium))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: isLarge ? 15 : 13, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isLarge ? 24 : 16)
        .padding(.horizontal, 10)
    }
}

// MARK: - Compact Quick Action Button
struct CompactQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56)
        }
        .buttonStyle(HomeCardButtonStyle())
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isLarge: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 12 : 8) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 24 : 20, weight: .medium))
                .foregroundStyle(color)
            
            Spacer(minLength: 2)
            
            Text(value)
                .font(.system(size: isLarge ? 32 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: isLarge ? 13 : 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.system(size: isLarge ? 12 : 10, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isLarge ? 18 : 14)
    }
}

// MARK: - Compact Status Pill
struct CompactStatusPill: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Signing History Row
struct SigningHistoryRow: View {
    let app: Signed
    var isLarge: Bool = false
    
    private var formattedDate: String {
        guard let date = app.date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var relativeDate: String {
        guard let date = app.date else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var appSize: String {
        ByteCountFormatter.string(fromByteCount: app.size, countStyle: .file)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: isLarge ? 12 : 10)
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: isLarge ? 48 : 40, height: isLarge ? 48 : 40)
                
                Image(systemName: "signature")
                    .font(.system(size: isLarge ? 20 : 16, weight: .medium))
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: isLarge ? 4 : 2) {
                Text(app.name ?? "Unknown App")
                    .font(.system(size: isLarge ? 16 : 14, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(relativeDate)
                        .font(.system(size: isLarge ? 13 : 11))
                        .foregroundStyle(.secondary)
                    
                    if isLarge {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(appSize)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if isLarge, let bundleId = app.identifier {
                    Text(bundleId)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isLarge {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(appSize)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, isLarge ? 4 : 2)
    }
}

// MARK: - Compact History Item
struct CompactHistoryItem: View {
    let app: Signed
    
    private var relativeDate: String {
        guard let date = app.date else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "signature")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.purple)
            }
            
            VStack(spacing: 2) {
                Text(app.name ?? "App")
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .frame(width: 60)
                
                Text(relativeDate)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(12)
    }
}

// MARK: - At A Glance Row
struct AtAGlanceRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Device Info Row
struct DeviceInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - App Stat Card
struct AppStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var compact: Bool = false
    
    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Image(systemName: icon)
                .font(.system(size: compact ? 18 : 22, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: compact ? 20 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: compact ? 10 : 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 10 : 14)
    }
}

// MARK: - Favorite App Card
struct FavoriteAppCard: View {
    let name: String
    let isSigned: Bool
    var compact: Bool = false
    
    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: compact ? 44 : 56, height: compact ? 44 : 56)
                
                Image(systemName: isSigned ? "checkmark.seal.fill" : "app.fill")
                    .font(.system(size: compact ? 18 : 24))
                    .foregroundStyle(isSigned ? .green : .orange)
            }
            
            Text(name)
                .font(.system(size: compact ? 10 : 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: compact ? 50 : 64)
        }
    }
}

// MARK: - Recent App Row
struct RecentAppRow: View {
    let name: String
    let bundleId: String
    let isSigned: Bool
    let date: Date?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSigned ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isSigned ? "checkmark.seal.fill" : "square.and.arrow.down.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(isSigned ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(isSigned ? "Signed" : "Imported")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isSigned ? .green : .orange)
                    
                    if let date = date {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(date, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Storage Info Row
struct StorageInfoRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Certificate Expiration Bar
struct CertificateExpirationBar: View {
    let expiration: Date
    
    private var progress: Double {
        let totalDays: Double = 365
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return max(0, min(1, Double(daysRemaining) / totalDays))
    }
    
    private var barColor: Color {
        if progress < 0.1 {
            return .red
        } else if progress < 0.25 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(barColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Source Overview Row
struct SourceOverviewRow: View {
    let name: String
    let appCount: Int
    let iconURL: URL?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                if let iconURL = iconURL {
                    AsyncImage(url: iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "globe.desk.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.cyan)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: "globe.desk.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.cyan)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(appCount) Apps")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Sign And Install Picker View
struct SignAndInstallPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var _showFilePicker = false
    @State private var _isProcessing = false
    @State private var _processedApp: Imported? = nil
    @State private var _urlText = ""
    @State private var _showURLError = false
    @State private var _urlErrorMessage = ""
    @State private var _downloadProgress: Double = 0.0
    @State private var _currentDownloadId: String = ""
    @State private var _importStatus: SignInstallImportStatus = .idle
    @FocusState private var _isURLFieldFocused: Bool
    
    enum SignInstallImportStatus {
        case idle
        case downloading
        case processing
        case success
        case failed
    }
    
    let onAppSelected: (Imported) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "signature")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(.purple)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Quick Sign Apps")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            
                            Text("Select an IPA file or import from URL.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    if _isProcessing || _importStatus == .downloading || _importStatus == .processing {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                if _importStatus == .downloading {
                                    Circle()
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .trim(from: 0, to: _downloadProgress)
                                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 70, height: 70)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 0.2), value: _downloadProgress)
                                    
                                    VStack(spacing: 2) {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(.purple)
                                        Text("\(Int(_downloadProgress * 100))%")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.purple)
                                    }
                                } else {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                }
                            }
                            
                            Text(_importStatus == .downloading ? "Downloading IPA..." : "Processing IPA...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 16) {
                            // URL Input Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Import from URL")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "link")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 16))
                                        
                                        TextField("Enter IPA URL", text: $_urlText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .keyboardType(.URL)
                                            .focused($_isURLFieldFocused)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                handleURLImport()
                                            }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(_showURLError ? Color.red : (_isURLFieldFocused ? Color.purple : Color.clear), lineWidth: 2)
                                    )
                                    
                                    // Paste Button
                                    Button {
                                        if let pastedString = UIPasteboard.general.string {
                                            _urlText = pastedString
                                            HapticsManager.shared.softImpact()
                                        }
                                    } label: {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.purple)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.purple.opacity(0.15))
                                            )
                                    }
                                }
                                
                                if _showURLError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                        Text(_urlErrorMessage)
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                                
                                // Import from URL Button
                                Button {
                                    handleURLImport()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Text("Import from URL")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .purple.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                                }
                                .disabled(_urlText.isEmpty)
                                .opacity(_urlText.isEmpty ? 0.5 : 1.0)
                            }
                            .padding(.horizontal, 24)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            
                            // Select IPA Button
                            Button {
                                _showFilePicker = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    Text("Select IPA File")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundStyle(.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.purple.opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Info text
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            
                            Text("The signing process will start automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Sign & Install")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $_showFilePicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.ipa, .tipa],
                    allowsMultipleSelection: false,
                    onDocumentsPicked: { urls in
                        guard let url = urls.first else { return }
                        _isProcessing = true
                        
                        // Process the IPA file
                        let id = "FeatherSignInstall_\(UUID().uuidString)"
                        let dl = DownloadManager.shared.startArchive(from: url, id: id)
                        
                        do {
                            try DownloadManager.shared.handlePachageFile(url: url, dl: dl)
                            
                            // Wait a moment for the import to complete, then find the app
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                // Fetch the most recently imported app
                                let request = Imported.fetchRequest()
                                request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
                                request.fetchLimit = 1
                                
                                if let importedApp = try? Storage.shared.context.fetch(request).first {
                                    _isProcessing = false
                                    onAppSelected(importedApp)
                                } else {
                                    _isProcessing = false
                                }
                            }
                        } catch {
                            _isProcessing = false
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidProgressNotification)) { notification in
                guard let userInfo = notification.userInfo,
                      let downloadId = userInfo["downloadId"] as? String,
                      downloadId == _currentDownloadId,
                      let progress = userInfo["progress"] as? Double else { return }
                
                _downloadProgress = progress
                
                if progress >= 0.99 && _importStatus == .downloading {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        _importStatus = .processing
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)) { notification in
                guard let userInfo = notification.userInfo,
                      let downloadId = userInfo["downloadId"] as? String,
                      downloadId == _currentDownloadId else { return }
                
                // Fetch the most recently imported app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let request = Imported.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
                    request.fetchLimit = 1
                    
                    if let importedApp = try? Storage.shared.context.fetch(request).first {
                        _importStatus = .idle
                        _isProcessing = false
                        onAppSelected(importedApp)
                    } else {
                        _importStatus = .idle
                        _isProcessing = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidFailNotification)) { notification in
                guard let userInfo = notification.userInfo,
                      let downloadId = userInfo["downloadId"] as? String,
                      downloadId == _currentDownloadId else { return }
                
                _urlErrorMessage = userInfo["error"] as? String ?? "Import failed"
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _showURLError = true
                    _importStatus = .idle
                    _isProcessing = false
                }
                HapticsManager.shared.error()
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidFailNotification)) { notification in
                guard let userInfo = notification.userInfo,
                      let downloadId = userInfo["downloadId"] as? String,
                      downloadId == _currentDownloadId else { return }
                
                _urlErrorMessage = userInfo["error"] as? String ?? "Download failed"
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _showURLError = true
                    _importStatus = .idle
                    _isProcessing = false
                }
                HapticsManager.shared.error()
            }
            .onChange(of: _urlText) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _showURLError = false
                    _urlErrorMessage = ""
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func handleURLImport() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            _showURLError = false
            _urlErrorMessage = ""
        }
        
        guard !_urlText.isEmpty else {
            showURLError("Please enter a URL")
            return
        }
        
        var urlString = _urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Auto-add https:// if no scheme is provided
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString) else {
            showURLError("Invalid URL format")
            return
        }
        
        guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            showURLError("URL must start with http:// or https://")
            return
        }
        
        guard let host = url.host, !host.isEmpty else {
            showURLError("Invalid URL - missing host")
            return
        }
        
        // Start the download
        let downloadId = "FeatherSignInstall_\(UUID().uuidString)"
        _currentDownloadId = downloadId
        _downloadProgress = 0.0
        _importStatus = .downloading
        _isProcessing = true
        
        HapticsManager.shared.impact()
        _ = DownloadManager.shared.startDownload(from: url, id: downloadId)
    }
    
    private func showURLError(_ message: String) {
        _urlErrorMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            _showURLError = true
        }
        HapticsManager.shared.error()
    }
}

// MARK: - App Updates List Sheet
struct AppUpdatesListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let updates: [AppUpdateInfo]
    let onSignApp: (AppUpdateInfo) -> Void
    let onDismissUpdate: (AppUpdateInfo) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                if updates.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                            
                            Text("All Apps Up to Date")
                                .font(.headline)
                            
                            Text("No updates available for your tracked apps.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                } else {
                    Section {
                        ForEach(updates) { update in
                            AppUpdateRow(
                                update: update,
                                onSign: { onSignApp(update) },
                                onDismiss: { onDismissUpdate(update) }
                            )
                        }
                    } header: {
                        Text("Available Updates (\(updates.count))")
                    }
                }
            }
            .navigationTitle("App Updates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - App Update Row
private struct AppUpdateRow: View {
    let update: AppUpdateInfo
    let onSign: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let iconURLString = update.iconURL, let iconURL = URL(string: iconURLString) {
                AsyncImage(url: iconURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Image(systemName: "app.fill")
                                .foregroundStyle(.green)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundStyle(.green)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(update.appName)
                    .font(.subheadline.weight(.semibold))
                
                HStack(spacing: 4) {
                    Text("v\(update.currentVersion)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("v\(update.newVersion)")
                        .foregroundStyle(.green)
                }
                .font(.caption)
                
                Text(update.sourceName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Button {
                onSign()
            } label: {
                Text("Sign")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
    }
}

#Preview {
    HomeView()
}
