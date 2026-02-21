import SwiftUI

struct HoldToSign: View {
    var onComplete: () -> Void

    @State private var isHolding = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(isHolding ? 1.2 : 1.0)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding {
                            startHolding()
                        }
                    }
                    .onEnded { _ in
                        stopHolding()
                    }
            )

            Text("Hold to Sign")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
    }

    private func startHolding() {
        isHolding = true
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                progress += 0.025 // Takes 2 seconds to fill
            }

            if progress >= 1.0 {
                stopHolding()
                HapticsManager.shared.success()
                onComplete()
                // Reset progress after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    progress = 0
                }
            }
        }
    }

    private func stopHolding() {
        isHolding = false
        timer?.invalidate()
        timer = nil
        if progress < 1.0 {
            withAnimation {
                progress = 0
            }
        }
    }
}
