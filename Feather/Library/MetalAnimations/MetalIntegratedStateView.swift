import SwiftUI

struct MetalIntegratedStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var state: MetalAnimationState

    var body: some View {
        ZStack {
            if state != .idle {
                MetalRepresentable(state: $state)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}
