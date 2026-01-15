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
                
                // General
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        settingsRow(icon: "paintbrush.fill", title: "Appearance", color: .pink)
                    }
                    NavigationLink(destination: HapticsView()) {
                        settingsRow(icon: "waveform", title: "Haptics", color: .purple)
                    }
                    Picker(selection: $certificateExperience) {
                        ForEach(CertificateExperience.allCases, id: \.rawValue) { exp in
                            Text(exp.displayName).tag(exp.rawValue)
                        }
                    } label: {
                        settingsRow(icon: "person.badge.shield.checkmark.fill", title: "Certificate Type", color: .blue)
                    }
                    .onChange(of: certificateExperience) { newValue in
                        if newValue == CertificateExperience.enterprise.rawValue {
                            forceShowGuides = true
                        }
                    }
                } header: {
                    Text("General")
                }
                
                // Configuration
                Section {
                    NavigationLink(destination: CertificatesView()) {
                        settingsRow(icon: "checkmark.seal.fill", title: "Certificates", color: .green)
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        settingsRow(icon: "signature", title: "Signing Options", color: .orange)
                    }
                    NavigationLink(destination: InstallationView()) {
                        settingsRow(icon: "arrow.down.app.fill", title: "Installation", color: .cyan)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        settingsRow(icon: "archivebox.fill", title: "Archive & Compression", color: .indigo)
                    }
                } header: {
                    Text("Configuration")
                }
                
                // Features
                Section {
                    NavigationLink(destination: FilesSettingsView()) {
                        settingsRow(icon: "folder.fill", title: "Files", color: .blue)
                    }
                    NavigationLink(destination: GuidesSettingsView()) {
                        settingsRow(icon: "book.fill", title: "Guides", color: .orange)
                    }
                } header: {
                    Text("Features")
                }
                
                // App
                if certificateExperience != CertificateExperience.enterprise.rawValue {
                    Section {
                        NavigationLink(destination: AppIconView()) {
                            settingsRow(icon: "app.badge.fill", title: "App Icons", color: .pink)
                        }
                        NavigationLink(destination: ManageStorageView()) {
                            settingsRow(icon: "internaldrive.fill", title: "Storage", color: .gray)
                        }
                        NavigationLink(destination: CheckForUpdatesView(), isActive: $navigateToCheckForUpdates) {
                            settingsRow(icon: "arrow.triangle.2.circlepath", title: "Updates", color: .green)
                        }
                    } header: {
                        Text("App")
                    }
                }
                
                // Developer
                if isDeveloperModeEnabled {
                    Section {
                        NavigationLink(destination: DeveloperView()) {
                            settingsRow(icon: "hammer.fill", title: "Developer Tools", color: .yellow)
                        }
                    } header: {
                        Text("Developer")
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
    
    @ViewBuilder
    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(title)
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
