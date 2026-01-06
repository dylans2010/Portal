import SwiftUI
import NimbleViews
import Zip

// MARK: - ZipOperationView
struct ZipOperationView: View {
    let files: [FileItem]
    let operation: Operation
    let directoryURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var zipName: String = ""
    @State private var targetDirectory: URL?
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var errorMessage: String?
    @State private var conflictResolution: ConflictResolution = .rename
    
    enum Operation {
        case zip
        case unzip
    }
    
    enum ConflictResolution: String, CaseIterable {
        case rename = "Rename"
        case replace = "Replace"
        case skip = "Skip"
    }
    
    var body: some View {
        NBNavigationView(operation == .zip ? .localized("Create Zip") : .localized("Unzip File"), displayMode: .inline) {
            ZStack {
                // Modern background
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    if operation == .zip {
                        zipConfigSection
                    } else {
                        unzipConfigSection
                    }
                    
                    if isProcessing {
                        Section {
                            VStack(spacing: 12) {
                                // Modern progress indicator
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: CGFloat(progress) * UIScreen.main.bounds.width * 0.8, height: 8)
                                        .animation(.linear(duration: 0.2), value: progress)
                                }
                                
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                    Text("\(Int(progress * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(operation == .zip ? .localized("Compressing...") : .localized("Extracting..."))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Label(.localized("Progress"), systemImage: "chart.bar.fill")
                        }
                    }
                    
                    if let error = errorMessage {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Label(.localized("Error"), systemImage: "xmark.circle.fill")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        performOperation()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: operation == .zip ? "archivebox.fill" : "tray.and.arrow.down.fill")
                                .font(.caption)
                            Text(operation == .zip ? .localized("Zip") : .localized("Unzip"))
                        }
                    }
                    .disabled(isProcessing || (operation == .zip && zipName.isEmpty))
                }
            }
        }
        .onAppear {
            targetDirectory = directoryURL
            if operation == .zip {
                zipName = "Archive"
            }
        }
    }
    
    @ViewBuilder
    private var zipConfigSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.body)
                TextField(.localized("Archive Name"), text: $zipName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 4)
        } header: {
            Label(.localized("Archive Name"), systemImage: "tag.fill")
        } footer: {
            Text(.localized("Name for the zip archive (without .zip extension)"))
                .font(.caption2)
        }
        
        Section {
            ForEach(files) { file in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(file.iconColor.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: file.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(file.iconColor)
                    }
                    Text(file.name)
                        .font(.subheadline)
                    Spacer()
                    if let size = file.size {
                        Text(size)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label(.localized("Files to Zip (\(files.count))"), systemImage: "doc.on.doc.fill")
        }
    }
    
    @ViewBuilder
    private var unzipConfigSection: some View {
        Section {
            if let zipFile = files.first {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(zipFile.iconColor.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: zipFile.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(zipFile.iconColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zipFile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let size = zipFile.size {
                            Text(size)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label(.localized("Archive"), systemImage: "archivebox.fill")
        }
        
        Section {
            Picker(.localized("If File Exists"), selection: $conflictResolution) {
                ForEach(ConflictResolution.allCases, id: \.self) { option in
                    HStack {
                        Image(systemName: iconForResolution(option))
                            .font(.caption)
                        Text(option.rawValue)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Label(.localized("Conflict Resolution"), systemImage: "exclamationmark.triangle.fill")
        } footer: {
            Text(.localized("Choose what to do if files already exist"))
                .font(.caption2)
        }
    }
    
    private func iconForResolution(_ resolution: ConflictResolution) -> String {
        switch resolution {
        case .rename: return "doc.badge.plus"
        case .replace: return "arrow.triangle.2.circlepath"
        case .skip: return "forward.fill"
        }
    }
    
    private func performOperation() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                if operation == .zip {
                    try await performZip()
                } else {
                    try await performUnzip()
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
    
    private func performZip() async throws {
        let zipURL = directoryURL.appendingPathComponent(zipName + ".zip")
        let filePaths = files.map { $0.url }
        
        try await Task.detached(priority: .userInitiated) { [self] in
            try Zip.zipFiles(
                paths: filePaths,
                zipFilePath: zipURL,
                password: nil,
                compression: .DefaultCompression,
                progress: { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                    }
                }
            )
        }.value
    }
    
    private func performUnzip() async throws {
        guard let zipFile = files.first else { return }
        let destinationURL = directoryURL
        let zipFileURL = zipFile.url
        
        try await Task.detached(priority: .userInitiated) { [self] in
            try await Zip.unzipFile(
                zipFile.url,
                destination: destinationURL,
                overwrite: conflictResolution == .replace,
                password: nil,
                progress: { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                    }
                }
            )
            
            // Delete the zip file after successful extraction
            try? FileManager.default.removeItem(at: zipFileURL)
        }.value
    }
}
