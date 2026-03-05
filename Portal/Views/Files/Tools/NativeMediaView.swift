import SwiftUI
import QuickLook
import PDFKit
import AVKit

struct NativeFileViewer: View {
    let fileURL: URL
    @State private var qlItem: URL?

    var body: some View {
        Group {
            if fileURL.pathExtension.lowercased() == "pdf" {
                PDFKitView(url: fileURL)
            } else if ["mp4", "mov", "m4v"].contains(fileURL.pathExtension.lowercased()) {
                VideoPlayerView(url: fileURL)
            } else if ["mp3", "wav", "m4a", "caf"].contains(fileURL.pathExtension.lowercased()) {
                AudioPlayerView(url: fileURL)
            } else {
                QuickLookController(url: fileURL)
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct VideoPlayerView: View {
    let url: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .ignoresSafeArea()
    }
}

struct AudioPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            Text(url.lastPathComponent)
                .font(.headline)

            HStack(spacing: 40) {
                Button {
                    player?.seek(to: .zero)
                    player?.play()
                    isPlaying = true
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }

                Button {
                    if isPlaying {
                        player?.pause()
                    } else {
                        player?.play()
                    }
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }

                Button {
                    // Fast forward or next?
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
        }
        .onAppear {
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
        }
    }
}

struct QuickLookController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookController

        init(parent: QuickLookController) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}
