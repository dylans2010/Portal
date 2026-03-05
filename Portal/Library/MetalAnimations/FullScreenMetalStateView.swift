import SwiftUI
import MetalKit

enum MetalAnimationState: Int, CaseIterable {
    case idle = 0
    case loading = 1
    case success = 2
    case error = 3
}

struct FullScreenMetalStateView: View {
    @Binding var state: MetalAnimationState
    var appName: String?
    var errorMessage: String?
    var onDismissError: (() -> Void)?

    var body: some View {
        ZStack {
            if state != .idle {
                MetalRepresentable(state: $state)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(0)

                if state == .loading || state == .success {
                    loadingOverlay
                        .zIndex(1)
                }

                if state == .error {
                    errorOverlay
                        .zIndex(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
        .allowsHitTesting(state != .idle)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)

            if let appName = appName {
                Text("Please wait while \(appName) gets signed...")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer().frame(height: 100)
        }
    }

    private var errorOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .pulseEffect(true)

            Text("Error")
                .font(.title.bold())
                .foregroundStyle(.white)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                onDismissError?()
                state = .idle
            } label: {
                Text("Dismiss")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
    }
}

struct MetalRepresentable: UIViewRepresentable {
    @Binding var state: MetalAnimationState

    func makeCoordinator() -> MetalStateRenderer {
        let renderer = MetalStateRenderer()
        renderer.onAnimationComplete = {
            DispatchQueue.main.async {
                self.state = .idle
            }
        }
        return renderer
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = context.coordinator.device
        mtkView.delegate = context.coordinator
        mtkView.backgroundColor = .clear
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        mtkView.isUserInteractionEnabled = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateState(state)
    }
}
