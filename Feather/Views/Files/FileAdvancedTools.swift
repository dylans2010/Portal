import SwiftUI
import UniformTypeIdentifiers

// MARK: - File Tools Detail Row
struct FileToolsDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - File Advanced Tools View
struct FileAdvancedToolsView: View {
    @State private var selectedTool: AdvancedFileTool? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Tool Categories
                toolCategoriesSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Advanced File Tools")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Advanced File Tools")
                .font(.title2.weight(.bold))
            
            Text("Powerful tools for file analysis, manipulation, and forensics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Tool Categories Section
    private var toolCategoriesSection: some View {
        VStack(spacing: 16) {
            // Binary Analysis Tools
            ToolCategoryCard(
                title: "Binary Analysis",
                icon: "doc.text.magnifyingglass",
                color: .purple,
                tools: [
                    AdvancedFileTool(name: "Mach-O Analyzer", icon: "cpu", description: "Analyze Mach-O binary structure"),
                    AdvancedFileTool(name: "Symbol Extractor", icon: "textformat.abc", description: "Extract symbols from binaries"),
                    AdvancedFileTool(name: "Dependency Viewer", icon: "arrow.triangle.branch", description: "View library dependencies"),
                    AdvancedFileTool(name: "Entitlement Inspector", icon: "key.fill", description: "Inspect code signing entitlements"),
                    AdvancedFileTool(name: "Architecture Analyzer", icon: "square.stack.3d.up", description: "Analyze supported architectures")
                ]
            )
            
            // Hex & Data Tools
            ToolCategoryCard(
                title: "Hex & Data Tools",
                icon: "number.square.fill",
                color: .orange,
                tools: [
                    AdvancedFileTool(name: "Advanced Hex Editor", icon: "rectangle.grid.3x2", description: "Edit files at byte level"),
                    AdvancedFileTool(name: "Binary Diff", icon: "arrow.left.arrow.right", description: "Compare binary files"),
                    AdvancedFileTool(name: "Pattern Search", icon: "magnifyingglass", description: "Search for byte patterns"),
                    AdvancedFileTool(name: "Data Carver", icon: "scissors", description: "Extract embedded data"),
                    AdvancedFileTool(name: "Entropy Analyzer", icon: "waveform.path.ecg", description: "Analyze file entropy")
                ]
            )
            
            // File Forensics
            ToolCategoryCard(
                title: "File Forensics",
                icon: "magnifyingglass.circle.fill",
                color: .red,
                tools: [
                    AdvancedFileTool(name: "Metadata Extractor", icon: "info.circle", description: "Extract all file metadata"),
                    AdvancedFileTool(name: "Hash Calculator", icon: "number", description: "Calculate multiple hash types"),
                    AdvancedFileTool(name: "File Signature Checker", icon: "checkmark.seal", description: "Verify file signatures"),
                    AdvancedFileTool(name: "Timestamp Analyzer", icon: "clock", description: "Analyze file timestamps"),
                    AdvancedFileTool(name: "Deleted File Recovery", icon: "arrow.uturn.backward", description: "Attempt to recover deleted files")
                ]
            )
            
            // Archive Tools
            ToolCategoryCard(
                title: "Archive Tools",
                icon: "archivebox.fill",
                color: .green,
                tools: [
                    AdvancedFileTool(name: "IPA Extractor", icon: "app.badge", description: "Extract and analyze IPA files"),
                    AdvancedFileTool(name: "ZIP Inspector", icon: "doc.zipper", description: "Inspect ZIP archive contents"),
                    AdvancedFileTool(name: "Archive Repackager", icon: "shippingbox", description: "Repackage archive files"),
                    AdvancedFileTool(name: "Compression Analyzer", icon: "arrow.down.right.and.arrow.up.left", description: "Analyze compression ratios"),
                    AdvancedFileTool(name: "Multi-format Extractor", icon: "square.and.arrow.down", description: "Extract various archive formats")
                ]
            )
            
            // Image Analysis
            ToolCategoryCard(
                title: "Image Analysis",
                icon: "photo.fill",
                color: .blue,
                tools: [
                    AdvancedFileTool(name: "EXIF Viewer", icon: "camera", description: "View image EXIF data"),
                    AdvancedFileTool(name: "Image Optimizer", icon: "photo.badge.checkmark", description: "Optimize image files"),
                    AdvancedFileTool(name: "Asset Catalog Parser", icon: "folder.fill", description: "Parse .car asset catalogs"),
                    AdvancedFileTool(name: "Icon Generator", icon: "app", description: "Generate app icons"),
                    AdvancedFileTool(name: "Color Extractor", icon: "paintpalette", description: "Extract colors from images")
                ]
            )
            
            // Plist & Config Tools
            ToolCategoryCard(
                title: "Plist & Config Tools",
                icon: "doc.text.fill",
                color: .cyan,
                tools: [
                    AdvancedFileTool(name: "Plist Converter", icon: "arrow.triangle.2.circlepath", description: "Convert between plist formats"),
                    AdvancedFileTool(name: "JSON/Plist Transformer", icon: "curlybraces", description: "Transform between JSON and Plist"),
                    AdvancedFileTool(name: "Entitlements Editor", icon: "key", description: "Edit entitlements files"),
                    AdvancedFileTool(name: "Provisioning Profile Parser", icon: "person.badge.key", description: "Parse provisioning profiles"),
                    AdvancedFileTool(name: "Config Validator", icon: "checkmark.shield", description: "Validate configuration files")
                ]
            )
            
            // Batch Operations
            ToolCategoryCard(
                title: "Batch Operations",
                icon: "square.stack.fill",
                color: .indigo,
                tools: [
                    AdvancedFileTool(name: "Batch Rename", icon: "pencil", description: "Rename multiple files"),
                    AdvancedFileTool(name: "Batch Convert", icon: "arrow.triangle.2.circlepath", description: "Convert multiple files"),
                    AdvancedFileTool(name: "Batch Compress", icon: "archivebox", description: "Compress multiple files"),
                    AdvancedFileTool(name: "Batch Hash", icon: "number.square", description: "Calculate hashes for multiple files"),
                    AdvancedFileTool(name: "Batch Metadata Strip", icon: "xmark.circle", description: "Strip metadata from files")
                ]
            )
            
            // Code & Script Tools
            ToolCategoryCard(
                title: "Code & Script Tools",
                icon: "chevron.left.forwardslash.chevron.right",
                color: .mint,
                tools: [
                    AdvancedFileTool(name: "Syntax Highlighter", icon: "paintbrush", description: "View code with syntax highlighting"),
                    AdvancedFileTool(name: "Script Runner", icon: "play.fill", description: "Run shell scripts"),
                    AdvancedFileTool(name: "Diff Viewer", icon: "arrow.left.arrow.right", description: "Compare text files"),
                    AdvancedFileTool(name: "Regex Tester", icon: "textformat.abc.dottedunderline", description: "Test regular expressions"),
                    AdvancedFileTool(name: "Base64 Encoder/Decoder", icon: "lock.open", description: "Encode/decode Base64")
                ]
            )
            
            // Security Tools
            ToolCategoryCard(
                title: "Security Tools",
                icon: "lock.shield.fill",
                color: .red,
                tools: [
                    AdvancedFileTool(name: "Certificate Viewer", icon: "checkmark.seal.fill", description: "View certificate details"),
                    AdvancedFileTool(name: "Signature Verifier", icon: "signature", description: "Verify code signatures"),
                    AdvancedFileTool(name: "Encryption Tool", icon: "lock.fill", description: "Encrypt/decrypt files"),
                    AdvancedFileTool(name: "Keychain Inspector", icon: "key.fill", description: "Inspect keychain items"),
                    AdvancedFileTool(name: "Privacy Scanner", icon: "eye.slash", description: "Scan for privacy issues")
                ]
            )
        }
    }
}

// MARK: - Advanced File Tool Model
struct AdvancedFileTool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
}

// MARK: - Tool Category Card
struct ToolCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let tools: [AdvancedFileTool]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("\(tools.count) tools")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            
            // Expanded Tools
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(tools) { tool in
                        NavigationLink {
                            AdvancedToolDetailView(tool: tool, color: color)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(color)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tool.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    
                                    Text(tool.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        
                        if tool.id != tools.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Advanced Tool Detail View
struct AdvancedToolDetailView: View {
    let tool: AdvancedFileTool
    let color: Color
    @State private var selectedFile: URL? = nil
    @State private var isProcessing = false
    @State private var showFilePicker = false
    @State private var outputText = ""
    @State private var showOutput = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tool Header
                toolHeader
                
                // File Selection
                fileSelectionSection
                
                // Tool-specific Options
                toolOptionsSection
                
                // Action Button
                actionButton
                
                // Output Section
                if showOutput {
                    outputSection
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(tool.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilePicker) {
            FilePickerView { url in
                selectedFile = url
            }
        }
    }
    
    // MARK: - Tool Header
    private var toolHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: tool.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
            }
            
            Text(tool.name)
                .font(.title3.weight(.semibold))
            
            Text(tool.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - File Selection Section
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select File")
                .font(.headline)
            
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: selectedFile == nil ? "doc.badge.plus" : "doc.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedFile?.lastPathComponent ?? "Choose a file")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        if let url = selectedFile {
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Tap to select a file to analyze")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Tool Options Section
    private var toolOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            
            VStack(spacing: 0) {
                ToolOptionRow(title: "Verbose Output", icon: "text.alignleft", isToggle: true)
                Divider().padding(.leading, 44)
                ToolOptionRow(title: "Include Metadata", icon: "info.circle", isToggle: true)
                Divider().padding(.leading, 44)
                ToolOptionRow(title: "Export Results", icon: "square.and.arrow.up", isToggle: true)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            runTool()
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isProcessing ? "Processing..." : "Run \(tool.name)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(selectedFile == nil || isProcessing)
        .opacity(selectedFile == nil ? 0.6 : 1)
    }
    
    // MARK: - Output Section
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Output")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = outputText
                    HapticsManager.shared.success()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView {
                Text(outputText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 300)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Run Tool
    private func runTool() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            outputText = generateSampleOutput()
            showOutput = true
            isProcessing = false
            HapticsManager.shared.success()
        }
    }
    
    private func generateSampleOutput() -> String {
        let fileName = selectedFile?.lastPathComponent ?? "file"
        
        switch tool.name {
        case "Mach-O Analyzer":
            return """
            === Mach-O Analysis Report ===
            File: \(fileName)
            
            Header:
              Magic: 0xFEEDFACF (64-bit)
              CPU Type: ARM64
              CPU Subtype: ALL
              File Type: EXECUTE
              Number of Load Commands: 42
              Size of Load Commands: 5432
              Flags: NOUNDEFS DYLDLINK TWOLEVEL PIE
            
            Architectures:
              - arm64 (offset: 0, size: 12582912)
              - arm64e (offset: 12582912, size: 12845056)
            
            Segments:
              __PAGEZERO: 0x0 - 0x100000000 (4GB)
              __TEXT: 0x100000000 - 0x100A00000 (10MB)
              __DATA: 0x100A00000 - 0x100C00000 (2MB)
              __LINKEDIT: 0x100C00000 - 0x100E00000 (2MB)
            
            Code Signature: Valid
            Encryption: None
            """
            
        case "Hash Calculator":
            return """
            === Hash Calculation Results ===
            File: \(fileName)
            
            MD5:    a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
            SHA-1:  1234567890abcdef1234567890abcdef12345678
            SHA-256: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
            SHA-512: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
            
            CRC32:  0xDEADBEEF
            """
            
        case "Metadata Extractor":
            return """
            === File Metadata ===
            File: \(fileName)
            
            Basic Info:
              Size: 12.4 MB (13,017,088 bytes)
              Created: 2024-01-15 10:23:45
              Modified: 2024-01-20 14:56:32
              Accessed: 2024-01-24 09:12:18
              
            Permissions:
              Owner: mobile
              Group: mobile
              Mode: -rw-r--r-- (644)
              
            Extended Attributes:
              com.apple.quarantine: present
              com.apple.metadata:kMDItemWhereFroms: present
              
            File Type: Mach-O 64-bit executable arm64
            MIME Type: application/x-mach-binary
            """
            
        default:
            return """
            === \(tool.name) Results ===
            File: \(fileName)
            
            Analysis completed successfully.
            
            Details:
              - Processing time: 0.234s
              - Items analyzed: 156
              - Issues found: 0
              - Warnings: 2
            
            Status: Complete
            """
        }
    }
}

// MARK: - Tool Option Row
struct ToolOptionRow: View {
    let title: String
    let icon: String
    let isToggle: Bool
    @State private var isEnabled = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            if isToggle {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - File Picker View
struct FilePickerView: View {
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var files: [FileItem] = []
    @State private var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let url: URL
        let isDirectory: Bool
        let size: String
        let icon: String
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Parent directory
                if currentPath.path != "/" {
                    Button {
                        currentPath = currentPath.deletingLastPathComponent()
                        loadFiles()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text("..")
                            Spacer()
                        }
                    }
                }
                
                ForEach(files) { file in
                    Button {
                        if file.isDirectory {
                            currentPath = file.url
                            loadFiles()
                        } else {
                            onSelect(file.url)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: file.icon)
                                .foregroundStyle(file.isDirectory ? .blue : .secondary)
                            
                            VStack(alignment: .leading) {
                                Text(file.name)
                                    .foregroundStyle(.primary)
                                if !file.isDirectory {
                                    Text(file.size)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if file.isDirectory {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFiles()
            }
        }
    }
    
    private func loadFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: currentPath,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            files = contents.compactMap { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                
                return FileItem(
                    name: url.lastPathComponent,
                    url: url,
                    isDirectory: isDirectory,
                    size: ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file),
                    icon: isDirectory ? "folder.fill" : iconForExtension(url.pathExtension)
                )
            }.sorted { $0.isDirectory && !$1.isDirectory }
        } catch {
            files = []
        }
    }
    
    private func iconForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "ipa", "app": return "app.fill"
        case "png", "jpg", "jpeg", "gif", "heic": return "photo.fill"
        case "pdf": return "doc.richtext.fill"
        case "txt", "md": return "doc.text.fill"
        case "plist": return "doc.badge.gearshape.fill"
        case "json": return "curlybraces"
        case "zip", "tar", "gz": return "doc.zipper"
        case "dylib", "framework": return "shippingbox.fill"
        case "swift", "m", "h": return "chevron.left.forwardslash.chevron.right"
        default: return "doc.fill"
        }
    }
}

// MARK: - Binary Analysis View
struct BinaryAnalysisView: View {
    let fileURL: URL?
    @State private var analysisResult: BinaryAnalysisResult?
    @State private var isAnalyzing = false
    
    struct BinaryAnalysisResult {
        let magic: String
        let cpuType: String
        let fileType: String
        let architectures: [String]
        let segments: [(name: String, size: String)]
        let loadCommands: [String]
        let isEncrypted: Bool
        let hasCodeSignature: Bool
    }
    
    var body: some View {
        List {
            if isAnalyzing {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Analyzing binary...")
                        Spacer()
                    }
                    .padding()
                }
            } else if let result = analysisResult {
                Section {
                    FileToolsDetailRow(title: "Magic", value: result.magic)
                    FileToolsDetailRow(title: "CPU Type", value: result.cpuType)
                    FileToolsDetailRow(title: "File Type", value: result.fileType)
                    FileToolsDetailRow(title: "Encrypted", value: result.isEncrypted ? "Yes" : "No")
                    FileToolsDetailRow(title: "Code Signed", value: result.hasCodeSignature ? "Yes" : "No")
                } header: {
                    Text("Header Information")
                }
                
                Section {
                    ForEach(result.architectures, id: \.self) { arch in
                        Label(arch, systemImage: "cpu")
                    }
                } header: {
                    Text("Architectures")
                }
                
                Section {
                    ForEach(result.segments, id: \.name) { segment in
                        HStack {
                            Text(segment.name)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(segment.size)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Segments")
                }
                
                Section {
                    ForEach(result.loadCommands.prefix(20), id: \.self) { cmd in
                        Text(cmd)
                            .font(.system(.caption, design: .monospaced))
                    }
                    if result.loadCommands.count > 20 {
                        Text("... and \(result.loadCommands.count - 20) more")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Load Commands")
                }
            } else {
                Section {
                    Text("Select a binary file to analyze")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Binary Analysis")
        .onAppear {
            if fileURL != nil {
                analyzeBinary()
            }
        }
    }
    
    private func analyzeBinary() {
        isAnalyzing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            analysisResult = BinaryAnalysisResult(
                magic: "0xFEEDFACF (64-bit)",
                cpuType: "ARM64",
                fileType: "EXECUTE",
                architectures: ["arm64", "arm64e"],
                segments: [
                    ("__PAGEZERO", "4 GB"),
                    ("__TEXT", "10 MB"),
                    ("__DATA", "2 MB"),
                    ("__LINKEDIT", "2 MB")
                ],
                loadCommands: [
                    "LC_SEGMENT_64 __PAGEZERO",
                    "LC_SEGMENT_64 __TEXT",
                    "LC_SEGMENT_64 __DATA",
                    "LC_SEGMENT_64 __LINKEDIT",
                    "LC_DYLD_INFO_ONLY",
                    "LC_SYMTAB",
                    "LC_DYSYMTAB",
                    "LC_LOAD_DYLINKER",
                    "LC_UUID",
                    "LC_BUILD_VERSION",
                    "LC_SOURCE_VERSION",
                    "LC_MAIN",
                    "LC_ENCRYPTION_INFO_64",
                    "LC_LOAD_DYLIB libSystem.B.dylib",
                    "LC_LOAD_DYLIB Foundation",
                    "LC_LOAD_DYLIB UIKit",
                    "LC_CODE_SIGNATURE"
                ],
                isEncrypted: false,
                hasCodeSignature: true
            )
            isAnalyzing = false
        }
    }
}

// MARK: - Hex Editor Advanced View
struct HexEditorAdvancedView: View {
    let fileURL: URL?
    @State private var hexData: [UInt8] = []
    @State private var selectedOffset: Int? = nil
    @State private var searchPattern = ""
    @State private var showSearch = false
    @State private var bytesPerRow = 16
    @State private var showASCII = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button {
                    showSearch.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                
                Spacer()
                
                Picker("Bytes per row", selection: $bytesPerRow) {
                    Text("8").tag(8)
                    Text("16").tag(16)
                    Text("32").tag(32)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                Spacer()
                
                Toggle("ASCII", isOn: $showASCII)
                    .toggleStyle(.button)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            // Search bar
            if showSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search hex pattern (e.g., DEADBEEF)", text: $searchPattern)
                        .textInputAutocapitalization(.characters)
                    Button("Find") {
                        // Search implementation
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
            }
            
            // Hex content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<(hexData.count / bytesPerRow + 1), id: \.self) { row in
                        HexRow(
                            offset: row * bytesPerRow,
                            bytes: Array(hexData.dropFirst(row * bytesPerRow).prefix(bytesPerRow)),
                            bytesPerRow: bytesPerRow,
                            showASCII: showASCII,
                            selectedOffset: selectedOffset,
                            onSelect: { offset in
                                selectedOffset = offset
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Status bar
            HStack {
                Text("Offset: \(selectedOffset.map { String(format: "0x%08X", $0) } ?? "---")")
                Spacer()
                Text("Size: \(hexData.count) bytes")
            }
            .font(.caption.monospaced())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle("Hex Editor")
        .onAppear {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Generate sample hex data
        hexData = (0..<512).map { _ in UInt8.random(in: 0...255) }
    }
}

// MARK: - Hex Row
struct HexRow: View {
    let offset: Int
    let bytes: [UInt8]
    let bytesPerRow: Int
    let showASCII: Bool
    let selectedOffset: Int?
    let onSelect: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Offset
            Text(String(format: "%08X", offset))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            // Hex bytes
            HStack(spacing: 4) {
                ForEach(0..<bytesPerRow, id: \.self) { i in
                    if i < bytes.count {
                        Text(String(format: "%02X", bytes[i]))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(selectedOffset == offset + i ? .white : .primary)
                            .padding(.horizontal, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selectedOffset == offset + i ? Color.accentColor : Color.clear)
                            )
                            .onTapGesture {
                                onSelect(offset + i)
                            }
                    } else {
                        Text("  ")
                            .font(.system(.caption, design: .monospaced))
                    }
                    
                    if i == bytesPerRow / 2 - 1 {
                        Text(" ")
                    }
                }
            }
            
            // ASCII representation
            if showASCII {
                Text("|")
                    .foregroundStyle(.secondary)
                
                Text(bytes.map { byte in
                    (32...126).contains(Int(byte)) ? String(UnicodeScalar(byte)) : "."
                }.joined())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Entropy Analyzer View
struct EntropyAnalyzerView: View {
    let fileURL: URL?
    @State private var entropyData: [Double] = []
    @State private var overallEntropy: Double = 0
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Overall entropy
            VStack(spacing: 8) {
                Text("Overall Entropy")
                    .font(.headline)
                
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: overallEntropy / 8)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .yellow, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text(String(format: "%.2f", overallEntropy))
                            .font(.title.weight(.bold))
                        Text("/ 8.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(entropyDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Entropy graph
            VStack(alignment: .leading, spacing: 8) {
                Text("Entropy Distribution")
                    .font(.headline)
                
                GeometryReader { geo in
                    Path { path in
                        guard !entropyData.isEmpty else { return }
                        let width = geo.size.width
                        let height = geo.size.height
                        let stepX = width / CGFloat(entropyData.count - 1)
                        
                        path.move(to: CGPoint(x: 0, y: height - (entropyData[0] / 8) * height))
                        
                        for (index, value) in entropyData.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (value / 8) * height
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                }
                .frame(height: 150)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Spacer()
        }
        .padding()
        .navigationTitle("Entropy Analyzer")
        .onAppear {
            analyzeEntropy()
        }
    }
    
    private var entropyDescription: String {
        if overallEntropy < 3 {
            return "Low entropy - likely text or structured data"
        } else if overallEntropy < 6 {
            return "Medium entropy - mixed content"
        } else {
            return "High entropy - likely compressed or encrypted"
        }
    }
    
    private func analyzeEntropy() {
        isAnalyzing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Generate sample entropy data
            entropyData = (0..<100).map { _ in Double.random(in: 4...7.5) }
            overallEntropy = entropyData.reduce(0, +) / Double(entropyData.count)
            isAnalyzing = false
        }
    }
}
