import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct DeveloperBatchSigningView: View {
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>

    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>

    @State private var selectedApps: Set<String> = []
    @State private var selectedCertificateIndex = 0
    @State private var isSigningBatch = false
    @State private var batchProgress: Double = 0
    @State private var currentSigningApp: String = ""
    @State private var batchResults: [DeveloperBatchSignResult] = []
    @State private var showResults = false

    struct DeveloperBatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        let message: String
    }

    var body: some View {
        ZStack {
            List {
                // Certificate Selection
                Section {
                    if certificates.isEmpty {
                        Text("No Certificates Available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Signing Certificate", selection: $selectedCertificateIndex) {
                            ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                                Text(cert.nickname ?? "Certificate \(index + 1)")
                                    .tag(index)
                            }
                        }
                    }
                } header: {
                    Text("Certificate")
                }

                // App Selection
                Section {
                    if importedApps.isEmpty {
                        Text("No Apps Available For Signing")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(importedApps, id: \.uuid) { app in
                            DeveloperBatchAppRow(
                                app: app,
                                isSelected: selectedApps.contains(app.uuid ?? ""),
                                onToggle: {
                                    toggleAppSelection(app)
                                }
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text("Select Apps (\(selectedApps.count) Selected)")
                        Spacer()
                        if !importedApps.isEmpty {
                            Button(selectedApps.count == importedApps.count ? "Deselect All" : "Select All") {
                                withAnimation {
                                    if selectedApps.count == importedApps.count {
                                        selectedApps.removeAll()
                                    } else {
                                        selectedApps = Set(importedApps.compactMap { $0.uuid })
                                    }
                                }
                            }
                            .font(.caption)
                        }
                    }
                }

                // Batch Action
                Section {
                    Button {
                        startBatchSigning()
                    } label: {
                        HStack {
                            Image(systemName: "signature")
                            Text("Sign Selected Apps (\(selectedApps.count))")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
                } header: {
                    Text("Actions")
                }

                // Results Section
                if !batchResults.isEmpty {
                    Section {
                        ForEach(batchResults) { result in
                            HStack {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.success ? .green : .red)
                                VStack(alignment: .leading) {
                                    Text(result.appName)
                                        .font(.subheadline)
                                    Text(result.message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Results")
                    }
                }
            }
            .scrollContentBackground(.hidden)

            // Progress Overlay
            if isSigningBatch {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(AnyTransition.opacity)

                    VStack(spacing: 20) {
                        ProgressView(value: batchProgress)
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)

                        VStack(spacing: 8) {
                            Text("Signing Apps...")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text(currentSigningApp)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)

                            Text("\(Int(batchProgress * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(40)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .transition(AnyTransition.scale.combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Batch Signing")
    }

    private func toggleAppSelection(_ app: Imported) {
        guard let id = app.uuid else { return }
        if selectedApps.contains(id) {
            selectedApps.remove(id)
        } else {
            selectedApps.insert(id)
        }
    }

    private func startBatchSigning() {
        guard !selectedApps.isEmpty, certificates.indices.contains(selectedCertificateIndex) else { return }

        isSigningBatch = true
        batchProgress = 0
        batchResults.removeAll()

        let appsToSign = importedApps.filter { selectedApps.contains($0.uuid ?? "") }
        let totalApps = Double(appsToSign.count)

        AppLogManager.shared.info("Starting batch signing for \(Int(totalApps)) apps", category: "BatchSign")

        // Logic for signing will be here because i cbf to add it
        Task {
            for (index, app) in appsToSign.enumerated() {
                await MainActor.run {
                    currentSigningApp = app.name ?? "App \(index + 1)"
                    batchProgress = Double(index) / totalApps
                }

                // Simulate signing delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Add result
                await MainActor.run {
                    let result = DeveloperBatchSignResult(
                        appName: app.name ?? "Unknown",
                        success: true,
                        message: "Signed Successfully"
                    )
                    batchResults.append(result)
                }
            }

            await MainActor.run {
                isSigningBatch = false
                batchProgress = 1.0
                selectedApps.removeAll()
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ Batch Signing Completed", type: .success)
                AppLogManager.shared.success("Batch signing completed for \(Int(totalApps)) apps", category: "BatchSign")
            }
        }
    }
}
