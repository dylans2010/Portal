import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import QuickLook

// MARK: - FilesView
struct FilesView: View {
    @StateObject private var fileManager = FileManagerService.shared
    @State private var showCreateMenu = false
    @State private var showCreateFolder = false
    @State private var showCreateTextFile = false
    @State private var showCreatePlist = false
    @State private var showCreateJSONFile = false
    @State private var showCreateXMLFile = false
    @State private var showDocumentPicker = false
    @State private var showZipSheet = false
    @State private var showUnzipSheet = false
    @State private var showSearch = false
    @State private var showFileInfo = false
    @State private var showMoveSheet = false
    @State private var showChecksumSheet = false
    @State private var showBatchRenameSheet = false
    @State private var showCompareSheet = false
    @State private var compareFile1: FileItem?
    @State private var compareFile2: FileItem?
    @State private var searchText = ""
    @State private var selectedFile: FileItem?
    @State private var selectedFiles: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var layoutMode: LayoutMode = .list
    @State private var sortOption: SortOption = .name
    @State private var showShareSheet = false
    @State private var shareURLs: [URL] = []
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var fileToRename: FileItem?
    @State private var showCertificateQuickAdd = false
    @State private var detectedP12: URL?
    @State private var detectedMobileprovision: URL?
    @State private var showBulkActionsMenu = false
    @State private var showSearchReplaceSheet = false
    @State private var copiedFiles: [FileItem] = []
    @State private var showPermissionsSheet = false
    @State private var showTemplatesSheet = false
    @State private var showQuickInspect = false
    @State private var quickInspectFile: FileItem?
    @State private var dismissedCertificateBanner = false
    @State private var showDownloadsPortal = false
    // New tool states
    @State private var showURLImport = false
    @State private var showClipboardImport = false
    @State private var showTerminal = false
    @State private var showFileSearch = false
    @State private var showDiskUsage = false
    @State private var showFileHasher = false
    @State private var showBase64Tool = false
    @State private var showSymlinkCreator = false
    
    // Constants for Open in Signer
    private let importPollingIntervalSeconds: Double = 0.5
    private let importMaxWaitTimeSeconds: Double = 10.0
    private let importRecentThresholdSeconds: Double = 2.0
    private let importErrorDomain = "com.feather.files"
    private let importTimeoutErrorCode = 1001
    
    // Settings
    @AppStorage("files_viewStyle") private var viewStyleSetting: String = "list"
    @AppStorage("files_sortOption") private var sortOptionSetting: String = "name"
    @AppStorage("files_showFileSize") private var showFileSize = true
    @AppStorage("files_showModificationDate") private var showModificationDate = true
    @AppStorage("files_enableQuickInspect") private var enableQuickInspect = true
    @AppStorage("files_enableOpenInSigner") private var enableOpenInSigner = true
    @AppStorage("files_enableFixStructure") private var enableFixStructure = true
    @AppStorage("files_enableBreadcrumbs") private var enableBreadcrumbs = true
    
    enum LayoutMode: String {
        case list, grid
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case date = "Date Modified"
        case size = "Size"
        case type = "Type"
    }
    
    var filteredFiles: [FileItem] {
        var files = fileManager.currentFiles
        
        if !searchText.isEmpty {
            files = files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOption {
        case .name:
            files.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date:
            files.sort { ($0.modificationDate ?? Date.distantPast) > ($1.modificationDate ?? Date.distantPast) }
        case .size:
            files.sort { ($0.sizeInBytes ?? 0) > ($1.sizeInBytes ?? 0) }
        case .type:
            files.sort { $0.url.pathExtension.localizedCaseInsensitiveCompare($1.url.pathExtension) == .orderedAscending }
        }
        
        return files
    }
    
    var hasCertificateFiles: Bool {
        let files = fileManager.currentFiles
        let hasP12 = files.contains(where: { $0.url.pathExtension.lowercased() == "p12" })
        let hasMobileprovision = files.contains(where: { $0.url.pathExtension.lowercased() == "mobileprovision" })
        return hasP12 && hasMobileprovision
    }
    
    var body: some View {
        NBNavigationView(.localized("Files")) {
            VStack(spacing: 0) {
                // Certificate Quick Add Banner (at top, before breadcrumb)
                if hasCertificateFiles && !dismissedCertificateBanner {
                    certificateQuickAddBanner
                }
                
                // Breadcrumb Navigation - pinned at top (only if enabled)
                if enableBreadcrumbs {
                    BreadcrumbView(
                        currentPath: fileManager.currentDirectory.path,
                        baseDirectory: fileManager.baseDirectory,
                        onNavigate: { url in
                            fileManager.navigateToDirectory(url)
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
                
                // Main content area
                if fileManager.currentFiles.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if layoutMode == .list {
                        fileListView
                    } else {
                        fileGridView
                    }
                }
            }
            .searchable(text: $searchText, prompt: .localized("Search Files"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if fileManager.currentDirectory != fileManager.baseDirectory {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fileManager.navigateUp()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Back")
                                    .font(.body)
                            }
                        }
                    }
                    
                    if isSelectionMode {
                        Button(.localized("Cancel")) {
                            isSelectionMode = false
                            selectedFiles.removeAll()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Downloads Portal button
                    Button {
                        showDownloadsPortal = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                    }
                    
                    // Bulk actions menu when in selection mode
                    if isSelectionMode && !selectedFiles.isEmpty {
                        Menu {
                            bulkActionMenuItems
                        } label: {
                            Image(systemName: "square.on.square")
                                .font(.title3)
                        }
                    }
                    
                    Menu {
                        Button {
                            layoutMode = layoutMode == .list ? .grid : .list
                        } label: {
                            Label(layoutMode == .list ? .localized("Grid View") : .localized("List View"), 
                                  systemImage: layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                        }
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    if sortOption == option {
                                        Label(option.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Label(.localized("Sort By"), systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedFiles.removeAll()
                            }
                        } label: {
                            Label(.localized("Select"), systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Menu {
                        createMenuItems
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .sheet(isPresented: $showCreateTextFile) {
                CreateTextFileView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreatePlist) {
                CreatePlistView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showDocumentPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        for url in urls {
                            fileManager.importFile(from: url)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showZipSheet) {
                ZipOperationView(files: selectedFilesArray, operation: .zip, directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showUnzipSheet) {
                if let zipFile = selectedFilesArray.first(where: { $0.url.pathExtension == "zip" }) {
                    ZipOperationView(files: [zipFile], operation: .unzip, directoryURL: fileManager.currentDirectory)
                }
            }
            .sheet(item: $selectedFile) { file in
                fileDetailSheet(for: file)
            }
            .sheet(isPresented: $showFileInfo) {
                if let file = selectedFilesArray.first {
                    FileInfoView(file: file)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(urls: shareURLs)
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveFileView(files: selectedFilesArray, currentDirectory: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showChecksumSheet) {
                if let file = selectedFilesArray.first {
                    ChecksumCalculatorView(fileURL: file.url)
                }
            }
            .sheet(isPresented: $showBatchRenameSheet) {
                BatchRenameView(files: selectedFilesArray)
            }
            .sheet(isPresented: $showCompareSheet) {
                if let file1 = compareFile1, let file2 = compareFile2 {
                    FileCompareView(file1: file1, file2: file2)
                } else {
                    // Fallback view if files are not set
                    NBNavigationView(.localized("Compare Files"), displayMode: .inline) {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)
                            
                            Text(.localized("Files Not Selected"))
                                .font(.headline)
                            
                            Text(.localized("Please select exactly two files to compare."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(.localized("Close")) {
                                    showCompareSheet = false
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCertificateQuickAdd) {
                if let p12 = detectedP12, let provision = detectedMobileprovision {
                    CertificateQuickAddView(p12URL: p12, mobileprovisionURL: provision)
                } else {
                    // Fallback view if detection failed
                    NBNavigationView(.localized("Certificate Import"), displayMode: .inline) {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)
                            
                            Text(.localized("Certificate Files Not Found"))
                                .font(.headline)
                            
                            Text(.localized("Please ensure both .p12 and .mobileprovision files are present in the current directory."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(.localized("Close")) {
                                    showCertificateQuickAdd = false
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearchReplaceSheet) {
                if let file = selectedFilesArray.first, !file.isDirectory {
                    SearchReplaceView(fileURL: file.url)
                }
            }
            .sheet(isPresented: $showPermissionsSheet) {
                if let file = selectedFilesArray.first {
                    FilePermissionsView(fileURL: file.url)
                }
            }
            .sheet(isPresented: $showTemplatesSheet) {
                FileTemplatesView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showQuickInspect) {
                if let file = quickInspectFile {
                    QuickInspectView(file: file)
                }
            }
            .sheet(isPresented: $showDownloadsPortal) {
                DownloadsPortalView()
            }
            // New tool sheets
            .sheet(isPresented: $showCreateJSONFile) {
                CreateJSONFileView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showCreateXMLFile) {
                CreateXMLFileView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showURLImport) {
                URLImportView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showClipboardImport) {
                ClipboardImportView(directoryURL: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showTerminal) {
                FileTerminalView(currentDirectory: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showFileSearch) {
                AdvancedFileSearchView(baseDirectory: fileManager.baseDirectory)
            }
            .sheet(isPresented: $showDiskUsage) {
                DiskUsageView(directory: fileManager.currentDirectory)
            }
            .sheet(isPresented: $showFileHasher) {
                FileHasherView()
            }
            .sheet(isPresented: $showBase64Tool) {
                Base64ToolView()
            }
            .sheet(isPresented: $showSymlinkCreator) {
                SymlinkCreatorView(directoryURL: fileManager.currentDirectory)
            }
            .alert(.localized("Rename File"), isPresented: $showRenameAlert) {
                TextField(.localized("New Name"), text: $renameText)
                Button(.localized("Cancel"), role: .cancel) { }
                Button(.localized("Rename")) {
                    if let file = fileToRename {
                        fileManager.renameFile(file, to: renameText)
                    }
                }
            } message: {
                Text(.localized("Enter a new name for the file"))
            }
            .onAppear {
                applySettings()
            }
            .onChange(of: viewStyleSetting) { _ in
                applySettings()
            }
            .onChange(of: sortOptionSetting) { _ in
                applySettings()
            }
        }
    }
    
    private func applySettings() {
        // Apply view style
        layoutMode = viewStyleSetting == "grid" ? .grid : .list
        
        // Apply sort option
        switch sortOptionSetting {
        case "date":
            sortOption = .date
        case "size":
            sortOption = .size
        case "type":
            sortOption = .type
        default:
            sortOption = .name
        }
    }
    
    private var certificateQuickAddBanner: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: "person.badge.key.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(.localized("Certificate Files Detected"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(.localized("Tap to add certificate"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Add button
            Button {
                detectCertificateFiles()
                showCertificateQuickAdd = true
            } label: {
                Text(.localized("Add"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            
            // Dismiss button
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    dismissedCertificateBanner = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var selectedFilesArray: [FileItem] {
        fileManager.currentFiles.filter { selectedFiles.contains($0.id) }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.15),
                                Color.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text(.localized("No Files"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(.localized("Import files or create new content"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showDocumentPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.headline)
                    Text(.localized("Import Files"))
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .accentColor.opacity(0.4), radius: 10, x: 0, y: 6)
            }
        }
    }
    
    private var fileListView: some View {
        List(selection: isSelectionMode ? $selectedFiles : .constant(Set<UUID>())) {
            ForEach(filteredFiles) { file in
                FileRowView(file: file, isSelected: selectedFiles.contains(file.id))
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleFileTap(file)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            HapticsManager.shared.warning()
                            fileManager.deleteFile(file)
                        } label: {
                            Label(.localized("Delete"), systemImage: "trash")
                        }
                        
                        Button {
                            shareURLs = [file.url]
                            showShareSheet = true
                        } label: {
                            Label(.localized("Share"), systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            fileToRename = file
                            renameText = file.name
                            showRenameAlert = true
                        } label: {
                            Label(.localized("Rename"), systemImage: "pencil")
                        }
                        .tint(.orange)
                        
                        Button {
                            fileManager.duplicateFile(file)
                        } label: {
                            Label(.localized("Duplicate"), systemImage: "doc.on.doc")
                        }
                        .tint(.green)
                    }
                    .contextMenu {
                        fileContextMenu(for: file)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, isSelectionMode ? .constant(.active) : .constant(.inactive))
    }
    
    @ViewBuilder
    private var bulkActionMenuItems: some View {
        Button {
            shareURLs = selectedFilesArray.map { $0.url }
            showShareSheet = true
        } label: {
            Label(.localized("Share"), systemImage: "square.and.arrow.up")
        }
        
        if selectedFiles.count > 1 {
            Button {
                showBatchRenameSheet = true
            } label: {
                Label(.localized("Batch Rename"), systemImage: "pencil")
            }
        }
        
        if selectedFiles.count == 2 {
            Button {
                let files = selectedFilesArray
                if files.count == 2 {
                    compareFile1 = files[0]
                    compareFile2 = files[1]
                    showCompareSheet = true
                }
            } label: {
                Label(.localized("Compare"), systemImage: "arrow.left.arrow.right")
            }
        }
        
        Button {
            showMoveSheet = true
        } label: {
            Label(.localized("Move"), systemImage: "folder")
        }
        
        Button {
            copiedFiles = selectedFilesArray
            HapticsManager.shared.success()
        } label: {
            Label(.localized("Copy"), systemImage: "doc.on.doc")
        }
        
        if !copiedFiles.isEmpty {
            Button {
                pasteFiles()
            } label: {
                Label(.localized("Paste"), systemImage: "doc.on.clipboard")
            }
        }
        
        Button {
            showZipSheet = true
        } label: {
            Label(.localized("Zip"), systemImage: "doc.zipper")
        }
        
        Divider()
        
        Button(role: .destructive) {
            for id in selectedFiles {
                if let file = fileManager.currentFiles.first(where: { $0.id == id }) {
                    fileManager.deleteFile(file)
                }
            }
            selectedFiles.removeAll()
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }
    }
    
    private var fileGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredFiles) { file in
                    FileGridItemView(file: file, isSelected: selectedFiles.contains(file.id))
                        .onTapGesture {
                            handleFileTap(file)
                        }
                        .contextMenu {
                            fileContextMenu(for: file)
                        }
                }
            }
            .padding()
        }
    }
    
    private func handleFileTap(_ file: FileItem) {
        HapticsManager.shared.impact()
        
        if isSelectionMode {
            if selectedFiles.contains(file.id) {
                selectedFiles.remove(file.id)
            } else {
                selectedFiles.insert(file.id)
            }
        } else {
            if file.isDirectory {
                fileManager.navigateToDirectory(file.url)
            } else {
                selectedFile = file
            }
        }
    }
    
    private func fileDetailSheet(for file: FileItem) -> some View {
        Group {
            if file.isDirectory {
                FolderCustomizationView(folderURL: file.url)
            } else if ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "heic"].contains(file.url.pathExtension.lowercased()) {
                ImageViewerView(fileURL: file.url)
            } else if file.url.pathExtension.lowercased() == "plist" {
                PlistEditorView(fileURL: file.url)
            } else if file.url.pathExtension.lowercased() == "json" {
                JSONViewerView(fileURL: file.url)
            } else if ["txt", "text", "md", "log", "swift", "py", "js", "ts", "html", "css", "xml", "yml", "yaml"].contains(file.url.pathExtension.lowercased()) {
                TextViewerView(fileURL: file.url)
            } else {
                HexEditorView(fileURL: file.url)
            }
        }
    }
    
    @ViewBuilder
    private var createMenuItems: some View {
        // Import Section
        Section {
            Button {
                HapticsManager.shared.impact()
                showDocumentPicker = true
            } label: {
                Label(.localized("Import Files"), systemImage: "square.and.arrow.down")
            }
            
            Button {
                HapticsManager.shared.impact()
                showURLImport = true
            } label: {
                Label(.localized("Import from URL"), systemImage: "link")
            }
            
            Button {
                HapticsManager.shared.impact()
                showClipboardImport = true
            } label: {
                Label(.localized("Import from Clipboard"), systemImage: "doc.on.clipboard")
            }
        }
        
        Divider()
        
        // Create Section
        Section {
            Button {
                HapticsManager.shared.impact()
                showCreateTextFile = true
            } label: {
                Label(.localized("Text File"), systemImage: "doc.text")
            }
            
            Button {
                HapticsManager.shared.impact()
                showCreatePlist = true
            } label: {
                Label(.localized("Plist File"), systemImage: "doc.badge.gearshape")
            }
            
            Button {
                HapticsManager.shared.impact()
                showCreateJSONFile = true
            } label: {
                Label(.localized("JSON File"), systemImage: "curlybraces")
            }
            
            Button {
                HapticsManager.shared.impact()
                showCreateXMLFile = true
            } label: {
                Label(.localized("XML File"), systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            Button {
                HapticsManager.shared.impact()
                showCreateFolder = true
            } label: {
                Label(.localized("Folder"), systemImage: "folder.badge.plus")
            }
            
            Button {
                HapticsManager.shared.impact()
                showTemplatesSheet = true
            } label: {
                Label(.localized("From Template"), systemImage: "doc.badge.plus")
            }
        }
        
        if !copiedFiles.isEmpty {
            Divider()
            
            Button {
                pasteFiles()
            } label: {
                Label(.localized("Paste Files"), systemImage: "doc.on.clipboard.fill")
            }
        }
        
        // Archive Section
        if !selectedFiles.isEmpty || fileManager.currentFiles.contains(where: { $0.url.pathExtension == "zip" }) {
            Divider()
            
            if !selectedFiles.isEmpty {
                Button {
                    HapticsManager.shared.impact()
                    showZipSheet = true
                } label: {
                    Label(.localized("Zip Selected"), systemImage: "doc.zipper")
                }
            }
            
            if fileManager.currentFiles.contains(where: { $0.url.pathExtension == "zip" }) {
                Button {
                    HapticsManager.shared.impact()
                    showUnzipSheet = true
                } label: {
                    Label(.localized("Unzip File"), systemImage: "arrow.up.doc")
                }
            }
        }
        
        // Tools Section
        Divider()
        
        Menu {
            Button {
                HapticsManager.shared.impact()
                showTerminal = true
            } label: {
                Label(.localized("Terminal"), systemImage: "terminal")
            }
            
            Button {
                HapticsManager.shared.impact()
                showFileSearch = true
            } label: {
                Label(.localized("Advanced Search"), systemImage: "magnifyingglass")
            }
            
            Button {
                HapticsManager.shared.impact()
                showDiskUsage = true
            } label: {
                Label(.localized("Disk Usage"), systemImage: "chart.pie")
            }
            
            Button {
                HapticsManager.shared.impact()
                showFileHasher = true
            } label: {
                Label(.localized("Hash Calculator"), systemImage: "number.circle")
            }
            
            Button {
                HapticsManager.shared.impact()
                showBase64Tool = true
            } label: {
                Label(.localized("Base64 Encoder"), systemImage: "textformat.abc")
            }
            
            Button {
                HapticsManager.shared.impact()
                showSymlinkCreator = true
            } label: {
                Label(.localized("Create Symlink"), systemImage: "link")
            }
        } label: {
            Label(.localized("Tools"), systemImage: "wrench.and.screwdriver")
        }
    }
    
    private func pasteFiles() {
        for file in copiedFiles {
            fileManager.duplicateFile(file, toDirectory: fileManager.currentDirectory)
        }
        copiedFiles.removeAll()
        HapticsManager.shared.success()
    }
    
    @ViewBuilder
    private func fileContextMenu(for file: FileItem) -> some View {
        if file.isDirectory {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("Customize Folder"), systemImage: "paintbrush")
            }
        } else if file.url.pathExtension.lowercased() == "plist" {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("Edit Plist"), systemImage: "doc.text.fill")
            }
        } else {
            Button {
                HapticsManager.shared.impact()
                selectedFile = file
            } label: {
                Label(.localized("View/Edit"), systemImage: "doc.text")
            }
        }
        
        Divider()
        
        // Smart Actions
        if enableQuickInspect && !file.isDirectory {
            Button {
                quickInspectFile = file
                showQuickInspect = true
            } label: {
                Label(.localized("Quick Inspect"), systemImage: "doc.text.magnifyingglass")
            }
        }
        
        if enableOpenInSigner && file.url.pathExtension.lowercased() == "ipa" {
            Button {
                openInSigner(file)
            } label: {
                Label(.localized("Open in Signer"), systemImage: "signature")
            }
        }
        
        if enableFixStructure && !file.isDirectory {
            Button {
                fixFileStructure(file)
            } label: {
                Label(.localized("Fix Structure"), systemImage: "wrench.and.screwdriver")
            }
        }
        
        Divider()
        
        Button {
            selectedFiles = [file.id]
            showFileInfo = true
        } label: {
            Label(.localized("Info"), systemImage: "info.circle")
        }
        
        Button {
            selectedFiles = [file.id]
            showPermissionsSheet = true
        } label: {
            Label(.localized("Permissions"), systemImage: "lock.shield")
        }
        
        Button {
            fileToRename = file
            renameText = file.name
            showRenameAlert = true
        } label: {
            Label(.localized("Rename"), systemImage: "pencil")
        }
        
        Button {
            fileManager.duplicateFile(file)
        } label: {
            Label(.localized("Duplicate"), systemImage: "doc.on.doc")
        }
        
        Button {
            copiedFiles = [file]
            HapticsManager.shared.success()
        } label: {
            Label(.localized("Copy"), systemImage: "doc.on.doc.fill")
        }
        
        Button {
            selectedFiles = [file.id]
            showMoveSheet = true
        } label: {
            Label(.localized("Move"), systemImage: "folder")
        }
        
        Button {
            shareURLs = [file.url]
            showShareSheet = true
        } label: {
            Label(.localized("Share"), systemImage: "square.and.arrow.up")
        }
        
        if !file.isDirectory {
            Divider()
            
            if ["txt", "text", "md", "log", "swift", "py", "js", "ts", "html", "css", "xml", "yml", "yaml"].contains(file.url.pathExtension.lowercased()) {
                Button {
                    selectedFiles = [file.id]
                    showSearchReplaceSheet = true
                } label: {
                    Label(.localized("Search & Replace"), systemImage: "magnifyingglass")
                }
            }
            
            Button {
                selectedFiles = [file.id]
                showChecksumSheet = true
            } label: {
                Label(.localized("Calculate Checksums"), systemImage: "number.square")
            }
        }
        
        if file.url.pathExtension.lowercased() == "zip" {
            Divider()
            
            Button {
                selectedFiles = [file.id]
                showUnzipSheet = true
            } label: {
                Label(.localized("Unzip"), systemImage: "arrow.up.doc")
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            HapticsManager.shared.warning()
            fileManager.deleteFile(file)
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }
    }
    
    private func detectCertificateFiles() {
        let files = fileManager.currentFiles
        detectedP12 = files.first(where: { $0.url.pathExtension.lowercased() == "p12" })?.url
        detectedMobileprovision = files.first(where: { $0.url.pathExtension.lowercased() == "mobileprovision" })?.url
        HapticsManager.shared.impact()
    }
    
    private func fixFileStructure(_ file: FileItem) {
        HapticsManager.shared.impact()
        
        // Basic file structure repair
        Task {
            do {
                let fileManager = FileManager.default
                let _ = try fileManager.attributesOfItem(atPath: file.url.path)
                
                // Check if file is readable
                if fileManager.isReadableFile(atPath: file.url.path) {
                    AppLogManager.shared.info("File structure appears valid", category: "Files")
                    HapticsManager.shared.success()
                } else {
                    AppLogManager.shared.warning("File may be corrupted", category: "Files")
                    HapticsManager.shared.error()
                }
            } catch {
                AppLogManager.shared.error("Failed to check file structure: \(error.localizedDescription)", category: "Files")
                HapticsManager.shared.error()
            }
        }
    }
    
    private func openInSigner(_ file: FileItem) {
        HapticsManager.shared.impact()
        
        // Import IPA to library and open signing view
        Task { @MainActor in
            let id = "FeatherFileOpen_\(UUID().uuidString)"
            let downloadManager = DownloadManager.shared
            let dl = downloadManager.startArchive(from: file.url, id: id)
            
            do {
                try downloadManager.handlePachageFile(url: file.url, dl: dl)
                
                // Wait for the download/import to complete by checking the download status
                let maxAttempts = Int(importMaxWaitTimeSeconds / importPollingIntervalSeconds)
                var attempts = 0
                
                while attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(importPollingIntervalSeconds * 1_000_000_000))
                    
                    // Check if import is complete by trying to get the latest imported app
                    // We check if an app was imported very recently
                    if let importedApp = Storage.shared.getLatestImportedApp(),
                       let appDate = importedApp.date,
                       Date().timeIntervalSince(appDate) < importRecentThresholdSeconds {
                        // This is likely the app we just imported
                        // Trigger signing with default certificate
                        NotificationCenter.default.post(
                            name: Notification.Name("Feather.signApp"),
                            object: nil,
                            userInfo: ["app": AnyApp(base: importedApp)]
                        )
                        
                        HapticsManager.shared.success()
                        return
                    }
                    
                    attempts += 1
                }
                
                // If we get here, the import didn't complete in time
                throw NSError(
                    domain: importErrorDomain,
                    code: importTimeoutErrorCode,
                    userInfo: [NSLocalizedDescriptionKey: "Import timed out. Please try again.".localized]
                )
                
            } catch {
                HapticsManager.shared.error()
                AppLogManager.shared.error("Failed to open in signer: \(error.localizedDescription)", category: "Files")
                
                let errorMessage = String(format: .localized("Failed to import IPA file: %@"), error.localizedDescription)
                UIAlertController.showAlertWithOk(
                    title: .localized("Error"),
                    message: errorMessage
                )
            }
        }
    }
}

// MARK: - FileRowView
struct FileRowView: View {
    let file: FileItem
    var isSelected: Bool = false
    @AppStorage("files_showFileSize") private var showFileSize = true
    @AppStorage("files_showModificationDate") private var showModificationDate = true
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon with background and gradient
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
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
                    .frame(width: 48, height: 48)
                
                Image(systemName: file.icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [file.iconColor, file.iconColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: file.iconColor.opacity(0.2), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(file.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if showFileSize, let size = file.size {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.caption2)
                            Text(size)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if showModificationDate, let modDate = file.modificationDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(modDate, style: .relative)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
            } else if file.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - FileGridItemView
struct FileGridItemView: View {
    let file: FileItem
    var isSelected: Bool = false
    @AppStorage("files_showFileSize") private var showFileSize = true
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // Icon container with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                        .frame(width: 100, height: 90)
                    
                    Image(systemName: file.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [file.iconColor, file.iconColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: file.iconColor.opacity(0.2), radius: 6, x: 0, y: 3)
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.title3)
                    }
                    .offset(x: 8, y: -8)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            
            VStack(spacing: 4) {
                Text(file.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                
                if showFileSize, let size = file.size {
                    Text(size)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - FileItem
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: String?
    let sizeInBytes: Int?
    let modificationDate: Date?
    let customIcon: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var icon: String {
        if let customIcon = customIcon {
            return customIcon
        }
        if isDirectory {
            return "folder.fill"
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "text":
            return "doc.text.fill"
        case "plist":
            return "doc.badge.gearshape.fill"
        case "zip":
            return "doc.zipper.fill"
        case "json":
            return "curlybraces.square.fill"
        case "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "ipa", "tipa":
            return "app.badge.fill"
        case "p12":
            return "key.fill"
        case "mobileprovision":
            return "doc.badge.key.fill"
        case "png", "jpg", "jpeg", "gif":
            return "photo.fill"
        case "mp4", "mov":
            return "film.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        default:
            return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if isDirectory {
            return .blue
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "text":
            return .orange
        case "plist":
            return .purple
        case "zip":
            return .green
        case "json":
            return .yellow
        case "xml":
            return .red
        case "ipa", "tipa":
            return .cyan
        case "p12", "mobileprovision":
            return .indigo
        case "png", "jpg", "jpeg", "gif":
            return .pink
        case "mp4", "mov":
            return .purple
        case "mp3", "wav", "m4a":
            return .teal
        default:
            return .gray
        }
    }
}

// MARK: - FileManagerService
class FileManagerService: ObservableObject {
    static let shared = FileManagerService()
    
    @Published var currentDirectory: URL
    @Published var currentFiles: [FileItem] = []
    
    let documentsDirectory: URL
    let baseDirectory: URL
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.baseDirectory = documentsDirectory.appendingPathComponent("PortalFiles", isDirectory: true)
        self.currentDirectory = baseDirectory
        
        // Create base directory if needed
        try? FileManager.default.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        
        loadFiles()
    }
    
    func loadFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: self.currentDirectory, 
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
                )
                
                let files = contents.compactMap { url -> FileItem? in
                    let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDirectory = resourceValues?.isDirectory ?? false
                    let fileSize = resourceValues?.fileSize
                    let modDate = resourceValues?.contentModificationDate
                    
                    let sizeString: String? = {
                        if isDirectory {
                            return nil
                        }
                        guard let fileSize = fileSize else { return nil }
                        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                    }()
                    
                    // Get custom icon if exists
                    let customIcon = UserDefaults.standard.string(forKey: "folder_icon_\(url.path)")
                    
                    return FileItem(
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: isDirectory,
                        size: sizeString,
                        sizeInBytes: fileSize,
                        modificationDate: modDate,
                        customIcon: customIcon
                    )
                }.sorted { $0.isDirectory && !$1.isDirectory }
                
                DispatchQueue.main.async {
                    self.currentFiles = files
                }
            } catch {
                DispatchQueue.main.async {
                    self.currentFiles = []
                }
            }
        }
    }
    
    func navigateToDirectory(_ url: URL) {
        currentDirectory = url
        loadFiles()
    }
    
    func navigateUp() {
        // Don't navigate if we're already at the base directory
        guard currentDirectory != baseDirectory else { return }
        
        let parent = currentDirectory.deletingLastPathComponent()
        
        // Navigate up as long as the parent is at or within the base directory
        // Use path comparison to check if parent is within bounds
        let parentPath = parent.standardized.path
        let basePath = baseDirectory.standardized.path
        
        // Allow navigation if parent equals base OR parent starts with base path
        if parentPath == basePath || parentPath.hasPrefix(basePath + "/") || parentPath.hasPrefix(basePath) {
            currentDirectory = parent
            loadFiles()
        }
    }
    
    func deleteFile(_ file: FileItem) {
        do {
            try FileManager.default.removeItem(at: file.url)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to delete file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func renameFile(_ file: FileItem, to newName: String) {
        let newURL = file.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: file.url, to: newURL)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to rename file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func duplicateFile(_ file: FileItem, toDirectory destinationDir: URL? = nil) {
        let targetDir = destinationDir ?? file.url.deletingLastPathComponent()
        let nameWithoutExt = file.url.deletingPathExtension().lastPathComponent
        let ext = file.url.pathExtension
        let baseName = ext.isEmpty ? nameWithoutExt : "\(nameWithoutExt).\(ext)"
        
        var counter = 1
        var newURL = targetDir.appendingPathComponent("Copy of \(baseName)")
        
        while FileManager.default.fileExists(atPath: newURL.path) {
            counter += 1
            newURL = targetDir.appendingPathComponent("Copy \(counter) of \(baseName)")
        }
        
        do {
            try FileManager.default.copyItem(at: file.url, to: newURL)
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to duplicate file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    func importFile(from sourceURL: URL) {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = currentDirectory.appendingPathComponent(fileName)
        
        do {
            // Copy file to destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                // Handle name conflict
                var counter = 1
                var newDestinationURL = currentDirectory.appendingPathComponent("\(counter)_\(fileName)")
                while FileManager.default.fileExists(atPath: newDestinationURL.path) {
                    counter += 1
                    newDestinationURL = currentDirectory.appendingPathComponent("\(counter)_\(fileName)")
                }
                try FileManager.default.copyItem(at: sourceURL, to: newDestinationURL)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            }
            
            HapticsManager.shared.success()
            loadFiles()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to import file: \(error.localizedDescription)", category: "Files")
        }
    }
}
