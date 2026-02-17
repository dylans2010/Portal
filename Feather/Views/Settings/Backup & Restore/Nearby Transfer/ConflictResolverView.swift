import SwiftUI
import NimbleViews
import CoreData

// MARK: - Conflict Resolution Strategy
enum ConflictResolution {
    case keepLocal
    case replace
    case duplicate
}

// MARK: - Conflict Item
struct ConflictItem: Identifiable {
    let id = UUID()
    let type: ConflictType
    let localName: String
    let incomingName: String
    let localDetails: String
    let incomingDetails: String
    let path: String
    var resolution: ConflictResolution = .keepLocal
}

enum ConflictType {
    case certificate
    case preset
    case bundleID
    case source
    
    var icon: String {
        switch self {
        case .certificate: return "doc.text.fill"
        case .preset: return "slider.horizontal.3"
        case .bundleID: return "app.fill"
        case .source: return "link.circle.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .certificate: return "Certificate"
        case .preset: return "Preset"
        case .bundleID: return "Bundle ID"
        case .source: return "Source"
        }
    }
}

// MARK: - Conflict Resolver View
struct ConflictResolverView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ConflictResolverViewModel()
    
    var backupDirectory: URL
    var onResolve: ([ConflictItem]) -> Void
    
    var body: some View {
        NBList(.localized("Resolve Conflicts")) {
            // Summary Section
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    
                    Text("\(viewModel.conflicts.count) Conflict\(viewModel.conflicts.count == 1 ? "" : "s") Detected")
                        .font(.headline)
                    
                    Text("Choose how to handle duplicate items.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } header: {
                AppearanceSectionHeader(title: String.localized("Status"), icon: "exclamationmark.shield.fill")
            }
            
            // Conflicts List
            if viewModel.isScanning {
                Section {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Scanning For Conflicts")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 16)
                }
            } else {
                ForEach($viewModel.conflicts) { $conflict in
                    ConflictItemSection(conflict: $conflict)
                }
            }
            
            // Action Buttons
            if !viewModel.isScanning && !viewModel.conflicts.isEmpty {
                Section {
                    Button {
                        viewModel.applyToAll(.keepLocal)
                    } label: {
                        HStack {
                            Image(systemName: "square.stack.fill")
                            Text("Keep All Local")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        viewModel.applyToAll(.replace)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Replace All")
                        }
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Quick Actions"), icon: "bolt.fill")
                }
                
                Section {
                    Button {
                        onResolve(viewModel.conflicts)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Resolutions")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    Text("Your choices will be applied during the restoration process.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Conflicts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.scanForConflicts(backupDirectory: backupDirectory)
        }
    }
}

// MARK: - Conflict Item Section
struct ConflictItemSection: View {
    @Binding var conflict: ConflictItem
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: conflict.type.icon)
                        .foregroundStyle(.orange)
                    Text(conflict.type.displayName)
                        .font(.headline)
                    Spacer()
                }
                
                // Local vs Incoming
                VStack(spacing: 12) {
                    // Local
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current (Local)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(conflict.localName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(conflict.localDetails)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // VS Indicator
                    Text("VS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Incoming
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backup (Incoming)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(conflict.incomingName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(conflict.incomingDetails)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Resolution Picker
                Picker("Resolution", selection: $conflict.resolution) {
                    Label("Keep Local", systemImage: "square.fill").tag(ConflictResolution.keepLocal)
                    Label("Replace", systemImage: "arrow.triangle.2.circlepath").tag(ConflictResolution.replace)
                    Label("Keep Both", systemImage: "square.on.square.fill").tag(ConflictResolution.duplicate)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Conflict Resolver View Model
class ConflictResolverViewModel: ObservableObject {
    @Published var conflicts: [ConflictItem] = []
    @Published var isScanning: Bool = true
    
    func scanForConflicts(backupDirectory: URL) {
        isScanning = true
        
        Task {
            // Simulate scanning delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                detectConflicts(backupDirectory: backupDirectory)
                isScanning = false
            }
        }
    }
    
    private func detectConflicts(backupDirectory: URL) {
        var detectedConflicts: [ConflictItem] = []
        let fileManager = FileManager.default
        
        // 1. Check Certificate Conflicts (by fingerprint)
        let certsSourceDir = backupDirectory.appendingPathComponent("certificates")
        if fileManager.fileExists(atPath: certsSourceDir.path) {
            let localCerts = Storage.shared.getAllCertificates()
            
            // Create a set of local certificate fingerprints/identifiers
            let localCertIds = Set(localCerts.compactMap { $0.uuid })
            
            // Check incoming certificates
            if let incomingCerts = try? fileManager.contentsOfDirectory(at: certsSourceDir, includingPropertiesForKeys: nil) {
                for incomingCert in incomingCerts where incomingCert.pathExtension == "p12" {
                    let certName = incomingCert.deletingPathExtension().lastPathComponent
                    
                    // Check if this cert ID already exists locally
                    if localCertIds.contains(certName) {
                        // Find the local cert details
                        if let localCert = localCerts.first(where: { $0.uuid == certName }) {
                            let localDetails = getProvisionDetails(for: localCert)
                            
                            detectedConflicts.append(ConflictItem(
                                type: .certificate,
                                localName: localDetails.name,
                                incomingName: certName,
                                localDetails: "Expires: \(localDetails.expiration)",
                                incomingDetails: "From Backup",
                                path: "certificates/\(certName).p12",
                                resolution: .keepLocal
                            ))
                        }
                    }
                }
            }
        }
        
        // 2. Check Bundle ID Conflicts in Signed Apps
        let signedSourceDir = backupDirectory.appendingPathComponent("signed_apps")
        if fileManager.fileExists(atPath: signedSourceDir.path) {
            let localSignedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
            let localBundleIds = Set(localSignedApps.compactMap { $0.identifier })
            
            // Load metadata from backup
            let metadataPath = backupDirectory.appendingPathComponent("signed_apps_metadata.json")
            if let metadataData = try? Data(contentsOf: metadataPath),
               let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [[String: String]] {
                
                for app in metadata {
                    if let bundleId = app["identifier"], localBundleIds.contains(bundleId) {
                        // Find local app with same bundle ID
                        if let localApp = localSignedApps.first(where: { $0.identifier == bundleId }) {
                            detectedConflicts.append(ConflictItem(
                                type: .bundleID,
                                localName: localApp.name ?? "Unknown",
                                incomingName: app["name"] ?? "Unknown",
                                localDetails: "Version: \(localApp.version ?? "Unknown")",
                                incomingDetails: "Version: \(app["version"] ?? "Unknown")",
                                path: "signed_apps/\(bundleId)",
                                resolution: .keepLocal
                            ))
                        }
                    }
                }
            }
        }
        
        // 3. Check Source Conflicts (by URL)
        let sourcesPath = backupDirectory.appendingPathComponent("sources.json")
        if fileManager.fileExists(atPath: sourcesPath.path) {
            let localSources = Storage.shared.getSources()
            let localSourceUrls = Set(localSources.compactMap { $0.sourceURL?.absoluteString })
            
            if let sourcesData = try? Data(contentsOf: sourcesPath),
               let incomingSources = try? JSONSerialization.jsonObject(with: sourcesData) as? [[String: String]] {
                
                for source in incomingSources {
                    if let url = source["url"], localSourceUrls.contains(url) {
                        if let localSource = localSources.first(where: { $0.sourceURL?.absoluteString == url }) {
                            detectedConflicts.append(ConflictItem(
                                type: .source,
                                localName: localSource.name ?? "Unknown",
                                incomingName: source["name"] ?? "Unknown",
                                localDetails: localSource.identifier ?? "",
                                incomingDetails: source["identifier"] ?? "",
                                path: "sources/\(source["identifier"] ?? url)",
                                resolution: .keepLocal
                            ))
                        }
                    }
                }
            }
        }
        
        self.conflicts = detectedConflicts
    }
    
    private func getProvisionDetails(for cert: CertificatePair) -> (name: String, expiration: String) {
        if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
            let name = provisionData.Name
            let expiration = provisionData.ExpirationDate.formatted(
                date: Date.FormatStyle.DateStyle.abbreviated,
                time: Date.FormatStyle.TimeStyle.omitted
            )
            return (name, expiration)
        }
        return ("Unknown", "Unknown")
    }
    
    func applyToAll(_ resolution: ConflictResolution) {
        for index in conflicts.indices {
            conflicts[index].resolution = resolution
        }
    }
}
