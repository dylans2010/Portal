import SwiftUI
import UniformTypeIdentifiers

struct ImageConverterView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var targetFormat: UTType = .png
    @State private var isConverting = false
    @State private var errorMessage: String?

    let formats: [UTType] = [.png, .jpeg, .heic]

    var body: some View {
        NavigationStack {
            Form {
                Section(.localized("Source File")) {
                    Text(fileURL.lastPathComponent)
                        .foregroundStyle(.secondary)
                }

                Section(.localized("Target Format")) {
                    Picker(.localized("Format"), selection: $targetFormat) {
                        ForEach(formats, id: \.identifier) { format in
                            Text(format.localizedDescription ?? format.preferredFilenameExtension?.uppercased() ?? "Unknown").tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        convert()
                    } label: {
                        if isConverting {
                            ProgressView()
                        } else {
                            Text(.localized("Convert"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isConverting)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Image Converter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
            }
        }
    }

    private func convert() {
        isConverting = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let image = UIImage(contentsOfFile: fileURL.path) else {
                    throw NSError(domain: "ImageConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }

                let data: Data?
                let ext: String

                if targetFormat == .png {
                    data = image.pngData()
                    ext = "png"
                } else if targetFormat == .jpeg {
                    data = image.jpegData(compressionQuality: 0.8)
                    ext = "jpg"
                } else if targetFormat == .heic {
                    // HEIC conversion requires specialized handling or iOS 11+
                    if #available(iOS 11.0, *) {
                        data = image.heicData()
                    } else {
                        throw NSError(domain: "ImageConverter", code: -2, userInfo: [NSLocalizedDescriptionKey: "HEIC not supported on this iOS version"])
                    }
                    ext = "heic"
                } else {
                    throw NSError(domain: "ImageConverter", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unsupported format"])
                }

                guard let finalData = data else {
                    throw NSError(domain: "ImageConverter", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
                }

                let newURL = fileURL.deletingPathExtension().appendingPathExtension(ext)
                try finalData.write(to: newURL)

                DispatchQueue.main.async {
                    isConverting = false
                    HapticsManager.shared.success()
                    FileManagerService.shared.loadFiles()
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isConverting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

@available(iOS 11.0, *)
extension UIImage {
    func heicData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, UTType.heic.identifier as CFString, 1, nil),
              let cgImage = self.cgImage else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }

        return mutableData as Data
    }
}
