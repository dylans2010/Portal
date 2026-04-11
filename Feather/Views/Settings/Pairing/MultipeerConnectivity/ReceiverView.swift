import SwiftUI
import MultipeerConnectivity
import NimbleViews

struct ReceiverView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    // MARK: - Dependencies

    @ObservedObject var service: PairingMPCService
    let onCancel: () -> Void

    // MARK: - Transfer Cover State

    @State private var showLoadingCover = false
    @State private var showSuccessCover = false
    @State private var successReceivedURL: URL?

    // MARK: - Animation State

    @State private var scanRingScale: CGFloat = 1.0
    @State private var scanRingOpacity: Double = 0.6
    @State private var errorShakeOffset: CGFloat = 0
    @State private var visiblePeers: [MCPeerID] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 20)
                        scanningIcon
                        statusSection
                        peerListSection
                        errorSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle(.localized("Receiving Data"))
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
                    isHost: false,
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
                    wasHost: false,
                    onDone: {
                        showSuccessCover = false
                        onCancel()
                    }
                )
                .preferredColorScheme(.dark)
            }
            .onAppear {
                startScanAnimation()
            }
            .onChange(of: service.nearbyPeers) { newPeers in
                updateVisiblePeers(newPeers)
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
                Color(hue: 0.55, saturation: 0.14, brightness: 0.07),
                Color(hue: 0.58, saturation: 0.11, brightness: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Scanning Icon

    private var scanningIcon: some View {
        ZStack {
            // Expanding scan rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        Color(hue: 0.55, saturation: 0.7, brightness: 0.85).opacity(0.25 - Double(i) * 0.07),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: CGFloat(90 + i * 44),
                        height: CGFloat(90 + i * 44)
                    )
                    .scaleEffect(scanRingScale)
                    .opacity(scanRingOpacity - Double(i) * 0.15)
            }

            // Center icon
            Image(systemName: iconForState)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.55, saturation: 0.7, brightness: 0.95),
                            Color(hue: 0.42, saturation: 0.65, brightness: 0.90)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(hue: 0.55, saturation: 0.7, brightness: 0.9).opacity(0.45),
                    radius: 16
                )
                .ifAvailableiOS17SymbolPulse(isActive: service.state == .browsing)
        }
        .frame(width: 200, height: 200)
        .offset(x: errorShakeOffset)
    }

    private var iconForState: String {
        switch service.state {
        case .connected:
            return "checkmark.circle.fill"
        case .connecting:
            return "personalhotspot"
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

            if service.state == .browsing && service.nearbyPeers.isEmpty {
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
                    Image(systemName: "checkmark.circle.fill")
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
        case .browsing:
            return service.nearbyPeers.isEmpty
                ? .localized("Looking For Senders")
                : .localized("Devices Found!")
        case .connecting:
            return .localized("Connecting…")
        case .connected:
            return .localized("Connected — Receiving")
        case .failed:
            return .localized("Connection Failed")
        default:
            return .localized("Starting…")
        }
    }

    private var statusDetail: String {
        switch service.state {
        case .browsing:
            return service.nearbyPeers.isEmpty
                ? .localized("Open Portal on the sender's device and select \"Send Data\". Both devices must be on the same WiFi network and have the latest version of Portal.")
                : .localized("Tap a device below to start receiving its data.")
        case .connecting:
            return .localized("Establishing a secure network connection…")
        case .connected:
            return .localized("Keep both devices nearby. Do NOT close Portal.")
        case .failed(let msg):
            return msg
        default:
            return .localized("Preparing to scan for nearby devices…")
        }
    }

    // MARK: - Peer List Section

    @ViewBuilder
    private var peerListSection: some View {
        if !visiblePeers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(.localized("Nearby Senders"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)

                ForEach(visiblePeers, id: \.self) { peer in
                    peerRow(peer)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: visiblePeers.map(\.displayName))
        }
    }

    private func peerRow(_ peer: MCPeerID) -> some View {
        Button {
            service.connectToPeer(peer)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.7, brightness: 0.4).opacity(0.4),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.7, brightness: 0.95),
                                    Color(hue: 0.42, saturation: 0.6, brightness: 0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(peer.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(.localized("Tap To Connect"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.trailing, 2)
            }
            .padding(14)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                    service.startBrowsing()
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
        case .failed:
            triggerErrorAnimation()
        case .connected:
            HapticsManager.shared.success()
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

    private func updateVisiblePeers(_ newPeers: [MCPeerID]) {
        let added = newPeers.filter { p in !visiblePeers.contains(where: { $0 == p }) }
        let removed = visiblePeers.filter { p in !newPeers.contains(where: { $0 == p }) }

        if !added.isEmpty {
            HapticsManager.shared.impact(.light)
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            for peer in removed {
                visiblePeers.removeAll { $0 == peer }
            }
            for peer in added {
                visiblePeers.append(peer)
            }
        }
    }

    // MARK: - Animations

    private func startScanAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scanRingScale = 1.12
            scanRingOpacity = 0.25
        }
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
    ReceiverView(service: PairingMPCService(), onCancel: {})
        .preferredColorScheme(.dark)
}
#endif
