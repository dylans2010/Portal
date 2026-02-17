import SwiftUI
import NimbleViews

// MARK: - JSONViewerView
struct JSONViewerView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var jsonContent: String = ""
    @State private var isEditing: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var validationError: String?
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NBNavigationView(.localized("JSON Viewer"), displayMode: .inline) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Validation error banner
                    if let error = validationError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.body)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Invalid JSON")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .padding()
                    }
                    
                    // Loading state
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading JSON...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // File info header
                        if !isEditing {
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fileURL.lastPathComponent)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        HStack(spacing: 8) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "curlybraces")
                                                    .font(.caption2)
                                                Text("JSON File")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            
                                            if validationError == nil {
                                                Text("•")
                                                    .foregroundStyle(.secondary)
                                                HStack(spacing: 4) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption2)
                                                    Text("Valid")
                                                }
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                        }
                        
                        // Content
                        if isEditing {
                            TextEditor(text: $jsonContent)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .focused($isTextEditorFocused)
                                .onChange(of: jsonContent) { _ in
                                    validateJSON()
                                }
                        } else {
                            ScrollView {
                                Text(jsonContent)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button {
                            formatJSON()
                        } label: {
                            Label(.localized("Format JSON"), systemImage: "text.alignleft")
                        }
                        
                        Button {
                            minifyJSON()
                        } label: {
                            Label(.localized("Minify JSON"), systemImage: "arrow.down.right.and.arrow.up.left")
                        }
                        
                        Divider()
                        
                        Button {
                            copyToClipboard()
                        } label: {
                            Label(.localized("Copy All"), systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button(isEditing ? .localized("Save") : .localized("Edit")) {
                        if isEditing {
                            saveContent()
                        } else {
                            isEditing = true
                        }
                    }
                    .disabled(isEditing && validationError != nil)
                }
            }
        }
        .onAppear {
            loadContent()
        }
    }
    
    private func loadContent() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                
                if let content = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.jsonContent = content
                        self.isLoading = false
                        self.validateJSON()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to decode file as UTF-8"
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                AppLogManager.shared.error("Failed to load JSON file: \(error.localizedDescription)", category: "Files")
            }
        }
    }
    
    private func validateJSON() {
        guard let data = jsonContent.data(using: .utf8) else {
            validationError = "Invalid UTF-8 Encoding"
            return
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            validationError = nil
        } catch {
            validationError = "Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func saveContent() {
        guard validationError == nil else {
            HapticsManager.shared.error()
            return
        }
        
        do {
            guard let data = jsonContent.data(using: .utf8) else {
                throw NSError(domain: "JSONViewer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode text"])
            }
            
            try data.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            isEditing = false
        } catch {
            HapticsManager.shared.error()
            validationError = "Save Failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to save JSON file: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func formatJSON() {
        guard let data = jsonContent.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            
            if let formatted = String(data: formattedData, encoding: .utf8) {
                jsonContent = formatted
                HapticsManager.shared.success()
            }
        } catch {
            HapticsManager.shared.error()
        }
    }
    
    private func minifyJSON() {
        guard let data = jsonContent.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let minifiedData = try JSONSerialization.data(withJSONObject: json, options: [])
            
            if let minified = String(data: minifiedData, encoding: .utf8) {
                jsonContent = minified
                HapticsManager.shared.success()
            }
        } catch {
            HapticsManager.shared.error()
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = jsonContent
        HapticsManager.shared.success()
    }
}
