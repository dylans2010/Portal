import SwiftUI

struct DataConverterView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var isConverting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(.localized("Source File")) {
                    Text(fileURL.lastPathComponent)
                        .foregroundStyle(.secondary)
                }

                Section {
                    if fileURL.pathExtension.lowercased() == "plist" {
                        Button(.localized("Convert to JSON")) {
                            convertPlistToJSON()
                        }
                    } else if fileURL.pathExtension.lowercased() == "json" {
                        Button(.localized("Convert to Plist")) {
                            convertJSONToPlist()
                        }
                    } else {
                        Text(.localized("Unsupported file type for conversion"))
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Data Converter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) { dismiss() }
                }
            }
        }
    }

    private func convertPlistToJSON() {
        do {
            let data = try Data(contentsOf: fileURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            let jsonData = try JSONSerialization.data(withJSONObject: plist, options: [.prettyPrinted])
            let newURL = fileURL.deletingPathExtension().appendingPathExtension("json")
            try jsonData.write(to: newURL)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    private func convertJSONToPlist() {
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let plistData = try PropertyListSerialization.data(fromPropertyList: json, format: .xml, options: 0)
            let newURL = fileURL.deletingPathExtension().appendingPathExtension("plist")
            try plistData.write(to: newURL)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }
}
