import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct IPAInspectorView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var ipaInfo: IPAInfo?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showFileBrowser = false
    @State private var selectedTab = 0

    struct IPAInfo {
        let fileName: String
        let fileSize: String
        let infoPlist: [String: Any]?
        let bundleID: String?
        let version: String?
        let buildNumber: String?
        let displayName: String?
        let minIOSVersion: String?
        let dylibs: [String]
        let frameworks: [String]
        let plugins: [String]
        let entitlements: [String: Any]?
        let provisioning: ProvisioningInfo?
        let fileStructure: [String]
        let appIconData: Data?
        let limitations: [String]
        // New binary analysis fields
        let binaryInfo: MachOAnalyzer.BinaryInfo?
        let signatureInfo: CodeSignatureAnalyzer.SignatureInfo?
        let executableName: String?
        let supportedArchitectures: [String]
        let isEncrypted: Bool
        let linkedFrameworks: [String]
        let weakLinkedFrameworks: [String]
        let embeddedBinaries: [String]
    }

    struct ProvisioningInfo {
        let teamName: String?
        let teamID: String?
        let expirationDate: Date?
        let appIDName: String?
        let provisionedDevices: [String]?
        let entitlements: [String: Any]?
    }

    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import")) {
                Button(action: { isImporting = true }) {
                    HStack {
                        Image(systemName: "doc.zipper")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select IPA File")
                                .font(.headline)
                            if let file = selectedFile {
                                Text(file.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No File Selected")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if isAnalyzing {
                            ProgressView()
                        }
                    }
                }
            }

            // Error Section
            if let error = errorMessage {
                Section(header: Text("Error")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Basic Info Section
            if let info = ipaInfo {
                // App Icon Section (if available)
                if let iconData = info.appIconData, let iconImage = UIImage(data: iconData) {
                    Section {
                        HStack {
                            Spacer()
                            Image(uiImage: iconImage)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 4)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                Section(header: Text("Basic Information")) {
                    DeveloperInfoRow(label: "File Name", value: info.fileName)
                    DeveloperInfoRow(label: "File Size", value: info.fileSize)
                    if let bundleID = info.bundleID {
                        DeveloperInfoRow(label: "Bundle ID", value: bundleID)
                    }
                    if let displayName = info.displayName {
                        DeveloperInfoRow(label: "App Name", value: displayName)
                    }
                    if let version = info.version {
                        DeveloperInfoRow(label: "Version", value: version)
                    }
                    if let buildNumber = info.buildNumber {
                        DeveloperInfoRow(label: "Build Number", value: buildNumber)
                    }
                    if let minVersion = info.minIOSVersion {
                        DeveloperInfoRow(label: "Min iOS", value: minVersion)
                    }
                }

                // Provisioning Profile Section
                if let provisioning = info.provisioning {
                    Section(header: Text("Provisioning Profile")) {
                        if let teamName = provisioning.teamName {
                            DeveloperInfoRow(label: "Team Name", value: teamName)
                        }
                        if let teamID = provisioning.teamID {
                            DeveloperInfoRow(label: "Team ID", value: teamID)
                        }
                        if let appIDName = provisioning.appIDName {
                            DeveloperInfoRow(label: "App ID Name", value: appIDName)
                        }
                        if let expirationDate = provisioning.expirationDate {
                            DeveloperInfoRow(
                                label: "Expires",
                                value: {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .medium
                                    formatter.timeStyle = .short
                                    return formatter.string(from: expirationDate)
                                }()
                            )
                        }
                        if let devices = provisioning.provisionedDevices {
                            NavigationLink(destination: ListDetailView(items: devices, title: "Provisioned Devices")) {
                                HStack {
                                    Image(systemName: "iphone")
                                        .foregroundStyle(.blue)
                                    Text("\(devices.count) Devices")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // Info.plist Section
                if let plist = info.infoPlist, !plist.isEmpty {
                    Section(header: Text("Info.plist")) {
                        NavigationLink(destination: PlistViewer(dictionary: plist, title: "Info.plist")) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)
                                Text("\(plist.count) entries")
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // Dynamic Libraries Section
                if !info.dylibs.isEmpty {
                    Section(header: Text("Dynamic Libraries (\(info.dylibs.count))"), footer: Text("Detected .dylib files that may be injected into the app.")) {
                        ForEach(info.dylibs.prefix(10), id: \.self) { dylib in
                            HStack {
                                Image(systemName: "cube.box")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                Text(dylib)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.dylibs.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.dylibs, title: "All Dynamic Libraries")) {
                                Text("View All \(info.dylibs.count) Libraries")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // Frameworks Section
                if !info.frameworks.isEmpty {
                    Section(header: Text("Frameworks (\(info.frameworks.count))")) {
                        ForEach(info.frameworks.prefix(10), id: \.self) { framework in
                            HStack {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(framework)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.frameworks.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.frameworks, title: "All Frameworks")) {
                                Text("View All \(info.frameworks.count) Frameworks")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // Plugins Section
                if !info.plugins.isEmpty {
                    Section(header: Text("Plugins/Extensions (\(info.plugins.count))")) {
                        ForEach(info.plugins, id: \.self) { plugin in
                            HStack {
                                Image(systemName: "puzzlepiece.extension")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(plugin)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                // Entitlements Section
                if let entitlements = info.entitlements, !entitlements.isEmpty {
                    Section(header: Text("Entitlements (From Provisioning Profile)"), footer: Text("Entitlements declared in the embedded provisioning profile.")) {
                        NavigationLink(destination: PlistViewer(dictionary: entitlements, title: "Entitlements")) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundStyle(.green)
                                Text("\(entitlements.count) Entitlements")
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // File Structure Section
                if !info.fileStructure.isEmpty {
                    Section(header: Text("File Structure (\(info.fileStructure.count) Files)")) {
                        ForEach(info.fileStructure.prefix(15), id: \.self) { file in
                            HStack {
                                Image(systemName: fileIcon(for: file))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(file)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.fileStructure.count > 15 {
                            NavigationLink(destination: ListDetailView(items: info.fileStructure, title: "All Files")) {
                                Text("View All \(info.fileStructure.count) Files")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // Limitations Section
                Section(header: Text("Limitations"), footer: Text("Some advanced analysis features require macOS command-line tools or specialized security frameworks not available in the iOS sandbox.")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("iOS On Device Limitations")
                                .font(.subheadline.bold())
                        }

                        ForEach(info.limitations, id: \.self) { limitation in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(limitation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("IPA Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIPA(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }

    private func analyzeIPA(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        ipaInfo = nil

        AppLogManager.shared.info("Analyzing IPA: \(url.lastPathComponent)", category: "IPA Inspector")

        Task {
            do {
                let info = try await extractIPAInfo(from: url)
                await MainActor.run {
                    ipaInfo = info
                    isAnalyzing = false
                    AppLogManager.shared.success("Successfully Analyzed IPA: \(url.lastPathComponent)", category: "IPA Inspector")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "IPA Inspector")
                }
            }
        }
    }

    private func extractIPAInfo(from url: URL) async throws -> IPAInfo {
        let fileManager = FileManager.default

        // Start accessing security-scoped resource FIRST
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IPAInspector", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied."])
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)

        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Extract IPA using ZIPFoundation
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            throw NSError(domain: "IPAInspector", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract IPA: \(error.localizedDescription)"])
        }

        // Find .app bundle in Payload directory
        let payloadDir = tempDir.appendingPathComponent("Payload")
        guard let appBundle = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPAInspector", code: -1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found in IPA"])
        }

        // Parse Info.plist
        let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
        var infoPlist: [String: Any]?
        var bundleID: String?
        var version: String?
        var buildNumber: String?
        var displayName: String?
        var minIOSVersion: String?

        if let plistData = try? Data(contentsOf: infoPlistURL),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            infoPlist = plist
            bundleID = plist["CFBundleIdentifier"] as? String
            version = plist["CFBundleShortVersionString"] as? String
            buildNumber = plist["CFBundleVersion"] as? String
            displayName = plist["CFBundleDisplayName"] as? String ?? plist["CFBundleName"] as? String
            minIOSVersion = plist["MinimumOSVersion"] as? String
        }

        // Find dynamic libraries (.dylib files in main bundle)
        var dylibs: [String] = []
        if let dylibFiles = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
            dylibs = dylibFiles.filter { $0.pathExtension == "dylib" }.map { $0.lastPathComponent }
        }

        // Find frameworks
        var frameworks: [String] = []
        let frameworksDir = appBundle.appendingPathComponent("Frameworks")
        if fileManager.fileExists(atPath: frameworksDir.path) {
            if let frameworkFiles = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                frameworks = frameworkFiles.filter { $0.pathExtension == "framework" }.map { $0.lastPathComponent }
            }
        }

        // Find plugins/extensions
        var plugins: [String] = []
        let pluginsDir = appBundle.appendingPathComponent("PlugIns")
        if fileManager.fileExists(atPath: pluginsDir.path) {
            if let pluginFiles = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                plugins = pluginFiles.map { $0.lastPathComponent }
            }
        }

        // Extract provisioning profile information
        var provisioningInfo: ProvisioningInfo? = nil
        let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
        if fileManager.fileExists(atPath: provisioningURL.path) {
            provisioningInfo = parseProvisioningProfile(at: provisioningURL)
        }

        // Try to extract app icon
        var appIconData: Data? = nil
        if let iconFiles = infoPlist?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = iconFiles["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFileNames = primaryIcon["CFBundleIconFiles"] as? [String] {
            // Try to find the largest icon
            for iconName in iconFileNames.reversed() {
                let iconURL = appBundle.appendingPathComponent("\(iconName).png")
                if fileManager.fileExists(atPath: iconURL.path),
                   let data = try? Data(contentsOf: iconURL) {
                    appIconData = data
                    break
                }
                // Also try with @2x and @3x
                let icon2xURL = appBundle.appendingPathComponent("\(iconName)@2x.png")
                if fileManager.fileExists(atPath: icon2xURL.path),
                   let data = try? Data(contentsOf: icon2xURL) {
                    appIconData = data
                    break
                }
            }
        }

        // Get file structure
        var fileStructure: [String] = []
        if let enumerator = fileManager.enumerator(at: appBundle, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let fileURL as URL in enumerator {
                if let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, isRegularFile {
                    let relativePath = fileURL.path.replacingOccurrences(of: appBundle.path + "/", with: "")
                    fileStructure.append(relativePath)
                }
            }
        }

        // Analyze main executable binary
        var binaryInfo: MachOAnalyzer.BinaryInfo? = nil
        let signatureInfo: CodeSignatureAnalyzer.SignatureInfo? = nil
        var executableName: String? = nil
        var supportedArchitectures: [String] = []
        var isEncrypted = false
        var linkedFrameworksList: [String] = []
        let weakLinkedFrameworksList: [String] = []
        var embeddedBinaries: [String] = []

        // Get executable name from Info.plist
        if let execName = infoPlist?["CFBundleExecutable"] as? String {
            executableName = execName
            let executableURL = appBundle.appendingPathComponent(execName)

            if let execData = try? Data(contentsOf: executableURL) {
                // Analyze binary
                if let binInfo = MachOAnalyzer.analyze(data: execData) {
                    binaryInfo = binInfo
                    supportedArchitectures = binInfo.architectures
                    isEncrypted = binInfo.isEncrypted

                    // Separate system frameworks from linked libraries
                    for lib in binInfo.linkedLibraries {
                        if lib.contains(".framework") {
                            if lib.hasPrefix("/System") || lib.hasPrefix("@rpath") {
                                linkedFrameworksList.append(lib)
                            }
                        }
                    }
                }
            }
        }

        // Find embedded binaries in Frameworks folder (reuse existing frameworksDir)
        if fileManager.fileExists(atPath: frameworksDir.path) {
            if let contents = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                for item in contents {
                    if item.pathExtension == "framework" || item.pathExtension == "dylib" {
                        embeddedBinaries.append(item.lastPathComponent)
                    }
                }
            }
        }

        // Define limitations for iOS on-device inspection (now fewer with pure Swift analysis)
        let limitations = [
            "Certificate chain validation: Limited (cannot verify Apple root CA)",
            "Notarization check: Not available on iOS",
            "Full code signature verification: Partial (structure only, not cryptographic)"
        ]

        return IPAInfo(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            infoPlist: infoPlist,
            bundleID: bundleID,
            version: version,
            buildNumber: buildNumber,
            displayName: displayName,
            minIOSVersion: minIOSVersion,
            dylibs: dylibs,
            frameworks: frameworks,
            plugins: plugins,
            entitlements: provisioningInfo?.entitlements,
            provisioning: provisioningInfo,
            fileStructure: fileStructure.sorted(),
            appIconData: appIconData,
            limitations: limitations,
            binaryInfo: binaryInfo,
            signatureInfo: signatureInfo,
            executableName: executableName,
            supportedArchitectures: supportedArchitectures,
            isEncrypted: isEncrypted,
            linkedFrameworks: linkedFrameworksList,
            weakLinkedFrameworks: weakLinkedFrameworksList,
            embeddedBinaries: embeddedBinaries
        )
    }

    private func parseProvisioningProfile(at url: URL) -> ProvisioningInfo? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        // Provisioning profiles contain XML plist data between <plist> tags
        // Extract the plist portion
        guard let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            return nil
        }

        // Find plist content
        guard let plistStart = dataString.range(of: "<?xml"),
              let plistEnd = dataString.range(of: "</plist>") else {
            return nil
        }

        let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }

        let teamName = plist["TeamName"] as? String
        let teamID = (plist["TeamIdentifier"] as? [String])?.first
        let expirationDate = plist["ExpirationDate"] as? Date
        let appIDName = plist["AppIDName"] as? String
        let provisionedDevices = plist["ProvisionedDevices"] as? [String]
        let entitlements = plist["Entitlements"] as? [String: Any]

        return ProvisioningInfo(
            teamName: teamName,
            teamID: teamID,
            expirationDate: expirationDate,
            appIDName: appIDName,
            provisionedDevices: provisionedDevices,
            entitlements: entitlements
        )
    }

    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "plist": return "doc.text"
        case "png", "jpg", "jpeg": return "photo"
        case "dylib": return "cube.box"
        case "framework": return "shippingbox"
        case "nib", "storyboard", "xib": return "square.grid.3x3"
        case "strings": return "text.quote"
        case "html", "css", "js": return "globe"
        case "json", "xml": return "doc.badge.gearshape"
        default: return "doc"
        }
    }
}
