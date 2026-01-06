import SwiftUI
import NimbleViews

// MARK: - QuickInspectView
struct QuickInspectView: View {
    let file: FileItem
    @Environment(\.dismiss) private var dismiss
    @State private var fileInfo: FileAnalysisEngine.FileInformation?
    @State private var hashInfo: FileAnalysisEngine.HashInformation?
    @State private var ipaInfo: FileAnalysisEngine.IPAInformation?
    @State private var machoInfo: FileAnalysisEngine.MachOInformation?
    @State private var isLoading = true
    @State private var hasContent = false
    
    var body: some View {
        NBNavigationView(.localized("Quick Inspect"), displayMode: .inline) {
            ScrollView {
                VStack(spacing: 20) {
                    // File Icon and Name
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            file.iconColor.opacity(0.15),
                                            file.iconColor.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: file.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [file.iconColor, file.iconColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: file.iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text(file.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if !hasContent {
                        // Error state when file doesn't support Quick Inspect
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)
                            
                            Text(.localized("Quick Inspect Not Supported"))
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(.localized("This file type cannot be inspected with Quick Inspect. Try opening it with a specific editor or viewer."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Basic Info Section
                        if let info = fileInfo {
                            infoSection(info)
                        }
                        
                        // Hash Info Section
                        if let hashes = hashInfo {
                            hashSection(hashes)
                        }
                        
                        // IPA Info Section
                        if let ipa = ipaInfo {
                            ipaSection(ipa)
                        }
                        
                        // Mach-O Info Section
                        if let macho = machoInfo {
                            machoSection(macho)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadFileInformation()
        }
    }
    
    @ViewBuilder
    private func infoSection(_ info: FileAnalysisEngine.FileInformation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("File Information"))
                .font(.headline)
                .foregroundStyle(.primary)
            
            GroupBox {
                VStack(spacing: 10) {
                    QuickInfoRow(label: .localized("Type"), value: info.type.displayName)
                    QuickInfoRow(label: .localized("Size"), value: ByteCountFormatter.string(fromByteCount: Int64(info.size), countStyle: .file))
                    QuickInfoRow(label: .localized("Path"), value: info.path)
                    
                    if !info.magicSignature.isEmpty && info.magicSignature.trimmingCharacters(in: .whitespaces) != "" {
                        QuickInfoRow(label: .localized("Magic Bytes"), value: info.magicSignature)
                    }
                    
                    QuickInfoRow(label: .localized("Executable"), value: info.isExecutable ? "Yes" : "No")
                }
            }
        }
    }
    
    @ViewBuilder
    private func hashSection(_ hashes: FileAnalysisEngine.HashInformation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Hashes"))
                .font(.headline)
                .foregroundStyle(.primary)
            
            GroupBox {
                VStack(spacing: 10) {
                    HashRow(label: "MD5", value: hashes.md5)
                    HashRow(label: "SHA1", value: hashes.sha1)
                    HashRow(label: "SHA256", value: hashes.sha256)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ipaSection(_ ipa: FileAnalysisEngine.IPAInformation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("IPA Information"))
                .font(.headline)
                .foregroundStyle(.primary)
            
            GroupBox {
                VStack(spacing: 10) {
                    QuickInfoRow(label: .localized("Bundle ID"), value: ipa.bundleId)
                    QuickInfoRow(label: .localized("Version"), value: ipa.version)
                    QuickInfoRow(label: .localized("Min OS"), value: ipa.minOSVersion)
                    QuickInfoRow(label: .localized("Display Name"), value: ipa.displayName)
                    QuickInfoRow(label: .localized("Signed"), value: ipa.isSigned ? "Yes" : "No")
                    QuickInfoRow(label: .localized("Has Provisioning"), value: ipa.hasProvisioning ? "Yes" : "No")
                    QuickInfoRow(label: .localized("Executables"), value: "\(ipa.numberOfExecutables)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func machoSection(_ macho: FileAnalysisEngine.MachOInformation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Mach-O Information"))
                .font(.headline)
                .foregroundStyle(.primary)
            
            GroupBox {
                VStack(spacing: 10) {
                    QuickInfoRow(label: .localized("Valid"), value: macho.isValid ? "Yes" : "No")
                    QuickInfoRow(label: .localized("Architecture"), value: macho.architectures)
                    QuickInfoRow(label: .localized("64-bit"), value: macho.is64Bit ? "Yes" : "No")
                    QuickInfoRow(label: .localized("ARM64e"), value: macho.isArm64e ? "Yes" : "No")
                    QuickInfoRow(label: .localized("PIE"), value: macho.isPIE ? "Yes" : "No")
                    QuickInfoRow(label: .localized("Encrypted"), value: macho.hasEncryption ? "Yes" : "No")
                    QuickInfoRow(label: .localized("Load Commands"), value: "\(macho.numberOfLoadCommands)")
                }
            }
        }
    }
    
    private func loadFileInformation() async {
        isLoading = true
        
        await Task.detached {
            let path = file.url.path
            
            // Get basic file info
            let info = FileAnalysisEngine.getFileInformation(at: path)
            
            // Calculate hashes (for smaller files)
            var hashes: FileAnalysisEngine.HashInformation?
            if file.sizeInBytes ?? 0 < 100_000_000 { // Only for files < 100MB
                hashes = FileAnalysisEngine.computeHashes(for: path)
            }
            
            // Analyze specific file types
            var ipa: FileAnalysisEngine.IPAInformation?
            var macho: FileAnalysisEngine.MachOInformation?
            
            if file.url.pathExtension.lowercased() == "ipa" {
                ipa = FileAnalysisEngine.analyzeIPAFile(at: path)
            }
            
            if info?.type == .machO || file.url.pathExtension.lowercased() == "dylib" {
                macho = FileAnalysisEngine.analyzeMachOFile(at: path)
            }
            
            // Capture copies for use in MainActor context
            let hashesCopy = hashes
            let ipaCopy = ipa
            let machoCopy = macho
            
            await MainActor.run {
                self.fileInfo = info
                self.hashInfo = hashesCopy
                self.ipaInfo = ipaCopy
                self.machoInfo = machoCopy
                
                // Determine if we have any content to show
                self.hasContent = info != nil || hashesCopy != nil || ipaCopy != nil || machoCopy != nil
                
                self.isLoading = false
            }
            }
        }.value
    }
}

// MARK: - QuickInfoRow
private struct QuickInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

// MARK: - HashRow
private struct HashRow: View {
    let label: String
    let value: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = value
                    copied = true
                    HapticsManager.shared.success()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(copied ? .green : .blue)
                        .font(.caption)
                }
            }
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(nil)
        }
    }
}

// MARK: - Preview
struct QuickInspectView_Previews: PreviewProvider {
    static var previews: some View {
        let testFile = FileItem(
            name: "test.ipa",
            url: URL(fileURLWithPath: "/test.ipa"),
            isDirectory: false,
            size: "10 MB",
            sizeInBytes: 10_000_000,
            modificationDate: Date(),
            customIcon: nil
        )
        
        QuickInspectView(file: testFile)
    }
}
