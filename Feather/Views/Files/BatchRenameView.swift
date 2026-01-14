import SwiftUI
import NimbleViews

// MARK: - BatchRenameView
struct BatchRenameView: View {
    let files: [FileItem]
    @Environment(\.dismiss) var dismiss
    
    @State private var renamePattern: String = ""
    @State private var replaceText: String = ""
    @State private var withText: String = ""
    @State private var addPrefix: String = ""
    @State private var addSuffix: String = ""
    @State private var selectedMode: RenameMode = .findReplace
    @State private var startNumber: Int = 1
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @State private var previewNames: [String] = []
    
    enum RenameMode: String, CaseIterable {
        case findReplace = "Find & Replace"
        case sequential = "Sequential Numbering"
        case prefixSuffix = "Add Prefix/Suffix"
    }
    
    var body: some View {
        NBNavigationView(.localized("Batch Rename"), displayMode: .inline) {
            Form {
                Section {
                    Picker(.localized("Rename Method"), selection: $selectedMode) {
                        ForEach(RenameMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: iconForMode(mode))
                                    .font(.caption)
                                Text(mode.rawValue)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label(.localized("Method"), systemImage: "slider.horizontal.3")
                }
                
                Section {
                    switch selectedMode {
                    case .findReplace:
                        findReplaceFields
                    case .sequential:
                        sequentialFields
                    case .prefixSuffix:
                        prefixSuffixFields
                    }
                } header: {
                    Label(.localized("Options"), systemImage: "gearshape")
                }
                
                Section {
                    ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: file.icon)
                                    .font(.caption)
                                    .foregroundStyle(file.iconColor.opacity(0.6))
                                Text(file.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .strikethrough()
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                            
                            if index < previewNames.count {
                                HStack(spacing: 8) {
                                    Image(systemName: file.icon)
                                        .font(.caption)
                                        .foregroundStyle(file.iconColor)
                                    Text(previewNames[index])
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label(.localized("Preview"), systemImage: "eye")
                } footer: {
                    Text(.localized("\(files.count) file(s) will be renamed"))
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        performBatchRename()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                            Text(.localized("Rename"))
                        }
                    }
                    .disabled(isProcessing || !isValidConfiguration)
                }
            }
            .onChange(of: selectedMode) { _ in updatePreview() }
            .onChange(of: replaceText) { _ in updatePreview() }
            .onChange(of: withText) { _ in updatePreview() }
            .onChange(of: addPrefix) { _ in updatePreview() }
            .onChange(of: addSuffix) { _ in updatePreview() }
            .onChange(of: renamePattern) { _ in updatePreview() }
            .onChange(of: startNumber) { _ in updatePreview() }
            .onAppear {
                updatePreview()
            }
        }
    }
    
    private func iconForMode(_ mode: RenameMode) -> String {
        switch mode {
        case .findReplace:
            return "magnifyingglass"
        case .sequential:
            return "number.square"
        case .prefixSuffix:
            return "textformat"
        }
    }
    
    @ViewBuilder
    private var findReplaceFields: some View {
        TextField(.localized("Find Text"), text: $replaceText)
            .textInputAutocapitalization(.never)
        
        TextField(.localized("Replace With"), text: $withText)
            .textInputAutocapitalization(.never)
    }
    
    @ViewBuilder
    private var sequentialFields: some View {
        TextField(.localized("Name Pattern"), text: $renamePattern)
            .textInputAutocapitalization(.never)
        
        Stepper(value: $startNumber, in: 1...9999) {
            HStack {
                Text(.localized("Start From"))
                Spacer()
                Text("\(startNumber)")
                    .foregroundStyle(.secondary)
            }
        }
        
        Text(.localized("Use {n} in pattern for number, e.g., \"File_{n}\""))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var prefixSuffixFields: some View {
        TextField(.localized("Prefix"), text: $addPrefix)
            .textInputAutocapitalization(.never)
        
        TextField(.localized("Suffix"), text: $addSuffix)
            .textInputAutocapitalization(.never)
    }
    
    private var isValidConfiguration: Bool {
        switch selectedMode {
        case .findReplace:
            return !replaceText.isEmpty
        case .sequential:
            return !renamePattern.isEmpty && renamePattern.contains("{n}")
        case .prefixSuffix:
            return !addPrefix.isEmpty || !addSuffix.isEmpty
        }
    }
    
    private func updatePreview() {
        previewNames = files.enumerated().map { index, file in
            let nameWithoutExt = file.url.deletingPathExtension().lastPathComponent
            let ext = file.url.pathExtension
            
            var newName: String
            
            switch selectedMode {
            case .findReplace:
                newName = nameWithoutExt.replacingOccurrences(of: replaceText, with: withText)
            case .sequential:
                let number = startNumber + index
                newName = renamePattern.replacingOccurrences(of: "{n}", with: String(format: "%04d", number))
            case .prefixSuffix:
                newName = addPrefix + nameWithoutExt + addSuffix
            }
            
            return ext.isEmpty ? newName : "\(newName).\(ext)"
        }
    }
    
    private func performBatchRename() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                for (index, file) in files.enumerated() {
                    guard index < previewNames.count else { continue }
                    
                    let newName = previewNames[index]
                    let newURL = file.url.deletingLastPathComponent().appendingPathComponent(newName)
                    
                    // Check if target already exists
                    if FileManager.default.fileExists(atPath: newURL.path) && newURL != file.url {
                        throw NSError(
                            domain: "BatchRename",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "File '\(newName)' Already Exists"]
                        )
                    }
                    
                    try FileManager.default.moveItem(at: file.url, to: newURL)
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
