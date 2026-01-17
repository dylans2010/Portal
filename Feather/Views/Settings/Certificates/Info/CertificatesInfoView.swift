import SwiftUI
import NimbleViews
import ZsignSwift
import OSLog

// MARK: - Entitlement Mapping Helper
struct EntitlementMapping {
    static func humanReadableName(for entitlement: String) -> String {
        let mappings: [String: String] = [
            "com.apple.developer.applesignin": "Sign in with Apple",
            "com.apple.developer.associated-domains": "Associated Domains",
            "com.apple.developer.authentication-services.autofill-credential-provider": "AutoFill Credential Provider",
            "com.apple.developer.default-data-protection": "Default Data Protection",
            "com.apple.developer.healthkit": "HealthKit",
            "com.apple.developer.homekit": "HomeKit",
            "com.apple.developer.icloud-container-identifiers": "iCloud Container Identifiers",
            "com.apple.developer.icloud-services": "iCloud Services",
            "com.apple.developer.in-app-payments": "In-App Payments",
            "com.apple.developer.networking.wifi-info": "Wi-Fi Information",
            "com.apple.developer.networking.networkextension": "Network Extension",
            "com.apple.developer.networking.vpn.api": "VPN API",
            "com.apple.developer.nfc.readersession.formats": "NFC Reader Session",
            "com.apple.developer.pass-type-identifiers": "Pass Type Identifiers",
            "com.apple.developer.siri": "Siri",
            "com.apple.developer.usernotifications.filtering": "User Notifications Filtering",
            "com.apple.developer.usernotifications.time-sensitive": "Time Sensitive Notifications",
            "com.apple.external-accessory.wireless-configuration": "External Accessory Wireless Configuration",
            "com.apple.security.application-groups": "App Groups",
            "keychain-access-groups": "Keychain Access Groups",
            "aps-environment": "Push Notifications",
            "com.apple.developer.game-center": "Game Center",
            "com.apple.developer.maps": "Maps",
            "com.apple.developer.ClassKit-environment": "ClassKit",
            "com.apple.developer.devicecheck.appattest-environment": "App Attest",
            "com.apple.developer.kernel.extended-virtual-addressing": "Extended Virtual Addressing",
            "com.apple.developer.networking.multipath": "Multipath Networking",
            "com.apple.developer.associated-domains.mdm-managed": "MDM Managed Associated Domains",
            "com.apple.developer.automatic-assessment-configuration": "Automatic Assessment Configuration",
            "com.apple.developer.group-session": "Group Activities",
            "com.apple.developer.contacts.notes": "Contacts Notes",
            "com.apple.developer.shared-with-you": "Shared with You",
            "com.apple.developer.family-controls": "Family Controls",
            "com.apple.developer.proximity-reader.payment.acceptance": "Tap to Pay on iPhone",
            "inter-app-audio": "Inter-App Audio",
            "com.apple.developer.carplay-audio": "CarPlay Audio",
            "com.apple.developer.carplay-communication": "CarPlay Communication",
            "com.apple.developer.carplay-messaging": "CarPlay Messaging",
            "com.apple.developer.carplay-navigation": "CarPlay Navigation",
            "com.apple.developer.carplay-parking": "CarPlay Parking",
            "com.apple.developer.carplay-playback": "CarPlay Playback",
            "com.apple.developer.coremedia.hls.low-latency": "Low Latency HLS",
            "com.apple.developer.weatherkit": "WeatherKit"
        ]
        return mappings[entitlement] ?? entitlement
    }
}

// MARK: - Clean Certificate Info View
struct CertificatesInfoView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("feature_usePortalCert") private var usePortalCert = false
    @State private var data: Certificate?
    @State private var isEntitlementsExpanded = false
    @State private var isDevicesExpanded = false
    @State private var appearAnimation = false
    @State private var showExportSheet = false
    @State private var exportedFileURL: URL?
    
    var cert: CertificatePair
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let data = data {
                        // Header Card
                        headerCard(data: data)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 15)
                        
                        // Status Badges
                        statusBadges(data: data)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                        
                        // Info Cards
                        infoSection(data: data)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                        
                        // Validity Card
                        validityCard(data: data)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                        
                        // Devices (if available)
                        if let devices = data.ProvisionedDevices, !devices.isEmpty {
                            devicesCard(devices: devices)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 10)
                        }
                        
                        // Entitlements (if available)
                        if let entitlements = data.Entitlements, !entitlements.isEmpty {
                            entitlementsCard(entitlements: entitlements)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 10)
                        }
                        
                        // Actions
                        actionsCard()
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 10)
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Certificate Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            data = Storage.shared.getProvisionFileDecoded(for: cert)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Header Card
    private func headerCard(data: Certificate) -> some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: statusGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: statusGradientColors[0].opacity(0.4), radius: 10, x: 0, y: 5)
            
            // Name & App ID
            VStack(spacing: 6) {
                Text(cert.nickname ?? data.Name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(data.AppIDName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Status Badges
    private func statusBadges(data: Certificate) -> some View {
        HStack(spacing: 10) {
            // Active/Revoked
            statusBadge(
                title: cert.revoked == true ? "Revoked" : "Active",
                icon: cert.revoked == true ? "xmark.circle.fill" : "checkmark.circle.fill",
                color: cert.revoked == true ? .red : .green
            )
            
            // PPQ Check
            if let ppq = data.PPQCheck {
                statusBadge(
                    title: ppq ? "PPQ Check" : "No PPQ",
                    icon: ppq ? "exclamationmark.shield.fill" : "shield.fill",
                    color: ppq ? .orange : .green
                )
            }
            
            Spacer()
        }
    }
    
    private func statusBadge(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Info Section
    private func infoSection(data: Certificate) -> some View {
        VStack(spacing: 0) {
            infoRow(icon: "person.3.fill", title: "Team", value: data.TeamName, color: .blue)
            Divider().padding(.leading, 50)
            infoRow(icon: "number", title: "Team ID", value: data.TeamIdentifier.first ?? "-", color: .purple)
            Divider().padding(.leading, 50)
            infoRow(icon: "barcode", title: "UUID", value: String(data.UUID.prefix(12)) + "...", color: .indigo)
            
            if !data.Platform.isEmpty {
                Divider().padding(.leading, 50)
                infoRow(icon: "iphone", title: "Platforms", value: data.Platform.joined(separator: ", "), color: .cyan)
            }
        }
        .background(cardBackground)
    }
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 26)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Validity Card
    private func validityCard(data: Certificate) -> some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Validity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            // Timeline
            HStack(spacing: 16) {
                // Created
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(data.CreationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Progress Ring
                progressRing(data: data)
                
                Spacer()
                
                // Expires
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expires")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(data.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(expirationColor(for: data.ExpirationDate))
                }
            }
            
            // Remaining time
            Text(data.ExpirationDate.expirationInfo().formatted)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(expirationColor(for: data.ExpirationDate))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private func progressRing(data: Certificate) -> some View {
        let progress = calculateProgress(created: data.CreationDate, expires: data.ExpirationDate)
        let color = progressColor(for: progress)
        
        return ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Devices Card
    private func devicesCard(devices: [String]) -> some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDevicesExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "iphone")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.cyan)
                    Text("Provisioned Devices")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(devices.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.cyan))
                    
                    Image(systemName: isDevicesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            
            // Device list
            if isDevicesExpanded {
                Divider()
                VStack(spacing: 0) {
                    ForEach(devices.prefix(10), id: \.self) { device in
                        HStack {
                            Text(device)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    if devices.count > 10 {
                        Text("+ \(devices.count - 10) more devices")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .background(cardBackground)
    }
    
    // MARK: - Entitlements Card
    private func entitlementsCard(entitlements: [String: Any]) -> some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isEntitlementsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.purple)
                    Text("Entitlements")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(entitlements.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.purple))
                    
                    Image(systemName: isEntitlementsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            
            // Entitlements list
            if isEntitlementsExpanded {
                Divider()
                VStack(spacing: 0) {
                    ForEach(Array(entitlements.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(EntitlementMapping.humanReadableName(for: key))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        if key != entitlements.keys.sorted().last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(cardBackground)
    }
    
    // MARK: - Actions Card
    private func actionsCard() -> some View {
        VStack(spacing: 10) {
            actionButton(
                icon: "doc.badge.arrow.up",
                title: "Open P12 in Files",
                action: {
                    if let p12URL = Storage.shared.getFile(.certificate, from: cert) {
                        UIApplication.shared.open(p12URL)
                    }
                }
            )
            
            actionButton(
                icon: "doc.badge.gearshape",
                title: "Open Provision in Files",
                action: {
                    if let provisionURL = Storage.shared.getFile(.provision, from: cert) {
                        UIApplication.shared.open(provisionURL)
                    }
                }
            )
            
            // Show export to .portalcert only when feature flag is enabled
            if usePortalCert {
                exportPortalCertButton
            }
        }
    }
    
    // MARK: - Export Portal Cert Button
    private var exportPortalCertButton: some View {
        Button {
            exportToPortalCert()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.indigo)
                
                Text("Export as .portalcert")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.indigo)
            }
            .padding(14)
            .background(cardBackground)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(urls: [url])
            }
        }
    }
    
    // MARK: - Export to Portal Cert
    private func exportToPortalCert() {
        Logger.misc.info("[PortalCert Export] Starting export for certificate: \(cert.nickname ?? "Unknown")")
        
        do {
            let outputDir = FileManager.default.temporaryDirectory
            let exportedURL = try PortalCertHandler.exportCertificate(cert, to: outputDir)
            
            Logger.misc.info("[PortalCert Export] Successfully exported to: \(exportedURL.path)")
            
            exportedFileURL = exportedURL
            showExportSheet = true
            
            HapticsManager.shared.success()
        } catch {
            Logger.misc.error("[PortalCert Export] Failed: \(error.localizedDescription)")
            
            UIAlertController.showAlertWithOk(
                title: .localized("Export Failed"),
                message: error.localizedDescription
            )
        }
    }
    
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(cardBackground)
        }
    }
    
    // MARK: - Helpers
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private var statusIcon: String {
        if cert.revoked == true {
            return "xmark.seal.fill"
        } else if cert.ppQCheck == true {
            return "exclamationmark.shield.fill"
        } else {
            return "checkmark.seal.fill"
        }
    }
    
    private var statusGradientColors: [Color] {
        if cert.revoked == true {
            return [.red, .red.opacity(0.7)]
        } else if cert.ppQCheck == true {
            return [.orange, .orange.opacity(0.7)]
        } else {
            return [.green, .green.opacity(0.7)]
        }
    }
    
    private func calculateProgress(created: Date, expires: Date) -> Double {
        let total = expires.timeIntervalSince(created)
        let elapsed = Date().timeIntervalSince(created)
        return min(max(elapsed / total, 0), 1)
    }
    
    private func progressColor(for progress: Double) -> Color {
        if progress > 0.75 { return .red }
        else if progress > 0.5 { return .orange }
        else { return .green }
    }
    
    private func expirationColor(for date: Date) -> Color {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysRemaining < 7 { return .red }
        else if daysRemaining < 30 { return .orange }
        else { return .green }
    }
    
    private func platformIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "ios": return "iphone"
        case "macos": return "desktopcomputer"
        case "tvos": return "appletv"
        case "watchos": return "applewatch"
        default: return "app"
        }
    }
}
