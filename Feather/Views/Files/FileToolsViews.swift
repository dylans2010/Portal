import SwiftUI
import NimbleViews
import CryptoKit
import UniformTypeIdentifiers

// MARK: - Create JSON File View
struct CreateJSONFileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fileName = ""
    @State private var jsonContent = "{\n    \n}"
    let directoryURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("File Name"))
                } footer: {
                    Text(.localized(".json extension will be added automatically"))
                }
                
                Section {
                    TextEditor(text: $jsonContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    Text(.localized("Content"))
                }
            }
            .navigationTitle(.localized("Create JSON File"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createFile()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private func createFile() {
        let name = fileName.hasSuffix(".json") ? fileName : "\(fileName).json"
        let fileURL = directoryURL.appendingPathComponent(name)
        try? jsonContent.write(to: fileURL, atomically: true, encoding: .utf8)
        HapticsManager.shared.success()
        dismiss()
    }
}

// MARK: - Create XML File View
struct CreateXMLFileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fileName = ""
    @State private var xmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>\n    \n</root>"
    let directoryURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("File Name"))
                } footer: {
                    Text(.localized(".xml extension will be added automatically"))
                }
                
                Section {
                    TextEditor(text: $xmlContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    Text(.localized("Content"))
                }
            }
            .navigationTitle(.localized("Create XML File"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createFile()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private func createFile() {
        let name = fileName.hasSuffix(".xml") ? fileName : "\(fileName).xml"
        let fileURL = directoryURL.appendingPathComponent(name)
        try? xmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
        HapticsManager.shared.success()
        dismiss()
    }
}

// MARK: - URL Import View
struct URLImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = ""
    @State private var customFileName = ""
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var errorMessage: String?
    let directoryURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("Enter URL"), text: $urlString)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.localized("URL"))
                }
                
                Section {
                    TextField(.localized("Custom file name (optional)"), text: $customFileName)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("File Name"))
                } footer: {
                    Text(.localized("Leave empty to use the original file name"))
                }
                
                if isDownloading {
                    Section {
                        ProgressView(value: downloadProgress)
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(.localized("Import from URL"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Download")) {
                        downloadFile()
                    }
                    .disabled(urlString.isEmpty || isDownloading)
                }
            }
        }
    }
    
    private func downloadFile() {
        guard let url = URL(string: urlString) else {
            errorMessage = .localized("Invalid URL")
            return
        }
        
        isDownloading = true
        errorMessage = nil
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            DispatchQueue.main.async {
                isDownloading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let tempURL = tempURL else {
                    errorMessage = .localized("Download failed")
                    return
                }
                
                let fileName = customFileName.isEmpty ? url.lastPathComponent : customFileName
                let destURL = directoryURL.appendingPathComponent(fileName)
                
                do {
                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: destURL)
                    HapticsManager.shared.success()
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Clipboard Import View
struct ClipboardImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fileName = ""
    @State private var clipboardContent = ""
    @State private var hasContent = false
    let directoryURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("File Name"))
                }
                
                Section {
                    if hasContent {
                        Text(clipboardContent.prefix(500) + (clipboardContent.count > 500 ? "..." : ""))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(.localized("No text content in clipboard"))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(.localized("Clipboard Preview"))
                }
                
                Section {
                    Button {
                        loadClipboard()
                    } label: {
                        Label(.localized("Refresh Clipboard"), systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle(.localized("Import from Clipboard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Save")) {
                        saveFile()
                    }
                    .disabled(fileName.isEmpty || !hasContent)
                }
            }
            .onAppear {
                loadClipboard()
            }
        }
    }
    
    private func loadClipboard() {
        if let content = UIPasteboard.general.string {
            clipboardContent = content
            hasContent = !content.isEmpty
        } else {
            hasContent = false
        }
    }
    
    private func saveFile() {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? clipboardContent.write(to: fileURL, atomically: true, encoding: .utf8)
        HapticsManager.shared.success()
        dismiss()
    }
}

// MARK: - File Terminal View
struct FileTerminalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var commandHistory: [String] = []
    @State private var currentCommand = ""
    @State private var output: [TerminalOutput] = []
    let currentDirectory: URL
    
    struct TerminalOutput: Identifiable {
        let id = UUID()
        let command: String
        let result: String
        let isError: Bool
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Output area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(output) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("$ \(item.command)")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.green)
                                    Text(item.result)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(item.isError ? .red : .primary)
                                }
                                .id(item.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.9))
                    .onChange(of: output.count) { _ in
                        if let last = output.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                // Command input
                HStack {
                    Text("$")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green)
                    
                    TextField(.localized("Enter command"), text: $currentCommand)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            executeCommand()
                        }
                    
                    Button {
                        executeCommand()
                    } label: {
                        Image(systemName: "return")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            }
            .navigationTitle(.localized("Terminal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("ls") { currentCommand = "ls" }
                        Button("pwd") { currentCommand = "pwd" }
                        Button("cat") { currentCommand = "cat " }
                        Button("mkdir") { currentCommand = "mkdir " }
                        Button("rm") { currentCommand = "rm " }
                        Button("cp") { currentCommand = "cp " }
                        Button("mv") { currentCommand = "mv " }
                    } label: {
                        Image(systemName: "command")
                    }
                }
            }
        }
    }
    
    private func executeCommand() {
        guard !currentCommand.isEmpty else { return }
        
        let command = currentCommand
        currentCommand = ""
        commandHistory.append(command)
        
        let result = executeSimulatedCommand(command)
        output.append(TerminalOutput(command: command, result: result.output, isError: result.isError))
    }
    
    private func executeSimulatedCommand(_ command: String) -> (output: String, isError: Bool) {
        let parts = command.split(separator: " ", maxSplits: 1).map(String.init)
        let cmd = parts.first ?? ""
        let args = parts.count > 1 ? parts[1] : ""
        
        switch cmd {
        case "ls":
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: [.isDirectoryKey])
                let names = contents.map { url -> String in
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDir ? "\(url.lastPathComponent)/" : url.lastPathComponent
                }
                return (names.sorted().joined(separator: "\n"), false)
            } catch {
                return (error.localizedDescription, true)
            }
            
        case "pwd":
            return (currentDirectory.path, false)
            
        case "cat":
            let fileURL = currentDirectory.appendingPathComponent(args)
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                return (String(content.prefix(5000)), false)
            }
            return ("cat: \(args): No such file", true)
            
        case "mkdir":
            let dirURL = currentDirectory.appendingPathComponent(args)
            do {
                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
                return ("Directory created: \(args)", false)
            } catch {
                return (error.localizedDescription, true)
            }
            
        case "rm":
            let fileURL = currentDirectory.appendingPathComponent(args)
            do {
                try FileManager.default.removeItem(at: fileURL)
                return ("Removed: \(args)", false)
            } catch {
                return (error.localizedDescription, true)
            }
            
        case "touch":
            let fileURL = currentDirectory.appendingPathComponent(args)
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            return ("Created: \(args)", false)
            
        case "echo":
            return (args, false)
            
        case "clear":
            DispatchQueue.main.async {
                output.removeAll()
            }
            return ("", false)
            
        case "help":
            return ("Available commands: ls, pwd, cat, mkdir, rm, touch, echo, clear, help", false)
            
        default:
            return ("Command not found: \(cmd). Type 'help' for available commands.", true)
        }
    }
}

// MARK: - Advanced File Search View
struct AdvancedFileSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var searchByContent = false
    @State private var caseSensitive = false
    @State private var fileExtension = ""
    @State private var minSize: String = ""
    @State private var maxSize: String = ""
    @State private var isSearching = false
    @State private var results: [URL] = []
    let baseDirectory: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("Search query"), text: $searchQuery)
                        .autocorrectionDisabled()
                    
                    Toggle(.localized("Search in file content"), isOn: $searchByContent)
                    Toggle(.localized("Case sensitive"), isOn: $caseSensitive)
                } header: {
                    Text(.localized("Search"))
                }
                
                Section {
                    TextField(.localized("File extension (e.g., txt, json)"), text: $fileExtension)
                        .autocorrectionDisabled()
                    
                    TextField(.localized("Min size (KB)"), text: $minSize)
                        .keyboardType(.numberPad)
                    
                    TextField(.localized("Max size (KB)"), text: $maxSize)
                        .keyboardType(.numberPad)
                } header: {
                    Text(.localized("Filters"))
                }
                
                Section {
                    Button {
                        performSearch()
                    } label: {
                        HStack {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSearching ? .localized("Searching...") : .localized("Search"))
                        }
                    }
                    .disabled(searchQuery.isEmpty || isSearching)
                }
                
                if !results.isEmpty {
                    Section {
                        ForEach(results, id: \.absoluteString) { url in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                Text(url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text(.localized("Results (\(results.count))"))
                    }
                }
            }
            .navigationTitle(.localized("Advanced Search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
        }
    }
    
    private func performSearch() {
        isSearching = true
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var foundFiles: [URL] = []
            
            if let enumerator = FileManager.default.enumerator(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
                for case let fileURL as URL in enumerator {
                    guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                          let isDirectory = values.isDirectory, !isDirectory else { continue }
                    
                    // Check extension filter
                    if !fileExtension.isEmpty && fileURL.pathExtension.lowercased() != fileExtension.lowercased() {
                        continue
                    }
                    
                    // Check size filters
                    if let size = values.fileSize {
                        if let min = Int(minSize), size < min * 1024 { continue }
                        if let max = Int(maxSize), size > max * 1024 { continue }
                    }
                    
                    // Check name match
                    let fileName = fileURL.lastPathComponent
                    let matches = caseSensitive
                        ? fileName.contains(searchQuery)
                        : fileName.localizedCaseInsensitiveContains(searchQuery)
                    
                    if matches {
                        foundFiles.append(fileURL)
                    } else if searchByContent {
                        // Search in content
                        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                            let contentMatches = caseSensitive
                                ? content.contains(searchQuery)
                                : content.localizedCaseInsensitiveContains(searchQuery)
                            if contentMatches {
                                foundFiles.append(fileURL)
                            }
                        }
                    }
                    
                    if foundFiles.count >= 100 { break }
                }
            }
            
            DispatchQueue.main.async {
                results = foundFiles
                isSearching = false
            }
        }
    }
}

// MARK: - Disk Usage View
struct DiskUsageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCalculating = true
    @State private var items: [(name: String, size: Int64, isDirectory: Bool)] = []
    @State private var totalSize: Int64 = 0
    let directory: URL
    
    var body: some View {
        NavigationStack {
            Group {
                if isCalculating {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(.localized("Calculating disk usage..."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        Section {
                            HStack {
                                Text(.localized("Total Size"))
                                    .font(.headline)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Section {
                            ForEach(items, id: \.name) { item in
                                HStack {
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundStyle(item.isDirectory ? .blue : .gray)
                                    
                                    Text(item.name)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                            .font(.caption)
                                        
                                        if totalSize > 0 {
                                            Text("\(Int(Double(item.size) / Double(totalSize) * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text(.localized("Contents"))
                        }
                    }
                }
            }
            .navigationTitle(.localized("Disk Usage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
            .onAppear {
                calculateUsage()
            }
        }
    }
    
    private func calculateUsage() {
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [(name: String, size: Int64, isDirectory: Bool)] = []
            var total: Int64 = 0
            
            if let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey]) {
                for url in contents {
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    let size = calculateSize(at: url)
                    results.append((name: url.lastPathComponent, size: size, isDirectory: isDir))
                    total += size
                }
            }
            
            results.sort { $0.size > $1.size }
            
            DispatchQueue.main.async {
                items = results
                totalSize = total
                isCalculating = false
            }
        }
    }
    
    private func calculateSize(at url: URL) -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        } else if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            size = Int64(fileSize)
        }
        
        return size
    }
}

// MARK: - File Hasher View
struct FileHasherView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var md5Hash = ""
    @State private var sha1Hash = ""
    @State private var sha256Hash = ""
    @State private var sha512Hash = ""
    @State private var isCalculating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        isImporting = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(selectedFile?.lastPathComponent ?? .localized("Select File"))
                            Spacer()
                            if isCalculating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                } header: {
                    Text(.localized("File"))
                }
                
                if !md5Hash.isEmpty {
                    Section {
                        FileHashRow(algorithm: "MD5", hash: md5Hash)
                        FileHashRow(algorithm: "SHA-1", hash: sha1Hash)
                        FileHashRow(algorithm: "SHA-256", hash: sha256Hash)
                        FileHashRow(algorithm: "SHA-512", hash: sha512Hash)
                    } header: {
                        Text(.localized("Hashes"))
                    }
                }
            }
            .navigationTitle(.localized("Hash Calculator"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
            .sheet(isPresented: $isImporting) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.item],
                    onDocumentsPicked: { urls in
                        if let url = urls.first {
                            selectedFile = url
                            calculateHashes(for: url)
                        }
                    }
                )
                .ignoresSafeArea()
            }
        }
    }
    
    private func calculateHashes(for url: URL) {
        isCalculating = true
        md5Hash = ""
        sha1Hash = ""
        sha256Hash = ""
        sha512Hash = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async { isCalculating = false }
                return
            }
            
            let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha512 = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
            
            DispatchQueue.main.async {
                md5Hash = md5
                sha1Hash = sha1
                sha256Hash = sha256
                sha512Hash = sha512
                isCalculating = false
            }
        }
    }
}

struct FileHashRow: View {
    let algorithm: String
    let hash: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(algorithm)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = hash
                HapticsManager.shared.success()
            } label: {
                Label(.localized("Copy"), systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Base64 Tool View
struct Base64ToolView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var mode: Mode = .encode
    
    enum Mode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(.localized("Mode"), selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                } header: {
                    Text(.localized("Input"))
                }
                
                Section {
                    Button {
                        convert()
                    } label: {
                        HStack {
                            Spacer()
                            Text(mode == .encode ? .localized("Encode") : .localized("Decode"))
                            Spacer()
                        }
                    }
                }
                
                if !outputText.isEmpty {
                    Section {
                        Text(outputText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } header: {
                        HStack {
                            Text(.localized("Output"))
                            Spacer()
                            Button {
                                UIPasteboard.general.string = outputText
                                HapticsManager.shared.success()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                }
            }
            .navigationTitle(.localized("Base64 Tool"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
        }
    }
    
    private func convert() {
        if mode == .encode {
            if let data = inputText.data(using: .utf8) {
                outputText = data.base64EncodedString()
            }
        } else {
            if let data = Data(base64Encoded: inputText),
               let decoded = String(data: data, encoding: .utf8) {
                outputText = decoded
            } else {
                outputText = .localized("Invalid Base64 input")
            }
        }
    }
}

// MARK: - Symlink Creator View
struct SymlinkCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var linkName = ""
    @State private var targetPath = ""
    @State private var errorMessage: String?
    let directoryURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("Link name"), text: $linkName)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("Symbolic Link Name"))
                }
                
                Section {
                    TextField(.localized("Target path"), text: $targetPath)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.localized("Target Path"))
                } footer: {
                    Text(.localized("Enter the full path to the target file or directory"))
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(.localized("Create Symlink"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Create")) {
                        createSymlink()
                    }
                    .disabled(linkName.isEmpty || targetPath.isEmpty)
                }
            }
        }
    }
    
    private func createSymlink() {
        let linkURL = directoryURL.appendingPathComponent(linkName)
        
        do {
            try FileManager.default.createSymbolicLink(at: linkURL, withDestinationURL: URL(fileURLWithPath: targetPath))
            HapticsManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
