import SwiftUI
import NimbleViews

struct CustomAnimationView: View {
    // Reusability Parameters
    var iconName: String = "bell.badge.fill"
    var title: String = "Enable Notifications"
    var subtitle: String = "Get notified when your apps are ready to be installed or when updates are available."
    var primaryButtonText: String? = "Allow Access"
    var primaryAction: (() -> Void)? = nil
    var secondaryButtonText: String? = "Maybe Later"
    var secondaryAction: (() -> Void)? = nil

    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @ObservedObject private var motion = MotionManager.shared
    @Environment(\.dismiss) private var dismiss

    // Stable particle data to prevent flickering
    struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGFloat
        let targetOffset: CGSize
        let delay: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            // 1. Modern Background with Glass Effect
            AnimatedBackgroundView()
                .blur(radius: 40)

            // Background variable blur for depth
            NBVariableBlurView()
                .ignoresSafeArea()
                .opacity(0.8)

            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .padding()
                }

                Spacer()

                // 2. Sophisticated Central Animation Area
                ZStack {
                    // Background Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentColor.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.6 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                    // Rotating Decorative Rings with modern gradient
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.accentColor.opacity(0.6), .purple.opacity(0.3), .blue.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(180 + (i * 40)), height: CGFloat(180 + (i * 40)))
                            .rotationEffect(.degrees(rotationAngle * Double(i + 1) * 0.5))
                    }

                    // Floating Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(
                                x: isAnimating ? particle.targetOffset.width : 0,
                                y: isAnimating ? particle.targetOffset.height : 0
                            )
                            .opacity(isAnimating ? 0.7 : 0)
                            .scaleEffect(isAnimating ? 1 : 0.1)
                            .animation(
                                .spring(response: 2.5, dampingFraction: 0.8)
                                .delay(particle.delay)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }

                    // Main SF Symbol with Glass Card
                    ZStack {
                        // Glass Card with Border
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 150, height: 150)
                            .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 36, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )

                        // Animated SF Symbol
                        Image(systemName: iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 75, height: 75)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.accentColor, .accentColor.opacity(0.7), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                            .applySymbolEffect()
                    }
                    .offset(x: CGFloat(motion.roll * 20), y: CGFloat(motion.pitch * 20))
                    .scaleEffect(isAnimating ? 1.0 : 0.4)
                    .rotationEffect(.degrees(isAnimating ? 0 : -15))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.9, dampingFraction: 0.65).delay(0.2), value: isAnimating)
                }
                .padding(.bottom, 60)

                // 3. Stylized Content Staggered
                VStack(spacing: 18) {
                    Text(title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(y: isAnimating ? 0 : 25)
                        .animation(.spring(response: 0.7).delay(0.4), value: isAnimating)

                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(y: isAnimating ? 0 : 25)
                        .animation(.spring(response: 0.7).delay(0.55), value: isAnimating)
                }

                Spacer()

                // 4. Modern Buttons
                VStack(spacing: 16) {
                    if let primaryText = primaryButtonText {
                        Button(action: {
                            HapticsManager.shared.softImpact()
                            primaryAction?()
                            dismiss()
                        }) {
                            Text(primaryText)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )

                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.25), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    .shadow(color: Color.accentColor.opacity(0.4), radius: 15, x: 0, y: 10)
                                )
                        }
                        .padding(.horizontal, 32)
                        .scaleEffect(isAnimating ? 1.0 : 0.85)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.75), value: isAnimating)
                    }

                    if let secondaryText = secondaryButtonText {
                        Button(action: {
                            HapticsManager.shared.softImpact()
                            secondaryAction?()
                            dismiss()
                        }) {
                            Text(secondaryText)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7).delay(0.9), value: isAnimating)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupParticles()
            isAnimating = true
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            motion.start()
        }
        .onDisappear {
            motion.stop()
        }
    }

    private func setupParticles() {
        var newParticles: [Particle] = []
        let colors: [Color] = [.accentColor, .purple, .blue, .cyan]

        for i in 0..<15 {
            let particle = Particle(
                color: colors[i % colors.count],
                size: CGFloat.random(in: 3...7),
                targetOffset: CGSize(
                    width: CGFloat.random(in: -150...150),
                    height: CGFloat.random(in: -150...150)
                ),
                delay: Double.random(in: 0...0.8)
            )
            newParticles.append(particle)
        }
        particles = newParticles
    }
}

// Helper to handle iOS 17 symbol effects
extension View {
    @ViewBuilder
    func applySymbolEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, options: .repeating)
        } else if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce)
        } else {
            self
        }
    }
}

#Preview {
    CustomAnimationView(
        iconName: "wand.and.stars",
        title: "Modern UI Experience",
        subtitle: "Enjoy a completely redesigned interface with fluid animations, glassmorphism, and depth effects.",
        primaryButtonText: "Explore Now",
        secondaryButtonText: "Later"
    )
}
