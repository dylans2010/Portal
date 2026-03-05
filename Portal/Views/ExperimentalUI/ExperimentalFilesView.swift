//
//  ExperimentalFilesView.swift
//  Portal
// these new UIs arent expected for production, they are ugly ngl idk what i did here
//  Experimental UI redesigned Files view
//

import SwiftUI

struct ExperimentalFilesView: View {
    @StateObject private var fileManager = FileManagerService.shared
    @State private var selectedFolder: FileFolder = .all
    
    enum FileFolder: String, CaseIterable {
        case all = "All Files"
        case archives = "Archives"
        case signed = "Signed"
        case unsigned = "Unsigned"
    }
    
    private func getFilesForFolder(_ folder: FileFolder) -> [FileItem] {
        switch folder {
        case .all:
            return fileManager.currentFiles
        case .archives:
            return fileManager.currentFiles.filter { $0.url.pathExtension.lowercased() == "zip" }
        case .signed:
            // Files that might be signed IPAs or similar
            return fileManager.currentFiles.filter { ["ipa", "app"].contains($0.url.pathExtension.lowercased()) }
        case .unsigned:
            // Other files
            return fileManager.currentFiles.filter { 
                !["zip", "ipa", "app"].contains($0.url.pathExtension.lowercased()) && !$0.isDirectory 
            }
        }
    }
    
    private var totalSize: Int64 {
        fileManager.currentFiles.reduce(0) { total, file in
            total + Int64(file.sizeInBytes ?? 0)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Files",
                        subtitle: "Manage your files",
                        icon: "folder.fill"
                    )
                    
                    // Quick Stats
                    ExperimentalQuickStats(totalFiles: fileManager.currentFiles.count, storageUsed: totalSize)
                    
                    // Folder Sections
                    ForEach(FileFolder.allCases, id: \.self) { folder in
                        ExperimentalFolderSection(folder: folder, files: getFilesForFolder(folder), fileManager: fileManager)
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Quick Stats
struct ExperimentalQuickStats: View {
    let totalFiles: Int
    let storageUsed: Int64
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            ExperimentalStatCard(
                icon: "doc.fill",
                value: "\(totalFiles)",
                label: "Total Files"
            )
            
            ExperimentalStatCard(
                icon: "archivebox.fill",
                value: ByteCountFormatter.string(fromByteCount: storageUsed, countStyle: .file),
                label: "Storage Used"
            )
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
    }
}

// MARK: - Stat Card
struct ExperimentalStatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.sm) {
            HStack(spacing: ExperimentalUITheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                
                Text(value)
                    .font(ExperimentalUITheme.Typography.title2)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(ExperimentalUITheme.Typography.caption)
                .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Colors.cardBackground)
                .shadow(
                    color: ExperimentalUITheme.Shadow.sm.color,
                    radius: ExperimentalUITheme.Shadow.sm.radius,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        )
    }
}

// MARK: - Folder Section
struct ExperimentalFolderSection: View {
    let folder: ExperimentalFilesView.FileFolder
    let files: [FileItem]
    @ObservedObject var fileManager: FileManagerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            HStack {
                Text(folder.rawValue)
                    .font(ExperimentalUITheme.Typography.title3)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(files.count) items")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            if files.isEmpty {
                Text("No files in this category")
                    .font(ExperimentalUITheme.Typography.body)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                    .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                    .padding(.vertical, ExperimentalUITheme.Spacing.sm)
            } else {
                VStack(spacing: ExperimentalUITheme.Spacing.sm) {
                    ForEach(files.prefix(3)) { file in
                        NavigationLink(destination: fileDetailSheet(for: file)) {
                            ExperimentalFileRow(file: file, folder: folder)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            }
        }
    }
    
    @ViewBuilder
    private func fileDetailSheet(for file: FileItem) -> some View {
        if file.isDirectory {
            FolderCustomizationView(folderURL: file.url)
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

// MARK: - File Row
struct ExperimentalFileRow: View {
    let file: FileItem
    let folder: ExperimentalFilesView.FileFolder
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            // File Icon
            ZStack {
                RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.sm)
                    .fill(ExperimentalUITheme.Gradients.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
            }
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(ExperimentalUITheme.Typography.callout)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(file.size ?? "Unknown size")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ExperimentalUITheme.Colors.textTertiary)
        }
        .padding(ExperimentalUITheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Colors.backgroundSecondary)
        )
    }
    
    var fileIcon: String {
        if file.isDirectory {
            return "folder.fill"
        }
        switch folder {
        case .archives: return "archivebox.fill"
        case .signed: return "checkmark.seal.fill"
        case .unsigned: return "doc.fill"
        default: 
            let ext = file.url.pathExtension.lowercased()
            switch ext {
            case "zip": return "doc.zipper"
            case "ipa", "app": return "app.badge"
            default: return "doc.fill"
            }
        }
    }
}
