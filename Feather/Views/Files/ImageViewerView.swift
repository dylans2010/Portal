import SwiftUI
import NimbleViews

// MARK: - ImageViewerView
struct ImageViewerView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(fileURL.lastPathComponent, displayMode: .inline) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let error = errorMessage {
                    errorView(error: error)
                } else if let image = image {
                    imageView(image: image)
                } else {
                    loadingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
                
                if image != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            resetZoom()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            shareImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text(.localized("Loading Image..."))
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text(.localized("Error Loading Image"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func imageView(image: UIImage) -> some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1.0), 10.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    offset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            if scale <= 1.0 {
                                withAnimation(.spring()) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
                .onTapGesture {
                    withAnimation {
                        showControls.toggle()
                    }
                }
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                if let loadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = loadedImage
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Could not decode image"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
            lastScale = 1.0
        }
        HapticsManager.shared.impact()
    }
    
    private func shareImage() {
        guard let image = image else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        
        HapticsManager.shared.impact()
    }
}

// MARK: - Preview
struct ImageViewerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(fileURL: URL(fileURLWithPath: "/tmp/test.png"))
    }
}
