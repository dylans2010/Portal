import SwiftUI
import NimbleViews

// MARK: - Loading Pair View
/// Full-screen overlay shown on both devices immediately after the pairing code
/// is accepted — while data is being prepared, sent, or received.
///
/// Displays:
/// - An animated pulsing activity indicator
/// - The current transfer phase with a human-readable description
/// - A live progress bar with percentage
/// - Elapsed time and a running estimated time remaining
/// - The remote device name being paired with
struct LoadingPairView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    // MARK: - Input

    let transferPhase: TransferPhase
    let isHost: Bool
    let pairedDeviceName: String?
    let transferStartTime: Date?
    var transferSpeed: Double = 0

    // MARK: - State

    @State private var elapsedSeconds: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    /// Smoothed ETA in seconds, updated once per second using an exponential
    /// moving average (α = 0.25) to avoid jumpy estimates early in the transfer.
    @State private var smoothedETASeconds: Double = 0
    @State private var currentSpeed: Double = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 36) {
                Spacer()

                // Animated orbit ring indicator
                orbitIndicator

                // Phase label + progress
                VStack(spacing: 16) {
                    Text(phaseTitle)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .themedText(.primary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: phaseTitle)

                    Text(phaseDetail)
                        .font(.subheadline)
                        .themedText(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .animation(.easeInOut(duration: 0.3), value: phaseDetail)

                    if let progress = currentProgress {
                        progressBar(value: progress)
                    }
                }

                // Device & timing info
                infoCards

                Spacer()
            }
            .padding(.horizontal, 24)
            .globalTheme()
        }
        .onAppear {
            startAnimations()
        }
        .onReceive(timer) { _ in
            if let start = transferStartTime {
                elapsedSeconds = max(0, Int(Date().timeIntervalSince(start)))
            }
            updateSmoothedETA()
            currentSpeed = transferSpeed
        }
    }

    // MARK: - Orbit Indicator

    private var orbitIndicator: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            // Dashed orbit ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            themeManager.accentColor,
                            themeManager.accentColor.opacity(0.7),
                            themeManager.accentColor.opacity(0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, dash: [6, 4])
                )
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: 2.8).repeatForever(autoreverses: false),
                    value: rotationAngle
                )

            // Center icon
            Image(systemName: isHost ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .pulseEffect()
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor,
                            themeManager.accentColor.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: themeManager.accentColor.opacity(0.6), radius: 14)
        }
        .frame(width: 160, height: 160)
    }

    // MARK: - Progress Bar

    private func progressBar(value: Double) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.accentColor.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.accentColor,
                                    themeManager.accentColor.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * value, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: value)
                }
            }
            .frame(maxWidth: 280, minHeight: 6, maxHeight: 6)

            Text("\(Int(value * 100))%")
                .font(.caption.monospacedDigit())
                .themedText(.secondary)
        }
    }

    // MARK: - Info Cards

    private var infoCards: some View {
        VStack(spacing: 10) {
            // Device pairing info
            if let deviceName = pairedDeviceName, !deviceName.isEmpty {
                infoRow(
                    icon: "iphone.radiowaves.left.and.right",
                    label: .localized("Pairing with"),
                    value: deviceName
                )
            }

            // Elapsed time
            if transferStartTime != nil {
                infoRow(
                    icon: "clock",
                    label: .localized("Elapsed"),
                    value: formatDuration(elapsedSeconds)
                )
            }

            // Estimated time (only meaningful when progress > 5%)
            if let eta = estimatedTimeRemaining {
                infoRow(
                    icon: "timer",
                    label: .localized("Estimated remaining"),
                    value: eta
                )
            }

            // Transfer Speed
            if currentSpeed > 0 {
                infoRow(
                    icon: "bolt.fill",
                    label: .localized("Transfer Speed"),
                    value: formatSpeed(currentSpeed)
                )
            }

            // Current operation detail
            infoRow(
                icon: currentPhaseIcon,
                label: .localized("Currently"),
                value: currentOperationLabel
            )
        }
        .padding(16)
        .themedCard()
        .padding(.horizontal, 8)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .pulseEffect()
                .font(.footnote)
                .themedText(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .themedText(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .themedText(.primary)
        }
    }

    // MARK: - Computed Helpers

    private var currentProgress: Double? {
        switch transferPhase {
        case .sending(let p): return p
        case .receiving(let p): return p
        default: return nil
        }
    }

    private var phaseTitle: String {
        switch transferPhase {
        case .preparingData:
            return .localized("Preparing Transfer")
        case .sending:
            return isHost
                ? .localized("Sending Your Data")
                : .localized("Transferring Data")
        case .receiving:
            return .localized("Receiving Data")
        default:
            return .localized("Connecting…")
        }
    }

    private var phaseDetail: String {
        switch transferPhase {
        case .preparingData:
            return .localized("Packaging your sources, certificates, apps, and settings…")
        case .sending(let p):
            return p < 0.33
                ? .localized("Sending certificates and sources…")
                : p < 0.66
                    ? .localized("Sending apps and archives…")
                    : .localized("Sending settings and finishing up…")
        case .receiving(let p):
            return p < 0.33
                ? .localized("Receiving certificates and sources…")
                : p < 0.66
                    ? .localized("Receiving apps and archives…")
                    : .localized("Receiving settings and finishing up…")
        default:
            return .localized("Please keep both devices nearby and on the same Wi-Fi network.")
        }
    }

    private var currentPhaseIcon: String {
        switch transferPhase {
        case .preparingData: return "archivebox.fill"
        case .sending(let p):
            return p < 0.33
                ? "checkmark.seal.fill"
                : p < 0.66
                    ? "app.badge.fill"
                    : "gearshape.fill"
        case .receiving(let p):
            return p < 0.33
                ? "checkmark.seal.fill"
                : p < 0.66
                    ? "app.badge.fill"
                    : "gearshape.fill"
        default:
            return "antenna.radiowaves.left.and.right"
        }
    }

    private var currentOperationLabel: String {
        switch transferPhase {
        case .preparingData: return .localized("Packing data")
        case .sending(let p):
            return p < 0.33
                ? .localized("Certificates & sources")
                : p < 0.66
                    ? .localized("Apps & archives")
                    : .localized("Settings")
        case .receiving(let p):
            return p < 0.33
                ? .localized("Certificates & sources")
                : p < 0.66
                    ? .localized("Apps & archives")
                    : .localized("Settings")
        default:
            return .localized("Establishing connection")
        }
    }

    private var estimatedTimeRemaining: String? {
        guard transferStartTime != nil,
              let progress = currentProgress,
              progress > 0.05,
              smoothedETASeconds > 0 else { return nil }
        if smoothedETASeconds < 2 { return .localized("Almost done!") }
        return .localized("~") + formatDuration(Int(smoothedETASeconds))
    }

    private func updateSmoothedETA() {
        guard let start = transferStartTime,
              let progress = currentProgress,
              progress > 0.05 else {
            smoothedETASeconds = 0
            return
        }
        let elapsed = Date().timeIntervalSince(start)
        let rawRemaining = max(0, (elapsed / progress) - elapsed)
        if smoothedETASeconds <= 0 {
            // First valid estimate — initialise directly
            smoothedETASeconds = rawRemaining
        } else {
            // Exponential moving average (α = 0.25) for stability
            smoothedETASeconds = 0.25 * rawRemaining + 0.75 * smoothedETASeconds
        }
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let m = seconds / 60
            let s = seconds % 60
            return "\(m)m \(s)s"
        }
    }

    // MARK: - Animation Setup

    private func startAnimations() {
        pulseScale = 1.12
        rotationAngle = 360
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LoadingPairView(
        transferPhase: .sending(progress: 0.42),
        isHost: true,
        pairedDeviceName: "Dylan's iPhone",
        transferStartTime: Date().addingTimeInterval(-18)
    )
    .preferredColorScheme(.dark)
}
#endif
