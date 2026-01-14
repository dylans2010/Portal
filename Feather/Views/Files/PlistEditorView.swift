import SwiftUI
import NimbleViews

struct PlistEditorView: View {
    @Environment(\.dismiss) var dismiss
    let fileURL: URL
    
    @State private var plistContent: String = ""
    @State private var isEditing: Bool = false
    @State private var showFormatPicker: Bool = false
    @State private var selectedFormat: PlistFormat = .xml
    @State private var validationError: String?
    @State private var hasUnsavedChanges: Bool = false
    @State private var autoSaveTimer: Timer?
    @FocusState private var isTextEditorFocused: Bool
    
    enum PlistFormat: String, CaseIterable {
        case xml = "XML"
        case binary = "Binary"
    }
    
    enum ViewMode {
        case raw
        case formatted
    }
    
    var body: some View {
        NBNavigationView(.localized("Plist Editor"), displayMode: .inline) {
            ZStack {
                // Modern background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let error = validationError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.white)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if isEditing {
                        ZStack(alignment: .bottom) {
                            TextEditor(text: $plistContent)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .padding(.bottom, 50)
                                .focused($isTextEditorFocused)
                                .onChange(of: plistContent) { _ in
                                    validatePlist()
                                    if validationError == nil {
                                        hasUnsavedChanges = true
                                        scheduleAutoSave()
                                    }
                                }
                            
                            if isTextEditorFocused {
                                plistKeyboardToolbar
                            }
                        }
                    } else {
                        ScrollView {
                            Text(plistContent)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        if hasUnsavedChanges && validationError == nil {
                            saveContentSilently()
                        }
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    if hasUnsavedChanges {
                        Label(.localized("Auto Saving..."), systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Menu {
                        Button {
                            showFormatPicker = true
                        } label: {
                            Label(.localized("Convert Format"), systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button {
                            formatPlistContent()
                        } label: {
                            Label(.localized("Format XML"), systemImage: "text.alignleft")
                        }
                        .disabled(selectedFormat != .xml)
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
            .sheet(isPresented: $showFormatPicker) {
                formatConversionSheet
            }
        }
        .onAppear {
            loadContent()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
            if hasUnsavedChanges && validationError == nil {
                saveContentSilently()
            }
        }
    }
    
    private var formatConversionSheet: some View {
        NBNavigationView(.localized("Convert Format"), displayMode: .inline) {
            Form {
                Section {
                    Picker(.localized("Target Format"), selection: $selectedFormat) {
                        ForEach(PlistFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(.localized("Format"))
                } footer: {
                    Text(.localized("Convert the plist to the selected format"))
                }
                
                Section {
                    Button {
                        convertFormat()
                        showFormatPicker = false
                    } label: {
                        Text(.localized("Convert"))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showFormatPicker = false
                    }
                }
            }
        }
    }
    
    private func loadContent() {
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Try to detect format
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                // Successfully parsed, now determine format
                var format: PropertyListSerialization.PropertyListFormat = .xml
                _ = try? PropertyListSerialization.propertyList(from: data, options: [], format: &format)
                selectedFormat = format == .binary ? .binary : .xml
                
                // Convert to XML string for display
                if format == .binary {
                    let xmlData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                    plistContent = String(data: xmlData, encoding: .utf8) ?? ""
                } else {
                    plistContent = String(data: data, encoding: .utf8) ?? ""
                }
            } else {
                plistContent = String(data: data, encoding: .utf8) ?? ""
            }
            
            validatePlist()
        } catch {
            plistContent = "Error loading file: \(error.localizedDescription)"
            validationError = error.localizedDescription
            AppLogManager.shared.error("Failed to load plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func validatePlist() {
        guard let data = plistContent.data(using: .utf8) else {
            validationError = "Invalid String Encoding"
            return
        }
        
        do {
            _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            validationError = nil
        } catch {
            validationError = "Invalid Plist: \(error.localizedDescription)"
        }
    }
    
    private func saveContent() {
        guard validationError == nil else {
            HapticsManager.shared.error()
            return
        }
        
        do {
            guard let data = plistContent.data(using: .utf8) else {
                throw NSError(domain: "PlistEditor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"])
            }
            
            // Validate and reserialize
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let outputData = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
            
            try outputData.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            hasUnsavedChanges = false
            isEditing = false
            loadContent() // Reload to show formatted version
        } catch {
            HapticsManager.shared.error()
            validationError = "Save Failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to save plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private func saveContentSilently() {
        guard validationError == nil else { return }
        
        do {
            guard let data = plistContent.data(using: .utf8) else { return }
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let outputData = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
            try outputData.write(to: fileURL, options: .atomic)
            hasUnsavedChanges = false
        } catch {
            AppLogManager.shared.error("Failed to auto-save plist: \(error.localizedDescription)", category: "Files")
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
    
    private func formatPlistContent() {
        guard selectedFormat == .xml else { return }
        
        do {
            guard let data = plistContent.data(using: .utf8) else { return }
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let formattedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            plistContent = String(data: formattedData, encoding: .utf8) ?? plistContent
            HapticsManager.shared.success()
        } catch {
            HapticsManager.shared.error()
        }
    }
    
    private func convertFormat() {
        do {
            guard let data = plistContent.data(using: .utf8) else { return }
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let convertedData = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
            
            try convertedData.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            loadContent()
        } catch {
            HapticsManager.shared.error()
            validationError = "Conversion Failed: \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to convert plist: \(error.localizedDescription)", category: "Files")
        }
    }
    
    private var plistKeyboardToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    toolbarButton(title: .localized("Key"), icon: "key.fill") {
                        insertTemplate("<key></key>")
                    }
                    
                    toolbarButton(title: .localized("String"), icon: "text.quote") {
                        insertTemplate("<string></string>")
                    }
                    
                    toolbarButton(title: .localized("Integer"), icon: "number") {
                        insertTemplate("<integer>0</integer>")
                    }
                    
                    toolbarButton(title: .localized("Boolean"), icon: "checkmark.circle") {
                        insertTemplate("<true/>")
                    }
                    
                    toolbarButton(title: .localized("Array"), icon: "list.bullet") {
                        insertTemplate("<array>\n\t\n</array>")
                    }
                    
                    toolbarButton(title: .localized("Dict"), icon: "curlybraces") {
                        insertTemplate("<dict>\n\t\n</dict>")
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    toolbarButton(title: .localized("Format"), icon: "text.alignleft") {
                        formatPlistContent()
                    }
                    
                    toolbarButton(title: .localized("Done"), icon: "keyboard.chevron.compact.down") {
                        isTextEditorFocused = false
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 50)
            .background(Color(.systemGray6))
        }
    }
    
    private func toolbarButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
            }
            .frame(minWidth: 50)
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
    
    private func insertTemplate(_ template: String) {
        // Insert at current cursor position or at end
        plistContent.append("\n" + template)
        HapticsManager.shared.impact()
    }
}
