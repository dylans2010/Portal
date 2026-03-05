import SwiftUI
import ZIPFoundation

struct ArchiveBrowserView: View {
    let fileURL: URL
    @State private var entries: [ArchiveEntry] = []
    @State private var isLoading = true

    struct ArchiveEntry: Identifiable {
        let id = UUID()
        let path: String
        let isDirectory: Bool
        let size: Int64
    }

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                HStack {
                    Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                    Text(entry.path)
                        .font(.caption)
                    Spacer()
                    if !entry.isDirectory {
                        Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadEntries()
            }
        }
    }

    private func loadEntries() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let archive = Archive(url: fileURL, accessMode: .read) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            var found: [ArchiveEntry] = []
            for entry in archive {
                found.append(ArchiveEntry(
                    path: entry.path,
                    isDirectory: entry.type == .directory,
                    size: Int64(entry.uncompressedSize)
                ))
            }

            DispatchQueue.main.async {
                self.entries = found.sorted { $0.path < $1.path }
                self.isLoading = false
            }
        }
    }
}
