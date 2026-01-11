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
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // CoreSign Header at top
                Section {
                    CoreSignHeaderView(hideAboutButton: true)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            handleDeveloperModeTap()
                        }
                }
                
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        ConditionalLabel(title: .localized("Appearance"), systemImage: "paintbrush")
                    }
                    NavigationLink(destination: HapticsView()) {
                        ConditionalLabel(title: .localized("Haptics"), systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                
                NBSection(.localized("Experience")) {
                    Picker(.localized("Certificate Type"), selection: $certificateExperience) {
                        ForEach(CertificateExperience.allCases, id: \.rawValue) { experience in
                            Text(experience.displayName).tag(experience.rawValue)
                        }
                    }
                    .onChange(of: certificateExperience) { newValue in
                        // Always enable Guides for Enterprise
                        if newValue == CertificateExperience.enterprise.rawValue {
                            forceShowGuides = true
                        }
                    }
                } footer: {
                    Text(.localized("Select your certificate type. Enterprise certificates will enable the Guides feature."))
                }
                
                NBSection(.localized("Features")) {
                    NavigationLink(destination: FilesSettingsView()) {
                        ConditionalLabel(title: .localized("Files"), systemImage: "folder")
                    }
                    NavigationLink(destination: CertificatesView()) {
                        ConditionalLabel(title: .localized("Certificates"), systemImage: "checkmark.seal")
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        ConditionalLabel(title: .localized("Signing Options"), systemImage: "signature")
                    }
                    NavigationLink(destination: ArchiveView()) {
                        ConditionalLabel(title: .localized("Archive & Compression"), systemImage: "archivebox")
                    }
                    NavigationLink(destination: InstallationView()) {
                        ConditionalLabel(title: .localized("Installation"), systemImage: "arrow.down.circle")
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, custom modifications to apps, and enable experimental features."))
                }
                
                // Only show Extras section when NOT in Enterprise mode
                if certificateExperience != CertificateExperience.enterprise.rawValue {
                    NBSection(.localized("Extras")) {
                        NavigationLink(destination: AppIconView()) {
                            ConditionalLabel(title: .localized("App Icons"), systemImage: "app.badge")
                        }
                        NavigationLink(destination: ManageStorageView()) {
                            ConditionalLabel(title: .localized("Manage Storage"), systemImage: "internaldrive")
                        }
                        NavigationLink(destination: CheckForUpdatesView()) {
                            ConditionalLabel(title: .localized("Check For Updates"), systemImage: "arrow.down.circle")
                        }
                    } footer: {
                        Text(.localized("Customize your app icon, manage storage, and check for updates."))
                    }
                }
                
                if isDeveloperModeEnabled {
                    NBSection("Developer") {
                        NavigationLink(destination: DeveloperView()) {
                            ConditionalLabelString(title: "Developer Tools", systemImage: "hammer.fill")
                        }
                    }
                }
            }
        }
        .alert("Enable Developer Mode", isPresented: $showDeveloperConfirmation) {
            Button("Cancel", role: .cancel) {
                developerTapCount = 0
            }
            Button("Enable", role: .none) {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
                AppLogManager.shared.info("Developer mode enabled", category: "Settings")
            }
        } message: {
            Text("Developer mode provides advanced tools and diagnostics. This is intended for developers and advanced users only. Are you sure you want to enable it?")
        }
    }
    
    private func handleDeveloperModeTap() {
        let now = Date()
        
        // Reset counter if too much time has passed (5 seconds)
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 5.0 {
            developerTapCount = 0
        }
        
        lastTapTime = now
        developerTapCount += 1
        
        // Provide subtle feedback
        if developerTapCount >= 5 && developerTapCount < 10 {
            HapticsManager.shared.softImpact()
        }
        
        // Require 10 taps to show confirmation dialog
        if developerTapCount >= 10 {
            showDeveloperConfirmation = true
        }
    }
}

// MARK: - Extension: View
extension SettingsView {
}
