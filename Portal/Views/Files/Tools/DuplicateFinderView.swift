import SwiftUI
import CryptoKit

struct DuplicateFinderView: View {
    let baseDirectory: URL
    @State private var duplicates: [String: [URL]] = [:]
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack {
                if isSearching {
                    ProgressView(.localized("Searching for duplicates..."))
                } else if duplicates.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text(.localized("No duplicates found yet"))
                        Button(.localized("Start Search")) {
                            search()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(duplicates.keys.sorted(), id: \.self) { hash in
                            Section(header: Text("Hash: \(hash.prefix(8))...")) {
                                ForEach(duplicates[hash]!, id: \.self) { url in
                                    VStack(alignment: .leading) {
                                        Text(url.lastPathComponent)
                                        Text(url.path)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
            .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(.localized("Duplicate Finder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !duplicates.isEmpty {
                    Button(.localized("Rescan")) {
                        search()
                    }
                }
            }
        }
    }

    private func search() {
        isSearching = true
        duplicates = [:]

        DispatchQueue.global(qos: .userInitiated).async {
            var hashMap: [String: [URL]] = [:]

            if let enumerator = FileManager.default.enumerator(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let url as URL in enumerator {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                        if let data = try? Data(contentsOf: url) {
                            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                            if hashMap[hash] != nil {
                                hashMap[hash]?.append(url)
                            } else {
                                hashMap[hash] = [url]
                            }
                        }
                    }
                }
            }

            let filtered = hashMap.filter { $0.value.count > 1 }

            DispatchQueue.main.async {
                self.duplicates = filtered
                self.isSearching = false
                HapticsManager.shared.success()
            }
        }
    }
}
