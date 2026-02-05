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
    @StateObject private var viewModel = OTPPairingViewModel()
    @State private var selectedMode: OTPPairingMode = .sender
    @State private var otpInput: String = ""
    @State private var showingTransfer = false
    @FocusState private var isOTPFieldFocused: Bool
    
    // Delay to allow view to fully render before focusing keyboard
    private let keyboardFocusDelay: TimeInterval = 0.5
    
    var body: some View {
        NBList(.localized("Remote Pairing")) {
            // Mode Selection
            Section {
                Picker("Mode", selection: $selectedMode) {
                    Text("Sender").tag(OTPPairingMode.sender)
                    Text("Recipient").tag(OTPPairingMode.recipient)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { newMode in
                    viewModel.switchMode(to: newMode)
                    otpInput = ""
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Pairing Mode"), icon: "person.2.fill")
            }
            
            // Guidance Text
            Section {
                guidanceTextView
            } header: {
                AppearanceSectionHeader(title: String.localized("Instructions"), icon: "info.circle.fill")
            }
            
            // Sender UI
            if selectedMode == .sender {
                senderSection
            }
            
            // Recipient UI
            if selectedMode == .recipient {
                recipientSection
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
            }
        }
        .sheet(isPresented: $showingTransfer) {
            NavigationStack {
                TransferProgressView(
                    service: viewModel.transferService,
                    onCancel: {
                        viewModel.transferService.cancelTransfer()
                    },
                    onRetry: {
                        // Retry logic handled by service
                    }
                )
                .navigationTitle("Transfer Progress")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            viewModel.setup()
        }
        .onChange(of: viewModel.transferStarted) { started in
            if started {
                showingTransfer = true
            }
        }
    }
    
    // MARK: - Guidance Text
    @ViewBuilder
    private var guidanceTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selectedMode == .sender {
                Text("Share this code with your other device. It expires shortly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enter the code from the sender to connect securely.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Modern Sender Section
    @ViewBuilder
    private var senderSection: some View {
        Section {
            VStack(spacing: 24) {
                // Modern OTP Display with gradient
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.otpCode.enumerated()), id: \.offset) { index, char in
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 54, height: 70)
                                    .shadow(color: Color.blue.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Text(String(char))
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Modern Expiration Countdown
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(viewModel.expirationColor.opacity(0.15))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "clock.fill")
                                .foregroundStyle(viewModel.expirationColor)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        Text("Expires in \(viewModel.timeRemaining)s")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(viewModel.expirationColor)
                    }
                }
                
                // Connection Status
                if viewModel.isPeerConnected {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text("Recipient connected")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.08))
                    )
                } else if viewModel.isWaitingForRecipient {
                    // Waiting State with modern styling
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.blue)
                        
                        Text("Waiting for recipient...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.05))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } header: {
            AppearanceSectionHeader(title: String.localized("Your Code"), icon: "key.fill")
        } footer: {
            Text("Share this code with the receiving device. The code will expire in \(viewModel.otpExpirationSeconds) seconds.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Modern Action Buttons
        Section {
            Button {
                UIPasteboard.general.string = viewModel.otpCode
                // Could add a toast notification here
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Copy Code")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .disabled(viewModel.otpCode.isEmpty || viewModel.isPeerConnected)
            
            Button {
                viewModel.regenerateOTP()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Generate New Code")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .disabled(viewModel.isPeerConnected)
        }
    }
    
    // MARK: - Modern Recipient Section
    @ViewBuilder
    private var recipientSection: some View {
        Section {
            VStack(spacing: 20) {
                // Modern OTP Input with gradient
                HStack(spacing: 10) {
                    ForEach(0..<viewModel.otpLength, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    index < otpInput.count
                                        ? LinearGradient(
                                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.secondary.opacity(0.08), Color.secondary.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 54, height: 70)
                                .shadow(color: index == otpInput.count ? Color.blue.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 2)
                            
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(index == otpInput.count ? Color.blue : Color.clear, lineWidth: 2.5)
                                .frame(width: 54, height: 70)
                            
                            Text(index < otpInput.count ? String(Array(otpInput)[index]) : "")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    index < otpInput.count
                                        ? LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(
                                            colors: [.secondary.opacity(0.3), .secondary.opacity(0.3)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                )
                        }
                    }
                }
                .onTapGesture {
                    // Focus on the hidden text field when tapping on the code display
                    isOTPFieldFocused = true
                }
                .padding(.vertical, 8)
                
                // Keypad or TextField
                TextField("", text: $otpInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .frame(height: 0)
                    .opacity(0)
                    .focused($isOTPFieldFocused)
                    .onChange(of: otpInput) { newValue in
                        // Limit input to OTP length
                        if newValue.count > viewModel.otpLength {
                            otpInput = String(newValue.prefix(viewModel.otpLength))
                        }
                        // Auto-validate when complete
                        if otpInput.count == viewModel.otpLength {
                            viewModel.validateOTP(otpInput)
                        }
                    }
            }
            .padding(.vertical, 16)
            .onAppear {
                // Auto-focus when the recipient section appears
                DispatchQueue.main.asyncAfter(deadline: .now() + keyboardFocusDelay) {
                    isOTPFieldFocused = true
                }
            }
        } header: {
            AppearanceSectionHeader(title: String.localized("Enter Code"), icon: "keyboard.fill")
        } footer: {
            Text("Enter the \(viewModel.otpLength)-digit code from the sending device")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Paste Button
        Section {
            Button {
                if let pastedText = UIPasteboard.general.string {
                    // Filter to only numbers and limit to OTP length
                    let filtered = pastedText.filter { $0.isNumber }
                    otpInput = String(filtered.prefix(viewModel.otpLength))
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.clipboard.fill")
                    Text("Paste Code")
                }
                .frame(maxWidth: .infinity)
            }
        }
        
        // Validation Status
        if viewModel.isValidating {
            Section {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Validating code...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        
        // Device Preview (after successful validation)
        if let peerInfo = viewModel.connectedPeerInfo {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "iphone")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    
                    Text(peerInfo.deviceName)
                        .font(.headline)
                    
                    Toggle("Trust this device", isOn: $viewModel.trustDevice)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } header: {
                AppearanceSectionHeader(title: String.localized("Sender Device"), icon: "checkmark.shield.fill")
            }
            
            // Confirm Button
            Section {
                Button {
                    viewModel.confirmConnection()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Begin Transfer")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.trustDevice)
            }
        }
        
        // Error Display
        if let error = viewModel.errorMessage {
            Section {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
        }
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
    
    let otpLength: Int = 6
    let otpExpirationSeconds: Int = 300 // 5 minutes - shared with NearbyTransferService
    
    var transferService = NearbyTransferService()
    private var otpTimer: Timer?
    private var currentMode: OTPPairingMode = .sender
    private var otpStartTime: Date?
    private var otpStorage: [String: (otp: String, timestamp: Date)] = [:] // In-memory temporary storage
    
    var expirationColor: Color {
        if timeRemaining > 60 {
            return .green
        } else if timeRemaining > 30 {
            return .orange
        } else {
            return .red
        }
    }
    
    func setup() {
        if currentMode == .sender {
            generateOTP()
            startAdvertising()
        } else {
            startBrowsing()
        }
    }
    
    func switchMode(to mode: OTPPairingMode) {
        cleanup()
        currentMode = mode
        setup()
    }
    
    func cleanup() {
        otpTimer?.invalidate()
        otpTimer = nil
        transferService.stop()
        isPeerConnected = false
        isWaitingForRecipient = false
        connectedPeerInfo = nil
        errorMessage = nil
    }
    
    // MARK: - Sender Methods
    
    func generateOTP() {
        // Generate a random 6-8 digit OTP
        let otp = String(format: "%0\(otpLength)d", Int.random(in: 0..<Int(pow(10.0, Double(otpLength)))))
        otpCode = otp
        otpStartTime = Date()
        timeRemaining = otpExpirationSeconds
        isWaitingForRecipient = true
        
        // Store OTP in memory with timestamp
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        otpStorage[deviceID] = (otp: otp, timestamp: Date())
        
        // Also set OTP in the transfer service for advertising
        transferService.setOTP(otp)
        
        startTimer()
    }
    
    func regenerateOTP() {
        generateOTP()
        startAdvertising()
    }
    
    private func startTimer() {
        otpTimer?.invalidate()
        otpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.otpStartTime else { return }
            
            let elapsed = Int(Date().timeIntervalSince(startTime))
            self.timeRemaining = max(0, self.otpExpirationSeconds - elapsed)
            
            if self.timeRemaining == 0 {
                self.otpTimer?.invalidate()
                self.regenerateOTP()
            }
        }
    }
    
    private func startAdvertising() {
        transferService.startReceiveMode()
        isWaitingForRecipient = true
        
        // Monitor for peer connections
        observeConnections()
    }
    
    private func observeConnections() {
        // This would be called when a peer connects successfully
        // The actual connection state is managed by the MCSession delegate
    }
    
    // MARK: - Recipient Methods
    
    private func startBrowsing() {
        transferService.startSendMode()
    }
    
    func validateOTP(_ code: String) {
        isValidating = true
        errorMessage = nil
        
        // Small delay to show the validation UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Query discovered peers for matching OTP
            if let matchingPeer = self.transferService.findPeerWithOTP(code) {
                // Valid OTP found - show peer info
                self.connectedPeerInfo = (deviceName: matchingPeer.displayName, peerId: matchingPeer)
                self.isValidating = false
                self.errorMessage = nil
            } else {
                // No matching OTP found
                self.errorMessage = "Invalid or expired code. Please try again."
                self.isValidating = false
                self.connectedPeerInfo = nil
                
                // Clear error after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    func confirmConnection() {
        guard let peerInfo = connectedPeerInfo else { return }
        
        // Connect to the peer and start transfer
        transferService.connect(to: peerInfo.peerId)
        
        // Monitor connection state changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPeerConnected = true
            self?.transferStarted = true
        }
    }
}
