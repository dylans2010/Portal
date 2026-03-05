import SwiftUI
import MetalKit

struct MetalLoadingIndicator: View {
    @State private var state: MetalAnimationState = .loading
    var size: CGFloat = 24

    var body: some View {
        MetalRepresentable(state: $state)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .onAppear {
                state = .loading
            }
    }
}
