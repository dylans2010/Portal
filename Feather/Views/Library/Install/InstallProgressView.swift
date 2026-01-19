import SwiftUI
import IDeviceSwift

// MARK: - Modern Install Progress View
struct InstallProgressView: View {
    @State private var isPulsing = false
    @State private var dominantColor: Color = .accentColor
    @State private var rotationAngle: Double = 0
    @State private var glowAnimation = false
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 14) {
            progressIndicator
            statusInfo
        }
        .onAppear {
            isPulsing = true
            extractDominantColor()
            startRotation()
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            dominantColor.opacity(glowAnimation ? 0.2 : 0.1),
                            dominantColor.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            
            // Background track
            Circle()
                .stroke(dominantColor.opacity(0.1), lineWidth: 5)
                .frame(width: 72, height: 72)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: viewModel.overallProgress)
                .stroke(
                    LinearGradient(
                        colors: [dominantColor, dominantColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.overallProgress)
            
            // Spinning indicator (when not complete)
            if !viewModel.isCompleted {
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        dominantColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(rotationAngle))
            }
            
            // App icon with glass effect
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                
                FRAppIconView(app: app)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .shadow(color: dominantColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Success badge
            if viewModel.isCompleted {
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 26, y: 26)
                .shadow(color: .green.opacity(0.5), radius: 6, x: 0, y: 3)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isCompleted)
    }
    
    // MARK: - Status Info
    private var statusInfo: some View {
        Group {
            if viewModel.isCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Complete")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.green)
            } else {
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(dominantColor)
                    
                    Text(viewModel.currentStep)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isCompleted)
    }
    
    // MARK: - Helpers
    private func startRotation() {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func extractDominantColor() {
        Task {
            guard let iconURL = app.iconURL,
                  let data = try? Data(contentsOf: iconURL),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else { return }
            
            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIAreaAverage")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
            
            guard let outputImage = filter?.outputImage else { return }
            
            var pixel = [UInt8](repeating: 0, count: 4)
            CIContext().render(outputImage, toBitmap: &pixel, rowBytes: 4,
                               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                               format: .RGBA8, colorSpace: nil)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    dominantColor = Color(red: Double(pixel[0])/255, green: Double(pixel[1])/255, blue: Double(pixel[2])/255)
                }
            }
        }
    }
}
