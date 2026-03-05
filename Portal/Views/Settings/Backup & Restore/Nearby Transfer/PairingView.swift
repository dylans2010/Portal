import SwiftUI
import NimbleViews
import MultipeerConnectivity

// MARK: - Pairing View
struct PairingView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @StateObject private var service = NearbyTransferService()
    @State private var selectedMode: TransferMode = .receive
    @State private var showingProgress = false
    @State private var selectedPeer: MCPeerID?
    @State private var backupDirectory: URL?
    @State private var showRestoreOptions = false
    @State private var showOTPPairing = false
    @State private var showPreflightCheck = false
    @State private var showConflictResolver = false
    @State private var showPostRestoreHealthCheck = false
    @Namespace private var animation
    
    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    PairingHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // Mode Selection
            Section {
                Picker("Transfer Mode", selection: $selectedMode) {
                    Text("Send").tag(TransferMode.send)
                    Text("Receive").tag(TransferMode.receive)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                .onChange(of: selectedMode) { _ in
                    updateServiceMode()
                }
            } header: {
                Text(.localized("Transfer Mode"))
            }
            
            // Pairing Method
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nearby Pairing")
                            .font(.headline)
                        Text("Instant connection for devices on the same Wi-Fi.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.blue)
                }
                
                NavigationLink(destination: PairingThroughOTPView()) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pair Remotely")
                                .font(.headline)
                            Text("Secure 6 digit code connection over the internet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.purple)
                    }
                }
            } header: {
                Text(.localized("Pairing Method"))
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Nearby Pairing: Uses local network discovery.")
                    Text("• Remote Pairing: Uses a secure code for connection.")
                }
            }
            
            // Send Mode - Peer List
            if selectedMode == .send {
                Section {
                    if service.discoveredPeers.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Searching For Nearby Devices...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(service.discoveredPeers, id: \.self) { peer in
                            Button {
                                selectedPeer = peer
                                initiateBackupSend(to: peer)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(peer.displayName)
                                            .font(.headline)
                                        Text("Tap To Establish Secure Connection")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: peer.displayName.contains("iPad") ? "ipad.gen2" : "iphone.gen2")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(.localized("Available Devices"))
                }
            }
            
            // Receive Mode - Status
            if selectedMode == .receive {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                            .padding(.top, 10)
                        
                        Text("Ready To Receive")
                            .font(.headline)

                        Text("Stay on this screen to remain visible to senders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("Device Name", systemImage: "iphone")
                                Spacer()
                                Text(UIDevice.current.name).foregroundStyle(.secondary)
                            }
                            HStack {
                                Label("Connection", systemImage: "lock.shield.fill")
                                Spacer()
                                Text("Encrypted").foregroundStyle(.green)
                            }
                            HStack {
                                Label("Visibility", systemImage: "dot.radiowaves.left.and.right")
                                Spacer()
                                Text("Advertising").foregroundStyle(.blue)
                            }
                        }
                        .font(.subheadline)
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                } header: {
                    Text(.localized("Receiver Status"))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    service.stop()
                    dismiss()
                }
                .font(.system(.body, design: .rounded, weight: .bold))
            }
        }
        .sheet(isPresented: $showingProgress) {
            NavigationStack {
                TransferProgressView(
                    service: service,
                    onCancel: { service.cancelTransfer() },
                    onRetry: {
                        if selectedMode == .send, let peer = selectedPeer {
                            initiateBackupSend(to: peer)
                        } else {
                            service.resetReceive()
                            service.startReceiveMode()
                        }
                    }
                )
                .navigationTitle("Transfer Progress")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if case .completed = service.state {
                            Button("Done") {
                                showingProgress = false
                                if selectedMode == .receive {
                                    showRestoreOptions = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRestoreOptions) {
            RestoreOptionsView(
                onConflictResolution: { backupDir in
                    backupDirectory = backupDir
                    showConflictResolver = true
                },
                onHealthCheck: { showPostRestoreHealthCheck = true }
            )
        }
        .sheet(isPresented: $showPreflightCheck) {
            NavigationStack {
                PreflightCheckView {
                    showPreflightCheck = false
                    if let peer = selectedPeer {
                        startBackupSendAfterPreflight(to: peer)
                    }
                }
            }
        }
        .sheet(isPresented: $showConflictResolver) {
            NavigationStack {
                if let backupDir = backupDirectory {
                    ConflictResolverView(backupDirectory: backupDir) { resolvedConflicts in
                        showConflictResolver = false
                        performRestoreWithConflicts(backupDir: backupDir, resolvedConflicts: resolvedConflicts)
                    }
                }
            }
        }
        .sheet(isPresented: $showPostRestoreHealthCheck) {
            NavigationStack {
                PostRestoreHealthCheckView {
                    showPostRestoreHealthCheck = false
                    showRestartCompletionScreen()
                }
            }
        }
        .onAppear {
            updateServiceMode()
        }
        .onDisappear {
            service.stop()
        }
        .onChange(of: service.state) { newState in
            switch newState {
            case .connecting, .transferring:
                showingProgress = true
            case .completed:
                if !showingProgress {
                    showingProgress = true
                }
            case .failed(let error):
                UIAlertController.showAlertWithOk(title: .localized("Transfer Failed"), message: error.localizedDescription)
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Components

    @ViewBuilder
    private func modeCard(mode: TransferMode, title: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedMode = mode
                updateServiceMode()
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(selectedMode == mode ? .white : color)

                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(selectedMode == mode ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                if selectedMode == mode {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color)
                        .matchedGeometryEffect(id: "modeBackground", in: animation)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pairingMethodCard(title: String, subtitle: String, icon: String, gradientColors: [Color], isActive: Bool, badge: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom))
                    .pulseEffect()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))

                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                }
                
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.5), radius: 3)
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func deviceIcon(for name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 48, height: 48)

            Image(systemName: name.contains("iPad") ? "ipad.gen2" : "iphone.gen2")
                .font(.title3)
                .foregroundStyle(.blue)
        }
    }
    
    @ViewBuilder
    private func statusRow(icon: String, label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(valueColor)
        }
    }
    
    // MARK: - Logic

    private func updateServiceMode() {
        service.stop()
        if selectedMode == .send {
            service.startSendMode()
        } else {
            service.startReceiveMode()
        }
    }
    
    private func initiateBackupSend(to peer: MCPeerID) {
        selectedPeer = peer
        showPreflightCheck = true
    }
    
    private func startBackupSendAfterPreflight(to peer: MCPeerID) {
        service.connect(to: peer)
        Task {
            if let backupDir = await prepareBackupForTransfer() {
                service.sendBackup(from: backupDir, to: peer)
            } else {
                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Error"),
                        message: .localized("Failed to prepare backup for transfer.")
                    )
                }
            }
        }
    }
    
    private func prepareBackupForTransfer() async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NearbyBackup_\(UUID().uuidString)")
        let fileManager = FileManager.default
        
        let options = BackupOptions(
            includeCertificates: true,
            includeSignedApps: true,
            includeImportedApps: true,
            includeSources: true,
            includeDefaultFrameworks: true,
            includeArchives: true
        )
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // 1. Certificates
            if options.includeCertificates {
                let certificatesDir = tempDir.appendingPathComponent("certificates")
                try? fileManager.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
                
                let src = fileManager.certificates
                if fileManager.fileExists(atPath: src.path) {
                    for file in (try? fileManager.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? fileManager.copyItem(at: file, to: certificatesDir.appendingPathComponent(file.lastPathComponent))
                    }
                }
                
                let certificates = Storage.shared.getAllCertificates()
                var certMetadata: [[String: Any]] = []
                for cert in certificates {
                    guard let uuid = cert.uuid else { continue }
                    var metadata: [String: Any] = ["uuid": uuid]
                    if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
                        metadata["name"] = provisionData.Name
                        if let teamID = provisionData.TeamIdentifier.first { metadata["teamID"] = teamID }
                        metadata["teamName"] = provisionData.TeamName
                    }
                    if let date = cert.date { metadata["date"] = date.timeIntervalSince1970 }
                    metadata["ppQCheck"] = cert.ppQCheck
                    if let password = cert.password { metadata["password"] = password }
                    certMetadata.append(metadata)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: certMetadata)
                try jsonData.write(to: tempDir.appendingPathComponent("certificates_metadata.json"))
            }
            
            // 2. Sources
            if options.includeSources {
                let sources = Storage.shared.getSources()
                let sourcesData = sources.compactMap { source -> [String: String]? in
                    guard let urlString = source.sourceURL?.absoluteString,
                          let name = source.name,
                          let identifier = source.identifier else { return nil }
                    return ["url": urlString, "name": name, "identifier": identifier]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: sourcesData)
                try jsonData.write(to: tempDir.appendingPathComponent("sources.json"))
            }
            
            // 3. Signed Apps
            if options.includeSignedApps {
                let signedAppsDir = tempDir.appendingPathComponent("signed_apps")
                try? fileManager.createDirectory(at: signedAppsDir, withIntermediateDirectories: true)
                
                let src = fileManager.signed
                if fileManager.fileExists(atPath: src.path) {
                    let folders = (try? fileManager.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? []
                    for folder in folders {
                        try? fileManager.copyItem(at: folder, to: signedAppsDir.appendingPathComponent(folder.lastPathComponent))
                    }
                }
                
                let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
                let appsData = signedApps.compactMap { app -> [String: String]? in
                    guard let uuid = app.uuid else { return nil }
                    return ["uuid": uuid, "name": app.name ?? "", "identifier": app.identifier ?? "", "version": app.version ?? ""]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("signed_apps_metadata.json"))
            }
            
            // 4. Imported Apps
            if options.includeImportedApps {
                let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
                try? fileManager.createDirectory(at: importedAppsDir, withIntermediateDirectories: true)
                
                let src = fileManager.unsigned
                if fileManager.fileExists(atPath: src.path) {
                    let folders = (try? fileManager.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? []
                    for folder in folders {
                        try? fileManager.copyItem(at: folder, to: importedAppsDir.appendingPathComponent(folder.lastPathComponent))
                    }
                }
                
                let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
                let appsData = importedApps.compactMap { app -> [String: String]? in
                    guard let uuid = app.uuid else { return nil }
                    return ["uuid": uuid, "name": app.name ?? "", "identifier": app.identifier ?? "", "version": app.version ?? ""]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("imported_apps_metadata.json"))
            }
            
            // 5. Default Frameworks
            if options.includeDefaultFrameworks {
                let dest = tempDir.appendingPathComponent("default_frameworks")
                try? fileManager.createDirectory(at: dest, withIntermediateDirectories: true)
                
                let src = Storage.shared.documentsURL.appendingPathComponent("DefaultFrameworks")
                if fileManager.fileExists(atPath: src.path) {
                    for file in (try? fileManager.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? fileManager.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }
            
            // 6. Archives
            if options.includeArchives {
                let dest = tempDir.appendingPathComponent("archives")
                try? fileManager.createDirectory(at: dest, withIntermediateDirectories: true)
                let src = fileManager.archives
                if fileManager.fileExists(atPath: src.path) {
                    for file in (try? fileManager.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? fileManager.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }
            
            // 7. Extra Files
            let extraDir = tempDir.appendingPathComponent("extra_files")
            try? fileManager.createDirectory(at: extraDir, withIntermediateDirectories: true)
            let rootFiles = (try? fileManager.contentsOfDirectory(at: Storage.shared.documentsURL, includingPropertiesForKeys: nil)) ?? []
            for fileURL in rootFiles {
                let ext = fileURL.pathExtension.lowercased()
                let name = fileURL.lastPathComponent
                let importantExtensions = ["plist", "pem", "crt", "txt", "json", "log"]
                let importantNames = ["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"]
                
                if importantExtensions.contains(ext) || importantNames.contains(name) {
                    if ext == "sqlite" || name.contains("-shm") || name.contains("-wal") { continue }
                    try? fileManager.copyItem(at: fileURL, to: extraDir.appendingPathComponent(name))
                }
            }
            
            // 8. Database
            let dbDir = tempDir.appendingPathComponent("database")
            try? fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
            if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                let dir = storeURL.deletingLastPathComponent()
                for f in [storeURL.lastPathComponent, "\(storeURL.lastPathComponent)-shm", "\(storeURL.lastPathComponent)-wal"] {
                    let url = dir.appendingPathComponent(f)
                    if fileManager.fileExists(atPath: url.path) {
                        try? fileManager.copyItem(at: url, to: dbDir.appendingPathComponent(f))
                    }
                }
            }
            
            // 9. Settings
            let defaults = UserDefaults.standard.dictionaryRepresentation()
            let filtered = defaults.filter { k, _ in
                !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") &&
                !k.hasPrefix("WebKit") && !k.hasPrefix("CPU") && !k.hasPrefix("metal")
            }
            let data = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
            try data.write(to: tempDir.appendingPathComponent("settings.plist"))
            
            // 10. Marker
            try "PORTAL_BACKUP_v1.0_\(Date().timeIntervalSince1970)".write(to: tempDir.appendingPathComponent("PORTAL_BACKUP_MARKER.txt"), atomically: true, encoding: .utf8)
            
            return tempDir
        } catch {
            return nil
        }
    }

    private func performRestoreWithConflicts(backupDir: URL, resolvedConflicts: [ConflictItem]) {
        Task {
            do {
                for conflict in resolvedConflicts {
                    let backupFilePath = backupDir.appendingPathComponent(conflict.path)
                    let destPath = URL.documentsDirectory.appendingPathComponent(conflict.path)

                    switch conflict.resolution {
                    case .keepLocal:
                        continue
                    case .replace:
                        if FileManager.default.fileExists(atPath: backupFilePath.path) {
                            try? FileManager.default.removeItem(at: destPath)
                            try FileManager.default.copyItem(at: backupFilePath, to: destPath)
                        }
                    case .duplicate:
                        if FileManager.default.fileExists(atPath: backupFilePath.path) {
                            let tempPath = destPath.appendingPathExtension("backup")
                            try FileManager.default.copyItem(at: backupFilePath, to: tempPath)
                            try? FileManager.default.removeItem(at: destPath)
                            try FileManager.default.moveItem(at: tempPath, to: destPath)
                        }
                    }
                }
                try await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    showPostRestoreHealthCheck = true
                }
            } catch {
                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Restore Error"),
                        message: .localized("Failed to apply conflict resolutions: \(error.localizedDescription)")
                    )
                }
            }
        }
    }

    private func showRestartCompletionScreen() {
        let alert = UIAlertController(
            title: .localized("Backup Applied"),
            message: .localized("Backup applied. Portal must restart to finalize changes."),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: .localized("Restart Now"), style: .default) { _ in
            HapticsManager.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.suspendAndReopen()
            }
        })

        alert.addAction(UIAlertAction(title: .localized("Later"), style: .cancel))
        UIApplication.topViewController()?.present(alert, animated: true)
    }
}
