import SwiftUI

struct LargeFileFinderView: View {
    let baseDirectory: URL
    @State private var files: [FileInfo] = []
    @State private var isSearching = false

    struct FileInfo: Identifiable {
        let id = UUID()
        let url: URL
        let size: Int64
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isSearching {
                    ProgressView(.localized("Scanning files..."))
                } else {
                    List(files) { file in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(file.url.lastPathComponent)
                                Text(file.url.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(.localized("Large Files"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                search()
            }
        }
    }

    private func search() {
        isSearching = true

        DispatchQueue.global(qos: .userInitiated).async {
            var allFiles: [FileInfo] = []

            if let enumerator = FileManager.default.enumerator(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let url as URL in enumerator {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            allFiles.append(FileInfo(url: url, size: Int64(size)))
                        }
                    }
                }
            }

            let sorted = allFiles.sorted { $0.size > $1.size }.prefix(100)

            DispatchQueue.main.async {
                self.files = Array(sorted)
                self.isSearching = false
                HapticsManager.shared.success()
            }
        }
    }
}
