import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct SigningProcessView: View {
    @Environment(\.dismiss) var dismiss
    @State private var progress: Double = 0.0
    @State private var currentStep: String = "Initializing Signing Engine..."
    @State private var isFinished = false
    @State private var dominantColor: Color = .accentColor
    @State private var secondaryColor: Color = .accentColor
    
    var appName: String
    var appIcon: UIImage?
    
    var body: some View {
        ZStack {
            // Dynamic gradient background based on app icon
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.3),
                    dominantColor.opacity(0.15),
                    secondaryColor.opacity(0.1),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header with app name
                VStack(spacing: 12) {
                    Text(isFinished ? "Signing Complete!" : "Signing \(appName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    // App Icon
                    if let icon = appIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: dominantColor.opacity(0.5), radius: 15, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [dominantColor.opacity(0.6), dominantColor.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [dominantColor, dominantColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: isFinished ? "checkmark.seal.fill" : "signature")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: progress)
                        }
                        .shadow(color: dominantColor.opacity(0.5), radius: 15, x: 0, y: 8)
                    }
                }
                .padding(.top, 60)
                
                // Circular Progress with percentage in middle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    dominantColor.opacity(0.2),
                                    secondaryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 12
                        )
                        .frame(width: 180, height: 180)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    dominantColor,
                                    secondaryColor,
                                    dominantColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: dominantColor.opacity(0.5), radius: 8, x: 0, y: 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    
                    // Percentage text in center
                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [dominantColor, secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .monospacedDigit()
                        
                        Text(currentStep)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: 140)
                    }
                    
                    // Animated glow effect when not finished
                    if !isFinished {
                        Circle()
                            .stroke(dominantColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 195, height: 195)
                            .scaleEffect(isFinished ? 1.0 : 1.1)
                            .opacity(isFinished ? 0 : 0.6)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isFinished)
                    }
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                if isFinished {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                // Shadow layer
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [dominantColor.opacity(0.3), secondaryColor.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .blur(radius: 4)
                                    .offset(y: 3)
                                
                                // Main gradient
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                dominantColor,
                                                secondaryColor,
                                                dominantColor.opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        )
                        .clipShape(Capsule())
                        .shadow(color: dominantColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            extractColorsFromIcon()
            startSigningSimulation()
        }
    }
    
    // Extract dominant colors from app icon
    func extractColorsFromIcon() {
        guard let icon = appIcon, let cgImage = icon.cgImage else {
            // Use accent color as fallback
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
                // Create a slightly different secondary color
                secondaryColor = Color(
                    red: min(r + 0.1, 1.0),
                    green: min(g + 0.1, 1.0),
                    blue: min(b + 0.1, 1.0)
                )
            }
        }
    }
    
    func startSigningSimulation() {
        // logs (fake logging, UI looks only)
        let steps = [
            "Extracting IPA...",
            "Verifying Entitlements...",
            "Patching Binary...",
            "Signing Frameworks...",
            "Signing Application...",
            "Packaging...",
            "Done!"
        ]
        
        Task {
            for (index, step) in steps.enumerated() {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s delay
                await MainActor.run {
                    currentStep = step
                    withAnimation {
                        progress = Double(index + 1) / Double(steps.count)
                    }
                }
            }
            await MainActor.run {
                isFinished = true
            }
        }
    }
}
