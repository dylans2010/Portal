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
    
    // MARK: - Sender Section
    @ViewBuilder
    private var senderSection: some View {
        Section {
            VStack(spacing: 20) {
                // OTP Display with modern styling
                HStack(spacing: 8) {
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
                                .frame(width: 50, height: 60)
                            
                            Text(String(char))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
                .padding(.vertical, 12)
                
                // Expiration Countdown with enhanced design
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(viewModel.expirationColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(viewModel.expirationColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Code Expires In")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.timeRemaining)s")
                            .font(.headline)
                            .foregroundStyle(viewModel.expirationColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                )
                
                // Status
                if viewModel.isPeerConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Recipient Connected Successfully")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                // Waiting State
                if viewModel.isWaitingForRecipient && !viewModel.isPeerConnected {
                    HStack(spacing: 8) {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("Waiting For Recipient To Connect...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } header: {
            AppearanceSectionHeader(title: String.localized("Secure Code"), icon: "key.fill")
        } footer: {
            Text("Share this code with the receiving device. The code will expire in \(viewModel.otpExpirationSeconds) seconds for security.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Action Buttons
        Section {
            // Copy Button
            Button {
                UIPasteboard.general.string = viewModel.otpCode
                HapticsManager.shared.success()
                // Show temporary feedback
                withAnimation {
                    viewModel.showCopyFeedback = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        viewModel.showCopyFeedback = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.showCopyFeedback ? "checkmark" : "doc.on.doc.fill")
                    Text(viewModel.showCopyFeedback ? "Copied!" : "Copy Code To Clipboard")
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .disabled(viewModel.otpCode.isEmpty || viewModel.isPeerConnected)
            .buttonStyle(.borderedProminent)
            .tint(viewModel.showCopyFeedback ? .green : .blue)
            
            // Regenerate Button
            Button {
                viewModel.regenerateOTP()
                HapticsManager.shared.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Generate New Code")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isPeerConnected)
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Recipient Section
    @ViewBuilder
    private var recipientSection: some View {
        Section {
            VStack(spacing: 16) {
                // OTP Input with enhanced design
                HStack(spacing: 8) {
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
                                            colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 50, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            index == otpInput.count && isOTPFieldFocused ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            
                            if index < otpInput.count {
                                Text(String(Array(otpInput)[index]))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                    }
                }
                .onTapGesture {
                    isOTPFieldFocused = true
                }
                
                // Hidden TextField for input
                TextField("", text: $otpInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .frame(height: 0)
                    .opacity(0)
                    .focused($isOTPFieldFocused)
                    .onChange(of: otpInput) { newValue in
                        // Limit input to OTP length and only numbers
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > viewModel.otpLength {
                            otpInput = String(filtered.prefix(viewModel.otpLength))
                        } else {
                            otpInput = filtered
                        }
                        
                        // Auto-validate when complete
                        if otpInput.count == viewModel.otpLength {
                            isOTPFieldFocused = false
                            viewModel.validateOTP(otpInput)
                        }
                    }
            }
            .padding(.vertical, 16)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + keyboardFocusDelay) {
                    isOTPFieldFocused = true
                }
            }
        } header: {
            AppearanceSectionHeader(title: String.localized("Enter Code"), icon: "keyboard.fill")
        } footer: {
            Text("Enter the \(viewModel.otpLength) digit numeric code from the sending device. The code will be validated automatically when complete.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Action Buttons
        Section {
            // Paste Button
            Button {
                if let pastedText = UIPasteboard.general.string {
                    let filtered = pastedText.filter { $0.isNumber }
                    otpInput = String(filtered.prefix(viewModel.otpLength))
                    HapticsManager.shared.light()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard.fill")
                    Text("Paste Code From Clipboard")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Clear Button
            if !otpInput.isEmpty {
                Button(role: .destructive) {
                    otpInput = ""
                    isOTPFieldFocused = true
                    viewModel.errorMessage = nil
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear Code")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        
        // Validation Status
        if viewModel.isValidating {
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Validating Code...")
                            .font(.subheadline.weight(.medium))
                        Text("Searching For Sender Device")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        
        // Device Preview (after successful validation)
        if let peerInfo = viewModel.connectedPeerInfo {
            Section {
                VStack(spacing: 16) {
                    // Device icon with success animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "iphone.gen2")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(peerInfo.deviceName)
                            .font(.title3.weight(.semibold))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Verified Sender")
                                .foregroundStyle(.green)
                        }
                        .font(.caption)
                    }
                    
                    // Trust Toggle
                    Toggle(isOn: $viewModel.trustDevice) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trust This Device")
                                .font(.subheadline.weight(.medium))
                            Text("Allow secure data transfer from this sender?")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                    HapticsManager.shared.success()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Begin Receiving Transfer")
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
                .disabled(!viewModel.trustDevice)
                .buttonStyle(.borderedProminent)
                .tint(viewModel.trustDevice ? .green : .gray)
            } footer: {
                if !viewModel.trustDevice {
                    Text("You must trust this device before beginning the backup transfer, trust it then try again.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        
        // Enhanced Error Display
        if let error = viewModel.errorMessage {
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 18))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Validation Failed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    // Helpful suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try These Steps:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Verify the code with the sender device.")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Make sure both devices are on the same network.")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Request a new code if this one has expired.")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 12)
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
    @Published var showCopyFeedback: Bool = false
    
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
                self.errorMessage = "Invalid or expired code. Please get your sender's device to generate it again."
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
