import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct NearbyTransferSimulationView: View {
    @State private var selectedView: NearbyTransferUIView = .main
    @State private var simulationRole: SimulationRole = .sender
    @AppStorage("Feather.simulateNearbyTransfer") private var simulateNearbyTransfer = false

    // Mock service for simulation
    @StateObject private var mockService = MockNearbyTransferService()

    enum SimulationRole: String, CaseIterable {
        case sender = "Sender"
        case receiver = "Receiver"
    }

    enum NearbyTransferUIView: String, CaseIterable, Identifiable {
        case main = "Main View"
        case pairingNearby = "Pairing (Nearby)"
        case pairingOTP = "Pairing (OTP)"
        case transferProgress = "Transfer Progress"
        case preflightCheck = "Preflight Check"
        case conflictResolver = "Conflict Resolver"
        case postHealthCheck = "Post Restore Health Check"
        case senderAnimation = "Sender Animation"
        case receiverAnimation = "Receiver Animation"

        var id: String { rawValue }
    }

    var body: some View {
        NBList("Nearby Transfer Simulation") {
            // Warning Banner
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Simulation Mode Active")
                            .font(.headline)
                        Text("UI preview only - no actual data transfer will occur")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Role Selection
            Section {
                Picker("Device Role", selection: $simulationRole) {
                    ForEach(SimulationRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: simulationRole) { newRole in
                    // Update mock service based on role
                    if newRole == .sender {
                        mockService.setMode(.send)
                    } else {
                        mockService.setMode(.receive)
                    }
                }
            } header: {
                AppearanceSectionHeader(title: "Simulation Role", icon: "person.2.fill")
            } footer: {
                Text("Switch between Sender and Receiver roles to test both UI flows")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // View Selection
            Section {
                ForEach(NearbyTransferUIView.allCases) { view in
                    NavigationLink(destination: simulatedViewDestination(for: view)) {
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(view))
                                .foregroundStyle(colorFor(view))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(view.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Text(descriptionFor(view))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                AppearanceSectionHeader(title: "Available Views", icon: "square.grid.2x2")
            } footer: {
                Text("Select any view to see how it appears during a real transfer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Instructions
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(
                        number: 1,
                        text: "Select your device role (Sender or Receiver)"
                    )
                    instructionRow(
                        number: 2,
                        text: "Choose a view to preview its UI"
                    )
                    instructionRow(
                        number: 3,
                        text: "Test interactions and animations"
                    )
                    instructionRow(
                        number: 4,
                        text: "Switch roles to see both perspectives"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                AppearanceSectionHeader(title: "How to Use", icon: "info.circle.fill")
            }
        }
        .navigationTitle("UI Simulation")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Destinations
    @ViewBuilder
    private func simulatedViewDestination(for view: NearbyTransferUIView) -> some View {
        switch view {
        case .main:
            NearbyTransferView()
        case .pairingNearby:
            PairingView()
                .environment(\.nearbyTransferSimulation, true)
        case .pairingOTP:
            PairingThroughOTPView()
                .environment(\.nearbyTransferSimulation, true)
        case .transferProgress:
            TransferProgressView(
                service: mockService,
                onCancel: {},
                onRetry: {}
            )
        case .preflightCheck:
            PreflightCheckView(
                onContinue: {}
            )
        case .conflictResolver:
            if let mockURL = createMockBackupDirectory() {
                ConflictResolverView(backupDirectory: mockURL) { _ in }
            } else {
                Text("Unable to create mock data")
                    .foregroundStyle(.secondary)
            }
        case .postHealthCheck:
            PostRestoreHealthCheckView {}
        case .senderAnimation:
            SenderAnimationView(state: .transferring(progress: 0.65, bytesTransferred: 650_000_000, totalBytes: 1_000_000_000, speed: 5_000_000))
        case .receiverAnimation:
            ReceiverAnimationView(state: .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000))
        }
    }

    // MARK: - Helper Methods
    private func iconFor(_ view: NearbyTransferUIView) -> String {
        switch view {
        case .main: return "house.fill"
        case .pairingNearby: return "wifi"
        case .pairingOTP: return "key.fill"
        case .transferProgress: return "arrow.left.arrow.right"
        case .preflightCheck: return "checkmark.shield.fill"
        case .conflictResolver: return "exclamationmark.triangle.fill"
        case .postHealthCheck: return "stethoscope"
        case .senderAnimation: return "arrow.up.circle.fill"
        case .receiverAnimation: return "arrow.down.circle.fill"
        }
    }

    private func colorFor(_ view: NearbyTransferUIView) -> Color {
        switch view {
        case .main: return .blue
        case .pairingNearby: return .green
        case .pairingOTP: return .purple
        case .transferProgress: return .orange
        case .preflightCheck: return .cyan
        case .conflictResolver: return .red
        case .postHealthCheck: return .indigo
        case .senderAnimation: return .pink
        case .receiverAnimation: return .mint
        }
    }

    private func descriptionFor(_ view: NearbyTransferUIView) -> String {
        switch view {
        case .main: return "Entry point and feature overview"
        case .pairingNearby: return "Local network device pairing"
        case .pairingOTP: return "Remote pairing with code"
        case .transferProgress: return "Real-time transfer status"
        case .preflightCheck: return "Pre-transfer validation"
        case .conflictResolver: return "Handle data conflicts"
        case .postHealthCheck: return "Post-restore validation"
        case .senderAnimation: return "Sending animation view"
        case .receiverAnimation: return "Receiving animation view"
        }
    }

    private func createMockBackupDirectory() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MockBackup_\(UUID().uuidString)")

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    @ViewBuilder
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
