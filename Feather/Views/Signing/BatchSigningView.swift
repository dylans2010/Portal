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
        let success: Bool
        let message: String
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
.scrollContentBackground(.hidden)
                    // Custom Header
                    Section {
                        HStack {
                            Text("Batch Signing")
                                .font(.system(.title2, design: .rounded).bold())
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

                    // Certificate Selection
                    Section {
                        if certificates.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                Text("No Certificates Available")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Label("Signing Certificate", systemImage: "checkmark.seal.fill")
                                Spacer()
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
                                    HStack(spacing: 4) {
                                        Text(certificates[selectedCertificateIndex].nickname ?? "Certificate \(selectedCertificateIndex + 1)")
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Label("Certificate", systemImage: "checkmark.seal.fill")
                    }
                    
                    // Auto Install Toggle
                    Section {
                        Toggle(isOn: $autoInstall) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Auto Install After Signing")
                            }
                        }
                    } header: {
                        Label("Options", systemImage: "gearshape.fill")
                    } footer: {
                        Text("Automatically install apps after successful signing. This does not work as of now, you can install manually from Library after the Batch Signing is completed.")
                    }

                    // App Selection
                    Section {
                        if apps.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                Text("No Apps Available For Signing")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
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
                            }
                        }
                    } header: {
                        HStack {
                            Label("Select Apps (\(selectedApps.count) Selected)", systemImage: "app.badge.checkmark.fill")
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
                                .font(.caption)
                            }
                        }
                    }

                    // Batch Action
                    Section {
                        Button {
                            startBatchSigning()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "signature")
                                    .font(.title3)
                                Text("Sign Selected Apps (\(selectedApps.count))")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
                    } header: {
                        Label("Actions", systemImage: "bolt.fill")
                    }
                    
                    // Results Section
                    if !batchResults.isEmpty {
                        Section {
                            ForEach(batchResults) { result in
                                HStack(spacing: 12) {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(result.success ? .green : .red)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.appName)
                                            .font(.subheadline.weight(.medium))
                                        Text(result.message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        } header: {
                            Label("Results", systemImage: "checklist")
                        }
                    }
                }
            .scrollContentBackground(.hidden)
                
                // Progress Overlay
                if isSigningBatch {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        VStack(spacing: 24) {
                            // Animated Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 8)
                                
                                Image(systemName: currentPhase == .signing ? "signature" : "arrow.down.circle.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .pulseEffect(true)
                            }

                            VStack(spacing: 12) {
                                Text(currentPhase == .signing ? "Signing Apps" : "Installing Apps")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)

                                Text(currentSigningApp)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                                    .frame(maxWidth: 250)

                                // Progress Bar
                                VStack(spacing: 8) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.2))
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.accentColor, .accentColor.opacity(0.7)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * batchProgress)
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    Text("\(Int(batchProgress * 100))%")
                                        .font(.caption.bold().monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(40)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                        .transition(AnyTransition.scale.combined(with: .opacity))
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditSheet) {
Group {
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
}.applyGlobalTheme()
}
        }
    }
    
    private func createDefaultOptions(for app: AppInfoPresentable) -> Options {
        var options = OptionsManager.shared.options
        // Populate with app's existing values
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
        
        AppLogManager.shared.info("Starting batch signing for \(Int(totalApps)) apps", category: "BatchSign")
        
        Task {
            signedAppsForInstall.removeAll()
            
            for (index, app) in appsToSign.enumerated() {
                await MainActor.run {
                    currentSigningApp = app.name ?? "App \(index + 1)"
                    batchProgress = Double(index) / totalApps
                }
                
                // Perform actual signing
                let selectedCert = certificates[selectedCertificateIndex]
                AppLogManager.shared.info("Signing app \(index + 1)/\(Int(totalApps)): \(app.name ?? "Unknown")", category: "BatchSign")
                
                // Use custom options if available, otherwise use global options
                let signingOptions = appOptions[app.uuid ?? ""] ?? OptionsManager.shared.options
                
                await withCheckedContinuation { continuation in
                    if _serverMethod == 2 {
                        // Remote Signing
                        FR.remoteSignPackageFile(
                            app,
                            using: signingOptions,
                            certificate: selectedCert
                        ) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let installLink):
                                    let result = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: true,
                                        message: "Signed Successfully (Remote)"
                                    )
                                    batchResults.append(result)
                                    AppLogManager.shared.success("Batch remote signing succeeded for \(app.name ?? "Unknown")", category: "BatchSign")

                                    // Auto install for remote signing means opening the itms link
                                    if autoInstall {
                                        if let url = URL(string: installLink) {
                                            UIApplication.shared.open(url)
                                            updateBatchResult(for: app, message: "Signed - Installation Link Opened")
                                        }
                                    }
                                case .failure(let error):
                                    let result = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: false,
                                        message: error.localizedDescription
                                    )
                                    batchResults.append(result)
                                    AppLogManager.shared.error("Batch remote signing failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                                }
                                continuation.resume()
                            }
                        }
                    } else {
                        // Local Signing
                        FR.signPackageFile(
                            app,
                            using: signingOptions,
                            icon: nil,
                            certificate: selectedCert
                        ) { error in
                            if let error {
                                let result = BatchSignResult(
                                    appName: app.name ?? "Unknown",
                                    success: false,
                                    message: error.localizedDescription
                                )
                                batchResults.append(result)
                                AppLogManager.shared.error("Batch signing failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                            } else {
                                let result = BatchSignResult(
                                    appName: app.name ?? "Unknown",
                                    success: true,
                                    message: "Signed Successfully"
                                )
                                batchResults.append(result)
                                signedAppsForInstall.append(app)
                                AppLogManager.shared.success("Batch signing succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                            }
                            continuation.resume()
                        }
                    }
                }
                
                // Immediately trigger installation for this app after signing (Local only)
                if _serverMethod != 2 && autoInstall && signedAppsForInstall.contains(where: { $0.uuid == app.uuid }) {
                    await triggerInstallation(for: app, appIndex: index)
                }
            }

            await MainActor.run {
                batchProgress = 1.0
                AppLogManager.shared.success("Batch signing completed for \(Int(totalApps)) apps", category: "BatchSign")
            }
            
            // Only clean up for direct device installations
            // For server-based installations, keep the files available
            if installationMethod == 1 {
                await cleanupSignedApps()
            } else {
                AppLogManager.shared.info("Skipping cleanup for server-based installation", category: "BatchSign")
            }
            
            await MainActor.run {
                isSigningBatch = false
                selectedApps.removeAll()
                HapticsManager.shared.success()
                
                if autoInstall && installationMethod == 0 {
                    ToastManager.shared.show("✅ Apps Signed - Check Device for Installation", type: .success)
                } else {
                    ToastManager.shared.show("✅ Batch Signing Completed", type: .success)
                }
            }
        }
    }
    
    private func triggerInstallation(for app: AppInfoPresentable, appIndex: Int) async {
        await MainActor.run {
            currentPhase = .installing
        }
        
        AppLogManager.shared.info("Triggering installation for app: \(app.name ?? "Unknown")", category: "BatchSign")
        
        do {
            // Create ViewModel for installation
            let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
            
            // Archive the signed app
            let handler = ArchiveHandler(app: app, viewModel: viewModel)
            try await handler.move()
            let packageUrl = try await handler.archive()
            
            // Install using selected method
            if installationMethod == 0 {
                // Server-based installation - trigger itms link
                let installer = try ServerInstaller(app: app, viewModel: viewModel)
                await MainActor.run {
                    installer.packageUrl = packageUrl
                    viewModel.status = .ready
                }
                
                // Trigger the itms link to install the app
                await MainActor.run {
                    if let url = URL(string: installer.iTunesLink) {
                        UIApplication.shared.open(url)
                        AppLogManager.shared.success("Triggered installation link for \(app.name ?? "Unknown")", category: "BatchSign")
                        
                        // Update result to show installation was triggered
                        updateBatchResult(for: app, message: "Signed - Installation Link Opened")
                    }
                }
            } else if installationMethod == 1 {
                // Direct device installation
                let installProxy = InstallationProxy(viewModel: viewModel)
                let shouldSuspend = app.identifier == Bundle.main.bundleIdentifier
                try await installProxy.install(at: packageUrl, suspend: shouldSuspend)
                
                await MainActor.run {
                    updateBatchResult(for: app, message: "Signed and Installed Successfully")
                    AppLogManager.shared.success("Batch installation succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                }
            }
        } catch {
            await MainActor.run {
                updateBatchResult(for: app, message: "Signed Successfully, Installation Failed: \(error.localizedDescription)")
                AppLogManager.shared.error("Installation failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
            }
        }
        
        // Reset phase back to signing for next app
        await MainActor.run {
            currentPhase = .signing
        }
    }
    
    private func updateBatchResult(for app: AppInfoPresentable, message: String) {
        if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
            batchResults[resultIndex] = BatchSignResult(
                appName: app.name ?? "Unknown",
                success: true,
                message: message
            )
        }
    }
    
    private func cleanupSignedApps() async {
        AppLogManager.shared.info("Cleaning up signed apps to save space", category: "BatchSign")
        
        await MainActor.run {
            for app in signedAppsForInstall {
                Storage.shared.deleteApp(for: app)
                AppLogManager.shared.info("Deleted app: \(app.name ?? "Unknown")", category: "BatchSign")
            }
            
            AppLogManager.shared.success("Cleanup completed: \(signedAppsForInstall.count) apps deleted", category: "BatchSign")
            signedAppsForInstall.removeAll()
        }
    }
    
    private func startBatchInstallation() async {
        await MainActor.run {
            currentPhase = .installing
            batchProgress = 0
        }
        
        let totalApps = Double(signedAppsForInstall.count)
        
        for (index, app) in signedAppsForInstall.enumerated() {
            await MainActor.run {
                currentSigningApp = app.name ?? "App \(index + 1)"
                batchProgress = Double(index) / totalApps
                installationIndex = index
            }
            
            AppLogManager.shared.info("Installing App \(index + 1)/\(Int(totalApps)): \(app.name ?? "Unknown")", category: "BatchSign")
            
            do {
                // Create ViewModel for installation
                let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
                
                // Archive the signed app
                let handler = ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                let packageUrl = try await handler.archive()
                
                // Install using selected method
                if installationMethod == 0 {
                    // Server-based installation - notify user to open in browser/iTunes
                    let installer = try ServerInstaller(app: app, viewModel: viewModel)
                    await MainActor.run {
                        installer.packageUrl = packageUrl
                        viewModel.status = .ready
                    }
                    
                    // For batch operations, we can't wait for user interaction
                    // Just mark as ready for installation
                    await MainActor.run {
                        if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
                            batchResults[resultIndex] = BatchSignResult(
                                appName: app.name ?? "Unknown",
                                success: true,
                                message: "Signed Successfully (Server Ready)"
                            )
                        }
                        AppLogManager.shared.success("Batch installation ready for \(app.name ?? "Unknown")", category: "BatchSign")
                    }
                } else if installationMethod == 1 {
                    // Direct device installation
                    let installProxy = InstallationProxy(viewModel: viewModel)
                    try await installProxy.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                    
                    await MainActor.run {
                        if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
                            batchResults[resultIndex] = BatchSignResult(
                                appName: app.name ?? "Unknown",
                                success: true,
                                message: "Signed and Installed Successfully"
                            )
                        }
                        AppLogManager.shared.success("Batch installation succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                    }
                }
            } catch {
                await MainActor.run {
                    if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
                        batchResults[resultIndex] = BatchSignResult(
                            appName: app.name ?? "Unknown",
                            success: true,
                            message: "Signed Successfully, Installation Failed: \(error.localizedDescription)"
                        )
                    }
                    AppLogManager.shared.error("Batch installation failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                }
            }
        }
        
        await MainActor.run {
            isSigningBatch = false
            batchProgress = 1.0
            currentPhase = .completed
            selectedApps.removeAll()
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Batch Signing and Installation Completed", type: .success)
            AppLogManager.shared.success("Batch installation completed: \(Int(totalApps)) apps processed", category: "BatchSign")
        }
    }
}

// MARK: - Batch App Row
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
                        HStack(spacing: 4) {
                            Text(app.name ?? "Unknown App")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            if hasCustomOptions {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Text(app.identifier ?? "Unknown Bundle ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Batch App Edit Sheet
struct BatchAppEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let app: AppInfoPresentable
    @Binding var options: Options
    let onDismiss: () -> Void
    
    @State private var editedName: String = ""
    @State private var editedBundleId: String = ""
    @State private var editedVersion: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
.scrollContentBackground(.hidden)
                Section {
                    HStack {
                        Text("Edit App Information")
                            .font(.system(.title3, design: .rounded).bold())
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                Section {
                    HStack {
                        FRAppIconView(app: app, size: 60)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name ?? "Unknown App")
                                .font(.headline)
                            Text(app.identifier ?? "Unknown Bundle ID")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("App Information")
                }
                
                Section {
                    TextField("App Name", text: $editedName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Bundle ID", text: $editedBundleId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Version", text: $editedVersion)
                } header: {
                    Text("Modify App Data")
                } footer: {
                    Text("Leave fields empty to keep the original app values.")
                }
                
                Section {
                    NavigationLink {
                        SigningTweaksView(options: $options)
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(.green)
                            Text("Add Tweaks")
                            Spacer()
                            if !options.injectionFiles.isEmpty {
                                Text("\(options.injectionFiles.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Tweaks & Modifications")
                } footer: {
                    Text("Inject custom tweaks, dylibs, or frameworks into this app.")
                }
                
                Section {
                    Button("Reset To Default") {
                        editedName = app.name ?? ""
                        editedBundleId = app.identifier ?? ""
                        editedVersion = app.version ?? ""
                        options.injectionFiles = []
                    }
                    .foregroundStyle(.orange)
                }

                Section {
                    Button {
                        // Apply changes to options
                        if !editedName.isEmpty {
                            options.appName = editedName
                        }
                        if !editedBundleId.isEmpty {
                            options.appIdentifier = editedBundleId
                        }
                        if !editedVersion.isEmpty {
                            options.appVersion = editedVersion
                        }
                        
                        dismiss()
                        onDismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        Text("Discard Changes")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(.red)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .scrollContentBackground(.hidden)
            .navigationBarHidden(true)
            .onAppear {
                // Initialize with current values
                editedName = options.appName ?? app.name ?? ""
                editedBundleId = options.appIdentifier ?? app.identifier ?? ""
                editedVersion = options.appVersion ?? app.version ?? ""
            }
        }
    }
}
