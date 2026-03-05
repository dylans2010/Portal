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
            // Header Section
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                            .ifAvailableiOS17SymbolPulse()
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(viewModel.conflicts.count) Conflicts Detected")
                            .font(.system(.title3, design: .rounded, weight: .bold))

                        Text("Multiple items in the backup match existing data. Choose how to resolve each conflict.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                AppearanceSectionHeader(title: String.localized("Status"), icon: "exclamationmark.triangle.fill")
            }
            
            // Conflicts List
            if viewModel.isScanning {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Scanning For Duplicates...")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
                }
            } else {
                ForEach($viewModel.conflicts) { $conflict in
                    ConflictItemSection(conflict: $conflict)
                }
            }
            
            // Action Buttons
            if !viewModel.isScanning && !viewModel.conflicts.isEmpty {
                Section {
                    HStack(spacing: 12) {
                        Button { viewModel.applyToAll(.keepLocal) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "square.stack.fill")
                                Text("Keep Local")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button { viewModel.applyToAll(.replace) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Replace All")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .cornerRadius(12)
                        }

                        Button { viewModel.applyToAll(.duplicate) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "square.on.square.fill")
                                Text("Keep Both")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(12)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                } header: {
                    AppearanceSectionHeader(title: String.localized("Quick Actions"), icon: "bolt.fill")
                }
                
                Section {
                    Button {
                        onResolve(viewModel.conflicts)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm & Restore")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(.headline, design: .rounded))
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .navigationTitle("Resolve Conflicts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear { viewModel.scanForConflicts(backupDirectory: backupDirectory) }
    }
}

// MARK: - Conflict Item Section
struct ConflictItemSection: View {
    @Binding var conflict: ConflictItem
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: conflict.type.icon)
                            .foregroundStyle(.orange)
                            .font(.system(size: 16))
                    }
                    Text(conflict.type.displayName)
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    comparisonRow(title: "Current (Local)", name: conflict.localName, details: conflict.localDetails, color: .secondary)
                    
                    HStack {
                        Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                        Text("VS").font(.system(.caption2, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                        Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                    }

                    comparisonRow(title: "Incoming (Backup)", name: conflict.incomingName, details: conflict.incomingDetails, color: .orange)
                }
                
                Picker("Resolution", selection: $conflict.resolution) {
                    Text("Local").tag(ConflictResolution.keepLocal)
                    Text("Replace").tag(ConflictResolution.replace)
                    Text("Both").tag(ConflictResolution.duplicate)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func comparisonRow(title: String, name: String, details: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .textCase(.uppercase)

            Text(name)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            Text(details)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Conflict Resolver View Model
class ConflictResolverViewModel: ObservableObject {
    @Published var conflicts: [ConflictItem] = []
    @Published var isScanning: Bool = true
    
    func scanForConflicts(backupDirectory: URL) {
        isScanning = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                detectConflicts(backupDirectory: backupDirectory)
                isScanning = false
            }
        }
    }
    
    private func detectConflicts(backupDirectory: URL) {
        var detectedConflicts: [ConflictItem] = []
        let fileManager = FileManager.default
        
        let certsSourceDir = backupDirectory.appendingPathComponent("certificates")
        if fileManager.fileExists(atPath: certsSourceDir.path) {
            let localCerts = Storage.shared.getAllCertificates()
            let localCertIds = Set(localCerts.compactMap { $0.uuid })
            if let incomingCerts = try? fileManager.contentsOfDirectory(at: certsSourceDir, includingPropertiesForKeys: nil) {
                for incomingCert in incomingCerts where incomingCert.pathExtension == "p12" {
                    let certName = incomingCert.deletingPathExtension().lastPathComponent
                    if localCertIds.contains(certName), let localCert = localCerts.first(where: { $0.uuid == certName }) {
                        let details = getProvisionDetails(for: localCert)
                        detectedConflicts.append(ConflictItem(type: .certificate, localName: details.name, incomingName: certName, localDetails: "Expires: \(details.expiration)", incomingDetails: "From Backup", path: "certificates/\(certName).p12"))
                    }
                }
            }
        }
        
        let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
        let localBundleIds = Set(signedApps.compactMap { $0.identifier })
        let metadataPath = backupDirectory.appendingPathComponent("signed_apps_metadata.json")
        if fileManager.fileExists(atPath: metadataPath.path), let metadataData = try? Data(contentsOf: metadataPath), let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [[String: String]] {
            for app in metadata {
                if let bundleId = app["identifier"], localBundleIds.contains(bundleId), let localApp = signedApps.first(where: { $0.identifier == bundleId }) {
                    detectedConflicts.append(ConflictItem(type: .bundleID, localName: localApp.name ?? "Unknown", incomingName: app["name"] ?? "Unknown", localDetails: "Version: \(localApp.version ?? "Unknown")", incomingDetails: "Version: \(app["version"] ?? "Unknown")", path: "signed_apps/\(bundleId)"))
                }
            }
        }
        
        let sourcesPath = backupDirectory.appendingPathComponent("sources.json")
        if fileManager.fileExists(atPath: sourcesPath.path) {
            let localSources = Storage.shared.getSources()
            let localSourceUrls = Set(localSources.compactMap { $0.sourceURL?.absoluteString })
            if let sourcesData = try? Data(contentsOf: sourcesPath), let incomingSources = try? JSONSerialization.jsonObject(with: sourcesData) as? [[String: String]] {
                for source in incomingSources {
                    if let url = source["url"], localSourceUrls.contains(url), let localSource = localSources.first(where: { $0.sourceURL?.absoluteString == url }) {
                        detectedConflicts.append(ConflictItem(type: .source, localName: localSource.name ?? "Unknown", incomingName: source["name"] ?? "Unknown", localDetails: localSource.identifier ?? "", incomingDetails: source["identifier"] ?? "", path: "sources/\(source["identifier"] ?? url)"))
                    }
                }
            }
        }
        
        self.conflicts = detectedConflicts
    }
    
    private func getProvisionDetails(for cert: CertificatePair) -> (name: String, expiration: String) {
        if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
            return (provisionData.Name, provisionData.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
        }
        return ("Unknown", "Unknown")
    }
    
    func applyToAll(_ resolution: ConflictResolution) {
        for index in conflicts.indices { conflicts[index].resolution = resolution }
    }
}
