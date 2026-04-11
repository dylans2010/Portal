import SwiftUI
import MultipeerConnectivity
import NimbleViews

struct SenderView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    // MARK: - Dependencies

    @ObservedObject var service: PairingMPCService
    let onCancel: () -> Void

    // MARK: - Transfer Cover State

    @State private var showLoadingCover = false
    @State private var showSuccessCover = false
    @State private var successReceivedURL: URL?

    // MARK: - Animation State

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var foundPeerVisible = false
    @State private var foundPeerScale: CGFloat = 0.5
    @State private var errorShakeOffset: CGFloat = 0
    @State private var sparkleAngles: [Double] = (0..<8).map { Double($0) * 45.0 }
    @State private var sparklesVisible = false
    @State private var sparkleRadius: CGFloat = 0
    @State private var connectedBadgeScale: CGFloat = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 20)
                        advertisingIcon
                        statusSection
                        errorSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle(.localized("Sending Data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive) {
                        service.cancel()
                        onCancel()
                    } label: {
                        Text(.localized("Cancel"))
                            .foregroundStyle(.red)
                    }
                }
            }
            .fullScreenCover(isPresented: $showLoadingCover) {
                LoadingPairView(
                    transferPhase: service.transferPhase,
                    isHost: true,
                    pairedDeviceName: service.connectedPeerName,
                    transferStartTime: service.transferStartTime,
                    transferSpeed: service.transferSpeed
                )
                .preferredColorScheme(.dark)
            }
            .fullScreenCover(isPresented: $showSuccessCover) {
                MPCSuccessfulPairView(
                    receivedURL: successReceivedURL,
                    deviceName: service.connectedPeerName,
                    wasHost: true,
                    onDone: {
                        showSuccessCover = false
                        onCancel()
                    }
                )
                .preferredColorScheme(.dark)
            }
            .onAppear {
                startPulse()
            }
            .onChange(of: service.state) { newState in
                handleStateChange(newState)
            }
            .onChange(of: service.transferPhase) { phase in
                handlePhaseChange(phase)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.62, saturation: 0.15, brightness: 0.08),
                Color(hue: 0.65, saturation: 0.12, brightness: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Advertising Icon

    private var advertisingIcon: some View {
        ZStack {
            // Pulsing background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.70, saturation: 0.5, brightness: 0.5).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

            // Sparkle burst on connection
            if sparklesVisible {
                ForEach(0..<8, id: \.self) { i in
                    let angle = sparkleAngles[i]
                    Circle()
                        .fill(Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0))
                        .frame(width: 8, height: 8)
                        .offset(
                            x: cos(angle * .pi / 180.0) * sparkleRadius,
                            y: sin(angle * .pi / 180.0) * sparkleRadius
                        )
                        .shadow(
                            color: Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0).opacity(0.8),
                            radius: 4
                        )
                }
            }

            // Main icon
            Image(systemName: iconForState)
                .font(.system(size: 68))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.70, saturation: 0.75, brightness: 0.95),
                            Color(hue: 0.82, saturation: 0.65, brightness: 0.90)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(hue: 0.70, saturation: 0.75, brightness: 0.90).opacity(0.5),
                    radius: 18
                )
                .scaleEffect(connectedBadgeScale > 0 ? connectedBadgeScale : 1.0)
                .ifAvailableiOS17SymbolPulse(isActive: service.state == .advertising)

            // "Connected!" badge overlay
            if service.state == .connected {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color(hue: 0.62, saturation: 0.15, brightness: 0.08)).padding(-3))
                            .scaleEffect(connectedBadgeScale)
                    }
                }
                .frame(width: 100, height: 100)
            }
        }
        .frame(width: 180, height: 180)
        .offset(x: errorShakeOffset)
    }

    private var iconForState: String {
        switch service.state {
        case .connected:
            return "iphone.radiowaves.left.and.right"
        case .failed:
            return "exclamationmark.triangle.fill"
        default:
            return "personalhotspot"
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 10) {
            Text(statusTitle)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: statusTitle)

            Text(statusDetail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.3), value: statusDetail)

            if service.state == .advertising {
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(themeManager.accentColor)
                        .pulseEffect()

                    Text(.localized("Searching for nearby devices…"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 4)
            }

            if service.state == .connecting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(.top, 4)
            }

            if service.state == .connected, let name = service.connectedPeerName {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: service.state)
    }

    private var statusTitle: String {
        switch service.state {
        case .advertising:
            return .localized("Waiting for Receiver")
        case .connecting:
            return .localized("Device Found!")
        case .connected:
            return .localized("Connected — Transferring")
        case .failed:
            return .localized("Connection Failed")
        default:
            return .localized("Starting…")
        }
    }

    private var statusDetail: String {
        switch service.state {
        case .advertising:
            return .localized("Open Portal on the other device and select \"Receive Data\". Both devices must be on the same WiFi network and have the latest version of Portal.")
        case .connecting:
            return .localized("A nearby device accepted the pairing request. Establishing a secure connection…")
        case .connected:
            return .localized("Keep both devices nearby. Do NOT close Portal.")
        case .failed(let msg):
            return msg
        default:
            return .localized("Preparing To Broadcast…")
        }
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if case .failed(let message) = service.state {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.orange.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
                .background(Color.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    service.cancel()
                    service.startAdvertising()
                } label: {
                    Label(.localized("Try Again"), systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.orange.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - State Handlers

    private func handleStateChange(_ newState: PairingMPCState) {
        switch newState {
        case .connected:
            triggerConnectionAnimation()
        case .failed:
            triggerErrorAnimation()
        default:
            break
        }
    }

    private func handlePhaseChange(_ phase: TransferPhase) {
        switch phase {
        case .preparingData, .sending, .receiving:
            showSuccessCover = false
            showLoadingCover = true
        case .complete(let url):
            successReceivedURL = url
            showLoadingCover = false
            showSuccessCover = true
        case .failed:
            showLoadingCover = false
            showSuccessCover = false
        default:
            break
        }
    }

    // MARK: - Animations

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.18
            pulseOpacity = 0.55
        }
    }

    private func triggerConnectionAnimation() {
        // Stop pulse
        withAnimation(.easeOut(duration: 0.2)) {
            pulseScale = 1.0
            pulseOpacity = 0
        }

        // Sparkle burst
        sparklesVisible = true
        sparkleRadius = 0
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            sparkleRadius = 80
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                sparklesVisible = false
            }
        }

        // Connected badge bounce-in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
            connectedBadgeScale = 1.0
        }

        HapticsManager.shared.success()
    }

    private func triggerErrorAnimation() {
        HapticsManager.shared.error()
        withAnimation(.spring(response: 0.08, dampingFraction: 0.2)) {
            errorShakeOffset = 12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.08, dampingFraction: 0.2)) {
                errorShakeOffset = -12
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
                errorShakeOffset = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                errorShakeOffset = 0
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SenderView(service: PairingMPCService(), onCancel: {})
        .preferredColorScheme(.dark)
}
#endif
