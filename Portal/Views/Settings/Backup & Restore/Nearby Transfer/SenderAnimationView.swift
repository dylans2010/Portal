import SwiftUI

// MARK: - Sender Animation View
struct SenderAnimationView: View {
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

            // Dynamic particle background
            if isAnimating {
                GeometryReader { geo in
                    ForEach(0..<15, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: CGFloat.random(in: 10...30))
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                            .offset(y: waveOffset * (1 + CGFloat(i) * 0.1))
                    }
                }
                .ignoresSafeArea()
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
            sendingAnimation
        case .transferring(let progress, _, _, _):
            transferringAnimation(progress: progress)
        case .completed:
            completedAnimation
        case .failed:
            failedAnimation
        }
    }
    
    // MARK: - Sending Animation (Discovery/Connecting)
    
    private var sendingAnimation: some View {
        ZStack {
            // Sophisticated outer layers
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseAnimation ? 1.6 : 0.9)
                    .opacity(pulseAnimation ? 0 : 0.7)
                    .animation(
                        Animation
                            .easeOut(duration: 2.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.6),
                        value: pulseAnimation
                    )
            }
            
            // Core with glow and icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(scaleAmount)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                if #available(iOS 17.0, *) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .pulseEffect()
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? -8 : 8)
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
            // Background shadow ring
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 16)
                .frame(width: 210, height: 210)

            // Background track
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 16)
                .frame(width: 210, height: 210)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.white, .white.opacity(0.6), .white],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .shadow(color: .white.opacity(0.3), radius: 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Inner content card
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .offset(y: isAnimating ? -6 : 6)
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
                    .contentTransition(.numericText())
            }
        }
    }
    
    // MARK: - Completed Animation
    
    private var completedAnimation: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 10)
                .frame(width: 210, height: 210)
            
            Circle()
                .trim(from: 0, to: 1)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(scaleAmount)
            }
            
            // Particle explosion
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .offset(particleOffset(for: i, active: isAnimating))
                    .opacity(isAnimating ? 0 : 1)
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
                    .offset(x: isAnimating ? -8 : 8)
            }
        }
    }
    
    // MARK: - Progress Details
    
    @ViewBuilder
    private var progressDetails: some View {
        if case .transferring(_, let bytesTransferred, let totalBytes, let speed) = state {
            VStack(spacing: 16) {
                HStack {
                    progressInfoItem(icon: "doc.fill", label: "Uploaded", value: formatBytes(bytesTransferred))
                    Spacer()
                    progressInfoItem(icon: "speedometer", label: "Speed", value: formatSpeed(speed))
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))

                HStack {
                    progressInfoItem(icon: "archivebox.fill", label: "Total Size", value: formatBytes(totalBytes))
                    Spacer()
                    if totalBytes > 0 && speed > 0 {
                        let remaining = Double(totalBytes - bytesTransferred) / speed
                        progressInfoItem(icon: "clock.fill", label: "ETA", value: formatTime(remaining))
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
    
    // MARK: - Helpers & Animations
    
    private var backgroundColors: [Color] {
        switch state {
        case .idle, .discovering, .connecting, .transferring:
            return [Color(hex: "4F46E5"), Color(hex: "7C3AED"), Color(hex: "DB2777")]
        case .completed:
            return [Color(hex: "059669"), Color(hex: "10B981"), Color(hex: "34D399")]
        case .failed:
            return [Color(hex: "DC2626"), Color(hex: "EF4444"), Color(hex: "F87171")]
        }
    }
    
    private var statusTitle: String {
        switch state {
        case .idle: return "Ready to Go"
        case .discovering: return "Searching..."
        case .connecting: return "Handshaking"
        case .transferring: return "Sending Data"
        case .completed: return "All Done!"
        case .failed: return "Failed"
        }
    }
    
    private var statusSubtitle: String {
        switch state {
        case .idle: return "Establish connection to begin"
        case .discovering: return "Looking for nearby receivers"
        case .connecting: return "Establishing secure channel"
        case .transferring: return "Transmitting encrypted backup"
        case .completed: return "Backup transferred successfully"
        case .failed(let error): return error.localizedDescription
        }
    }
    
    private func startAnimations() {
        withAnimation {
            isAnimating = true
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            scaleAmount = 1.15
        }

        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            waveOffset = -100
        }
        
        if case .completed = state {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scaleAmount = 1.3
            }
        }
        
        if case .failed = state {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func particleOffset(for index: Int, active: Bool) -> CGSize {
        let angle = Double(index) * (360.0 / 20.0) * .pi / 180.0
        let distance: CGFloat = active ? 160 : 0
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
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(secs)s"
    }
}

