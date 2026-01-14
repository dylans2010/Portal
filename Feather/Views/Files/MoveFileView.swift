import SwiftUI
import NimbleViews

// MARK: - MoveFileView
struct MoveFileView: View {
    let files: [FileItem]
    let currentDirectory: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDestination: URL?
    @State private var availableFolders: [FileItem] = []
    @State private var navigationPath: [URL] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("Move Files"), displayMode: .inline) {
            VStack(spacing: 0) {
                if !navigationPath.isEmpty {
                    HStack {
                        Button {
                            navigateUp()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(.localized("Back"))
                            }
                            .font(.body)
                            .foregroundStyle(.blue)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                Form {
                    Section {
                        ForEach(files) { file in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [file.iconColor.opacity(0.15), file.iconColor.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: file.icon)
                                        .font(.body)
                                        .foregroundStyle(file.iconColor)
                                }
                                
                                Text(file.name)
                                    .lineLimit(1)
                            }
                        }
                    } header: {
                        Label(.localized("Files To Move"), systemImage: "arrow.up.doc")
                    }
                    
                    Section {
                        Button {
                            selectedDestination = currentNavigationDirectory
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedDestination == currentNavigationDirectory ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "folder.fill")
                                        .font(.body)
                                        .foregroundStyle(selectedDestination == currentNavigationDirectory ? Color.blue : Color.gray)
                                }
                                
                                Text(.localized("Current Folder"))
                                Spacer()
                                if selectedDestination == currentNavigationDirectory {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .disabled(currentNavigationDirectory == currentDirectory)
                        
                        ForEach(availableFolders) { folder in
                            Button {
                                if folder.isDirectory {
                                    navigateToFolder(folder.url)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [folder.iconColor.opacity(0.15), folder.iconColor.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: folder.icon)
                                            .font(.body)
                                            .foregroundStyle(folder.iconColor)
                                    }
                                    
                                    Text(folder.name)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Label(.localized("Destination"), systemImage: "folder.badge.questionmark")
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        } header: {
                            Text(.localized("Error"))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        moveFiles()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.body)
                            Text(.localized("Move"))
                        }
                    }
                    .disabled(selectedDestination == nil || isProcessing)
                }
            }
            .onAppear {
                loadFolders()
            }
        }
    }
    
    private var currentNavigationDirectory: URL {
        navigationPath.last ?? FileManagerService.shared.documentsDirectory.appendingPathComponent("PortalFiles", isDirectory: true)
    }
    
    private func loadFolders() {
        let targetDirectory = currentNavigationDirectory
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: targetDirectory,
                    includingPropertiesForKeys: [.isDirectoryKey]
                )
                
                let folders = contents.compactMap { url -> FileItem? in
                    guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                          resourceValues.isDirectory == true else {
                        return nil
                    }
                    
                    let customIcon = UserDefaults.standard.string(forKey: "folder_icon_\(url.path)")
                    
                    return FileItem(
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: true,
                        size: nil,
                        sizeInBytes: nil,
                        modificationDate: nil,
                        customIcon: customIcon
                    )
                }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                
                DispatchQueue.main.async {
                    self.availableFolders = folders
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func navigateToFolder(_ url: URL) {
        navigationPath.append(url)
        selectedDestination = url
        loadFolders()
        HapticsManager.shared.impact()
    }
    
    private func navigateUp() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            selectedDestination = currentNavigationDirectory
            loadFolders()
            HapticsManager.shared.impact()
        }
    }
    
    private func moveFiles() {
        guard let destination = selectedDestination else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                for file in files {
                    let destinationURL = destination.appendingPathComponent(file.name)
                    
                    // Check if file already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        throw NSError(
                            domain: "MoveFile",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "File '\(file.name)' already exists at destination"]
                        )
                    }
                    
                    try FileManager.default.moveItem(at: file.url, to: destinationURL)
                }
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    FileManagerService.shared.loadFiles()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    HapticsManager.shared.error()
                    isProcessing = false
                }
            }
        }
    }
}
