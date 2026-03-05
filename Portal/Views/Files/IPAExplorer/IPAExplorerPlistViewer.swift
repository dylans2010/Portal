import SwiftUI
import NimbleViews

struct IPAExplorerPlistViewer: View {
    let fileURL: URL
    @ObservedObject var viewModel: IPAExplorerViewModel
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @State private var plistData: [String: Any] = [:]
    @State private var keys: [String] = []
    @State private var showingEditAlert = false
    @State private var editingKey = ""
    @State private var editingValue = ""

    var body: some View {
        List {
            ForEach(keys.sorted(), id: \.self) { key in
                let value = plistData[key]
                PlistRow(key: key, value: value)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isDeveloperModeEnabled {
                            editingKey = key
                            editingValue = "\(value ?? "")"
                            showingEditAlert = true
                        }
                    }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(fileURL.lastPathComponent)
        .onAppear {
            loadPlist()
        }
        .alert(.localized("Edit Value"), isPresented: $showingEditAlert) {
            TextField(.localized("Value"), text: $editingValue)
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Save")) {
                saveValue()
            }
        } message: {
            Text(.localized("Enter new value for \(editingKey)"))
        }
    }

    private func loadPlist() {
        if let data = try? Data(contentsOf: fileURL),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            plistData = dict
            keys = Array(dict.keys)
        }
    }

    private func saveValue() {
        plistData[editingKey] = editingValue // This is a simplification; should handle types better

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
            try data.write(to: fileURL)
            viewModel.markAsModified()
            HapticsManager.shared.success()
            loadPlist()
        } catch {
            HapticsManager.shared.error()
        }
    }
}

struct PlistRow: View {
    let key: String
    let value: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let dict = value as? [String: Any] {
                Text("Dictionary (\(dict.count) items)")
                    .font(.body)
                    .italic()
            } else if let array = value as? [Any] {
                Text("Array (\(array.count) items)")
                    .font(.body)
                    .italic()
            } else {
                Text("\(String(describing: value ?? ""))")
                    .font(.body)
                    .lineLimit(5)
            }
        }
        .padding(.vertical, 4)
    }
}
