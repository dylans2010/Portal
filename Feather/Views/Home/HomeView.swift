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
    
    @StateObject private var _settingsManager = HomeSettingsManager.shared
    @StateObject private var _networkMonitor = NetworkMonitor.shared
    @StateObject private var _profileManager = ProfilePictureManager.shared
    
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
                    // Header
                    if _greetingEnabled {
                        headerSection
                    }
                    
                    VStack(spacing: _compactMode ? 16 : 24) {
                        // Dynamic widgets based on settings
                        ForEach(_settingsManager.enabledWidgets) { widget in
                            widgetView(for: widget.type)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, _greetingEnabled ? 0 : 20)
                    .padding(.bottom, 100)
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
        }
    }
    
    // MARK: - Widget View Builder
    @ViewBuilder
    private func widgetView(for type: HomeWidgetType) -> some View {
        switch type {
        case .quickActions:
            quickActionsSection
        case .status:
            statusSection
        case .atAGlance:
            atAGlanceSection
        case .recentApps:
            recentAppsSection
        case .storageInfo:
            storageInfoSection
        case .certificateStatus:
            certificateStatusSection
        case .sourcesOverview:
            sourcesOverviewSection
        case .networkStatus:
            networkStatusSection
        case .tips:
            tipsSection
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Portal Dashboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Profile Picture or App Icon
            if _useProfilePicture, let profileImage = _profileManager.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
            } else if _showAppIcon,
               let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : -20)
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8) : .none, value: _appearAnimation)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Quick Actions", icon: "bolt.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                HomeQuickActionCard(
                    title: "Add Certificate",
                    icon: "checkmark.seal.fill",
                    color: .green
                ) {
                    _showAddCertificate = true
                    HapticsManager.shared.softImpact()
                }
                
                HomeQuickActionCard(
                    title: "Add Source",
                    icon: "globe.desk.fill",
                    color: .cyan
                ) {
                    _showAddSource = true
                    HapticsManager.shared.softImpact()
                }
                
                HomeQuickActionCard(
                    title: "Import App",
                    icon: "square.and.arrow.down.fill",
                    color: .orange
                ) {
                    _showImportApp = true
                    HapticsManager.shared.softImpact()
                }
                
                HomeQuickActionCard(
                    title: "Sign & Install",
                    icon: "signature",
                    color: .purple
                ) {
                    _showSignAndInstallPicker = true
                    HapticsManager.shared.softImpact()
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
            
            Text("No Apps to Sign")
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
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Status", icon: "chart.bar.fill")
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatusCard(
                        title: "Portal Version",
                        value: "v\(portalVersion)",
                        subtitle: "Build \(buildNumber)",
                        icon: "app.badge.checkmark.fill",
                        color: .blue
                    )
                    
                    StatusCard(
                        title: "Sources",
                        value: "\(_sources.count)",
                        subtitle: _sources.count == 1 ? "repository" : "repositories",
                        icon: "globe.desk.fill",
                        color: .cyan
                    )
                }
                
                HStack(spacing: 12) {
                    StatusCard(
                        title: "Certificates",
                        value: "\(_certificates.count)",
                        subtitle: _certificates.count == 1 ? "certificate" : "certificates",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                    
                    StatusCard(
                        title: "Signed Apps",
                        value: "\(_signedApps.count)",
                        subtitle: _signedApps.count == 1 ? "app signed" : "apps signed",
                        icon: "signature",
                        color: .purple
                    )
                }
            }
        }
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: _appearAnimation)
    }
    
    // MARK: - At A Glance Section
    private var atAGlanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("At A Glance", icon: "eye.fill")
            
            VStack(spacing: 12) {
                // Total Apps Available
                AtAGlanceRow(
                    title: "Total Apps Available",
                    value: "\(totalAppsAvailable)",
                    icon: "app.badge.fill",
                    color: .blue
                )
                
                // Library Apps
                AtAGlanceRow(
                    title: "Apps in Library",
                    value: "\(_signedApps.count + _importedApps.count)",
                    icon: "square.grid.2x2.fill",
                    color: .orange
                )
                
                // Certificate Status
                if let selectedCert = getSelectedCertificate() {
                    AtAGlanceRow(
                        title: "Active Certificate",
                        value: selectedCert.nickname ?? "Unknown",
                        icon: "checkmark.shield.fill",
                        color: selectedCert.revoked ? .red : .green
                    )
                    
                    if let expiration = selectedCert.expiration {
                        AtAGlanceRow(
                            title: "Certificate Expires",
                            value: formatExpirationDate(expiration),
                            icon: "calendar.badge.clock",
                            color: expirationColor(expiration)
                        )
                    }
                } else {
                    AtAGlanceRow(
                        title: "Certificate Status",
                        value: "No certificate selected",
                        icon: "exclamationmark.shield.fill",
                        color: .orange
                    )
                }
                
                // Recent Activity
                if let recentSigned = _signedApps.first {
                    AtAGlanceRow(
                        title: "Last Signed App",
                        value: recentSigned.name ?? "Unknown",
                        icon: "clock.fill",
                        color: .purple
                    )
                }
                
                // Storage Info
                AtAGlanceRow(
                    title: "Unsigned Apps",
                    value: "\(_importedApps.count)",
                    icon: "doc.badge.plus",
                    color: .gray
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
        .animation(_animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8).delay(0.3) : .none, value: _appearAnimation)
    }
    
    // MARK: - Recent Apps Section
    private var recentAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Recent Apps", icon: "clock.fill")
            
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
            
            Text("Import or sign an app to see it here")
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
    private var storageInfoSection: some View {
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
    private var certificateStatusSection: some View {
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
                                Text("Expires \(formatExpirationDate(expiration))")
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
    private var sourcesOverviewSection: some View {
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
    private var networkStatusSection: some View {
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
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Tips & Tricks", icon: "lightbulb.fill")
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                }
                
                Text(_tips[_currentTipIndex])
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
            )
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
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HomeQuickActionCardContent(title: title, icon: icon, color: color)
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
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.25), color.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                
                // Inner circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                // Glass overlay
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Top highlight
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon with modern styling
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Spacer(minLength: 4)
            
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                // Accent gradient
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.08), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass highlight
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.06), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - At A Glance Row
struct AtAGlanceRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)
                
                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Subtle chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 4)
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
                
                Text("\(appCount) apps")
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
    
    let onAppSelected: (Imported) -> Void
    
    var body: some View {
        NavigationStack {
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
                        Text("Sign & Install")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        Text("Select an IPA file to sign and install")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                if _isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Processing IPA...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                } else {
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Info text
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        
                        Text("The signing process will start automatically")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 20)
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
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HomeView()
}
