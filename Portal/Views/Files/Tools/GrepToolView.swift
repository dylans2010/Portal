import SwiftUI

struct GrepToolView: View {
    let baseDirectory: URL
    @State private var pattern: String = ""
    @State private var results: [GrepResult] = []
    @State private var isSearching = false
    @State private var caseSensitive = false

    struct GrepResult: Identifiable {
        let id = UUID()
        let url: URL
        let lineNumber: Int
        let lineContent: String
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField(.localized("Regex Pattern"), text: $pattern)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Aa", isOn: $caseSensitive)
                        .toggleStyle(.button)

                    Button {
                        search()
                    } label: {
                        if isSearching {
                            ProgressView()
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .disabled(pattern.isEmpty || isSearching)
                }
                .padding()

                List(results) { result in
                    VStack(alignment: .leading) {
                        Text(result.url.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(result.lineNumber): \(result.lineContent)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .navigationTitle(.localized("File Content Search"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func search() {
        isSearching = true
        results = []

        let searchPattern = pattern
        let sensitive = caseSensitive

        DispatchQueue.global(qos: .userInitiated).async {
            var found: [GrepResult] = []

            if let enumerator = FileManager.default.enumerator(at: baseDirectory, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                        // Check if it's a text file (simple extension check for now)
                        let ext = url.pathExtension.lowercased()
                        let textExtensions = ["txt", "swift", "h", "m", "plist", "json", "xml", "md", "js", "py"]
                        if textExtensions.contains(ext) {
                            if let content = try? String(contentsOf: url, encoding: .utf8) {
                                let lines = content.components(separatedBy: .newlines)
                                for (index, line) in lines.enumerated() {
                                    let matches: Bool
                                    if sensitive {
                                        matches = line.contains(searchPattern)
                                    } else {
                                        matches = line.localizedCaseInsensitiveContains(searchPattern)
                                    }

                                    if matches {
                                        found.append(GrepResult(url: url, lineNumber: index + 1, lineContent: line.trimmingCharacters(in: .whitespaces)))
                                    }

                                    if found.count > 500 { break }
                                }
                            }
                        }
                    }
                    if found.count > 500 { break }
                }
            }

            DispatchQueue.main.async {
                results = found
                isSearching = false
                HapticsManager.shared.success()
            }
        }
    }
}
