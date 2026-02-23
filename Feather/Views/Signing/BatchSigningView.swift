import SwiftUI
import CoreData
import IDeviceSwift

// MARK: - Batch Signing View
struct BatchSigningView: View {
    @Environment(\.dismiss) private var dismiss
    let apps: [AppInfoPresentable]
    let onComplete: () -> Void
    
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
    @State private var batchResults: [BatchSignResult] = []
    @State private var showResults = false
    @State private var autoInstall = true
    @State private var currentPhase: BatchPhase = .signing
    @State private var installationIndex = 0
    @State private var signedAppsForInstall: [AppInfoPresentable] = []
    
    // Animation states
    @State private var pulseAnimation = false
    @State private var rotationAnimation = false
    @State private var glowAnimation = false
    
    // Edit functionality
    @State private var appOptions: [String: Options] = [:] // UUID -> Custom Options
    @State private var editingAppId: String? = nil
    @State private var showEditSheet = false
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    
    enum BatchPhase {
        case signing
        case installing
        case completed
    }
    
    struct BatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        var success: Bool
        let message: String
        let itmsLink: String?
    }
    
    var body: some View {
        ZStack {
            // Modern Background
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.05),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        certificateSection
                        optionsSection
                        appSelectionSection
                        
                        if !batchResults.isEmpty {
                            resultsSection
                        }
                    }
                    .padding()
                }
                
                // Bottom Action Button
                actionButton
            }
            
            // Progress Overlay
            if isSigningBatch {
                progressOverlay
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditSheet) {
            if let appId = editingAppId,
               let app = apps.first(where: { $0.uuid == appId }) {
                BatchAppEditSheet(
                    app: app,
                    options: Binding(
                        get: { appOptions[appId] ?? createDefaultOptions(for: app) },
                        set: { appOptions[appId] = $0 }
                    ),
                    onDismiss: {
                        showEditSheet = false
                    }
                )
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Batch Signing")
                    .font(.system(.title, design: .rounded).bold())
                Text("\(selectedApps.count) apps selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Signing Certificate", systemImage: "checkmark.seal.fill")
                .font(.headline)
            
            if certificates.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("No Certificates Available")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Menu {
                    ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                        Button {
                            selectedCertificateIndex = index
                        } label: {
                            HStack {
                                if selectedCertificateIndex == index {
                                    Image(systemName: "checkmark")
                                }
                                Text(cert.nickname ?? "Certificate \(index + 1)")
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "certificate.fill")
                            .foregroundStyle(.accentColor)
                        Text(certificates[selectedCertificateIndex].nickname ?? "Certificate \(selectedCertificateIndex + 1)")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Options", systemImage: "gearshape.fill")
                .font(.headline)
            
            Toggle(isOn: $autoInstall) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Install After Signing")
                        .font(.body.weight(.medium))
                    Text("Install apps automatically once signed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Select Apps", systemImage: "app.badge.checkmark.fill")
                    .font(.headline)
                Spacer()
                if !apps.isEmpty {
                    Button(selectedApps.count == apps.count ? "Deselect All" : "Select All") {
                        withAnimation {
                            if selectedApps.count == apps.count {
                                selectedApps.removeAll()
                            } else {
                                selectedApps = Set(apps.compactMap { $0.uuid })
                            }
                        }
                    }
                    .font(.caption.bold())
                }
            }
            
            if apps.isEmpty {
                Text("No Apps Available For Signing")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(apps, id: \.uuid) { app in
                        BatchAppRow(
                            app: app,
                            isSelected: selectedApps.contains(app.uuid ?? ""),
                            hasCustomOptions: appOptions[app.uuid ?? ""] != nil,
                            onToggle: {
                                toggleAppSelection(app)
                            },
                            onEdit: {
                                editingAppId = app.uuid
                                showEditSheet = true
                            }
                        )
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Results", systemImage: "checklist")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(batchResults) { result in
                    HStack(spacing: 12) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(result.success ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.appName)
                                .font(.subheadline.weight(.semibold))
                            Text(result.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let link = result.itmsLink, !link.isEmpty {
                            Button {
                                if let url = URL(string: link) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var actionButton: some View {
        Button {
            startBatchSigning()
        } label: {
            HStack {
                Image(systemName: "signature")
                Text("Sign \(selectedApps.count) Apps")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch ? Color.gray : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding()
        }
        .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
    }
    
    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: batchProgress)
                        .stroke(
                            AngularGradient(
                                colors: [.accentColor, .blue, .accentColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring, value: batchProgress)
                    
                    VStack {
                        Text("\(Int(batchProgress * 100))%")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(.white)
                        Text(currentPhase == .signing ? "Signing" : "Installing")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                    }
                }
                .shadow(color: .accentColor.opacity(0.5), radius: 20)
                
                VStack(spacing: 8) {
                    Text(currentSigningApp)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    Text("Please keep Feather open")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .padding(20)
        }
    }
    
    // MARK: - Logic
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotationAnimation = true
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
    }
    
    private func createDefaultOptions(for app: AppInfoPresentable) -> Options {
        var options = OptionsManager.shared.options
        options.appName = app.name
        options.appVersion = app.version
        options.appIdentifier = app.identifier
        return options
    }
    
    private func toggleAppSelection(_ app: AppInfoPresentable) {
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
        currentPhase = .signing
        
        let appsToSign = apps.filter { selectedApps.contains($0.uuid ?? "") }
        let totalApps = Double(appsToSign.count)
        
        Task {
            signedAppsForInstall.removeAll()
            
            for (index, app) in appsToSign.enumerated() {
                await MainActor.run {
                    currentSigningApp = app.name ?? "App \(index + 1)"
                    batchProgress = Double(index) / totalApps
                    currentPhase = .signing
                }
                
                let selectedCert = certificates[selectedCertificateIndex]
                let signingOptions = appOptions[app.uuid ?? ""] ?? OptionsManager.shared.options
                
                var itmsLink: String? = nil
                var success = false
                var message = ""
                
                await withCheckedContinuation { continuation in
                    if _serverMethod == 2 {
                        // Remote Signing
                        FR.remoteSignPackageFile(app, using: signingOptions, certificate: selectedCert) { result in
                            switch result {
                            case .success(let link):
                                itmsLink = link
                                success = true
                                message = "Signed Successfully (Remote)"
                                if autoInstall {
                                    if let url = URL(string: link) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            case .failure(let error):
                                success = false
                                message = error.localizedDescription
                            }
                            continuation.resume()
                        }
                    } else {
                        // Local Signing
                        FR.signPackageFile(app, using: signingOptions, icon: nil, certificate: selectedCert) { error in
                            if let error {
                                success = false
                                message = error.localizedDescription
                            } else {
                                success = true
                                message = "Signed Successfully"
                                signedAppsForInstall.append(app)
                            }
                            continuation.resume()
                        }
                    }
                }
                
                // If local signing succeeded and autoInstall is on, trigger installation
                if success && _serverMethod != 2 && autoInstall {
                    await MainActor.run { currentPhase = .installing }
                    do {
                        let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
                        let handler = ArchiveHandler(app: app, viewModel: viewModel)
                        try await handler.move()
                        let packageUrl = try await handler.archive()
                        
                        if installationMethod == 0 {
                            let installer = try ServerInstaller(app: app, viewModel: viewModel)
                            installer.packageUrl = packageUrl
                            itmsLink = installer.iTunesLink
                            if let url = URL(string: installer.iTunesLink) {
                                await MainActor.run { UIApplication.shared.open(url) }
                                message = "Signed & Installing"
                            }
                        } else {
                            // Direct install via iDeviceSwift (if applicable)
                            // This would typically use iDeviceSwift tools to push IPA
                            message = "Signed & Ready"
                        }
                    } catch {
                        message = "Signed, but installation failed: \(error.localizedDescription)"
                    }
                }
                
                let result = BatchSignResult(
                    appName: app.name ?? "Unknown",
                    success: success,
                    message: message,
                    itmsLink: itmsLink
                )
                
                await MainActor.run {
                    batchResults.append(result)
                }
            }
            
            await MainActor.run {
                batchProgress = 1.0
                isSigningBatch = false
                selectedApps.removeAll()
                HapticsManager.shared.success()
                ToastManager.shared.show("Batch Signing Completed", type: .success)
            }
            
            if installationMethod == 1 {
                await cleanupSignedApps()
            }
        }
    }
    
    private func cleanupSignedApps() async {
        // Clean up temporary IPA files if needed
    }
}

// MARK: - Supporting Views

struct BatchAppRow: View {
    let app: AppInfoPresentable
    let isSelected: Bool
    let hasCustomOptions: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                    FRAppIconView(app: app, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name ?? "Unknown App")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Text(app.identifier ?? "Unknown Bundle ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isSelected {
                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(hasCustomOptions ? Color.accentColor : .secondary)
                        .padding(8)
                        .background(Color.accentColor.opacity(hasCustomOptions ? 0.1 : 0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct BatchAppEditSheet: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        FRAppIconView(app: app, size: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name ?? "Unknown")
                                .font(.headline)
                            Text(app.identifier ?? "Unknown")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(app.version ?? "Unknown")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("App Information")
                }

                Section {
                    TextField("App Name", text: Binding(
                        get: { options.appName ?? "" },
                        set: { options.appName = $0 }
                    ))

                    TextField("Bundle Identifier", text: Binding(
                        get: { options.appIdentifier ?? "" },
                        set: { options.appIdentifier = $0 }
                    ))

                    TextField("Version", text: Binding(
                        get: { options.appVersion ?? "" },
                        set: { options.appVersion = $0 }
                    ))
                } header: {
                    Text("Custom Signing Options")
                } footer: {
                    Text("These values will be used when signing this specific app in the batch.")
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        options.appName = app.name
                        options.appIdentifier = app.identifier
                        options.appVersion = app.version
                    }
                }
            }
            .navigationTitle("Edit Signing Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
