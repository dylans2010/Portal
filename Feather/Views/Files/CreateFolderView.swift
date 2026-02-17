import SwiftUI
import NimbleViews

struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss
    let directoryURL: URL
    
    @State private var folderName: String = ""
    
    var body: some View {
        NBNavigationView(.localized("Create Folder"), displayMode: .inline) {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "folder.badge.plus")
                                .font(.body)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        TextField(.localized("Folder Name"), text: $folderName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Label(.localized("Name"), systemImage: "textformat")
                } footer: {
                    Text(.localized("Enter a name for the new folder."))
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
                        createFolder()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)
                            Text(.localized("Create"))
                        }
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
    
    private func createFolder() {
        let folderURL = directoryURL.appendingPathComponent(folderName)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to create folder: \(error.localizedDescription)", category: "Files")
        }
    }
}
