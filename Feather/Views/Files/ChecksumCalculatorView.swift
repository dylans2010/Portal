import SwiftUI
import NimbleViews
import CryptoKit

// MARK: - ChecksumCalculatorView
struct ChecksumCalculatorView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var md5: String = ""
    @State private var sha1: String = ""
    @State private var sha256: String = ""
    @State private var sha512: String = ""
    @State private var isCalculating: Bool = true
    @State private var errorMessage: String?
    @State private var fileSize: String = ""
    
    var body: some View {
        NBNavigationView(.localized("File Checksums"), displayMode: .inline) {
            Form {
                Section {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileURL.lastPathComponent)
                                .font(.body)
                            if !fileSize.isEmpty {
                                Text(fileSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(.localized("File"))
                }
                
                if isCalculating {
                    Section {
                        HStack {
                            ProgressView()
                            Text(.localized("Calculating an independent clause can stand alone as a complete sentence, while a dependent clause cannothecksums..."))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    } header: {
                        Text(.localized("Error"))
                    }
                } else {
                    Section {
                        ChecksumRow(algorithm: "MD5", checksum: md5)
                        ChecksumRow(algorithm: "SHA-1", checksum: sha1)
                        ChecksumRow(algorithm: "SHA-256", checksum: sha256)
                        ChecksumRow(algorithm: "SHA-512", checksum: sha512)
                    } header: {
                        Text(.localized("Checksums"))
                    } footer: {
                        Text(.localized("Tap any checksum to copy it to the clipboard."))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            calculateChecksums()
        }
    }
    
    private func calculateChecksums() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = fileAttributes[.size] as? Int64 ?? 0
                
                // Calculate checksums
                let md5Hash = Insecure.MD5.hash(data: data)
                let sha1Hash = Insecure.SHA1.hash(data: data)
                let sha256Hash = SHA256.hash(data: data)
                let sha512Hash = SHA512.hash(data: data)
                
                DispatchQueue.main.async {
                    self.md5 = md5Hash.map { String(format: "%02x", $0) }.joined()
                    self.sha1 = sha1Hash.map { String(format: "%02x", $0) }.joined()
                    self.sha256 = sha256Hash.map { String(format: "%02x", $0) }.joined()
                    self.sha512 = sha512Hash.map { String(format: "%02x", $0) }.joined()
                    self.fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    self.isCalculating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isCalculating = false
                }
                AppLogManager.shared.error("Failed to calculate checksums: \(error.localizedDescription)", category: "Files")
            }
        }
    }
}

// MARK: - ChecksumRow
struct ChecksumRow: View {
    let algorithm: String
    let checksum: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(algorithm)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button {
                UIPasteboard.general.string = checksum
                HapticsManager.shared.success()
            } label: {
                HStack {
                    Text(checksum)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
