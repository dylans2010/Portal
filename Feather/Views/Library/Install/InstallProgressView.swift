import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    @State private var isPulsing = false
    @State private var dominantColor: Color = .accentColor
    @State private var rotationAngle: Double = 0
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            progressIndicator
            statusLabel
        }
        .onAppear {
            isPulsing = true
            extractDominantColor()
            startRotation()
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        ZStack {
            // Subtle glow
            Circle()
                .fill(dominantColor.opacity(0.15))
                .frame(width: 90, height: 90)
                .blur(radius: 12)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            
            // Progress track
            Circle()
                .stroke(dominantColor.opacity(0.12), lineWidth: 4)
                .frame(width: 68, height: 68)
            
            // Progress fill
            Circle()
                .trim(from: 0, to: viewModel.overallProgress)
                .stroke(dominantColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.overallProgress)
            
            // Rotating indicator (when not complete)
            if !viewModel.isCompleted {
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(dominantColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(rotationAngle))
            }
            
            // App icon
            FRAppIconView(app: app)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: dominantColor.opacity(0.3), radius: 6, x: 0, y: 3)
            
            // Success badge
            if viewModel.isCompleted {
                Circle()
                    .fill(.green)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 24, y: 24)
                    .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Status Label
    private var statusLabel: some View {
        Group {
            if viewModel.isCompleted {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(dominantColor)
                    
                    Text("\(viewModel.currentStep)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCompleted)
    }
    
    // MARK: - Helpers
    private func startRotation() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
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
                dominantColor = Color(red: Double(pixel[0])/255, green: Double(pixel[1])/255, blue: Double(pixel[2])/255)
            }
        }
    }
}
