import SwiftUI
import CoreData
import NimbleViews

// MARK: - HomeView - Dashboard with Quick Actions, Status, and At A Glance
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.greetingsName") private var _greetingsName: String = ""
    
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
    @State private var _appearAnimation = false
    
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
                    headerSection
                    
                    VStack(spacing: 24) {
                        // Quick Actions
                        quickActionsSection
                        
                        // Status Section
                        statusSection
                        
                        // At A Glance Section
                        atAGlanceSection
                    }
                    .padding(.horizontal, 20)
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                _appearAnimation = true
            }
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
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
            
            // App Icon
            if let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .opacity(_appearAnimation ? 1 : 0)
        .offset(y: _appearAnimation ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: _appearAnimation)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Quick Actions", icon: "bolt.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    title: "Add Certificate",
                    icon: "checkmark.seal.fill",
                    color: .green
                ) {
                    _showAddCertificate = true
                    HapticsManager.shared.softImpact()
                }
                
                QuickActionCard(
                    title: "Add Source",
                    icon: "globe.desk.fill",
                    color: .cyan
                ) {
                    _showAddSource = true
                    HapticsManager.shared.softImpact()
                }
                
                QuickActionCard(
                    title: "Import App",
                    icon: "square.and.arrow.down.fill",
                    color: .orange
                ) {
                    _showImportApp = true
                    HapticsManager.shared.softImpact()
                }
                
                NavigationLink {
                    if let app = _importedApps.first {
                        ModernSigningView(app: app)
                    } else {
                        noAppsToSignView
                    }
                } label: {
                    QuickActionCardContent(
                        title: "Sign & Install",
                        icon: "signature",
                        color: .purple
                    )
                }
                .disabled(_importedApps.isEmpty && _signedApps.isEmpty)
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: _appearAnimation)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.accentColor)
            
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

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionCardContent(title: title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionCardContent: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
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

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
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
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
