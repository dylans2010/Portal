
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
            VStack {
                _headerView()
                
                Spacer()
                
                _imageScrollView()
            }
        }
        .background(Color.clear)
    }
}

extension ScreenshotPreviewView {
    @ViewBuilder
    private func _headerView() -> some View {
        HStack {
            Button(.localized("Close"), role: .cancel) { dismiss() }
            
            Spacer()
            
            Text(verbatim: "\(currentIndex + 1) / \(screenshotURLs.count)")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.clear)
                )
        }
        .padding(.horizontal, 20)
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
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .strokeBorder(.gray.opacity(0.3), lineWidth: 1)
                            }
                    }
                }
                .tag(index)
                .padding(.horizontal)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
