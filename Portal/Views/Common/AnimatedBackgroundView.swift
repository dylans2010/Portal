import SwiftUI

struct AnimatedBackgroundView: View {
    @ObservedObject private var motion = MotionManager.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                // Background is now handled by GlobalThemeModifier's resolvedColor

                // Animated orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(
                        x: CGFloat(motion.roll * 50) - 100,
                        y: CGFloat(motion.pitch * 50) - 100
                    )
                    .blur(radius: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: CGFloat(-motion.roll * 40) + 100,
                        y: CGFloat(-motion.pitch * 40) + 100
                    )
                    .blur(radius: 40)
            }
            .onAppear {
                motion.start()
            }
            .onDisappear {
                motion.stop()
            }
        }
        .ignoresSafeArea()
    }
}
