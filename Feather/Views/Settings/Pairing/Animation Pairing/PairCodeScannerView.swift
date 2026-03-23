import SwiftUI
import AVFoundation
import MultipeerConnectivity

struct PairCodeScannerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Input

    /// Called exactly once on the main thread with a valid, parsed pairing code.
    let onCodeDetected: (String) -> Void

    // MARK: - State

    @StateObject private var scanner = PairCodeScanner()
    @State private var scanLineOffset: CGFloat = -120

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                cameraViewfinder

                statusSection

                instructionText

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            scanner.startScanning { code in
                onCodeDetected(code)
            }
        }
        .onDisappear {
            scanner.stopScanning()
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

    // MARK: - Camera Viewfinder

    private var cameraViewfinder: some View {
        ZStack {
            // Glow behind the viewfinder
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.15),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)

            // Camera preview area
            CameraPreviewRepresentable()
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: scanner.isDetected
                                    ? [.green, .mint]
                                    : [.cyan.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )

            // Scanning line animation
            if !scanner.isDetected {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .cyan.opacity(0.6), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 3)
                    .offset(y: scanLineOffset)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: scanLineOffset
                    )
                    .onAppear { scanLineOffset = 120 }
            }

            // Corner brackets
            scannerCorners
                .frame(width: 240, height: 240)

            // Detection indicator
            if scanner.isDetected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
                    .shadow(color: .green.opacity(0.5), radius: 10)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: scanner.isDetected)
    }

    // MARK: - Scanner Corners

    private var scannerCorners: some View {
        GeometryReader { geo in
            let length: CGFloat = 30
            let lineWidth: CGFloat = 3
            let color = scanner.isDetected ? Color.green : Color.cyan

            // Top-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: length))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: length, y: 0))
            }
            .stroke(color, lineWidth: lineWidth)

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: geo.size.width - length, y: 0))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0))
                p.addLine(to: CGPoint(x: geo.size.width, y: length))
            }
            .stroke(color, lineWidth: lineWidth)

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height - length))
                p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                p.addLine(to: CGPoint(x: length, y: geo.size.height))
            }
            .stroke(color, lineWidth: lineWidth)

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: geo.size.width - length, y: geo.size.height))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - length))
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if scanner.isDetected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    ProgressView()
                        .tint(.cyan)
                }

                Text(scanner.statusText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(scanner.isDetected ? .green : .white)
            }
            .animation(.easeInOut(duration: 0.3), value: scanner.isDetected)
        }
    }

    // MARK: - Instruction

    private var instructionText: some View {
        VStack(spacing: 10) {
            Text(.localized("Point your camera at the pairing animation"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)

            Text(.localized("The scanner will automatically detect the animation on the other device"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }
}

@MainActor
final class PairCodeScanner: NSObject, ObservableObject {

    @Published var isDetected: Bool = false
    @Published var statusText: String = String.localized("Scanning for pairing animation…")

    private var browser: MCNearbyServiceBrowser?
    private var peerID: MCPeerID?
    private var onCodeFound: ((String) -> Void)?
    private var hasReported = false

    func startScanning(onDetected: @escaping (String) -> Void) {
        onCodeFound = onDetected
        hasReported = false
        isDetected = false
        statusText = .localized("Scanning for pairing animation…")

        peerID = MCPeerID(displayName: "\(UIDevice.current.name)-scanner-\(UUID().uuidString.prefix(8))")
        browser = MCNearbyServiceBrowser(
            peer: peerID!,
            serviceType: PairingService.serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stopScanning() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PairCodeScanner: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Task { @MainActor in
            guard !self.hasReported,
                  let code = info?["code"],
                  code.count == 6,
                  code.allSatisfy(\.isNumber) else { return }

            self.hasReported = true
            self.isDetected = true
            self.statusText = .localized("Pairing Animation Detected!")
            self.browser?.stopBrowsingForPeers()

            // Brief visual delay so the user sees the detection feedback
            try? await Task.sleep(nanoseconds: 600_000_000)
            self.onCodeFound?(code)
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {}

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Task { @MainActor in
            self.statusText = .localized("Unable to scan. Check Wi-Fi connection.")
        }
    }
}

private struct CameraPreviewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        CameraPreviewUIView()
    }
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

/// UIKit view that sets up and displays the rear camera feed.
private class CameraPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.05, alpha: 1)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = bounds
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showPlaceholder()
            return
        }

        guard session.canAddInput(input) else {
            showPlaceholder()
            return
        }
        session.addInput(input)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func showPlaceholder() {
        // Fallback when camera is unavailable (e.g. simulator)
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.1, blue: 0.15, alpha: 1).cgColor
        ]
        gradient.frame = bounds
        layer.addSublayer(gradient)

        let icon = UIImageView(image: UIImage(systemName: "camera.viewfinder"))
        icon.tintColor = UIColor(white: 0.4, alpha: 1)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairCodeScannerView { code in
        print("Detected pairing code: \(code)")
    }
    .preferredColorScheme(.dark)
}
#endif
