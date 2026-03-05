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
    @AppStorage("Feather.batchSigning.autoInstall") private var autoInstall = true
    @State private var currentPhase: BatchPhase = .signing
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
        var message: String
        var installLink: String? = nil
        var app: AppInfoPresentable? = nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    certificateSection
                    optionsSection
                    appSelectionSection

                    if !batchResults.isEmpty {
                        resultsSection
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Batch Signing")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    actionSection
                }

                // Progress Overlay
                if isSigningBatch {
                    progressOverlay
                }
            }
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
        }
    }

    // MARK: - Subviews

    private var certificateSection: some View {
        Section("Signing Certificate") {
            if certificates.isEmpty {
                Label("No Certificates Available", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Certificate", selection: $selectedCertificateIndex) {
                    ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                        Text(cert.nickname ?? "Certificate \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    private var optionsSection: some View {
        Section("Batch Options") {
            Toggle(isOn: $autoInstall) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Install")
                        .font(.headline)
                    Text("Install apps automatically after signing all selected apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.accentColor)

            Text("Apps will be signed using the selected certificate and global signing options unless customized.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var appSelectionSection: some View {
        Section {
            if apps.isEmpty {
                Text("No Apps Available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(apps, id: \.uuid) { app in
                    HStack(spacing: 12) {
                        Button {
                            toggleAppSelection(app)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedApps.contains(app.uuid ?? "") ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedApps.contains(app.uuid ?? "") ? Color.accentColor : Color.secondary)

                                FRAppIconView(app: app, size: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name ?? "Unknown App")
                                        .font(.subheadline.bold())

                                    Text(app.identifier ?? "Unknown Bundle ID")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)

                        Spacer()

                        Button {
                            editingAppId = app.uuid
                            showEditSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.subheadline.bold())
                                .foregroundStyle(appOptions[app.uuid ?? ""] != nil ? .white : .accentColor)
                                .padding(8)
                                .background(appOptions[app.uuid ?? ""] != nil ? Color.orange : Color.accentColor.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            HStack {
                Text("Select Apps (\(selectedApps.count))")
                Spacer()
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
                .textCase(nil)
            }
        }
    }

    private var resultsSection: some View {
        Section {
            ForEach(batchResults) { result in
                resultRow(for: result)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            if batchResults.contains(where: { $0.success && $0.installLink != nil }) {
                Button {
                    installAllSigned()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Install All Signed")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
        } header: {
            Text("Signing Results")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func resultRow(for result: BatchSignResult) -> some View {
        HStack(spacing: 12) {
            if let app = result.app {
                FRAppIconView(app: app, size: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(UIColor.secondarySystemFill))
                        .frame(width: 44, height: 44)
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.appName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .font(.caption2)
                        .foregroundStyle(result.success ? .green : .red)

                    Text(result.message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if result.success, let link = result.installLink {
                Button {
                    if let url = URL(string: link) { UIApplication.shared.open(url) }
                } label: {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
        .transition(.asymmetric(insertion: .push(from: .bottom).combined(with: .opacity), removal: .opacity))
    }
    private var actionSection: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                startBatchSigning()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "signature")
                    Text("Sign Selected Apps (\(selectedApps.count))")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch ? Color.gray : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: (selectedApps.isEmpty || certificates.isEmpty || isSigningBatch) ? .clear : Color.accentColor.opacity(0.3), radius: 10, y: 5)
            }
            .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
            .padding()
        }
        .background(.ultraThinMaterial)
    }

    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.1), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: batchProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(batchProgress * 100))%")
                            .font(.system(.title3, design: .rounded).bold())
                        Text(currentPhase == .signing ? "Signing" : "Installing")
                            .font(.system(size: 10, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                    }
                }
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10)

                VStack(spacing: 8) {
                    Text(currentSigningApp)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(currentPhase == .signing ? "Signing Apps..." : "Installing Apps...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(32)
            .frame(width: 280)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity)
        .animation(.spring(), value: batchProgress)
    }

    // MARK: - Logic
    
    private func createDefaultOptions(for app: AppInfoPresentable) -> Options {
        var options = OptionsManager.shared.options
        options.appName = app.name
        options.appVersion = app.version
        options.appIdentifier = app.identifier
        return options
    }
    
    private func toggleAppSelection(_ app: AppInfoPresentable) {
        guard let id = app.uuid else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedApps.contains(id) {
                selectedApps.remove(id)
            } else {
                selectedApps.insert(id)
            }
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
                
                let selectedCert = certificates[selectedCertificateIndex]
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
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: true,
                                        message: "Signed Successfully (Remote)",
                                        installLink: installLink,
                                        app: app
                                    )
                                    batchResults.append(res)

                                    if autoInstall {
                                        if let url = URL(string: installLink) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                case .failure(let error):
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: false,
                                        message: error.localizedDescription,
                                        app: app
                                    )
                                    batchResults.append(res)
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
                            DispatchQueue.main.async {
                                if let error {
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: false,
                                        message: error.localizedDescription,
                                        app: app
                                    )
                                    batchResults.append(res)
                                } else {
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: true,
                                        message: "Signed Successfully",
                                        app: app
                                    )
                                    batchResults.append(res)
                                    signedAppsForInstall.append(app)
                                }
                                continuation.resume()
                            }
                        }
                    }
                }
                
                // For local signing, we can generate the link if needed
                if _serverMethod != 2 && autoInstall && signedAppsForInstall.contains(where: { $0.uuid == app.uuid }) {
                    await triggerInstallation(for: app, appIndex: index)
                }
            }

            await MainActor.run {
                batchProgress = 1.0
                isSigningBatch = false
                selectedApps.removeAll()
            }
        }
    }
    
    private func triggerInstallation(for app: AppInfoPresentable, appIndex: Int) async {
        await MainActor.run {
            currentPhase = .installing
        }
        
        do {
            let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
            let handler = ArchiveHandler(app: app, viewModel: viewModel)
            try await handler.move()
            let packageUrl = try await handler.archive()
            
            if installationMethod == 0 {
                let installer = try ServerInstaller(app: app, viewModel: viewModel)
                await MainActor.run {
                    installer.packageUrl = packageUrl
                    viewModel.status = .ready

                    let link = installer.iTunesLink
                    updateBatchResult(for: app, message: "Signed - Ready to Install", link: link)

                    if let url = URL(string: link) {
                        UIApplication.shared.open(url)
                    }
                }
            } else if installationMethod == 1 {
                let installProxy = InstallationProxy(viewModel: viewModel)
                try await installProxy.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier)
                
                await MainActor.run {
                    updateBatchResult(for: app, message: "Signed and Installed")
                }
            }
        } catch {
            await MainActor.run {
                updateBatchResult(for: app, message: "Signed, Install Failed: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            currentPhase = .signing
        }
    }
    
    private func updateBatchResult(for app: AppInfoPresentable, message: String, link: String? = nil) {
        if let idx = batchResults.firstIndex(where: { $0.app?.uuid == app.uuid && $0.success }) {
            var updated = batchResults[idx]
            updated.message = message
            if let link = link {
                updated.installLink = link
            }
            batchResults[idx] = updated
        }
    }
    
    private func installAllSigned() {
        let links = batchResults.compactMap { $0.installLink }
        for link in links {
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
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
                Section {
                    HStack(spacing: 16) {
                        FRAppIconView(app: app, size: 64)
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name ?? "Unknown")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text(app.identifier ?? "Unknown")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Identifier & Build") {
                    TextField("App Name", text: $editedName)
                    TextField("Bundle ID", text: $editedBundleId)
                    TextField("Version", text: $editedVersion)
                }

                Section("Tweaks & Files") {
                    NavigationLink {
                        SigningTweaksView(options: $options)
                    } label: {
                        Label {
                            Text("Injection Options")
                        } icon: {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(.green)
                        }
                        .badge(options.injectionFiles.count > 0 ? "\(options.injectionFiles.count) Files" : "")
                    }
                }

                Section {
                    Button(action: saveAndDismiss) {
                        Text("Apply Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    Button(role: .destructive, action: { dismiss() }) {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Customize App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
            .onAppear {
                editedName = options.appName ?? app.name ?? ""
                editedBundleId = options.appIdentifier ?? app.identifier ?? ""
                editedVersion = options.appVersion ?? app.version ?? ""
            }
        }
    }

    private func saveAndDismiss() {
        if !editedName.isEmpty { options.appName = editedName }
        if !editedBundleId.isEmpty { options.appIdentifier = editedBundleId }
        if !editedVersion.isEmpty { options.appVersion = editedVersion }
        dismiss()
        onDismiss()
    }
}
