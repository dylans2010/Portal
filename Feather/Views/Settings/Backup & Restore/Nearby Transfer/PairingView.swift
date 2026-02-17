import SwiftUI
import NimbleViews
import MultipeerConnectivity

// MARK: - Pairing View
struct PairingView: View {
    @Environment(\.dismiss) var dismiss
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
    @State private var preflightApproved = false
    
    var body: some View {
        NBList(.localized("Nearby Transfer")) {
            // Mode Selection
            Section {
                Picker("Mode", selection: $selectedMode) {
                    Text("Send").tag(TransferMode.send)
                    Text("Receive").tag(TransferMode.receive)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { newMode in
                    service.stop()
                    if newMode == .send {
                        service.startSendMode()
                    } else {
                        service.startReceiveMode()
                    }
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Transfer Mode"), icon: "arrow.left.arrow.right")
            }
            
            // Instructions
            Section {
                instructionsView
            } header: {
                AppearanceSectionHeader(title: String.localized("Instructions"), icon: "info.circle.fill")
            }
            
            // Pairing Options
            Section {
                // Nearby Pairing - Clean Row Design
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Nearby Pairing")
                                .font(.headline)
                            
                            // Active indicator
                            Text("Active")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        
                        Text("Devices on the same WiFi network. Instant connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if selectedMode == .send && !service.discoveredPeers.isEmpty {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Remote Pairing (OTP) Button - Clean Row Design
                NavigationLink(destination: PairingThroughOTPView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Pair Remotely")
                                    .font(.headline)
                                
                                // Recommended badge
                                Text("Secure")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple)
                                    .clipShape(Capsule())
                            }
                            
                            Text("Connect from anywhere with a code.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Pairing Method"), icon: "rectangle.connected.to.line.below")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose How To Connect Your Devices:")
                        .font(.caption.weight(.semibold))
                    
                    Text("• Nearby Pairing works automatically when both devices are on the same WiFi network for a seamless experience.")
                        .font(.caption)
                    
                    Text("• Remote Pairing uses a secure 6 digit code generated with your WiFi and works over the internet to other devices.")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // Send Mode - Peer List
            if selectedMode == .send {
                Section {
                    if service.discoveredPeers.isEmpty {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Searching For Devices")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(service.discoveredPeers, id: \.self) { peer in
                            Button {
                                selectedPeer = peer
                                initiateBackupSend(to: peer)
                            } label: {
                                HStack {
                                    Image(systemName: "iphone")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading) {
                                        Text(peer.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Tap To Send Backup")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Available Devices"), icon: "antenna.radiowaves.left.and.right")
                }
            }
            
            // Receive Mode - Status
            if selectedMode == .receive {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                                .ifAvailableiOS18SymbolPulse()
                        }
                        
                        VStack(spacing: 8) {
                            Text("Ready To Receive")
                                .font(.headline)
                            Text("Waiting For Sender To Connect...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundStyle(.blue)
                                Text("Device Name:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(UIDevice.current.name)
                                    .font(.headline)
                            }
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.green)
                                Text("Status:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Advertising")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                } header: {
                    AppearanceSectionHeader(title: String.localized("Receiver Status"), icon: "square.and.arrow.down")
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
            }
        }
        .sheet(isPresented: $showingProgress) {
            NavigationStack {
                TransferProgressView(
                    service: service,
                    onCancel: {
                        service.cancelTransfer()
                    },
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
                onHealthCheck: {
                    showPostRestoreHealthCheck = true
                }
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
                        // Perform restore with resolved conflicts
                        performRestoreWithConflicts(backupDir: backupDir, resolvedConflicts: resolvedConflicts)
                    }
                }
            }
        }
        .sheet(isPresented: $showPostRestoreHealthCheck) {
            NavigationStack {
                PostRestoreHealthCheckView {
                    showPostRestoreHealthCheck = false
                    // Show completion screen
                    showRestartCompletionScreen()
                }
            }
        }
        .onAppear {
            if selectedMode == .send {
                service.startSendMode()
            } else {
                service.startReceiveMode()
            }
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
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    private var instructionsView: some View {
        if selectedMode == .send {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Choose Send on your other device and keep Portal open until finished.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                instructionRow(icon: "1.circle.fill", text: "Ensure both devices are on the same network.")
                instructionRow(icon: "2.circle.fill", text: "Select a device from the list below.")
                instructionRow(icon: "3.circle.fill", text: "Wait for the transfer to complete.")
                instructionRow(icon: "4.circle.fill", text: "The backup will be applied on the receiving device.")
            }
            .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Choose Receive on your other device and wait for the sender.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                instructionRow(icon: "1.circle.fill", text: "Keep this screen open. DO NOT close Portal.")
                instructionRow(icon: "2.circle.fill", text: "On the sending device, select this device.")
                instructionRow(icon: "3.circle.fill", text: "Accept the connection when prompted.")
                instructionRow(icon: "4.circle.fill", text: "Wait for the backup to transfer.")
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.body)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Actions
    
    private func initiateBackupSend(to peer: MCPeerID) {
        selectedPeer = peer
        
        // Show preflight check first
        showPreflightCheck = true
    }
    
    private func startBackupSendAfterPreflight(to peer: MCPeerID) {
        // First connect to the peer
        service.connect(to: peer)
        
        // Prepare the backup
        Task {
            if let backupDir = await prepareBackupForTransfer() {
                // Send the backup
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
        // Reuse the backup preparation logic from BackupRestoreView
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NearbyBackup_\(UUID().uuidString)")
        let fileManager = FileManager.default
        
        // Default options - include everything
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
            
            // Copy backup preparation logic from BackupRestoreView
            // This is intentionally duplicated to reuse the exact same logic
            
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
        // Apply conflict resolutions to the restore process
        Task {
            do {
                // Process each conflict resolution
                for conflict in resolvedConflicts {
                    let backupFilePath = backupDir.appendingPathComponent(conflict.path)
                    let destPath = URL.documentsDirectory.appendingPathComponent(conflict.path)

                    switch conflict.resolution {
                    case .keepLocal:
                        // Keep existing data, skip restore for this item
                        continue
                    case .replace:
                        // Replace with backup data
                        if FileManager.default.fileExists(atPath: backupFilePath.path) {
                            try? FileManager.default.removeItem(at: destPath)
                            try FileManager.default.copyItem(at: backupFilePath, to: destPath)
                        }
                    case .duplicate:
                        // For duplicate, we'll prioritize backup data but preserve existing metadata
                        if FileManager.default.fileExists(atPath: backupFilePath.path) {
                            // Copy backup file with a temporary name, then rename
                            let tempPath = destPath.appendingPathExtension("backup")
                            try FileManager.default.copyItem(at: backupFilePath, to: tempPath)
                            // Move temp file to final destination (will replace if exists)
                            try? FileManager.default.removeItem(at: destPath)
                            try FileManager.default.moveItem(at: tempPath, to: destPath)
                        }
                    }
                }

                // Small delay to show progress
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
        // Show completion alert
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

// MARK: - Restore Options View
extension View {
    @ViewBuilder
    func ifAvailableiOS18SymbolPulse() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.pulse, options: .repeating)
        } else {
            self
        }
    }
}
