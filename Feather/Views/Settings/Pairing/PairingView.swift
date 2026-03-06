import SwiftUI
import NimbleViews
import CoreImage

// MARK: - Pairing View
/// The main "Pair Devices" screen.
///
/// The pairing code is generated **automatically** the moment this view appears —
/// no button press required.  A 3D morphing-dot sphere (chaos → Fibonacci order)
/// plays throughout the session.
///
/// Pairing happens **only** via the pairing code: the user on the other device
/// taps **Scan Pairing Code** and enters the 6-digit code shown on the sending
/// device's `LoadingPairView` header.
///
/// - `LoadingPairView` is shown on both devices as soon as the transfer starts.
/// - `SuccessfulPairView` is shown when the transfer completes.
/// - `PairHistoryView` is reachable via the toolbar History button.
///
/// When `isEmbedded` is `true` the view skips its own `NavigationStack` wrapper
/// and relies on the parent navigation context (e.g. a `NavigationLink`).
struct PairingView: View {

    // MARK: - Parameters

    /// Pass `true` when this view is pushed via a `NavigationLink` so that it
    /// doesn't add a redundant `NavigationStack`.
    var isEmbedded: Bool = false

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PairingViewModel()

    // Full-screen cover flags
    @State private var showLoadingCover: Bool = false
    @State private var showSuccessCover: Bool = false
    @State private var successReceivedURL: URL? = nil
    @State private var showHistory: Bool = false

    // Demo sheet
    @State private var showDemo: Bool = false

    // MARK: - Body

    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    sphereSection
                    statusSection
                    actionSection
                    errorSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle(.localized("Pair Devices"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(.localized("Cancel")) {
                    viewModel.cancel()
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $viewModel.showScanSheet) {
            NavigationStack {
                PairCodeScannerView { code in
                    connectWithScannedCode(code)
                }
                .navigationTitle(.localized("Scan Pairing Code"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(.localized("Cancel")) {
                            viewModel.showScanSheet = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                PairHistoryView()
            }
        }
        .sheet(isPresented: $showDemo) {
            PairingDemoView()
        }
        .fullScreenCover(isPresented: $showLoadingCover) {
            LoadingPairView(
                transferPhase: viewModel.transferPhase,
                isHost: viewModel.isHost,
                pairedDeviceName: viewModel.pairedDeviceName,
                transferStartTime: viewModel.transferStartTime
            )
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showSuccessCover) {
            SuccessfulPairView(
                receivedURL: successReceivedURL,
                deviceName: viewModel.pairedDeviceName,
                onDone: {
                    showSuccessCover = false
                    dismiss()
                }
            )
            .preferredColorScheme(.dark)
        }
        .onChange(of: viewModel.transferPhase) { phase in
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
        .onAppear {
            viewModel.autoStart()
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

    // MARK: - Sphere Section

    private var sphereSection: some View {
        ZStack {
            // Glow halo behind the sphere — intensifies as morphProgress grows
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 0.6, brightness: 0.5)
                                .opacity(0.18 + viewModel.progress * 0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 300, height: 300)

            PairingCodeSphere(
                morphProgress: viewModel.progress,
                pairingStatus: viewModel.status
            )
            .frame(width: 280, height: 280)

            // Sender side: show the pairing code as a scannable QR code
            if viewModel.isHost, let code = viewModel.generatedCode {
                VStack {
                    HStack {
                        Spacer()
                        pairingQRCode(for: code)
                    }
                    Spacer()
                }
                .frame(width: 280, height: 280)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.generatedCode)
            }
        }
    }

    // MARK: - QR Code View

    private func pairingQRCode(for code: String) -> some View {
        Group {
            if let image = generateQRCode(from: code) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(6)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.5), radius: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(hue: 0.65, saturation: 0.8, brightness: 0.9),
                                             Color(hue: 0.75, saturation: 0.7, brightness: 0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)

            // Gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.8, brightness: 0.9),
                                    Color(hue: 0.42, saturation: 0.7, brightness: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * viewModel.progress,
                            height: 5
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(maxWidth: 240, minHeight: 5, maxHeight: 5)
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 14) {
            // "Scan Pairing Code" — the main CTA on both idle AND waiting states.
            // When idle, auto-start hasn't fired yet (brief window);
            // always show it so the receiver can enter the sender's code.
            if viewModel.status == .idle || viewModel.status == .waiting || viewModel.status == .generating {
                Button(action: { viewModel.showScanSheet = true }) {
                    Label(.localized("Scan Pairing Code"), systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.70, saturation: 0.75, brightness: 0.90),
                                    Color(hue: 0.82, saturation: 0.65, brightness: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: { showDemo = true }) {
                    Label(.localized("See Demo"), systemImage: "play.circle")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if viewModel.canRetry {
                Button(action: { viewModel.retry() }) {
                    Label(.localized("Try Again"), systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.status)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage, case .failed = viewModel.status {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.orange)
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func connectWithScannedCode(_ code: String) {
        viewModel.showScanSheet = false
        viewModel.scanCodeInput = code
        viewModel.startPairing(with: code)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingView()
        .preferredColorScheme(.dark)
}
#endif
