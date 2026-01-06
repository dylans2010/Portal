import SwiftUI
import NimbleViews

// MARK: - TextViewerView
struct TextViewerView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var textContent: String = ""
    @State private var selectedEncoding: String.Encoding = .utf8
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showEncodingPicker: Bool = false
    @State private var isEditing: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    @State private var autoSaveTimer: Timer?
    @FocusState private var isTextEditorFocused: Bool
    
    let availableEncodings: [(name: String, encoding: String.Encoding)] = [
        ("UTF-8", .utf8),
        ("UTF-16", .utf16),
        ("UTF-32", .utf32),
        ("ASCII", .ascii),
        ("ISO Latin 1", .isoLatin1),
        ("ISO Latin 2", .isoLatin2),
        ("Windows CP1252", .windowsCP1252),
        ("Mac OS Roman", .macOSRoman)
    ]
    
    var body: some View {
        NBNavigationView(.localized("Text Viewer"), displayMode: .inline) {
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
                
                VStack(spacing: 0) {
                    // Error banner
                    if let error = errorMessage {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.white)
                                .font(.body)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Loading state
                    if isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading file...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        // File info header
                        if !isEditing {
                            VStack(spacing: 0) {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .font(.caption)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(fileURL.lastPathComponent)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        
                                        HStack(spacing: 6) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "text.alignleft")
                                                    .font(.caption2)
                                                Text("\(textContent.split(separator: "\n").count)")
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "textformat")
                                                    .font(.caption2)
                                                Text(selectedEncoding.description)
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                            }
                        }
                        
                        // Content
                        if isEditing {
                            TextEditor(text: $textContent)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .focused($isTextEditorFocused)
                                .onChange(of: textContent) { _ in
                                    hasUnsavedChanges = true
                                    scheduleAutoSave()
                                }
                        } else {
                            ScrollView {
                                Text(textContent)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .textSelection(.enabled)
                            }
                            .background(Color(UIColor.systemGroupedBackground))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        if hasUnsavedChanges {
                            saveContentSilently()
                        }
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    if hasUnsavedChanges {
                        Label(.localized("Auto-saving..."), systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Menu {
                        Button {
                            showEncodingPicker = true
                        } label: {
                            Label(.localized("Change Encoding"), systemImage: "textformat.abc")
                        }
                        
                        Button {
                            copyToClipboard()
                        } label: {
                            Label(.localized("Copy All"), systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            shareFile()
                        } label: {
                            Label(.localized("Share"), systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    if !isLoading {
                        Button(isEditing ? .localized("Save") : .localized("Edit")) {
                            if isEditing {
                                saveContent()
                            } else {
                                isEditing = true
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showEncodingPicker) {
                encodingPickerSheet
            }
        }
        .onAppear {
            loadContent()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
            if hasUnsavedChanges {
                saveContentSilently()
            }
        }
    }
    
    private var encodingPickerSheet: some View {
        NBNavigationView(.localized("Text Encoding"), displayMode: .inline) {
            Form {
                Section {
                    ForEach(availableEncodings, id: \.name) { item in
                        Button {
                            selectedEncoding = item.encoding
                            showEncodingPicker = false
                            loadContent()
                        } label: {
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedEncoding == item.encoding {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(.localized("Select Encoding"))
                } footer: {
                    Text(.localized("Choose the character encoding for this file"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showEncodingPicker = false
                    }
                }
            }
        }
    }
    
    private func loadContent() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                
                guard let content = String(data: data, encoding: selectedEncoding) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to decode file with \(encodingName()) encoding"
                        self.isLoading = false
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.textContent = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                AppLogManager.shared.error("Failed to load text file: \(error.localizedDescription)", category: "Files")
            }
        }
    }
    
    private func saveContent() {
        do {
            guard let data = textContent.data(using: selectedEncoding) else {
                throw NSError(domain: "TextViewer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode text"])
            }
            
            try data.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            hasUnsavedChanges = false
            isEditing = false
        } catch {
            HapticsManager.shared.error()
            errorMessage = "Save failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to save text file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func saveContentSilently() {
        do {
            guard let data = textContent.data(using: selectedEncoding) else { return }
            try data.write(to: fileURL, options: .atomic)
            hasUnsavedChanges = false
        } catch {
            AppLogManager.shared.error("Failed to auto-save text file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        DispatchQueue.main.async {
            self.autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                self.saveContentSilently()
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = textContent
        HapticsManager.shared.success()
    }
    
    private func shareFile() {
        UIActivityViewController.show(activityItems: [fileURL])
    }
    
    private func encodingName() -> String {
        availableEncodings.first(where: { $0.encoding == selectedEncoding })?.name ?? "UTF-8"
    }
}
