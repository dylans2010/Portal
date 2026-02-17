import SwiftUI
import NimbleViews
import CoreData

// MARK: - Preflight Check Item
struct PreflightItem: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let size: String
    let icon: String
    let issues: [String]
}

// MARK: - Preflight Check View
struct PreflightCheckView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PreflightCheckViewModel()
    
    var onContinue: () -> Void
    
    var body: some View {
        NBList(.localized("Preflight Check")) {
            // Summary Section
            Section {
                VStack(spacing: 16) {
                    if viewModel.isScanning {
                        ProgressView()
                            .padding()
                        Text("Scanning Backup Data")
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: viewModel.hasIssues ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(viewModel.hasIssues ? .orange : .green)
                        
                        VStack(spacing: 8) {
                            Text(viewModel.summaryTitle)
                                .font(.headline)
                            Text(viewModel.summaryMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } header: {
                AppearanceSectionHeader(title: String.localized("Scan Results"), icon: "doc.text.magnifyingglass")
            }
            
            // Items Breakdown
            if !viewModel.isScanning {
                Section {
                    ForEach(viewModel.items) { item in
                        PreflightItemRow(item: item)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Backup Contents"), icon: "list.bullet")
                } footer: {
                    Text("Total Size: \(viewModel.totalSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Issues Section
                if viewModel.hasIssues {
                    Section {
                        ForEach(viewModel.allIssues, id: \.self) { issue in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text(issue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } header: {
                        AppearanceSectionHeader(title: String.localized("Detected Issues"), icon: "exclamationmark.triangle")
                    } footer: {
                        Text("These issues will not prevent the transfer, but may require attention after restoration so fix them before you continue.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Action Button
                Section {
                    Button {
                        onContinue()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Continue Transfer")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    Text("This will prepare your backup and begin the transfer process.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Preflight Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.performScan()
        }
    }
}

// MARK: - Preflight Item Row
struct PreflightItemRow: View {
    let item: PreflightItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.category)
                    .font(.headline)
                
                HStack {
                    Text("\(item.count) Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(item.size)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !item.issues.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(item.issues.count) Issue\(item.issues.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preflight Check View Model
class PreflightCheckViewModel: ObservableObject {
    @Published var isScanning: Bool = true
    @Published var items: [PreflightItem] = []
    @Published var totalSize: String = "0 KB"
    @Published var hasIssues: Bool = false
    @Published var allIssues: [String] = []
    
    var summaryTitle: String {
        if hasIssues {
            return "Ready With Warnings"
        } else {
            return "Ready To Transfer"
        }
    }
    
    var summaryMessage: String {
        if hasIssues {
            return "Some issues detected. You can continue, but review after restoration."
        } else {
            return "All checks passed. Your backup is ready for transfer."
        }
    }
    
    func performScan() {
        isScanning = true
        
        Task {
            // Simulate scanning with delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                scanBackupContents()
                isScanning = false
            }
        }
    }
    
    private func scanBackupContents() {
        var itemsList: [PreflightItem] = []
        var totalBytes: Int64 = 0
        var issuesList: [String] = []
        
        // 1. Certificates
        let certificates = Storage.shared.getAllCertificates()
        var certIssues: [String] = []
        var expiredCount = 0
        
        for cert in certificates {
            // Check for expired certificates
            if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
                let expirationDate = provisionData.ExpirationDate
                if expirationDate < Date() {
                    expiredCount += 1
                }
            }
        }
        
        if expiredCount > 0 {
            certIssues.append("\(expiredCount) Expired Certificate\(expiredCount == 1 ? "" : "s")")
        }
        
        let certSize = calculateDirectorySize(FileManager.default.certificates)
        totalBytes += certSize
        
        itemsList.append(PreflightItem(
            category: "Certificates",
            count: certificates.count,
            size: formatBytes(certSize),
            icon: "doc.text.fill",
            issues: certIssues
        ))
        
        // 2. Provisioning Profiles (included in certificates)
        let profileCount = certificates.filter { cert in
            Storage.shared.getProvisionFileDecoded(for: cert) != nil
        }.count
        
        itemsList.append(PreflightItem(
            category: "Provisioning Profiles",
            count: profileCount,
            size: "Included",
            icon: "doc.badge.gearshape",
            issues: []
        ))
        
        // 3. Signed Apps
        let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
        let signedSize = calculateDirectorySize(FileManager.default.signed)
        totalBytes += signedSize
        
        itemsList.append(PreflightItem(
            category: "Signed Apps",
            count: signedApps.count,
            size: formatBytes(signedSize),
            icon: "checkmark.seal.fill",
            issues: []
        ))
        
        // 4. Imported Apps
        let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
        let importedSize = calculateDirectorySize(FileManager.default.unsigned)
        totalBytes += importedSize
        
        itemsList.append(PreflightItem(
            category: "Imported Apps",
            count: importedApps.count,
            size: formatBytes(importedSize),
            icon: "square.and.arrow.down.fill",
            issues: []
        ))
        
        // 5. Sources
        let sources = Storage.shared.getSources()
        itemsList.append(PreflightItem(
            category: "Sources",
            count: sources.count,
            size: formatBytes(Int64(sources.count * 1024)), // Approximate
            icon: "link.circle.fill",
            issues: []
        ))
        
        // 6. Default Frameworks
        let frameworksDir = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
        let frameworksSize = calculateDirectorySize(frameworksDir)
        let frameworksCount = (try? FileManager.default.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil).count) ?? 0
        totalBytes += frameworksSize
        
        itemsList.append(PreflightItem(
            category: "Default Frameworks",
            count: frameworksCount,
            size: formatBytes(frameworksSize),
            icon: "cube.box.fill",
            issues: []
        ))
        
        // 7. Archives
        let archivesSize = calculateDirectorySize(FileManager.default.archives)
        let archivesCount = (try? FileManager.default.contentsOfDirectory(at: FileManager.default.archives, includingPropertiesForKeys: nil).count) ?? 0
        totalBytes += archivesSize
        
        itemsList.append(PreflightItem(
            category: "Archives",
            count: archivesCount,
            size: formatBytes(archivesSize),
            icon: "archivebox.fill",
            issues: []
        ))
        
        // 8. Settings
        itemsList.append(PreflightItem(
            category: "Settings & Preferences",
            count: 1,
            size: "Included",
            icon: "gearshape.fill",
            issues: []
        ))
        
        // 9. History & Entitlements
        itemsList.append(PreflightItem(
            category: "History & Entitlements",
            count: 1,
            size: "Included",
            icon: "clock.arrow.circlepath",
            issues: []
        ))
        
        // Collect all issues
        for item in itemsList {
            issuesList.append(contentsOf: item.issues)
        }
        
        self.items = itemsList
        self.totalSize = formatBytes(totalBytes)
        self.allIssues = issuesList
        self.hasIssues = !issuesList.isEmpty
    }
    
    private func calculateDirectorySize(_ directory: URL) -> Int64 {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
