import SwiftUI
import CoreData
import IDeviceSwift

// MARK: - Batch Signing View
struct BatchSigningView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
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
    
    @State private var appOptions: [String: Options] = [:]
    @State private var editingAppId: String? = nil
    @State private var showEditSheet = false
    @State private var appeared = false
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    
    enum BatchPhase { case signing, installing, completed }
    
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
                ScrollView {
                    VStack(spacing: 20) {
                        certificateSection
                        optionsSection
                        appSelectionSection
                        if !batchResults.isEmpty { resultsSection }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .navigationTitle("Batch Signing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(themeManager.secondaryTextColor)
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                    }
                }

                VStack {
                    Spacer()
                    actionSection
                }

                if isSigningBatch { progressOverlay }
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
                        onDismiss: { showEditSheet = false }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .onAppear {
                if !appeared {
                    appeared = true
                    selectedApps = Set(apps.compactMap { $0.uuid })
                }
            }
        }
    }

    // MARK: - Certificate Section

    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Certificate", systemImage: "seal.fill")
                .font(.subheadline.bold())
                .foregroundStyle(themeManager.secondaryTextColor)

            if certificates.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(themeManager.accentColor)
                        .font(.title3)
                    Text("No Certificates Available")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.title3)
                        .foregroundStyle(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                        .background(themeManager.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Picker("Certificate", selection: $selectedCertificateIndex) {
                        ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                            Text(cert.nickname ?? "Certificate \(index + 1)").tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(themeManager.primaryTextColor)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Options", systemImage: "slider.horizontal.3")
                .font(.subheadline.bold())
                .foregroundStyle(themeManager.secondaryTextColor)

            Toggle(isOn: $autoInstall) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.title3)
                        .foregroundStyle(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                        .background(themeManager.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("Auto Install After Signing")
                        .font(.subheadline.weight(.medium))
                }
            }
            .tint(themeManager.accentColor)
            .padding(14)
            .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - App Selection Section

    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Apps (\(selectedApps.count)/\(apps.count))", systemImage: "square.stack.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(themeManager.secondaryTextColor)
                Spacer()
                Button(selectedApps.count == apps.count ? "Deselect All" : "Select All") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedApps.count == apps.count {
                            selectedApps.removeAll()
                        } else {
                            selectedApps = Set(apps.compactMap { $0.uuid })
                        }
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(themeManager.accentColor)
            }

            if apps.isEmpty {
                Text("No Apps Available")
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(apps.enumerated()), id: \.element.uuid) { index, app in
                        appSelectionRow(for: app)

                        if index < apps.count - 1 {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func appSelectionRow(for app: AppInfoPresentable) -> some View {
        let isSelected = selectedApps.contains(app.uuid ?? "")

        HStack(spacing: 12) {
            Button { toggleAppSelection(app) } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.35))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)

                    FRAppIconView(app: app, size: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name ?? "Unknown App")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(app.identifier ?? "")
                            .font(.caption2.monospaced())
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                editingAppId = app.uuid
                showEditSheet = true
            } label: {
                Image(systemName: appOptions[app.uuid ?? ""] != nil ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(appOptions[app.uuid ?? ""] != nil ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        appOptions[app.uuid ?? ""] != nil
                            ? AnyShapeStyle(themeManager.accentColor)
                            : AnyShapeStyle(themeManager.groupedBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .opacity(isSelected ? 1.0 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Results", systemImage: "checkmark.seal.fill")
                .font(.subheadline.bold())
                .foregroundStyle(themeManager.secondaryTextColor)

            VStack(spacing: 8) {
                ForEach(batchResults) { result in
                    resultRow(for: result)
                }

                if batchResults.contains(where: { $0.success && $0.installLink != nil }) {
                    Button { installAllSigned() } label: {
                        Label("Install All Signed", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func resultRow(for result: BatchSignResult) -> some View {
        HStack(spacing: 12) {
            if let app = result.app {
                FRAppIconView(app: app, size: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(themeManager.groupedBackgroundColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: "app.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.appName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(result.success ? .green : .red)
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
            }

            Spacer()

            if result.success, let link = result.installLink {
                Button {
                    if let url = URL(string: link) { UIApplication.shared.open(url) }
                } label: {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(themeManager.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeManager.cardBackgroundColor)
        )
        .transition(.asymmetric(insertion: .push(from: .bottom).combined(with: .opacity), removal: .opacity))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 0) {
            Divider()
            Button { startBatchSigning() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "signature")
                        .font(.system(size: 16, weight: .bold))
                    Text(selectedApps.isEmpty ? "Select Apps to Sign" : "Sign \(selectedApps.count) App\(selectedApps.count == 1 ? "" : "s")")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    canSign
                        ? AnyShapeStyle(LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(themeManager.secondaryTextColor.opacity(0.2))
                )
                .foregroundStyle(canSign ? .white : themeManager.secondaryTextColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: canSign ? themeManager.accentColor.opacity(0.3) : .clear, radius: 10, y: 5)
            }
            .disabled(!canSign)
            .animation(.easeInOut(duration: 0.2), value: canSign)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }

    private var canSign: Bool {
        !selectedApps.isEmpty && !certificates.isEmpty && !isSigningBatch
    }

    // MARK: - Progress Overlay

    private var progressOverlay: some View {
        ZStack {
            themeManager.primaryTextColor.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(themeManager.accentColor.opacity(0.12), lineWidth: 7)
                        .frame(width: 96, height: 96)
                    Circle()
                        .trim(from: 0, to: batchProgress)
                        .stroke(
                            LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.35), value: batchProgress)

                    VStack(spacing: 2) {
                        Text("\(Int(batchProgress * 100))%")
                            .font(.system(.title3, design: .rounded).bold())
                        Text(currentPhase == .signing ? "Signing" : "Installing")
                            .font(.system(size: 9, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .tracking(0.5)
                    }
                }

                VStack(spacing: 6) {
                    Text(currentSigningApp)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(currentPhase == .signing ? "Signing in progress..." : "Installing...")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .padding(32)
            .frame(width: 270)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    let app: AppInfoPresentable
    @Binding var options: Options
    let onDismiss: () -> Void

    @State private var editedName: String = ""
    @State private var editedBundleId: String = ""
    @State private var editedVersion: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 14) {
                        FRAppIconView(app: app, size: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.name ?? "Unknown")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text(app.identifier ?? "Unknown")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(themeManager.secondaryTextColor)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Identifier & Build")
                            .font(.subheadline.bold())
                            .foregroundStyle(themeManager.secondaryTextColor)

                        VStack(spacing: 0) {
                            editField(title: "App Name", text: $editedName)
                            Divider().padding(.leading, 16)
                            editField(title: "Bundle ID", text: $editedBundleId, keyboard: .URL, capitalize: false)
                            Divider().padding(.leading, 16)
                            editField(title: "Version", text: $editedVersion)
                        }
                        .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tweaks & Files")
                            .font(.subheadline.bold())
                            .foregroundStyle(themeManager.secondaryTextColor)

                        NavigationLink {
                            SigningTweaksView(options: $options)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.title3)
                                    .foregroundStyle(themeManager.accentColor)
                                    .frame(width: 36, height: 36)
                                    .background(themeManager.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text("Injection Options")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(themeManager.primaryTextColor)

                                Spacer()

                                if options.injectionFiles.count > 0 {
                                    Text("\(options.injectionFiles.count)")
                                        .font(.caption.bold())
                                        .foregroundStyle(themeManager.buttonTextColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(themeManager.accentColor, in: Capsule())
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(themeManager.secondaryTextColor.opacity(0.7))
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)
                        .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(spacing: 10) {
                        Button(action: saveAndDismiss) {
                            Text("Apply Changes")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(themeManager.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(themeManager.buttonTextColor)
                        }

                        Button(role: .destructive) { dismiss() } label: {
                            Text("Discard")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(themeManager.appBackgroundColor)
            .navigationTitle("Customize App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
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

    private func editField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, capitalize: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(themeManager.secondaryTextColor)
                .frame(width: 85, alignment: .leading)
            TextField(title, text: text)
                .font(.subheadline)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard == .URL)
                .textInputAutocapitalization(capitalize ? .sentences : .never)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func saveAndDismiss() {
        if !editedName.isEmpty { options.appName = editedName }
        if !editedBundleId.isEmpty { options.appIdentifier = editedBundleId }
        if !editedVersion.isEmpty { options.appVersion = editedVersion }
        dismiss()
        onDismiss()
    }
}
