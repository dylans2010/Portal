import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct NearbyShareUITestingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedView: NearbyShareViewType = .loading
    @State private var showDismissButton: Bool = true

    enum NearbyShareViewType: String, CaseIterable {
        case loading = "Loading State"
        case error = "Error State"
        case success = "Success State"
        case senderAnimation = "Sender Animation"
        case receiverAnimation = "Receiver Animation"
        case nearbyPairingSender = "Nearby Pairing (Sender)"
        case nearbyPairingReceiver = "Nearby Pairing (Receiver)"
        case remotePairing = "Remote Pairing (OTP)"
        case transferProgress = "Transfer Progress"
        case preflightCheck = "Preflight Check"
        case postRestoreHealthCheck = "Post Restore Health Check"
        case conflictResolver = "Conflict Resolver"
    }

    @ViewBuilder
    private func renderSelectedView() -> some View {
        switch selectedView {
        case .loading:
            NearbyTransferView()
        case .error:
            TransferProgressView(
                service: {
                    let s = MockNearbyTransferService()
                    s.state = .failed(NSError(domain: "NearbyTransfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection Lost During Transfer"]))
                    return s
                }(),
                onCancel: { selectedView = .loading },
                onRetry: { selectedView = .transferProgress }
            )
        case .success:
            TransferProgressView(
                service: {
                    let s = MockNearbyTransferService()
                    s.state = .completed
                    return s
                }(),
                onCancel: { selectedView = .loading },
                onRetry: { selectedView = .transferProgress }
            )
        case .senderAnimation:
            SenderAnimationView(state: .transferring(progress: 0.65, bytesTransferred: 650_000_000, totalBytes: 1_000_000_000, speed: 5_000_000))
        case .receiverAnimation:
            ReceiverAnimationView(state: .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000))
        case .nearbyPairingSender:
            PairingView()
        case .nearbyPairingReceiver:
            PairingView()
        case .remotePairing:
            PairingThroughOTPView()
        case .transferProgress:
            TransferProgressView(
                service: MockNearbyTransferService(),
                onCancel: { selectedView = .loading },
                onRetry: { selectedView = .transferProgress }
            )
        case .preflightCheck:
            PreflightCheckView(onContinue: { selectedView = .transferProgress })
        case .postRestoreHealthCheck:
            PostRestoreHealthCheckView(onComplete: { selectedView = .success })
        case .conflictResolver:
            ConflictResolverView(
                backupDirectory: FileManager.default.temporaryDirectory,
                onResolve: { _ in selectedView = .postRestoreHealthCheck }
            )
        }
    }

    var body: some View {
        ZStack {
            // Main content - the selected view
            Group {
                renderSelectedView()
            }

            // Overlay controls
            VStack {
                HStack {
                    // Dropdown picker
                    Menu {
                        ForEach(NearbyShareViewType.allCases, id: \.self) { viewType in
                            Button(viewType.rawValue) {
                                selectedView = viewType
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedView.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.clear.opacity(0.95))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    // Dismiss button (only when opened from debug mode)
                    if showDismissButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }

}
