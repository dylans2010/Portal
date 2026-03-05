import SwiftUI
import CoreImage.CIFilterBuiltins

struct SourcesQRView: View {
    @Environment(\.dismiss) private var dismiss
    let data: String

    @State private var _isScanning = false

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scan to Import Sources")
                    .font(.headline)

                if data.count > 2000 {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)

                        Text("Exporting with QR Code won’t work because you have too many sources to export.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(height: 250)
                } else {
                    qrCodeImage
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }

                Text("Sharing \(data.count) Bytes Of Data")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        let image = generateQRCode(from: data)
                        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            rootVC.present(av, animated: true)
                        }
                    } label: {
                        Label("Share QR Code", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(data.count > 2000)

                    Button {
                        _isScanning = true
                    } label: {
                        Label("Scan Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $_isScanning) {
                QRScannerView { result in
                    _isScanning = false
                    _handleScannedResult(result)
                }
            }
        }
    }

    private func _handleScannedResult(_ result: String) {
        guard let urls = PortalSourceExport.decode(result) else {
            return
        }

        for url in urls {
            Storage.shared.addSource(url: url)
        }

        dismiss()
    }

    private var qrCodeImage: Image {
        let uiImage = generateQRCode(from: data)
        return Image(uiImage: uiImage)
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
