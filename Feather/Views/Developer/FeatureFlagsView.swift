import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct FeatureFlagsView: View {
    @AppStorage("feature_enhancedAnimations") var enhancedAnimations = false
    @AppStorage("feature_advancedSigning") var advancedSigning = false
    @AppStorage("feature_usePortalCert") var usePortalCert = false
    @AppStorage("feature_advancedFilesFeatures") var advancedFilesFeatures = false
    @AppStorage("feature_advancedBackupTools") var advancedBackupTools = false
    @AppStorage("feature_passwordChanger") var passwordChanger = false

    var body: some View {
        List {
            Section {
                Toggle("Enhanced Animations", isOn: $enhancedAnimations)
            } header: {
                Text("Performance")
            }

            Section {
                Toggle("Advanced Signing Options", isOn: $advancedSigning)
            } header: {
                Text("Signing")
            }

            Section {
                Toggle("Password Changer", isOn: $passwordChanger)

                Toggle("Use .portalcert for certificates", isOn: $usePortalCert)
            } header: {
                Text("Certificates")
            } footer: {
                Text("When enabled, allows exporting and importing certificates as a single .portalcert file that bundles the P12 and provisioning profile together. This is a super early beta, does not work.")
            }

            Section {
                Toggle("Advanced Files Features", isOn: $advancedFilesFeatures)

                if advancedFilesFeatures {
                    NavigationLink {
                        FileAdvancedToolsView()
                    } label: {
                        Label("Open Advanced File Tools", systemImage: "wrench.and.screwdriver.fill")
                    }
                }

                Toggle("Show Advanced Backup Tools", isOn: $advancedBackupTools)
            } header: {
                Text("Files")
            } footer: {
                Text("Enables advanced file management features including binary analysis, hex editing, file forensics, metadata extraction, batch operations, and more powerful file manipulation tools.")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Feature Flags")
    }
}
