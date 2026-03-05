
import SwiftUI
import NukeUI

struct ScreenshotPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex: Int
    
    let screenshotURLs: [URL]
    
    init(
        screenshotURLs: [URL],
        initialIndex: Int = 0
    ) {
        self.screenshotURLs = screenshotURLs
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                _headerView()
                
                _imageScrollView()
            }
        }
    }
}

extension ScreenshotPreviewView {
    @ViewBuilder
    private func _headerView() -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            
            Spacer()
            
            Text(verbatim: "\(currentIndex + 1) / \(screenshotURLs.count)")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private func _imageScrollView() -> some View {
        TabView(selection: $currentIndex) {
            ForEach(screenshotURLs.indices, id: \.self) { index in
                LazyImage(url: screenshotURLs[index]) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    } else {
                        ProgressView()
                    }
                }
                .tag(index)
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}
