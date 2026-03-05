import SwiftUI
import ImageIO

struct EXIFViewerView: View {
    let fileURL: URL
    @State private var metadata: [String: Any] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView(.localized("Loading Metadata..."))
                } else if metadata.isEmpty {
                    Text(.localized("No EXIF metadata found"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(metadata.keys.sorted(), id: \.self) { key in
                        if let dict = metadata[key] as? [String: Any] {
                            Section(header: Text(key)) {
                                ForEach(dict.keys.sorted(), id: \.self) { subKey in
                                    HStack {
                                        Text(subKey)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(String(describing: dict[subKey] ?? ""))")
                                            .font(.caption2.monospaced())
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(String(describing: metadata[key] ?? ""))")
                                    .font(.caption2.monospaced())
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("EXIF Viewer"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadMetadata()
            }
        }
    }

    private func loadMetadata() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]

            DispatchQueue.main.async {
                self.metadata = imageProperties ?? [:]
                self.isLoading = false
            }
        }
    }
}
