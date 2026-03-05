import SwiftUI

// MARK: - Receiver Animation View
struct ReceiverAnimationView: View {
    let state: TransferState
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var scaleAmount: CGFloat = 1.0
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background dynamic gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: state)

            // Floating background blobs
            if isAnimating {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 300)
                        .offset(x: -100, y: -200 + waveOffset)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 250)
                        .offset(x: 150, y: 100 - waveOffset)
                }
                .blur(radius: 60)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main animation content
                mainAnimationContent
                    .transition(.scale.combined(with: .opacity))
                
                // Status Information
                VStack(spacing: 12) {
                    Text(statusTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 10)

                    Text(statusSubtitle)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Progress details
                progressDetails
                    .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Main Animation Content
    
    @ViewBuilder
    private var mainAnimationContent: some View {
        switch state {
        case .idle, .discovering, .connecting:
            receivingAnimation
        case .transferring(let progress, _, _, _):
            transferringAnimation(progress: progress)
        case .completed:
            completedAnimation
        case .failed:
            failedAnimation
        }
    }
    
    // MARK: - Receiving Animation (Discovery/Connecting)
    
    private var receivingAnimation: some View {
        ZStack {
            // Pulse waves
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 3
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.8 : 0.8)
                    .opacity(pulseAnimation ? 0 : 0.8)
                    .animation(
                        Animation
                            .easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.7),
                        value: pulseAnimation
                    )
            }
            
            // Core component
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(scaleAmount)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                if #available(iOS 17.0, *) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .bounceEffect()
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? 8 : -8)
                        .animation(
                            Animation
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
        }
        .frame(width: 260, height: 260)
    }
    
    // MARK: - Transferring Animation
    
    private func transferringAnimation(progress: Double) -> some View {
        ZStack {
            // Outer track
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 16)
                .frame(width: 210, height: 210)
            
            // Glowing progress bar
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.white, .cyan, .white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .shadow(color: .cyan.opacity(0.4), radius: 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? 6 : -6)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Completed Animation
    
    private var completedAnimation: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 10)
                .frame(width: 210, height: 210)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(scaleAmount)
            }
            
            // Confetti fall
            ForEach(0..<15, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 12)
                    .offset(x: CGFloat.random(in: -150...150), y: isAnimating ? 400 : -400)
                    .rotationEffect(.degrees(Double(i) * 24))
                    .animation(.easeOut(duration: 2).delay(Double(i) * 0.1), value: isAnimating)
            }
        }
    }
    
    // MARK: - Failed Animation
    
    private var failedAnimation: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 10)
                .frame(width: 210, height: 210)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                
                Image(systemName: "xmark")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isAnimating ? -10 : 10))
            }
        }
    }
    
    // MARK: - Progress Details
    
    @ViewBuilder
    private var progressDetails: some View {
        if case .transferring(_, let bytesTransferred, let totalBytes, let speed) = state {
            VStack(spacing: 16) {
                HStack {
                    progressInfoItem(icon: "arrow.down.to.line.compact", label: "Received", value: formatBytes(bytesTransferred))
                    Spacer()
                    progressInfoItem(icon: "speedometer", label: "Speed", value: formatSpeed(speed))
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))

                HStack {
                    progressInfoItem(icon: "doc.zipper", label: "Total Data", value: formatBytes(totalBytes))
                    Spacer()
                    if totalBytes > 0 && speed > 0 {
                        let remaining = Double(totalBytes - bytesTransferred) / speed
                        progressInfoItem(icon: "clock.fill", label: "Remaining", value: formatTime(remaining))
                    }
                }
            }
            .padding(20)
            .background(Color.clear)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func progressInfoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColors: [Color] {
        switch state {
        case .idle, .discovering, .connecting, .transferring:
            return [Color(hex: "0891B2"), Color(hex: "4F46E5"), Color(hex: "7C3AED")]
        case .completed:
            return [Color(hex: "059669"), Color(hex: "10B981"), Color(hex: "34D399")]
        case .failed:
            return [Color(hex: "DC2626"), Color(hex: "EF4444"), Color(hex: "F87171")]
        }
    }
    
    private var statusTitle: String {
        switch state {
        case .idle: return "Ready"
        case .discovering: return "Discoverable"
        case .connecting: return "Connecting"
        case .transferring: return "Downloading"
        case .completed: return "Success!"
        case .failed: return "Error"
        }
    }
    
    private var statusSubtitle: String {
        switch state {
        case .idle: return "Waiting for sender device"
        case .discovering: return "Visible to nearby devices"
        case .connecting: return "Establishing secure link"
        case .transferring: return "Receiving backup files"
        case .completed: return "Restoration ready to begin"
        case .failed(let error): return error.localizedDescription
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation {
            isAnimating = true
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            scaleAmount = 1.2
        }
        
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            waveOffset = 50
        }
        
        if case .completed = state {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scaleAmount = 1.3
            }
        }
        
        if case .failed = state {
            withAnimation(.easeInOut(duration: 0.12).repeatCount(6, autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(secs)s"
    }
}
