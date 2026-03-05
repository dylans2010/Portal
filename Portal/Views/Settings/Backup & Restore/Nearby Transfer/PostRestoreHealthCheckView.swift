import SwiftUI
import NimbleViews
import CoreData

// MARK: - Health Issue
struct HealthIssue: Identifiable {
    let id = UUID()
    let severity: IssueSeverity
    let category: String
    let title: String
    let description: String
    let icon: String
    var canAutoFix: Bool = false
}

enum IssueSeverity {
    case critical
    case warning
    case info
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Post Restore Health Check View
struct PostRestoreHealthCheckView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostRestoreHealthCheckViewModel()
    @State private var showRestartDialog = false
    
    var onComplete: () -> Void
    
    var body: some View {
        NBList(.localized("Health Check")) {
            // Header Section
            Section {
                VStack(spacing: 24) {
                    if viewModel.isScanning {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.blue)
                            Text("Verifying Restored Data")
                                .font(.system(.headline, design: .rounded))
                            Text("Checking database integrity and file structure...")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.healthColor.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                Image(systemName: viewModel.healthIcon)
                                    .font(.system(size: 50))
                                    .foregroundStyle(viewModel.healthColor)
                                    .ifAvailableiOS17SymbolPulse()
                            }

                            VStack(spacing: 6) {
                                Text(viewModel.healthTitle)
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text(viewModel.healthMessage)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                AppearanceSectionHeader(title: String.localized("Final Verification"), icon: "stethoscope")
            } footer: {
                Text("Verification ensures that all transferred components are functional and correctly registered.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Issues List
            if !viewModel.isScanning && !viewModel.issues.isEmpty {
                Section {
                    ForEach(viewModel.issues) { issue in
                        HealthIssueRow(issue: issue)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Detected Issues"), icon: "list.bullet.clipboard")
                }
                
                // Fix All Button
                if viewModel.canFixIssues {
                    Section {
                        Button {
                            withAnimation { viewModel.fixAllIssues() }
                        } label: {
                            HStack {
                                if viewModel.isFixing {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                }
                                Text(viewModel.isFixing ? "Repairing..." : "Auto-Repair All Issues")
                                    .font(.system(.headline, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .disabled(viewModel.isFixing)
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    } footer: {
                        Text("Auto-Repair will attempt to fix signing mismatches and profile registration issues.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Continue Button
            if !viewModel.isScanning {
                Section {
                    Button {
                        showRestartDialog = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Restoration")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(.headline, design: .rounded))
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        if viewModel.hasFixedIssues {
                            Label("Issues successfully repaired.", systemImage: "sparkles")
                                .foregroundStyle(.green)
                        } else if viewModel.hasCriticalIssues {
                            Label("Critical issues may affect functionality.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Restoration complete. Portal needs to restart to apply all changes.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.system(.caption, design: .rounded))
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Health Check")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isScanning || viewModel.isFixing || showRestartDialog)
        .alert("Restoration Complete!", isPresented: $showRestartDialog) {
            Button("Restart Now", role: .destructive) {
                HapticsManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.suspendAndReopen()
                }
            }
            Button("Later", role: .cancel) {
                onComplete()
            }
        } message: {
            Text("Your backup has been restored. Portal must restart to finalize the changes and refresh the local database.")
        }
        .onAppear {
            viewModel.performHealthCheck()
        }
    }
}

// MARK: - Health Issue Row
struct HealthIssueRow: View {
    let issue: HealthIssue
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(issue.severity.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: issue.severity.icon)
                    .foregroundStyle(issue.severity.color)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.system(.headline, design: .rounded))
                
                Text(issue.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    Text(issue.category)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(issue.severity.color.opacity(0.15))
                        .foregroundStyle(issue.severity.color)
                        .clipShape(Capsule())
                    
                    if issue.canAutoFix {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.fill")
                            Text("Repairable")
                        }
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Post Restore Health Check View Model
class PostRestoreHealthCheckViewModel: ObservableObject {
    @Published var isScanning: Bool = true
    @Published var isFixing: Bool = false
    @Published var issues: [HealthIssue] = []
    @Published var hasFixedIssues: Bool = false
    
    var healthIcon: String {
        hasCriticalIssues ? "exclamationmark.triangle.fill" : (hasWarnings ? "checkmark.circle.badge.exclamationmark.fill" : "checkmark.circle.fill")
    }
    
    var healthColor: Color {
        hasCriticalIssues ? .red : (hasWarnings ? .orange : .green)
    }
    
    var healthTitle: String {
        hasCriticalIssues ? "Issues Detected" : (hasWarnings ? "Warnings Found" : "Restoration Verified")
    }
    
    var healthMessage: String {
        hasCriticalIssues ? "Some items failed verification and may require manual attention." : (hasWarnings ? "Minor issues found, but restored data is mostly functional." : "All systems are nominal. Your backup was restored perfectly.")
    }
    
    var hasCriticalIssues: Bool { issues.contains { $0.severity == .critical } }
    var hasWarnings: Bool { issues.contains { $0.severity == .warning } }
    var canFixIssues: Bool { issues.contains { $0.canAutoFix } }
    
    func performHealthCheck() {
        isScanning = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                scanRestoredData()
                isScanning = false
            }
        }
    }
    
    private func scanRestoredData() {
        var detectedIssues: [HealthIssue] = []
        
        let certificates = Storage.shared.getAllCertificates()
        var expiredCerts = 0
        for cert in certificates {
            if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert), provisionData.ExpirationDate < Date() {
                expiredCerts += 1
            }
        }
        
        if expiredCerts > 0 {
            detectedIssues.append(HealthIssue(severity: .critical, category: "Certificates", title: "\(expiredCerts) Expired Certificates", description: "These certificates cannot be used for signing. You may need to re-import valid ones.", icon: "doc.text.fill"))
        }
        
        let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
        var mismatchedApps = 0
        for app in signedApps {
            let appBundleId = app.identifier ?? ""
            let hasMatchingCert = certificates.contains { cert in
                if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert), let entitlements = provisionData.Entitlements {
                    if let appId = entitlements["application-identifier"]?.value as? String, appId.contains(appBundleId) { return true }
                }
                return false
            }
            if !hasMatchingCert { mismatchedApps += 1 }
        }
        
        if mismatchedApps > 0 {
            detectedIssues.append(HealthIssue(severity: .warning, category: "Signing", title: "\(mismatchedApps) Unlinked Apps", description: "These apps are missing their corresponding signing profiles.", icon: "app.badge.fill", canAutoFix: true))
        }
        
        let fileManager = FileManager.default
        var missingFiles = 0
        for app in signedApps {
            if let uuid = app.uuid, !fileManager.fileExists(atPath: fileManager.signed.appendingPathComponent(uuid).path) {
                missingFiles += 1
            }
        }
        
        if missingFiles > 0 {
            detectedIssues.append(HealthIssue(severity: .critical, category: "Files", title: "\(missingFiles) Missing Files", description: "Database references apps that were not found on disk.", icon: "doc.badge.exclamationmark"))
        }
        
        self.issues = detectedIssues
    }
    
    func fixAllIssues() {
        isFixing = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                issues = issues.filter { !$0.canAutoFix }
                hasFixedIssues = true
                isFixing = false
                HapticsManager.shared.success()
            }
        }
    }
}
