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
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery = ""
    @State private var searchByContent = false
    @State private var caseSensitive = false
    @State private var fileExtension = ""
    @State private var minSize: String = ""
    @State private var maxSize: String = ""
    @State private var isSearching = false
    @State private var results: [URL] = []
    let baseDirectory: URL
    
    private var gradientColors: [Color] {
        [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        searchHeaderSection
                        searchInputCard
                        filtersCard
                        searchButton
                        
                        if !results.isEmpty {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
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
    
    // MARK: - Header Section
    private var searchHeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(.localized("Find files with precision"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Search Input Card
    private var searchInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(.localized("Search Query"), systemImage: "text.magnifyingglass")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                TextField(.localized("Enter search term..."), text: $searchQuery)
                    .font(.body)
                    .autocorrectionDisabled()
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            VStack(spacing: 12) {
                searchModernToggle(
                    title: .localized("Search in file content"),
                    icon: "doc.text.magnifyingglass",
                    isOn: $searchByContent,
                    color: .purple
                )
                
                searchModernToggle(
                    title: .localized("Case sensitive"),
                    icon: "textformat.abc",
                    isOn: $caseSensitive,
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Filters Card
    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(.localized("Filters"), systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                }
                
                TextField(.localized("File extension (e.g., txt, json)"), text: $fileExtension)
                    .font(.body)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.cyan)
                    }
                    
                    TextField(.localized("Min KB"), text: $minSize)
                        .font(.body)
                        .keyboardType(.numberPad)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.up.to.line")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.pink)
                    }
                    
                    TextField(.localized("Max KB"), text: $maxSize)
                        .font(.body)
                        .keyboardType(.numberPad)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Search Button
    private var searchButton: some View {
        Button {
            performSearch()
        } label: {
            HStack(spacing: 12) {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isSearching ? .localized("Searching...") : .localized("Search Files"))
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        searchQuery.isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.5))
                        : AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                    )
            )
            .shadow(color: searchQuery.isEmpty ? .clear : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(searchQuery.isEmpty || isSearching)
        .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(.localized("Results"), systemImage: "doc.on.doc.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(results.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
            }
            
            VStack(spacing: 0) {
                ForEach(results.prefix(50), id: \.absoluteString) { url in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: searchIconForFile(url))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(url.lastPathComponent)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Text(url.deletingLastPathComponent().path)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    
                    if url != results.prefix(50).last {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            if results.count > 50 {
                Text(.localized("Showing first 50 of \(results.count) results"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Helper Views
    private func searchModernToggle(title: String, icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, 4)
    }
    
    private func searchIconForFile(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "md", "rtf": return "doc.text.fill"
        case "json", "xml", "plist": return "doc.badge.gearshape.fill"
        case "swift", "js", "py", "html", "css": return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "gif", "heic": return "photo.fill"
        case "mp3", "wav", "m4a": return "music.note"
        case "mp4", "mov", "avi": return "film.fill"
        case "zip", "rar", "7z": return "doc.zipper"
        case "pdf": return "doc.richtext.fill"
        default: return "doc.fill"
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isCalculating = true
    @State private var items: [(name: String, size: Int64, isDirectory: Bool)] = []
    @State private var totalSize: Int64 = 0
    let directory: URL
    
    private var gradientColors: [Color] {
        [Color.teal.opacity(0.8), Color.green.opacity(0.6)]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isCalculating {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            diskUsageHeaderSection
                            totalSizeCard
                            contentsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .teal.opacity(0.3), radius: 12, x: 0, y: 6)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
            }
            
            Text(.localized("Calculating disk usage..."))
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(.localized("Analyzing files and folders"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Header Section
    private var diskUsageHeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .teal.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(.localized("Storage Analysis"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Total Size Card
    private var totalSizeCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Total Size"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.2), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.teal)
                }
            }
            
            // Items count
            HStack {
                Label("\(items.count) Items", systemImage: "doc.on.doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(directory.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Contents Section
    private var contentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(.localized("Contents"), systemImage: "folder.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 0) {
                ForEach(items, id: \.name) { item in
                    diskUsageItemRow(item: item)
                    
                    if item.name != items.last?.name {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Item Row
    private func diskUsageItemRow(item: (name: String, size: Int64, isDirectory: Bool)) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.isDirectory ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(item.isDirectory ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Progress bar and percentage
            VStack(alignment: .trailing, spacing: 6) {
                let percentage = totalSize > 0 ? Double(item.size) / Double(totalSize) : 0
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(percentage > 0.5 ? .orange : percentage > 0.25 ? .yellow : .green)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: percentage > 0.5 ? [.orange, .red.opacity(0.8)] :
                                            percentage > 0.25 ? [.yellow, .orange.opacity(0.8)] :
                                            [.green, .teal.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(percentage), height: 6)
                    }
                }
                .frame(width: 60, height: 6)
            }
        }
        .padding(12)
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var mode: Base64Mode = .encode
    @State private var showCopiedFeedback = false
    @State private var isConverting = false
    
    enum Base64Mode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
        
        var icon: String {
            switch self {
            case .encode: return "lock.fill"
            case .decode: return "lock.open.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .encode: return .indigo
            case .decode: return .cyan
            }
        }
    }
    
    private var gradientColors: [Color] {
        mode == .encode ? [Color.indigo.opacity(0.8), Color.purple.opacity(0.6)] : [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        base64HeaderSection
                        modeSelector
                        inputCard
                        convertButton
                        
                        if !outputText.isEmpty {
                            outputCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
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
    
    // MARK: - Header Section
    private var base64HeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [mode.color.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: mode.color.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: mode.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: mode)
            
            Text(mode == .encode ? .localized("Encode text data to Base64") : .localized("Decode Base64 to text"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: mode)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 12) {
            ForEach(Base64Mode.allCases, id: \.self) { modeOption in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        mode = modeOption
                        outputText = ""
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: modeOption.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(modeOption.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(mode == modeOption ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                mode == modeOption
                                ? AnyShapeStyle(LinearGradient(colors: [modeOption.color, modeOption.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color(UIColor.tertiarySystemBackground))
                            )
                    )
                    .shadow(color: mode == modeOption ? modeOption.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Input Card
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(.localized("Input"), systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                        outputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    if let clipboard = UIPasteboard.general.string {
                        inputText = clipboard
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundStyle(mode.color)
                }
            }
            
            TextEditor(text: $inputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(mode.color.opacity(0.2), lineWidth: 1)
                )
            
            // Character count
            HStack {
                Text("\(inputText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if mode == .decode {
                    let isValid = Data(base64Encoded: inputText) != nil
                    HStack(spacing: 4) {
                        Image(systemName: isValid || inputText.isEmpty ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(inputText.isEmpty ? "Enter Base64" : (isValid ? "Valid Base64" : "Invalid Base64"))
                    }
                    .font(.caption)
                    .foregroundColor(inputText.isEmpty ? .secondary : (isValid ? .green : .red))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Convert Button
    private var convertButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isConverting = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                convert()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isConverting = false
                }
            }
        } label: {
            HStack(spacing: 12) {
                if isConverting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: mode == .encode ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(mode == .encode ? .localized("Encode to Base64") : .localized("Decode from Base64"))
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        inputText.isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.5))
                        : AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                    )
            )
            .shadow(color: inputText.isEmpty ? .clear : mode.color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(inputText.isEmpty || isConverting)
        .animation(.easeInOut(duration: 0.2), value: inputText.isEmpty)
    }
    
    // MARK: - Output Card
    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(.localized("Output"), systemImage: "text.badge.checkmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = outputText
                    HapticsManager.shared.success()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCopiedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCopiedFeedback = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                        if showCopiedFeedback {
                            Text(.localized("Copied!"))
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(showCopiedFeedback ? .green : mode.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(showCopiedFeedback ? Color.green.opacity(0.15) : mode.color.opacity(0.15))
                    )
                }
            }
            
            Text(outputText)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            
            // Output info
            HStack {
                Text("\(outputText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if mode == .encode {
                    let ratio = inputText.isEmpty ? 0 : Double(outputText.count) / Double(inputText.count)
                    Text(String(format: "%.1fx size", ratio))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
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
                outputText = .localized("Invalid Base64 Input")
            }
        }
        HapticsManager.shared.success()
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
