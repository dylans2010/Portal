import SwiftUI
import AVFoundation

// MARK: - Pair Code Scanner View
/// A fully custom camera scanning view designed exclusively to detect Pairing Codes.
///
/// This scanner:
/// - Presents a centered circular scanning frame as the visual target zone.
/// - Restricts metadata detection to the bounding box of the circular region via
///   `AVCaptureMetadataOutput.rectOfInterest` so the entire camera frame is never
///   analyzed for codes that lie outside the circle.
/// - Only triggers for codes whose string value matches the 6-digit numeric pairing
///   code format used by `PairingService`.  All other QR patterns, barcodes, and
///   unrecognized strings are silently ignored.
/// - Automatically starts the camera session when the view appears and fully stops
///   it when the view is removed to avoid unnecessary background camera usage.
struct PairCodeScannerView: View {

    // MARK: - Input

    /// Called exactly once on the main thread with a valid, parsed pairing code.
    let onCodeDetected: (String) -> Void

    // MARK: - State

    @State private var cameraPermissionDenied = false
    @State private var scannerKey = UUID()

    // MARK: - Constants

    private let circleSize: CGFloat = 260

    // MARK: - Body

    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                permissionDeniedView
            } else {
                scannerContent
            }
        }
        .onAppear { checkCameraPermission() }
    }

    // MARK: - Scanner Content

    private var scannerContent: some View {
        ZStack {
            // Live camera feed managed by the underlying UIKit view
            PairCodeCameraPreview(circleSize: circleSize) { code in
                onCodeDetected(code)
            }
            .id(scannerKey)
            .ignoresSafeArea()

            // Dimmed overlay with circular cutout, plus animated circle border
            CircularScanOverlay(circleSize: circleSize)
                .ignoresSafeArea()

            // Instructional label positioned directly below the circular frame
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Push the label to just below the circle (centre + radius + gap)
                    Spacer()
                        .frame(height: geo.size.height / 2 + circleSize / 2 + 20)
                    Text(.localized("Center the Pairing Code inside this circle"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(.localized("Camera Access Required"))
                .font(.title3.bold())
            Text(.localized("Please allow camera access in Settings to scan the pairing code."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(.localized("Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Permission Check

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionDenied = !granted
                    if granted { scannerKey = UUID() }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

/// Wraps `PairCodeCameraUIView` so it can be embedded in a SwiftUI hierarchy.
/// The capture session is started on `makeUIView` and stopped via `dismantleUIView`
/// to guarantee the camera is off whenever the SwiftUI view leaves the hierarchy.
private struct PairCodeCameraPreview: UIViewRepresentable {

    let circleSize: CGFloat
    let onCodeDetected: (String) -> Void

    func makeUIView(context: Context) -> PairCodeCameraUIView {
        let view = PairCodeCameraUIView(circleSize: circleSize)
        view.configure(delegate: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: PairCodeCameraUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    static func dismantleUIView(_ uiView: PairCodeCameraUIView, coordinator: Coordinator) {
        uiView.stopSession()
    }

    // MARK: - Coordinator

    /// Receives metadata output callbacks and filters them to the pairing code format.
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

        private let onCodeDetected: (String) -> Void
        /// Prevents double-firing after the first successful detection.
        private var hasDetected = false

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasDetected else { return }

            for object in metadataObjects {
                guard
                    let readable = object as? AVMetadataMachineReadableCodeObject,
                    readable.type == .qr,
                    let value = readable.stringValue,
                    isPairingCode(value)
                else { continue }

                hasDetected = true
                DispatchQueue.main.async {
                    self.onCodeDetected(value)
                }
                return
            }
        }

        /// Returns `true` only when `value` is exactly 6 decimal digits —
        /// the format produced by `PairingService.generatePairingCode()`.
        private func isPairingCode(_ value: String) -> Bool {
            value.count == 6 && value.allSatisfy(\.isNumber)
        }
    }
}

// MARK: - Camera UIView

/// A `UIView` whose `layerClass` is `AVCaptureVideoPreviewLayer` so the camera
/// feed fills the view's bounds without an extra sub-layer.  The metadata output's
/// `rectOfInterest` is updated in `layoutSubviews` so it always tracks the circular
/// scanning region even after device rotation or view resizing.
final class PairCodeCameraUIView: UIView {

    // MARK: - Private

    private let circleSize: CGFloat
    private var captureSession: AVCaptureSession?
    private var metadataOutput: AVCaptureMetadataOutput?

    // MARK: - Init

    init(circleSize: CGFloat) {
        self.circleSize = circleSize
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layer

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }

    // MARK: - Configuration

    func configure(delegate: AVCaptureMetadataOutputObjectsDelegate) {
        let session = AVCaptureSession()
        captureSession = session

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        // Restrict to QR codes only — barcodes and other formats are not configured.
        // Filter against availableMetadataObjectTypes to avoid runtime errors on
        // devices where a type might not be supported.
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        let available = output.availableMetadataObjectTypes
        let requested: [AVMetadataObject.ObjectType] = [.qr]
        output.metadataObjectTypes = requested.filter { available.contains($0) }
        metadataOutput = output

        guard let previewLayer = videoPreviewLayer else { return }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        // Weak capture ensures startRunning() is a no-op if the view is already
        // dismantled before the background task runs.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
        updateRectOfInterest()
    }

    /// Maps the bounding box of the circular scanning frame from preview-layer
    /// coordinates into the normalized metadata-output coordinate space and sets
    /// `rectOfInterest` so that only codes inside the circle trigger callbacks.
    private func updateRectOfInterest() {
        guard
            let previewLayer = videoPreviewLayer,
            let output = metadataOutput,
            bounds.width > 0, bounds.height > 0
        else { return }

        let originX = (bounds.width  - circleSize) / 2
        let originY = (bounds.height - circleSize) / 2
        let circleRect = CGRect(x: originX, y: originY, width: circleSize, height: circleSize)
        output.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: circleRect)
    }

    // MARK: - Session Lifecycle

    func stopSession() {
        captureSession?.stopRunning()
    }

    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - Circular Scan Overlay

/// Draws a semi-transparent dimmed overlay over the full screen with a circular
/// cutout centred in the view.  An animated gradient-stroke circle highlights the
/// scanning zone.
private struct CircularScanOverlay: View {

    let circleSize: CGFloat

    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Semi-transparent overlay — the circular cutout lets the camera
                // feed show through unobscured in the scanning region.
                Color.black.opacity(0.55)
                    .mask(
                        Rectangle()
                            .overlay(
                                Circle()
                                    .frame(width: circleSize, height: circleSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )

                // Animated gradient border around the scanning circle
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: circleSize, height: circleSize)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .opacity(pulse ? 1.0 : 0.65)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulse
                    )
            }
            .onAppear { pulse = true }
        }
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
