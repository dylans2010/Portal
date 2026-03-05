import SwiftUI

struct XMLEditorView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var xmlContent: String = ""
    @State private var isEditing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }

                TextEditor(text: $xmlContent)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .disabled(!isEditing)
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) { dismiss() }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button(isEditing ? .localized("Save") : .localized("Edit")) {
                        if isEditing {
                            save()
                        } else {
                            isEditing = true
                        }
                    }

                    Menu {
                        Button {
                            formatXML()
                        } label: {
                            Label(.localized("Format XML"), systemImage: "text.alignleft")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        do {
            xmlContent = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            try xmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
            isEditing = false
            HapticsManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    private func formatXML() {
        // Simple indentation-based formatting
        let lines = xmlContent.components(separatedBy: .newlines)
        var formatted = ""
        var indent = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("</") {
                indent = max(0, indent - 1)
            }

            formatted += String(repeating: "    ", count: indent) + trimmed + "\n"

            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") && !trimmed.hasSuffix("/>") && !trimmed.contains("</") {
                indent += 1
            }
        }

        xmlContent = formatted
    }
}
