import SwiftUI

struct IPAExplorerFileBrowser: View {
    let rootURL: URL
    let currentURL: URL
    @ObservedObject var viewModel: IPAExplorerViewModel

    @State private var items: [URL] = []

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                if isDirectory(item) {
                    NavigationLink {
                        IPAExplorerFileBrowser(rootURL: rootURL, currentURL: item, viewModel: viewModel)
                    } label: {
                        FileRow(url: item)
                    }
                } else {
                    NavigationLink {
                        fileDetailView(for: item)
                    } label: {
                        FileRow(url: item)
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(currentURL == rootURL ? .localized("Payload") : currentURL.lastPathComponent)
        .onAppear {
            loadItems()
        }
    }

    private func loadItems() {
        items = (try? FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil))?.sorted { a, b in
            let aIsDir = isDirectory(a)
            let bIsDir = isDirectory(b)
            if aIsDir != bIsDir {
                return aIsDir
            }
            return a.lastPathComponent.localizedLowercase < b.lastPathComponent.localizedLowercase
        } ?? []
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    @ViewBuilder
    private func fileDetailView(for url: URL) -> some View {
        let ext = url.pathExtension.lowercased()
        if ext == "plist" {
            IPAExplorerPlistViewer(fileURL: url, viewModel: viewModel)
        } else if ext == "mobileprovision" {
            IPAExplorerProvisionViewer(fileURL: url)
        } else if isBinary(url) {
            IPAExplorerBinaryViewer(fileURL: url)
        } else {
            // Fallback to text viewer if it's text, or hex viewer
            SimpleFileViewer(url: url)
        }
    }

    private func isBinary(_ url: URL) -> Bool {
        let type = FileAnalysisEngine.detectFileType(at: url.path)
        return type == .machO || type == .dylib
    }
}

struct FileRow: View {
    let url: URL

    var body: some View {
        HStack {
            Image(systemName: isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(isDirectory ? .blue : .secondary)
            VStack(alignment: .leading) {
                Text(url.lastPathComponent)
                    .font(.body)
                if !isDirectory {
                    Text(fileSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    var fileSize: String {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attr[.size] as? Int64 else { return "" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct SimpleFileViewer: View {
    let url: URL
    @State private var content: String = ""

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear {
            if let data = try? Data(contentsOf: url), let s = String(data: data, encoding: .utf8) {
                content = s
            } else {
                content = "Binary file or encoding not supported."
            }
        }
    }
}
