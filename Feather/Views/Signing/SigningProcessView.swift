import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct SigningProcessView: View {
    @Environment(\.dismiss) var dismiss
    @State private var progress: Double = 0.0
    @State private var currentStep: String = "Initializing Signing Engine..."
    @State private var currentStepIndex: Int = 0
    @State private var isFinished = false
    @State private var dominantColor: Color = .accentColor
    @State private var secondaryColor: Color = .accentColor
    
    // Animation states
    @State private var floatingAnimation = false
    @State private var pulseAnimation = false
    @State private var rotationAnimation = false
    @State private var glowAnimation = false
    @State private var particleAnimation = false
    @State private var completedSteps: Set<Int> = []
    
    var appName: String
    var appIcon: UIImage?
    
    private let signingSteps = [
        ("Extracting IPA", "archivebox.fill"),
        ("Verifying Entitlements", "checkmark.shield.fill"),
        ("Patching Binary", "hammer.fill"),
        ("Signing Frameworks", "cube.fill"),
        ("Signing Application", "signature"),
        ("Packaging", "shippingbox.fill"),
        ("Finalizing", "checkmark.seal.fill")
    ]
    
    var body: some View {
        ZStack {
            // Modern animated mesh gradient background
            modernBackground
            
            // Floating particles
            floatingParticles
            
            VStack(spacing: 0) {
                // Header with app info
                headerSection
                    .padding(.top, 40)
                
                Spacer()
                
                // Main progress section
                progressSection
                
                Spacer()
                
                // Steps list
                stepsListSection
                    .padding(.bottom, 20)
                
                // Action button
                if isFinished {
                    completionButton
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                            removal: .opacity
                        ))
                }
            }
        }
        .onAppear {
            extractColorsFromIcon()
            startAnimations()
            startSigningSimulation()
        }
    }
    
    // MARK: - Modern Background
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.25),
                    dominantColor.opacity(0.1),
                    secondaryColor.opacity(0.08),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated orbs
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [dominantColor.opacity(0.4), dominantColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: floatingAnimation ? -40 : 40, y: floatingAnimation ? -30 : 30)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.15)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [secondaryColor.opacity(0.3), secondaryColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? 30 : -30, y: floatingAnimation ? 20 : -20)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Floating Particles
    @ViewBuilder
    private var floatingParticles: some View {
        GeometryReader { geo in
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(dominantColor.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: particleAnimation ? CGFloat.random(in: 0...geo.size.height * 0.3) : CGFloat.random(in: geo.size.height * 0.7...geo.size.height)
                    )
                    .blur(radius: 1)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon with glass effect
            ZStack {
                // Glow effect
                Circle()
                    .fill(dominantColor.opacity(glowAnimation ? 0.5 : 0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 25)
                    .scaleEffect(glowAnimation ? 1.2 : 1.0)
                
                if let icon = appIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: dominantColor.opacity(0.5), radius: 20, x: 0, y: 10)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [dominantColor, dominantColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isFinished ? "checkmark.seal.fill" : "signature")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: isFinished)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: dominantColor.opacity(0.5), radius: 20, x: 0, y: 10)
                }
            }
            
            VStack(spacing: 6) {
                Text(isFinished ? "Signing Complete!" : "Signing \(appName)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(isFinished ? "Your app is ready to install" : "Please wait...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Progress Section
    @ViewBuilder
    private var progressSection: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(dominantColor.opacity(pulseAnimation ? 0.3 : 0.1), lineWidth: 3)
                .frame(width: 220, height: 220)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
            
            // Background track
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [dominantColor.opacity(0.15), secondaryColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 14
                )
                .frame(width: 180, height: 180)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [dominantColor, secondaryColor, dominantColor.opacity(0.8), dominantColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .shadow(color: dominantColor.opacity(0.6), radius: 10, x: 0, y: 5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Rotating indicator
            if !isFinished {
                Circle()
                    .fill(dominantColor)
                    .frame(width: 16, height: 16)
                    .shadow(color: dominantColor, radius: 8)
                    .offset(y: -90)
                    .rotationEffect(.degrees(rotationAnimation ? 360 : 0))
            }
            
            // Center content
            VStack(spacing: 8) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [dominantColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                Text("%")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .offset(y: -8)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Steps List Section
    @ViewBuilder
    private var stepsListSection: some View {
        VStack(spacing: 8) {
            ForEach(Array(signingSteps.enumerated()), id: \.offset) { index, step in
                stepRowView(index: index, step: step)
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func stepRowView(index: Int, step: (String, String)) -> some View {
        HStack(spacing: 12) {
            stepIndicator(index: index, iconName: step.1)
            stepLabel(index: index, title: step.0)
            Spacer()
            stepStatusIndicator(index: index)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(stepRowBackground(index: index))
    }
    
    @ViewBuilder
    private func stepIndicator(index: Int, iconName: String) -> some View {
        ZStack {
            Circle()
                .fill(stepIndicatorGradient(index: index))
                .frame(width: 28, height: 28)
            
            stepIndicatorContent(index: index, iconName: iconName)
        }
    }
    
    private func stepIndicatorGradient(index: Int) -> LinearGradient {
        if completedSteps.contains(index) {
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if currentStepIndex == index {
            return LinearGradient(colors: [dominantColor, dominantColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color(UIColor.tertiarySystemFill), Color(UIColor.tertiarySystemFill)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    @ViewBuilder
    private func stepIndicatorContent(index: Int, iconName: String) -> some View {
        if completedSteps.contains(index) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        } else if currentStepIndex == index {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating, value: currentStepIndex)
        } else {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func stepLabel(index: Int, title: String) -> some View {
        let isActive = completedSteps.contains(index) || currentStepIndex == index
        Text(title)
            .font(.subheadline.weight(currentStepIndex == index ? .semibold : .regular))
            .foregroundStyle(isActive ? .primary : .secondary)
    }
    
    @ViewBuilder
    private func stepStatusIndicator(index: Int) -> some View {
        if completedSteps.contains(index) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green)
        } else if currentStepIndex == index {
            ProgressView()
                .scaleEffect(0.7)
        }
    }
    
    @ViewBuilder
    private func stepRowBackground(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(currentStepIndex == index ? .ultraThinMaterial : .clear)
    }
    
    // MARK: - Completion Button
    @ViewBuilder
    private var completionButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                // Glow
                Capsule()
                    .fill(dominantColor.opacity(0.4))
                    .blur(radius: 20)
                    .scaleEffect(glowAnimation ? 1.1 : 1.0)
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .symbolEffect(.bounce, value: isFinished)
                    Text("Done")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [dominantColor, secondaryColor, dominantColor.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Shine effect
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0), .white.opacity(0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: dominantColor.opacity(0.5), radius: 15, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatingAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotationAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            particleAnimation = true
        }
    }
    
    // Extract dominant colors from app icon
    func extractColorsFromIcon() {
        guard let icon = appIcon, let cgImage = icon.cgImage else {
            dominantColor = .accentColor
            secondaryColor = .accentColor.opacity(0.7)
            return
        }
        
        Task {
            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIAreaAverage")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
            
            guard let outputImage = filter?.outputImage else { return }
            
            var pixel = [UInt8](repeating: 0, count: 4)
            CIContext().render(
                outputImage,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: nil
            )
            
            let r = Double(pixel[0]) / 255.0
            let g = Double(pixel[1]) / 255.0
            let b = Double(pixel[2]) / 255.0
            
            await MainActor.run {
                dominantColor = Color(red: r, green: g, blue: b)
                secondaryColor = Color(
                    red: min(r + 0.15, 1.0),
                    green: min(g + 0.15, 1.0),
                    blue: min(b + 0.15, 1.0)
                )
            }
        }
    }
    
    func startSigningSimulation() {
        Task {
            for (index, _) in signingSteps.enumerated() {
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStepIndex = index
                        currentStep = signingSteps[index].0
                    }
                }
                
                try? await Task.sleep(nanoseconds: 700_000_000)
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        completedSteps.insert(index)
                        progress = Double(index + 1) / Double(signingSteps.count)
                    }
                }
            }
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isFinished = true
                }
            }
        }
    }
}
