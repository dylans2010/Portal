import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct SigningSecurityView: View {
    @AppStorage("signing.validateCertificates") private var validateCertificates = true
    @AppStorage("signing.checkRevocation") private var checkRevocation = true
    @AppStorage("signing.requireTrustedCerts") private var requireTrustedCerts = false
    @AppStorage("signing.logSecurityEvents") private var logSecurityEvents = true
    @AppStorage("signing.warnExpiringSoon") private var warnExpiringSoon = true
    @AppStorage("signing.expiryWarningDays") private var expiryWarningDays = 30

    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>

    var body: some View {
        List {
            // Certificate Validation Section
            Section {
                Toggle("Validate Certificates Before Signing", isOn: $validateCertificates)
                Toggle("Check Certificate Revocation", isOn: $checkRevocation)
                Toggle("Require Trusted Certificates Only", isOn: $requireTrustedCerts)
            } header: {
                Text("Certificate Validation")
            } footer: {
                Text("Enable these options for enhanced security during signing operations.")
            }

            // Expiration Warnings
            Section {
                Toggle("Warn About Expiring Certificates", isOn: $warnExpiringSoon)

                if warnExpiringSoon {
                    Stepper("Warning: \(expiryWarningDays) days before expiry", value: $expiryWarningDays, in: 7...90)
                }
            } header: {
                Text("Expiration Warnings")
            }

            // Logging
            Section {
                Toggle("Log Security Events", isOn: $logSecurityEvents)
            } header: {
                Text("Security Logging")
            }

            // Security Status
            Section {
                ForEach(certificates, id: \.uuid) { cert in
                    SecurityStatusRow(certificate: cert)
                }
            } header: {
                Text("Certificate Security Status")
            }

            // Actions
            Section {
                Button {
                    runSecurityAudit()
                } label: {
                    Label("Run Security Audit", systemImage: "shield.checkered")
                }

                Button {
                    checkAllRevocations()
                } label: {
                    Label("Check All Revocations", systemImage: "exclamationmark.shield")
                }
            } header: {
                Text("Security Actions")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Security")
    }

    private func runSecurityAudit() {
        AppLogManager.shared.info("Running security audit on certificates", category: "Security")

        var issues: [String] = []

        for cert in certificates {
            if let expiration = cert.expiration, expiration <= Date() {
                issues.append("Certificate '\(cert.nickname ?? "Unknown")' Has Expired")
            } else if let expiration = cert.expiration, expiration <= Date().addingTimeInterval(Double(expiryWarningDays) * 86400) {
                issues.append("Certificate '\(cert.nickname ?? "Unknown")' Expires Soon")
            }
        }

        if issues.isEmpty {
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Security Audit Passed - No Issues Found", type: .success)
        } else {
            HapticsManager.shared.warning()
            ToastManager.shared.show("⚠️ Found \(issues.count) Security Issue(s)", type: .warning)
        }

        AppLogManager.shared.info("Security Audit Complete: \(issues.count) issues found", category: "Security")
    }

    private func checkAllRevocations() {
        AppLogManager.shared.info("Checking Certificate Revocations", category: "Security")

        for cert in certificates {
            Storage.shared.revokagedCertificate(for: cert)
        }

        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Revocation Check Initiated", type: .success)
    }
}
