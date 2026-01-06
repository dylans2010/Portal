import SwiftUI
import NimbleViews

struct CreatePlistView: View {
    @Environment(\.dismiss) var dismiss
    let directoryURL: URL
    
    @State private var fileName: String = ""
    @State private var selectedFormat: PlistFormat = .xml
    
    enum PlistFormat: String, CaseIterable {
        case xml = "XML"
        case binary = "Binary"
    }
    
    var body: some View {
        NBNavigationView(.localized("Create Plist File"), displayMode: .inline) {
            ZStack {
                // Modern background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.purple.opacity(0.15),
                                                Color.purple.opacity(0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "doc.badge.gearshape.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            TextField(.localized("File Name"), text: $fileName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.body)
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Label(.localized("Name"), systemImage: "textformat")
                    } footer: {
                        Text(.localized("Enter a name for the plist file (without .plist extension)"))
                            .font(.caption2)
                    }
                    
                    Section {
                        Picker(.localized("Format"), selection: $selectedFormat) {
                            ForEach(PlistFormat.allCases, id: \.self) { format in
                                HStack(spacing: 8) {
                                    Image(systemName: format == .xml ? "chevron.left.forwardslash.chevron.right" : "01.square.fill")
                                        .font(.caption)
                                    Text(format.rawValue)
                                }
                                .tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                    } header: {
                        Label(.localized("Plist Format"), systemImage: "doc.badge.gearshape")
                    } footer: {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.accentColor)
                            Text(.localized("XML format is human-readable, Binary format is more compact"))
                                .font(.caption2)
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
                        createPlist()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)
                            Text(.localized("Create"))
                        }
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private func createPlist() {
        let fileURL = directoryURL.appendingPathComponent(fileName + ".plist")
        
        // Create an empty dictionary for the plist
        let emptyDict: [String: Any] = [:]
        
        do {
            let format: PropertyListSerialization.PropertyListFormat = selectedFormat == .xml ? .xml : .binary
            let data = try PropertyListSerialization.data(fromPropertyList: emptyDict, format: format, options: 0)
            try data.write(to: fileURL)
            
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to create plist file: \(error.localizedDescription)", category: "Files")
        }
    }
}
