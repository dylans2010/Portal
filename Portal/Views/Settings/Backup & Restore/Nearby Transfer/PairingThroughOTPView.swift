import SwiftUI
import NimbleViews
import MultipeerConnectivity
import Combine

// MARK: - OTP Pairing Mode
enum OTPPairingMode {
    case sender
    case recipient
}

// MARK: - Pairing Through OTP View
struct PairingThroughOTPView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @StateObject private var viewModel = OTPPairingViewModel()
    @State private var selectedMode: OTPPairingMode = .sender
    @State private var otpInput: String = ""
    @State private var showingTransfer = false
    @FocusState private var isOTPFieldFocused: Bool
    
    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    PairingThroughOTPHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // Mode Selection
            Section {
                Picker("Your Role", selection: $selectedMode) {
                    Text("Sender").tag(OTPPairingMode.sender)
                    Text("Recipient").tag(OTPPairingMode.recipient)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                .onChange(of: selectedMode) { newValue in
                    withAnimation {
                        viewModel.switchMode(to: newValue)
                        otpInput = ""
                    }
                }
            } header: {
                Text(.localized("Your Role"))
            }
            
            // Interaction Area
            if selectedMode == .sender {
                senderUI
            } else {
                recipientUI
            }
            
            // Guidance
            Section {
                Label("Direct Over Wi-Fi/Bluetooth", systemImage: "wifi")
                Label("Secure 6 Digit Encryption", systemImage: "lock.shield.fill")
                Label("Auto Expiring Codes", systemImage: "timer")
            } header: {
                Text(.localized("Security Features"))
            }
        }
        .navigationTitle("Remote Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    viewModel.cleanup()
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .sheet(isPresented: $showingTransfer) {
            NavigationStack {
                TransferProgressView(
                    service: viewModel.transferService,
                    onCancel: { viewModel.transferService.cancelTransfer() },
                    onRetry: {}
                )
                .navigationTitle("Transfer Progress")
            }
        }
        .onAppear { viewModel.setup() }
        .onChange(of: viewModel.transferStarted) { if $0 { showingTransfer = true } }
    }
    
    // MARK: - Sender UI
    @ViewBuilder
    private var senderUI: some View {
        Section {
            VStack(spacing: 20) {
                Text("Your Secure Code")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.otpCode)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .tracking(10)
                    .foregroundStyle(.blue)
                    .padding()
                
                // Expiry Countdown
                VStack(spacing: 8) {
                    ProgressView(value: Double(viewModel.timeRemaining), total: Double(viewModel.otpExpirationSeconds))
                        .tint(viewModel.expirationColor)
                    
                    Text("Expires In \(viewModel.timeRemaining) Seconds")
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.expirationColor)
                }
                .padding(.horizontal, 40)
                
                if viewModel.isPeerConnected {
                    Label("Recipient Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if viewModel.isWaitingForRecipient {
                    Label("Waiting For Recipient...", systemImage: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        
        Section {
            Button {
                UIPasteboard.general.string = viewModel.otpCode
                HapticsManager.shared.success()
                withAnimation { viewModel.showCopyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { viewModel.showCopyFeedback = false } }
            } label: {
                HStack {
                    Image(systemName: viewModel.showCopyFeedback ? "checkmark" : "doc.on.doc.fill")
                    Text(viewModel.showCopyFeedback ? "Copied!" : "Copy Code")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.showCopyFeedback ? .green : .blue)
            
            Button { viewModel.regenerateOTP() } label: {
                Text("Generate New Code")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Recipient UI
    @ViewBuilder
    private var recipientUI: some View {
        Section {
            VStack(spacing: 20) {
                Text("Enter 6 Digit Code")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("123456", text: $otpInput)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isOTPFieldFocused)
                    .onChange(of: otpInput) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        otpInput = String(filtered.prefix(6))
                        if otpInput.count == 6 {
                            isOTPFieldFocused = false
                            viewModel.validateOTP(otpInput)
                        }
                    }
                    .padding()

                if viewModel.isValidating {
                    ProgressView("Connecting To Sender...")
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                if let peer = viewModel.connectedPeerInfo {
                    VStack(spacing: 16) {
                        Label(peer.deviceName, systemImage: "iphone.gen2")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        
                        Toggle("Trust Device", isOn: $viewModel.trustDevice)

                        Button { viewModel.confirmConnection() } label: {
                            Text("Start Receiving")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(!viewModel.trustDevice)
                    }
                    .padding(.top, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - UI Helpers
    @ViewBuilder
    private func modeToggleCard(mode: OTPPairingMode, title: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.spring()) {
                selectedMode = mode
                viewModel.switchMode(to: mode)
                otpInput = ""
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selectedMode == mode ? color : color.opacity(0.1))
            .foregroundStyle(selectedMode == mode ? .white : color)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func otpDigitCard(char: String, color: Color, isPlaceholder: Bool = false, isFocused: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isPlaceholder ? Color.secondary.opacity(0.1) : color.opacity(0.1))
                .frame(width: 44, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? color : Color.clear, lineWidth: 2)
                )
            
            Text(char)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func statusBadge(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(.caption, design: .rounded, weight: .bold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .cornerRadius(20)
    }
}

// MARK: - OTP Pairing View Model
class OTPPairingViewModel: ObservableObject {
    @Published var otpCode: String = ""
    @Published var timeRemaining: Int = 0
    @Published var isPeerConnected: Bool = false
    @Published var isWaitingForRecipient: Bool = false
    @Published var isValidating: Bool = false
    @Published var errorMessage: String?
    @Published var connectedPeerInfo: (deviceName: String, peerId: MCPeerID)?
    @Published var trustDevice: Bool = false
    @Published var transferStarted: Bool = false
    @Published var showCopyFeedback: Bool = false
    
    let otpLength: Int = 6
    let otpExpirationSeconds: Int = 300 // 5 minutes - shared with NearbyTransferService
    
    var transferService = NearbyTransferService()
    private var otpTimer: Timer?
    private var currentMode: OTPPairingMode = .sender
    private var otpStartTime: Date?
    private var otpStorage: [String: (otp: String, timestamp: Date)] = [:] // In-memory temporary storage
    
    var expirationColor: Color {
        if timeRemaining > 60 { return .green } else if timeRemaining > 30 { return .orange } else { return .red }
    }
    
    func setup() {
        if currentMode == .sender { generateOTP(); startAdvertising() } else { startBrowsing() }
    }
    
    func switchMode(to mode: OTPPairingMode) {
        cleanup(); currentMode = mode; setup()
    }
    
    func cleanup() {
        otpTimer?.invalidate(); otpTimer = nil; transferService.stop(); isPeerConnected = false; isWaitingForRecipient = false; connectedPeerInfo = nil; errorMessage = nil
    }
    
    // MARK: - Sender Methods
    
    func generateOTP() {
        let otp = String(format: "%0\(otpLength)d", Int.random(in: 0..<Int(pow(10.0, Double(otpLength)))))
        otpCode = otp; otpStartTime = Date(); timeRemaining = otpExpirationSeconds; isWaitingForRecipient = true
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        otpStorage[deviceID] = (otp: otp, timestamp: Date())
        transferService.setOTP(otp)
        startTimer()
    }
    
    func regenerateOTP() { generateOTP(); startAdvertising() }
    
    private func startTimer() {
        otpTimer?.invalidate()
        otpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.otpStartTime else { return }
            let elapsed = Int(Date().timeIntervalSince(startTime))
            self.timeRemaining = max(0, self.otpExpirationSeconds - elapsed)
            if self.timeRemaining == 0 { self.otpTimer?.invalidate(); self.regenerateOTP() }
        }
    }
    
    private func startAdvertising() {
        transferService.startReceiveMode(); isWaitingForRecipient = true
    }
    
    // MARK: - Recipient Methods
    
    private func startBrowsing() { transferService.startSendMode() }
    
    func validateOTP(_ code: String) {
        isValidating = true; errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if let matchingPeer = self.transferService.findPeerWithOTP(code) {
                self.connectedPeerInfo = (deviceName: matchingPeer.displayName, peerId: matchingPeer); self.isValidating = false; self.errorMessage = nil

                // Record session as authenticated (Remote method)
                SecureTransferSessionManager.shared.recordSessionAuthenticated(method: "Remote", remoteDeviceName: matchingPeer.displayName)
            } else {
                self.errorMessage = "Invalid or expired code. Please get your sender's device to generate it again."; self.isValidating = false; self.connectedPeerInfo = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in self?.errorMessage = nil }
            }
        }
    }
    
    func confirmConnection() {
        guard let peerInfo = connectedPeerInfo else { return }
        transferService.currentPairingMethod = "Remote"
        transferService.connect(to: peerInfo.peerId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPeerConnected = true; self?.transferStarted = true
        }
    }
}
