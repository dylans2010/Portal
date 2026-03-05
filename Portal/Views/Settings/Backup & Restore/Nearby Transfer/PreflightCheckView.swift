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
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @StateObject private var viewModel = PreflightCheckViewModel()
    @State private var scanPhase: CGFloat = 0
    
    var onContinue: () -> Void
    
    var body: some View {
        NBList(.localized("Preflight Check")) {
            // Summary Section
            if showHeaderViews {
                Section {
                    VStack(spacing: 24) {
                        if viewModel.isScanning {
                            radarScanView
                        } else {
                            statusHeaderView
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            
            // Items Breakdown
            if !viewModel.isScanning {
                Section {
                    ForEach(viewModel.items) { item in
                        PreflightItemRow(item: item)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Backup Contents"), icon: "list.bullet.rectangle")
                } footer: {
                    HStack {
                        Text("Total Estimated Size:")
                        Spacer()
                        Text(viewModel.totalSize)
                            .fontWeight(.bold)
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                
                // Issues Section
                if viewModel.hasIssues {
                    Section {
                        ForEach(viewModel.allIssues, id: \.self) { issue in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 14))
                                    .padding(.top, 2)

                                Text(issue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        AppearanceSectionHeader(title: String.localized("Detected Warnings"), icon: "exclamationmark.triangle")
                    } footer: {
                        Text("These issues won't block the transfer, but they should be reviewed to ensure a successful restoration.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Action Button
                Section {
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Prepare & Send Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(.headline, design: .rounded))
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } footer: {
                    Text("Ready to transfer? Ensure the receiving device is still waiting.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
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
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                scanPhase = 360
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var radarScanView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    .frame(width: 150, height: 150)

                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    .frame(width: 50, height: 50)

                // Scanning beam
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        AngularGradient(colors: [.blue, .clear], center: .center),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(scanPhase))
            }

            VStack(spacing: 8) {
                Text("Analyzing Data")
                    .font(.system(.headline, design: .rounded))
                Text("Scanning your local database and files...")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusHeaderView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(viewModel.hasIssues ? Color.orange.opacity(0.1) : Color.green.opacity(0.1) )
                    .frame(width: 100, height: 100)

                Image(systemName: viewModel.hasIssues ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(viewModel.hasIssues ? .orange : .green)
                    .ifAvailableiOS17SymbolPulse()
            }

            VStack(spacing: 6) {
                Text(viewModel.summaryTitle)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(viewModel.summaryMessage)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Preflight Item Row
struct PreflightItemRow: View {
    let item: PreflightItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.category)
                    .font(.system(.headline, design: .rounded))
                
                HStack(spacing: 8) {
                    Text("\(item.count) Items")
                    Text("•")
                    Text(item.size)
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                
                if !item.issues.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(item.issues.count) Issue\(item.issues.count == 1 ? "" : "s")")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
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
        hasIssues ? "Check Complete (Warnings)" : "Ready for Transfer"
    }
    
    var summaryMessage: String {
        hasIssues
            ? "We found some minor issues. You can proceed, but please review the warnings."
            : "Everything looks great! Your backup is ready to be sent securely."
    }
    
    func performScan() {
        isScanning = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
        
        let certificates = Storage.shared.getAllCertificates()
        var expiredCount = 0
        for cert in certificates {
            if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert), provisionData.ExpirationDate < Date() {
                expiredCount += 1
            }
        }
        
        let certSize = calculateDirectorySize(FileManager.default.certificates)
        totalBytes += certSize
        itemsList.append(PreflightItem(category: "Certificates", count: certificates.count, size: formatBytes(certSize), icon: "doc.text.fill", issues: expiredCount > 0 ? ["\(expiredCount) Expired Certificates"] : []))
        
        let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
        let signedSize = calculateDirectorySize(FileManager.default.signed)
        totalBytes += signedSize
        itemsList.append(PreflightItem(category: "Signed Apps", count: signedApps.count, size: formatBytes(signedSize), icon: "checkmark.seal.fill", issues: []))
        
        let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
        let importedSize = calculateDirectorySize(FileManager.default.unsigned)
        totalBytes += importedSize
        itemsList.append(PreflightItem(category: "Imported Apps", count: importedApps.count, size: formatBytes(importedSize), icon: "square.and.arrow.down.fill", issues: []))
        
        let sources = Storage.shared.getSources()
        itemsList.append(PreflightItem(category: "Sources", count: sources.count, size: formatBytes(Int64(sources.count * 1024)), icon: "link.circle.fill", issues: []))
        
        let frameworksDir = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
        let frameworksSize = calculateDirectorySize(frameworksDir)
        totalBytes += frameworksSize
        itemsList.append(PreflightItem(category: "Default Frameworks", count: (try? FileManager.default.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil).count) ?? 0, size: formatBytes(frameworksSize), icon: "cube.box.fill", issues: []))
        
        let archivesSize = calculateDirectorySize(FileManager.default.archives)
        totalBytes += archivesSize
        itemsList.append(PreflightItem(category: "Archives", count: (try? FileManager.default.contentsOfDirectory(at: FileManager.default.archives, includingPropertiesForKeys: nil).count) ?? 0, size: formatBytes(archivesSize), icon: "archivebox.fill", issues: []))
        
        itemsList.append(PreflightItem(category: "Settings", count: 1, size: "Included", icon: "gearshape.fill", issues: []))
        
        for item in itemsList { issuesList.append(contentsOf: item.issues) }
        
        self.items = itemsList
        self.totalSize = formatBytes(totalBytes)
        self.allIssues = issuesList
        self.hasIssues = !issuesList.isEmpty
    }
    
    private func calculateDirectorySize(_ directory: URL) -> Int64 {
        guard FileManager.default.fileExists(atPath: directory.path) else { return 0 }
        var totalSize: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let fileSize = resourceValues.fileSize {
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
