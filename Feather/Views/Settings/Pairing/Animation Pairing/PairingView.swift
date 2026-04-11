import SwiftUI
import NimbleViews

struct PairingView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
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
        .globalTheme()
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
                        Button(.localized("Cancel")) { viewModel.showScanSheet = false }
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
                transferStartTime: viewModel.transferStartTime,
                transferSpeed: 0 // Animation pairing uses a different service
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
                            themeManager.accentColor
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
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .themedText(.secondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)

            // Gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.accentColor.opacity(0.1))
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 3)
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
            if viewModel.status == .idle || viewModel.status == .waiting || viewModel.status == .generating {
                Button(action: { viewModel.showScanSheet = true }) {
                    Label(.localized("Scan Pairing Code"), systemImage: "camera.viewfinder")
                        .pulseEffect()
                        .font(.headline)
                        .foregroundStyle(Color(hex: themeManager.resolvedColors.buttonText))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(hex: themeManager.resolvedColors.buttonBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: { showDemo = true }) {
                    Label(.localized("See Demo"), systemImage: "play.circle")
                        .pulseEffect()
                        .font(.subheadline)
                        .themedText(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(Color(hex: themeManager.resolvedColors.cardBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if viewModel.canRetry {
                Button(action: { viewModel.retry() }) {
                    Label(.localized("Try Again"), systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.accentColor)
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
                    .foregroundStyle(Color(hex: themeManager.resolvedColors.destructive))
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color(hex: themeManager.resolvedColors.destructive))
                    .opacity(0.9)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(Color(hex: themeManager.resolvedColors.destructive).opacity(0.12))
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
