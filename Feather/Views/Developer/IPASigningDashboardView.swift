import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct IPASigningDashboardView: View {
    var body: some View {
        List {
            // Certificate & Profile Manager Section
            Section {
                NavigationLink(destination: CertificateProfileManagerView()) {
                    DeveloperMenuRow(icon: "person.badge.key.fill", title: "Certificate & Profile Manager", color: .blue)
                }
            } header: {
                Text("Certificates & Profiles")
            } footer: {
                Text("Manage signing certificates and provisioning profiles")
            }

            // Signing Logs Section
            Section {
                NavigationLink(destination: SigningLogsView()) {
                    DeveloperMenuRow(icon: "doc.text.fill", title: "Signing Logs", color: .gray)
                }
            } header: {
                Text("Logs")
            } footer: {
                Text("View detailed signing operation logs.")
            }

            // Batch Signing Section
            Section {
                NavigationLink(destination: DeveloperBatchSigningView()) {
                    DeveloperMenuRow(icon: "square.stack.3d.up.fill", title: "Batch Signing", color: .green)
                }
            } header: {
                Text("Batch Operations")
            } footer: {
                Text("Sign multiple IPA files at once.")
            }

            // Entitlements & Info.plist Editor Section
            Section {
                NavigationLink(destination: EntitlementsPlistEditorView()) {
                    DeveloperMenuRow(icon: "doc.badge.gearshape.fill", title: "Entitlements & Info.plist Editor", color: .purple)
                }
            } header: {
                Text("Editors")
            } footer: {
                Text("Edit entitlements and Info.plist configurations.")
            }

            // Security Section
            Section {
                NavigationLink(destination: SigningSecurityView()) {
                    DeveloperMenuRow(icon: "lock.shield.fill", title: "Security", color: .red)
                }
            } header: {
                Text("Security")
            } footer: {
                Text("Certificate validation, revocation checks, and security settings.")
            }

            // Performance Metrics Section
            Section {
                NavigationLink(destination: SigningPerformanceMetricsView()) {
                    DeveloperMenuRow(icon: "chart.bar.fill", title: "Performance Metrics", color: .orange)
                }
            } header: {
                Text("Performance")
            } footer: {
                Text("Signing speed, success rates, and operation statistics.")
            }

            // API & Webhook Integration Section
            Section {
                NavigationLink(destination: APIWebhookIntegrationView()) {
                    DeveloperMenuRow(icon: "network", title: "API & Webhook Integration", color: .teal)
                }
            } header: {
                Text("Integration")
            } footer: {
                Text("Configure external APIs and webhook notifications.")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("IPA Signing Debugging")
    }
}
