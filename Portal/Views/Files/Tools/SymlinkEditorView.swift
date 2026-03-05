import SwiftUI

struct SymlinkEditorView: View {
    let fileURL: URL
    @State private var targetPath: String = ""
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(.localized("Current Link"))) {
                    Text(fileURL.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(.localized("Target Path"))) {
                    TextField(.localized("Target Path"), text: $targetPath)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button(.localized("Update Symlink")) {
                        update()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Symlink Editor"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        if let target = try? FileManager.default.destinationOfSymbolicLink(atPath: fileURL.path) {
            targetPath = target
        }
        isLoading = false
    }

    private func update() {
        do {
            try FileManager.default.removeItem(at: fileURL)
            try FileManager.default.createSymbolicLink(at: fileURL, withDestinationURL: URL(fileURLWithPath: targetPath))
            HapticsManager.shared.success()
            dismiss()
        } catch {
            HapticsManager.shared.error()
        }
    }
}
