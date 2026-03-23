import SwiftUI

struct IPAExplorerProvisionViewer: View {
    @EnvironmentObject var themeManager: ThemeManager
    let fileURL: URL
    @State private var certificate: Certificate?

    var body: some View {
        List {
            if let cert = certificate {
                ProvisionMetadataSection(cert: cert)
                ProvisionCapabilitiesSection(cert: cert)
                if let entitlements = cert.Entitlements {
                    ProvisionEntitlementsSection(entitlements: entitlements)
                }
            } else {
                Text(.localized("Loading..."))
            }
        }
        .globalTheme()
        .navigationTitle("embedded.mobileprovision")
        .onAppear {
            loadProvision()
        }
    }

    private func loadProvision() {
        let reader = CertificateReader(fileURL)
        certificate = reader.decoded
    }
}

private struct ProvisionMetadataSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cert: Certificate

    var body: some View {
        Section(.localized("Metadata")) {
            ProvisionInfoRow(label: .localized("Name"), value: cert.Name)
            ProvisionInfoRow(label: .localized("Team ID"), value: cert.TeamIdentifier.joined(separator: ", "))
            ProvisionInfoRow(label: .localized("Team Name"), value: cert.TeamName)
            ProvisionInfoRow(label: .localized("App ID Name"), value: cert.AppIDName)
            ProvisionInfoRow(label: .localized("UUID"), value: cert.UUID)
            ProvisionInfoRow(label: .localized("Created"), value: cert.CreationDate.formatted())
            ProvisionInfoRow(label: .localized("Expires"), value: cert.ExpirationDate.formatted())
        }
    }
}

private struct ProvisionCapabilitiesSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cert: Certificate

    var body: some View {
        Section(.localized("Capabilities")) {
            ProvisionInfoRow(label: .localized("Device Count"), value: cert.ProvisionsAllDevices == true ? "Unlimited" : "\(cert.ProvisionedDevices?.count ?? 0)")
            ProvisionInfoRow(label: .localized("Platform"), value: cert.Platform.joined(separator: ", "))
        }
    }
}

private struct ProvisionEntitlementsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entitlements: [String: AnyCodable]

    var body: some View {
        Section(.localized("Entitlements")) {
            ForEach(entitlements.keys.sorted(), id: \.self) { key in
                ProvisionEntitlementRow(key: key, value: entitlements[key])
            }
        }
    }
}

private struct ProvisionEntitlementRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let key: String
    let value: AnyCodable?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
                .themedText(.secondary)
            Text(value.map { String(describing: $0.value) } ?? "")
                .font(.system(.body, design: .monospaced))
                .themedText(.primary)
        }
    }
}

private struct ProvisionInfoRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .themedText(.secondary)
            Spacer()
            Text(value)
                .themedText(.primary)
                .textSelection(.enabled)
        }
    }
}
