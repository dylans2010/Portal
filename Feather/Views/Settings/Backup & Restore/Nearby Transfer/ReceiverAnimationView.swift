import SwiftUI

// MARK: - Receiver Animation View
struct ReceiverAnimationView: View {
    let state: TransferState
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var scaleAmount: CGFloat = 1.0
    @State private var wavePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main animation content
                mainAnimationContent
                
                // Status text
                statusText
                
                // Progress details
                progressDetails
                
                Spacer()
            }
            .padding(.horizontal, 40)
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
            // Animated wave rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseAnimation ? 1.6 : 0.8)
                    .opacity(pulseAnimation ? 0 : 1)
                    .animation(
                        Animation
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: pulseAnimation
                    )
            }
            
            // Center receiving icon with glow
            ZStack {
                // Pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(scaleAmount)
                
                // Icon background with subtle rotation
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                // Receiving icon
                if #available(iOS 17.0, *) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, options: .repeating)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? 5 : -5)
                        .animation(
                            Animation
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
        }
        .frame(width: 240, height: 240)
    }
    
    // MARK: - Transferring Animation
    
    private func transferringAnimation(progress: Double) -> some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 12)
                .frame(width: 200, height: 200)
            
            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
            
            // Inner content
            VStack(spacing: 12) {
                // Download icon with animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? 5 : 0)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Percentage
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Completed Animation
    
    private var completedAnimation: some View {
        ZStack {
            // Success ring with glow
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
            
            // Checkmark with bounce
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(scaleAmount)
            }
            
            // Success particles
            if #available(iOS 17.0, *) {
                ForEach(0..<12, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 6, height: 12)
                        .offset(particleOffset(for: index))
                        .rotationEffect(.degrees(Double(index) * 30))
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            Animation
                                .easeOut(duration: 1.2)
                                .delay(0.3),
                            value: isAnimating
                        )
                }
            }
        }
    }
    
    // MARK: - Failed Animation
    
    private var failedAnimation: some View {
        ZStack {
            // Error ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            // X mark with shake effect
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "xmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isAnimating ? -10 : 10))
            }
        }
    }
    
    // MARK: - Status Text
    
    @ViewBuilder
    private var statusText: some View {
        VStack(spacing: 8) {
            Text(statusTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text(statusSubtitle)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Progress Details
    
    @ViewBuilder
    private var progressDetails: some View {
        if case .transferring(_, let bytesTransferred, let totalBytes, let speed) = state {
            VStack(spacing: 12) {
                HStack {
                    Text("Received:")
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(formatBytes(bytesTransferred) + " / " + formatBytes(totalBytes))
                        .foregroundStyle(.white)
                }
                
                HStack {
                    Text("Speed:")
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(formatSpeed(speed))
                        .foregroundStyle(.white)
                }
                
                if totalBytes > 0 && speed > 0 {
                    let remaining = Double(totalBytes - bytesTransferred) / speed
                    HStack {
                        Text("Time Remaining:")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(formatTime(remaining))
                            .foregroundStyle(.white)
                    }
                }
            }
            .font(.system(size: 14, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColors: [Color] {
        switch state {
        case .idle, .discovering, .connecting, .transferring:
            return [Color.cyan.opacity(0.8), Color.indigo.opacity(0.8)]
        case .completed:
            return [Color.green.opacity(0.8), Color.mint.opacity(0.8)]
        case .failed:
            return [Color.red.opacity(0.8), Color.pink.opacity(0.8)]
        }
    }
    
    private var statusTitle: String {
        switch state {
        case .idle:
            return "Ready to Receive"
        case .discovering:
            return "Waiting for Sender..."
        case .connecting:
            return "Connecting..."
        case .transferring:
            return "Receiving Backup"
        case .completed:
            return "Received Successfully!"
        case .failed:
            return "Receive Failed"
        }
    }
    
    private var statusSubtitle: String {
        switch state {
        case .idle:
            return "Waiting to start transfer"
        case .discovering:
            return "Listening for sender devices"
        case .connecting:
            return "Establishing secure connection"
        case .transferring:
            return "Downloading your backup data"
        case .completed:
            return "Your backup has been received"
        case .failed(let error):
            return error.localizedDescription
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation {
            isAnimating = true
            pulseAnimation = true
        }
        
        // Scale animation for glow
        withAnimation(
            Animation
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
        ) {
            scaleAmount = 1.3
        }
        
        // Wave animation
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                wavePhase += 0.1
            }
        }
        
        // Completed state celebration
        if case .completed = state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scaleAmount = 1.3
                }
            }
        }
        
        // Failed state shake
        if case .failed = state {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.12)
                    .repeatCount(5, autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func particleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * 30.0 * .pi / 180.0
        let distance: CGFloat = isAnimating ? 140 : 0
        return CGSize(
            width: distance * Foundation.cos(angle),
            height: distance * Foundation.sin(angle)
        )
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
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(secs)s"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Preview
#Preview {
    ReceiverAnimationView(state: .transferring(progress: 0.45, bytesTransferred: 450000000, totalBytes: 1000000000, speed: 4194304))
}
