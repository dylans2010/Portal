import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct IPAIntegrityCheckerView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var integrityResults: IntegrityResults?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    struct IntegrityResults {
        let fileName: String
        let fileSize: String
        let bundleID: String?
        let isValidZip: Bool
        let hasPayloadFolder: Bool
        let hasAppBundle: Bool
        let hasValidInfoPlist: Bool
        let hasValidProvisioning: Bool
        let provisioningExpired: Bool
        let provisioningExpiryDate: Date?
        let hasCodeSignature: Bool
        let frameworksCount: Int
        let dylibsCount: Int
        let pluginsCount: Int
        let warnings: [String]
        let errors: [String]
        let suggestions: [String]
    }

    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import IPA")) {
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

            // Results Section
            if let results = integrityResults {
                // Basic Info
                Section(header: Text("File Information")) {
                    LabeledContent("File Name", value: results.fileName)
                    LabeledContent("File Size", value: results.fileSize)
                    if let bundleID = results.bundleID {
                        LabeledContent("Bundle ID", value: bundleID)
                    }
                }

                // Integrity Checks
                Section(header: Text("Integrity Checks")) {
                    CheckRow(label: "Valid ZIP Archive", passed: results.isValidZip)
                    CheckRow(label: "Has Payload Folder", passed: results.hasPayloadFolder)
                    CheckRow(label: "Has .app Bundle", passed: results.hasAppBundle)
                    CheckRow(label: "Valid Info.plist", passed: results.hasValidInfoPlist)
                    CheckRow(label: "Has Provisioning Profile", passed: results.hasValidProvisioning)
                    if results.hasValidProvisioning {
                        CheckRow(label: "Provisioning Not Expired", passed: !results.provisioningExpired)
                        if let expiryDate = results.provisioningExpiryDate {
                            LabeledContent("Expires", value: expiryDate.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    CheckRow(label: "Has Code Signature", passed: results.hasCodeSignature)
                }

                // Content Analysis
                Section(header: Text("Content Analysis")) {
                    LabeledContent("Frameworks", value: "\(results.frameworksCount)")
                    LabeledContent("Dynamic Libraries", value: "\(results.dylibsCount)")
                    LabeledContent("Plugins/Extensions", value: "\(results.pluginsCount)")
                }

                // Warnings
                if !results.warnings.isEmpty {
                    Section(header: Text("Warnings")) {
                        ForEach(results.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Errors
                if !results.errors.isEmpty {
                    Section(header: Text("Errors")) {
                        ForEach(results.errors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Suggestions
                if !results.suggestions.isEmpty {
                    Section(header: Text("Suggestions")) {
                        ForEach(results.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Overall Status
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: overallStatus.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(overallStatus.color)
                            Text(overallStatus.message)
                                .font(.headline)
                                .foregroundStyle(overallStatus.color)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Integrity Checker")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIntegrity(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }

    private var overallStatus: (icon: String, color: Color, message: String) {
        guard let results = integrityResults else {
            return ("questionmark.circle", .gray, "No Analysis Yet")
        }

        if !results.errors.isEmpty {
            return ("xmark.circle.fill", .red, "Integrity Issues Found")
        } else if !results.warnings.isEmpty {
            return ("exclamationmark.triangle.fill", .orange, "Minor Issues Detected")
        } else {
            return ("checkmark.circle.fill", .green, "All Checks Passed")
        }
    }

    private func analyzeIntegrity(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        integrityResults = nil

        Task {
            do {
                let results = try await performIntegrityChecks(url: url)
                await MainActor.run {
                    integrityResults = results
                    isAnalyzing = false

                    if results.errors.isEmpty && results.warnings.isEmpty {
                        ToastManager.shared.show("✅ IPA integrity verified", type: .success)
                        AppLogManager.shared.success("IPA integrity verified: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else if !results.errors.isEmpty {
                        ToastManager.shared.show("❌ IPA integrity issues found", type: .error)
                        AppLogManager.shared.error("IPA integrity issues found: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else {
                        ToastManager.shared.show("⚠️ IPA Has Warnings", type: .warning)
                        AppLogManager.shared.warning("IPA Has Warnings: \(url.lastPathComponent)", category: "Integrity Checker")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    ToastManager.shared.show("❌ Failed To Analyze IPA", type: .error)
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "Integrity Checker")
                }
            }
        }
    }

    private static let maxProvisioningFileSize: Int64 = 10 * 1024 * 1024 // 10 MB limit
    private static let provisioningWarningDays: TimeInterval = 7 * 24 * 3600 // 7 days

    private func performIntegrityChecks(url: URL) async throws -> IntegrityResults {
        let fileManager = FileManager.default

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IntegrityChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied due to iOS restrictions."])
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)

        var warnings: [String] = []
        var errors: [String] = []
        var suggestions: [String] = []

        // Check if it's a valid ZIP
        var isValidZip = true
        var hasPayloadFolder = false
        var hasAppBundle = false
        var hasValidInfoPlist = false
        var hasValidProvisioning = false
        var provisioningExpired = false
        var provisioningExpiryDate: Date? = nil
        var hasCodeSignature = false
        var bundleID: String? = nil
        var frameworksCount = 0
        var dylibsCount = 0
        var pluginsCount = 0

        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Extract IPA (using ZIPFoundation extension)
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            isValidZip = false
            errors.append("Failed to extract IPA: Not a valid ZIP archive")
            throw error
        }

        // Check for Payload folder
        let payloadDir = tempDir.appendingPathComponent("Payload")
        hasPayloadFolder = fileManager.fileExists(atPath: payloadDir.path)

        if !hasPayloadFolder {
            errors.append("Missing Payload folder")
        } else {
            // Find .app bundle
            if let appBundle = try? fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) {
                hasAppBundle = true

                // Check Info.plist
                let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
                if let plistData = try? Data(contentsOf: infoPlistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                    hasValidInfoPlist = true
                    bundleID = plist["CFBundleIdentifier"] as? String

                    if bundleID == nil {
                        warnings.append("Info.plist Missing CFBundleIdentifier")
                    }
                } else {
                    errors.append("Invalid or missing Info.plist")
                }

                // Check provisioning profile with size limits
                let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
                if fileManager.fileExists(atPath: provisioningURL.path) {
                    // Check file size before loading
                    if let provisioningAttrs = try? fileManager.attributesOfItem(atPath: provisioningURL.path),
                       let provisioningSize = provisioningAttrs[.size] as? Int64,
                       provisioningSize <= Self.maxProvisioningFileSize {
                        hasValidProvisioning = true

                        // Parse provisioning profile
                        if let data = try? Data(contentsOf: provisioningURL),
                           let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8),
                           let plistStart = dataString.range(of: "<?xml"),
                           let plistEnd = dataString.range(of: "</plist>") {
                            let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
                            if let plistData = plistString.data(using: .utf8),
                               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                                if let expirationDate = plist["ExpirationDate"] as? Date {
                                    provisioningExpiryDate = expirationDate
                                    provisioningExpired = expirationDate < Date()

                                    if provisioningExpired {
                                        errors.append("Provisioning profile has expired")
                                    } else if expirationDate.timeIntervalSinceNow < Self.provisioningWarningDays {
                                        warnings.append("Provisioning Profile Expires Soon")
                                    }
                                }
                            }
                        }
                    } else {
                        warnings.append("Provisioning profile file too large or invalid")
                    }
                } else {
                    warnings.append("No Embedded Provisioning Profile Found")
                }

                // Check code signature
                let codeSignatureDir = appBundle.appendingPathComponent("_CodeSignature")
                hasCodeSignature = fileManager.fileExists(atPath: codeSignatureDir.path)

                if !hasCodeSignature {
                    warnings.append("No Code Signature Found")
                    suggestions.append("Sign the IPA before installation")
                }

                // Count frameworks
                let frameworksDir = appBundle.appendingPathComponent("Frameworks")
                if fileManager.fileExists(atPath: frameworksDir.path) {
                    if let frameworks = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                        frameworksCount = frameworks.filter { $0.pathExtension == "framework" }.count
                    }
                }

                // Count dylibs (may be injected tweaks or legitimate dependencies)
                if let files = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
                    dylibsCount = files.filter { $0.pathExtension == "dylib" }.count

                    if dylibsCount > 0 {
                        warnings.append("Found \(dylibsCount) dynamic libraries (may be tweaks or legitimate dependencies)")
                    }
                }

                // Count plugins
                let pluginsDir = appBundle.appendingPathComponent("PlugIns")
                if fileManager.fileExists(atPath: pluginsDir.path) {
                    if let plugins = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                        pluginsCount = plugins.count
                    }
                }
            } else {
                errors.append("No .app bundle found in Payload folder")
            }
        }

        // Add suggestions based on findings
        if !hasValidProvisioning {
            suggestions.append("Add a valid provisioning profile before installation")
        }

        if errors.isEmpty && warnings.isEmpty {
            suggestions.append("IPA appears to be valid and ready for installation")
        }

        return IntegrityResults(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            bundleID: bundleID,
            isValidZip: isValidZip,
            hasPayloadFolder: hasPayloadFolder,
            hasAppBundle: hasAppBundle,
            hasValidInfoPlist: hasValidInfoPlist,
            hasValidProvisioning: hasValidProvisioning,
            provisioningExpired: provisioningExpired,
            provisioningExpiryDate: provisioningExpiryDate,
            hasCodeSignature: hasCodeSignature,
            frameworksCount: frameworksCount,
            dylibsCount: dylibsCount,
            pluginsCount: pluginsCount,
            warnings: warnings,
            errors: errors,
            suggestions: suggestions
        )
    }
}
