import SwiftUI
import NimbleViews

struct CreateTextFileView: View {
    @Environment(\.dismiss) var dismiss
    let directoryURL: URL
    
    @State private var fileName: String = ""
    @State private var fileContent: String = ""
    
    var body: some View {
        NBNavigationView(.localized("Create Text File"), displayMode: .inline) {
            Form {
                Section {
                    TextField(.localized("File Name"), text: $fileName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("Name"))
                }
                
                Section {
                    TextEditor(text: $fileContent)
                        .frame(minHeight: 200)
                } header: {
                    Text(.localized("Content"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
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
        let fileURL = directoryURL.appendingPathComponent(fileName + ".txt")
        
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to create text file: \(error.localizedDescription)", category: "Files")
        }
    }
}
