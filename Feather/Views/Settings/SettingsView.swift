import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - Certificate Experience Type
enum CertificateExperience: String, CaseIterable {
    case developer = "Developer"
    case enterprise = "Enterprise"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - View
struct SettingsView: View {
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var showDeveloperConfirmation = false
    @State private var navigateToCheckForUpdates = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @Environment(\.navigateToUpdates) private var navigateToUpdates
    
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // Header
                Section {
                    CoreSignHeaderView(hideAboutButton: true)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onTapGesture { handleDeveloperModeTap() }
                }
                
                // Preferences
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        modernSettingsRow(icon: "paintbrush.fill", title: "Appearance", color: .pink)
                    }
                    NavigationLink(destination: HapticsView()) {
                        modernSettingsRow(icon: "waveform", title: "Haptics", color: .purple)
                    }
                    Picker(selection: $certificateExperience) {
                        ForEach(CertificateExperience.allCases, id: \.rawValue) { exp in
                            Text(exp.displayName).tag(exp.rawValue)
                        }
                    } label: {
                        modernSettingsRow(icon: "person.badge.shield.checkmark.fill", title: "Certificate Type", color: .blue)
                    }
                    .onChange(of: certificateExperience) { newValue in
                        if newValue == CertificateExperience.enterprise.rawValue {
                            forceShowGuides = true
                        }
                    }
                } header: {
                    sectionHeader("Preferences", icon: "slider.horizontal.3")
                }
                
                // Signing & Security
                Section {
                    NavigationLink(destination: CertificatesView()) {
                        modernSettingsRow(icon: "checkmark.seal.fill", title: "Certificates", color: .green)
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        modernSettingsRow(icon: "signature", title: "Signing Options", color: .orange)
                    }
                    NavigationLink(destination: InstallationView()) {
                        modernSettingsRow(icon: "arrow.down.app.fill", title: "Installation", color: .cyan)
                    }
                } header: {
                    sectionHeader("Signing & Security", icon: "lock.shield.fill")
                }
                
                // Data & Storage
                Section {
                    NavigationLink(destination: FilesSettingsView()) {
                        modernSettingsRow(icon: "folder.fill", title: "Files", color: .blue)
                    }
                    if certificateExperience != CertificateExperience.enterprise.rawValue {
                        NavigationLink(destination: ManageStorageView()) {
                            modernSettingsRow(icon: "internaldrive.fill", title: "Storage", color: .gray)
                        }
                    }
                } header: {
                    sectionHeader("Data & Storage", icon: "externaldrive.fill")
                }
                
                // Resources
                Section {
                    NavigationLink(destination: GuidesSettingsView()) {
                        modernSettingsRow(icon: "book.fill", title: "Guides", color: .orange)
                    }
                    NavigationLink(destination: FeedbackView()) {
                        modernSettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Feedback", color: .purple)
                    }
                } header: {
                    sectionHeader("Resources", icon: "books.vertical.fill")
                }
                
                // App
                if certificateExperience != CertificateExperience.enterprise.rawValue {
                    Section {
                        NavigationLink(destination: AppIconView()) {
                            modernSettingsRow(icon: "app.badge.fill", title: "App Icons", color: .pink)
                        }
                        NavigationLink(destination: CheckForUpdatesView(), isActive: $navigateToCheckForUpdates) {
                            modernSettingsRow(icon: "arrow.triangle.2.circlepath", title: "Updates", color: .green)
                        }
                    } header: {
                        sectionHeader("App", icon: "app.fill")
                    }
                }
                
                // Developer
                if isDeveloperModeEnabled {
                    Section {
                        NavigationLink(destination: DeveloperView()) {
                            modernSettingsRow(icon: "hammer.fill", title: "Developer Tools", color: .yellow)
                        }
                    } header: {
                        sectionHeader("Developer", icon: "wrench.and.screwdriver.fill")
                    }
                }
            }
        }
        .alert("Enable Developer Mode", isPresented: $showDeveloperConfirmation) {
            Button("Cancel", role: .cancel) { developerTapCount = 0 }
            Button("Enable") {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
            }
        } message: {
            Text("Developer mode provides advanced tools for developers and advanced users.")
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
    
    // MARK: - Modern Settings Row (No colored background)
    @ViewBuilder
    private func modernSettingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 26)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Section Header
    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    
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

// MARK: - Extension: View
extension SettingsView {
}
