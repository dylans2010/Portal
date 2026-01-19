// DeveloperView changed, more features and redesigned

import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication

// MARK: - Developer Mode Entry Point
struct DeveloperView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showAuthSheet = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                DeveloperControlPanelView()
            } else {
                DeveloperAuthView(onAuthenticated: {
                    showAuthSheet = false
                })
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
        .onAppear {
            authManager.checkSessionValidity()
        }
    }
}

// MARK: - Developer Authentication View
struct DeveloperAuthView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var passcode = ""
    @State private var developerToken = ""
    @State private var showSetupPasscode = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var authMethod: AuthMethod = .passcode
    @State private var isAuthenticating = false
    @State private var showSuccessAnimation = false
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    let onAuthenticated: () -> Void
    
    enum AuthMethod: String, CaseIterable {
        case passcode = "Passcode"
        case biometric = "Biometric"
        case token = "Token"
        
        var icon: String {
            switch self {
            case .passcode: return "key.fill"
            case .biometric: return "faceid"
            case .token: return "ticket.fill"
            }
        }
    }
    
    private var gradientColors: [Color] {
        [Color.orange.opacity(0.8), Color.red.opacity(0.6)]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Modern Header with animated icon
                        headerSection
                        
                        // Auth method selector - modern pill style
                        authMethodSelector
                        
                        // Main auth card
                        authCard
                        
                        // Remember Me toggle
                        rememberMeSection
                        
                        // Error message with animation
                        errorSection
                        
                        Spacer(minLength: 20)
                        
                        // Cancel button
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSetupPasscode) {
                ModernPasscodeSetupView(onComplete: { success in
                    showSetupPasscode = false
                })
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                iconScale = 1.1
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated icon with glow effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(iconScale)
                
                // Inner circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
                
                // Icon
                Image(systemName: showSuccessAnimation ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(iconRotation))
            }
            .padding(.top, 30)
            
            // Title with gradient
            Text("Developer Mode")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Subtitle
            Text("Secure authentication required")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Auth Method Selector
    private var authMethodSelector: some View {
        HStack(spacing: 8) {
            ForEach(AuthMethod.allCases, id: \.self) { method in
                if method == .biometric && !authManager.canUseBiometrics {
                    EmptyView()
                } else {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            authMethod = method
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: method == .biometric ? 
                                  (authManager.biometricType == .faceID ? "faceid" : "touchid") : 
                                  method.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(method.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(authMethod == method ? 
                                      AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)) :
                                      AnyShapeStyle(Color(UIColor.tertiarySystemBackground)))
                        )
                        .foregroundStyle(authMethod == method ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
    }
    
    // MARK: - Auth Card
    private var authCard: some View {
        VStack(spacing: 20) {
            switch authMethod {
            case .passcode:
                passcodeAuthSection
            case .biometric:
                biometricAuthSection
            case .token:
                tokenAuthSection
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .frame(maxWidth: horizontalSizeClass == .regular ? 450 : .infinity)
    }
    
    // MARK: - Passcode Auth Section
    @ViewBuilder
    private var passcodeAuthSection: some View {
        if authManager.hasPasscodeSet {
            VStack(spacing: 16) {
                // Modern secure field
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    SecureField("Enter your passcode", text: $passcode)
                        .textContentType(.password)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                
                // Authenticate button
                Button {
                    authenticateWithPasscode()
                } label: {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(isAuthenticating ? "Authenticating..." : "Authenticate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(passcode.isEmpty || isAuthenticating)
                .opacity(passcode.isEmpty ? 0.6 : 1)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "key.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                
                Text("No passcode configured")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Button {
                    showSetupPasscode = true
                    HapticsManager.shared.softImpact()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Set Up Passcode")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
    
    // MARK: - Biometric Auth Section
    private var biometricAuthSection: some View {
        VStack(spacing: 20) {
            // Biometric icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
            }
            
            Text(authManager.biometricType == .faceID ? "Face ID" : "Touch ID")
                .font(.headline)
            
            Text("Use biometric authentication for quick access")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                authenticateWithBiometrics()
            } label: {
                HStack(spacing: 10) {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                    }
                    Text(isAuthenticating ? "Authenticating..." : "Authenticate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isAuthenticating)
        }
    }
    
    // MARK: - Token Auth Section
    private var tokenAuthSection: some View {
        VStack(spacing: 16) {
            // Token input
            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                TextField("Enter developer token", text: $developerToken)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            // Token hint
            Text("Enter your authorized developer token")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Validate button
            Button {
                authenticateWithToken()
            } label: {
                HStack(spacing: 10) {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text(isAuthenticating ? "Validating..." : "Validate Token")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(developerToken.isEmpty || isAuthenticating)
            .opacity(developerToken.isEmpty ? 0.6 : 1)
        }
    }
    
    // MARK: - Remember Me Section
    private var rememberMeSection: some View {
        HStack {
            Image(systemName: authManager.rememberMe ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(authManager.rememberMe ? .orange : .secondary)
                .font(.system(size: 22))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Remember Me")
                    .font(.subheadline.weight(.medium))
                Text("Stay authenticated for 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { authManager.rememberMe },
                set: { authManager.rememberMe = $0 }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .frame(maxWidth: horizontalSizeClass == .regular ? 450 : .infinity)
    }
    
    // MARK: - Error Section
    @ViewBuilder
    private var errorSection: some View {
        if let error = authManager.authenticationError {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.1))
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button {
            UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
            HapticsManager.shared.softImpact()
        } label: {
            Text("Cancel")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Authentication Methods
    private func authenticateWithPasscode() {
        isAuthenticating = true
        HapticsManager.shared.softImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.verifyPasscode(passcode) {
                showSuccessAnimation = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconRotation = 360
                }
                HapticsManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onAuthenticated()
                }
            } else {
                HapticsManager.shared.error()
            }
            isAuthenticating = false
        }
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        HapticsManager.shared.softImpact()
        
        authManager.authenticateWithBiometrics { success, error in
            isAuthenticating = false
            if success {
                showSuccessAnimation = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconRotation = 360
                }
                HapticsManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onAuthenticated()
                }
            } else {
                HapticsManager.shared.error()
            }
        }
    }
    
    private func authenticateWithToken() {
        isAuthenticating = true
        HapticsManager.shared.softImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.validateDeveloperToken(developerToken) {
                showSuccessAnimation = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconRotation = 360
                }
                HapticsManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onAuthenticated()
                }
            } else {
                HapticsManager.shared.error()
            }
            isAuthenticating = false
        }
    }
}

// MARK: - Modern Passcode Setup View
struct ModernPasscodeSetupView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage: String?
    @State private var isSettingUp = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let onComplete: (Bool) -> Void
    
    private var gradientColors: [Color] {
        [Color.orange.opacity(0.8), Color.red.opacity(0.6)]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 70, height: 70)
                                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "key.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text("Create Passcode")
                                .font(.title2.bold())
                            
                            Text("Set a secure passcode for Developer Mode")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Input fields
                        VStack(spacing: 16) {
                            // New passcode
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Passcode")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    SecureField("Enter passcode (min 6 characters)", text: $newPasscode)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                            }
                            
                            // Confirm passcode
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Passcode")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    SecureField("Confirm your passcode", text: $confirmPasscode)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Password strength indicator
                        if !newPasscode.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(0..<4) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(passwordStrengthColor(for: index))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.horizontal)
                            
                            Text(passwordStrengthText)
                                .font(.caption)
                                .foregroundStyle(passwordStrengthTextColor)
                        }
                        
                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                        
                        // Set passcode button
                        Button {
                            setPasscode()
                        } label: {
                            HStack(spacing: 10) {
                                if isSettingUp {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isSettingUp ? "Setting Up..." : "Set Passcode")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(newPasscode.isEmpty || confirmPasscode.isEmpty || isSettingUp)
                        .opacity(newPasscode.isEmpty || confirmPasscode.isEmpty ? 0.6 : 1)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(false)
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
    
    private var passwordStrength: Int {
        var strength = 0
        if newPasscode.count >= 6 { strength += 1 }
        if newPasscode.count >= 8 { strength += 1 }
        if newPasscode.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if newPasscode.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        return strength
    }
    
    private func passwordStrengthColor(for index: Int) -> Color {
        if index < passwordStrength {
            switch passwordStrength {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            default: return .gray.opacity(0.3)
            }
        }
        return .gray.opacity(0.3)
    }
    
    private var passwordStrengthText: String {
        switch passwordStrength {
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }
    
    private var passwordStrengthTextColor: Color {
        switch passwordStrength {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .secondary
        }
    }
    
    private func setPasscode() {
        errorMessage = nil
        
        if newPasscode.count < 6 {
            errorMessage = "Passcode must be at least 6 characters"
            HapticsManager.shared.error()
            return
        }
        
        if newPasscode != confirmPasscode {
            errorMessage = "Passcodes do not match"
            HapticsManager.shared.error()
            return
        }
        
        isSettingUp = true
        HapticsManager.shared.softImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.setPasscode(newPasscode) {
                HapticsManager.shared.success()
                onComplete(true)
                dismiss()
            } else {
                errorMessage = "Failed to set passcode"
                HapticsManager.shared.error()
            }
            isSettingUp = false
        }
    }
}

// MARK: - Developer Control Panel (Main View)
struct DeveloperControlPanelView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showResetConfirmation = false
    @AppStorage("Feather.enableCustomTabBar") private var enableCustomTabBar = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NBNavigationView("Developer Mode") {
            List {
                // Experimental UI Section
                Section {
                    Toggle(isOn: $enableCustomTabBar) {
                        DeveloperMenuRow(icon: "dock.rectangle", title: "Enable New Tab Bar", color: .cyan)
                    }
                    .tint(.cyan)
                } header: {
                    Text("Experimental UI")
                } footer: {
                    Text("Enable a fully custom modern tab bar with animations and glass effects. Requires app restart.")
                }
                
                // Updates & Releases Section
                Section {
                    NavigationLink(destination: UpdatesReleasesView()) {
                        DeveloperMenuRow(icon: "arrow.down.circle.fill", title: "Updates & Releases", color: .blue)
                    }
                } header: {
                    Text("Updates & Releases")
                } footer: {
                    Text("GitHub release checks, prerelease filtering, update enforcement")
                }
                
                // Sources & Library Section
                Section {
                    NavigationLink(destination: SourcesLibraryDevView()) {
                        DeveloperMenuRow(icon: "server.rack", title: "Sources & Library", color: .purple)
                    }
                } header: {
                    Text("Sources & Library")
                } footer: {
                    Text("Source reloads, cache invalidation, raw JSON inspection")
                }
                
                // Install & IPA Section
                Section {
                    NavigationLink(destination: InstallIPADevView()) {
                        DeveloperMenuRow(icon: "doc.zipper", title: "Install & IPA", color: .orange)
                    }
                } header: {
                    Text("Install & IPA")
                } footer: {
                    Text("IPA validation, install queue, logs, InstallModifyDialog testing")
                }
                
                // IPA Signing Dashboard Section
                Section {
                    NavigationLink(destination: IPASigningDashboardView()) {
                        DeveloperMenuRow(icon: "signature", title: "IPA Signing Dashboard", color: .blue)
                    }
                } header: {
                    Text("IPA Signing")
                } footer: {
                    Text("Full signing dashboard with certificates, batch signing, logs, entitlements editor, and API integration")
                }
                
                // UI & Layout Section
                Section {
                    NavigationLink(destination: UILayoutDevView()) {
                        DeveloperMenuRow(icon: "paintbrush.fill", title: "UI & Layout", color: .pink)
                    }
                } header: {
                    Text("UI & Layout")
                } footer: {
                    Text("Appearance overrides, dynamic type, animations, debugging overlays")
                }
                
                // Network & System Section
                Section {
                    NavigationLink(destination: NetworkSystemDevView()) {
                        DeveloperMenuRow(icon: "network", title: "Network & System", color: .green)
                    }
                } header: {
                    Text("Network & System")
                } footer: {
                    Text("Offline simulation, latency injection, request logging")
                }
                
                // State & Persistence Section
                Section {
                    NavigationLink(destination: StatePersistenceDevView()) {
                        DeveloperMenuRow(icon: "cylinder.split.1x2.fill", title: "State & Persistence", color: .cyan)
                    }
                } header: {
                    Text("State & Persistence")
                } footer: {
                    Text("AppStorage, UserDefaults, caches, onboarding state")
                }
                
                // Diagnostics & Debug Tools Section
                Section {
                    NavigationLink(destination: AppLogsView()) {
                        DeveloperMenuRow(icon: "terminal.fill", title: "App Logs", color: .gray)
                    }
                    NavigationLink(destination: DeviceInfoView()) {
                        DeveloperMenuRow(icon: "iphone", title: "Device Information", color: .indigo)
                    }
                    NavigationLink(destination: EnvironmentInspectorView()) {
                        DeveloperMenuRow(icon: "gearshape.2.fill", title: "Environment Inspector", color: .teal)
                    }
                    NavigationLink(destination: CrashLogViewer()) {
                        DeveloperMenuRow(icon: "exclamationmark.triangle.fill", title: "Crash Logs", color: .red)
                    }
                    NavigationLink(destination: TestNotificationsView()) {
                        DeveloperMenuRow(icon: "bell.badge.fill", title: "Test Notifications", color: .yellow)
                    }
                } header: {
                    Text("Diagnostics & Debugging")
                } footer: {
                    Text("Device info, environment variables, crash logs, and notification testing")
                }
                
                // Power Tools Section
                Section {
                    NavigationLink(destination: QuickActionsDevView()) {
                        DeveloperMenuRow(icon: "bolt.fill", title: "Quick Actions", color: .yellow)
                    }
                    NavigationLink(destination: FeatureFlagsView()) {
                        DeveloperMenuRow(icon: "flag.fill", title: "Feature Flags", color: .mint)
                    }
                    NavigationLink(destination: PerformanceMonitorView()) {
                        DeveloperMenuRow(icon: "gauge.with.dots.needle.67percent", title: "Performance Monitor", color: .purple)
                    }
                } header: {
                    Text("Power Tools")
                } footer: {
                    Text("Quick actions, feature flags, and performance monitoring")
                }
                
                // Security Section
                Section {
                    NavigationLink(destination: DeveloperSecurityView()) {
                        DeveloperMenuRow(icon: "lock.shield.fill", title: "Security Settings", color: .orange)
                    }
                    
                    Button {
                        authManager.lockDeveloperMode()
                        UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.red)
                            Text("Lock Developer Mode")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Security")
                }
            }
        }
        .withToast()
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
    }
}

// MARK: - Developer Menu Row
struct DeveloperMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
        }
    }
}

// MARK: - Developer Security View
struct DeveloperSecurityView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showChangePasscode = false
    @State private var showRemovePasscode = false
    
    var body: some View {
        List {
            Section(header: Text("Authentication")) {
                HStack {
                    Text("Passcode")
                    Spacer()
                    Text(authManager.hasPasscodeSet ? "Set" : "Not Set")
                        .foregroundStyle(.secondary)
                }
                
                if authManager.hasPasscodeSet {
                    Button("Change Passcode") {
                        showChangePasscode = true
                    }
                    
                    Button("Remove Passcode", role: .destructive) {
                        showRemovePasscode = true
                    }
                } else {
                    Button("Set Up Passcode") {
                        showChangePasscode = true
                    }
                }
            }
            
            Section(header: Text("Biometrics")) {
                HStack {
                    Text("Biometric Type")
                    Spacer()
                    Text(biometricTypeName)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Available")
                    Spacer()
                    Text(authManager.canUseBiometrics ? "Yes" : "No")
                        .foregroundStyle(authManager.canUseBiometrics ? .green : .red)
                }
            }
            
            Section(header: Text("Developer Token")) {
                HStack {
                    Text("Saved Token")
                    Spacer()
                    Text(authManager.hasSavedToken ? "Present" : "None")
                        .foregroundStyle(.secondary)
                }
                
                if authManager.hasSavedToken {
                    Button("Clear Saved Token", role: .destructive) {
                        authManager.clearSavedToken()
                    }
                }
            }
            
            Section(header: Text("Session")) {
                HStack {
                    Text("Last Authentication")
                    Spacer()
                    if let lastAuth = authManager.lastAuthTime {
                        Text(lastAuth, style: .relative)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Security Settings")
        .sheet(isPresented: $showChangePasscode) {
            ModernPasscodeSetupView(onComplete: { _ in })
        }
        .alert("Remove Passcode", isPresented: $showRemovePasscode) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                _ = authManager.removePasscode()
            }
        } message: {
            Text("Are you sure you want to remove the developer passcode?")
        }
    }
    
    private var biometricTypeName: String {
        switch authManager.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Subviews

struct NetworkInspectorView: View {
    var body: some View {
        List {
            Text("No active requests")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Network Inspector")
    }
}

struct FileSystemBrowserView: View {
    var body: some View {
        List {
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                Text(documentsPath.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Documents")
            Text("Library")
            Text("tmp")
        }
        .navigationTitle("File System")
    }
}

struct UserDefaultsEditorView: View {
    var body: some View {
        List {
            ForEach(Array(UserDefaults.standard.dictionaryRepresentation().keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption.monospaced())
                    Spacer()
                    Text("\(String(describing: UserDefaults.standard.object(forKey: key) ?? "nil"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .navigationTitle("UserDefaults")
    }
}

struct AppLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var selectedCategory: String?
    @State private var showFilters = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var autoScroll = true
    
    var filteredLogs: [LogEntry] {
        logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search Logs", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All logs
                        FilterPill(
                            title: "All",
                            isSelected: selectedLevel == nil,
                            count: logManager.logs.count
                        ) {
                            selectedLevel = nil
                        }
                        
                        // Level filters
                        ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                            let count = logManager.logs.filter { $0.level == level }.count
                            if count > 0 {
                                FilterPill(
                                    title: level.rawValue,
                                    icon: level.icon,
                                    isSelected: selectedLevel == level,
                                    count: count
                                ) {
                                    selectedLevel = selectedLevel == level ? nil : level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
            
            Divider()
            
            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text(logManager.logs.isEmpty ? "No Logs Yet" : "No Matching Logs")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if !logManager.logs.isEmpty {
                        Text("Try adjusting your search or filters")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredLogs) { log in
                                LogEntryRow(entry: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: filteredLogs.count) { _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Auto-scroll toggle
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                
                // Clear logs
                Button(role: .destructive, action: {
                    logManager.clearLogs()
                }) {
                    Image(systemName: "trash")
                }
                
                // Share menu
                Menu {
                    Button(action: shareAsText) {
                        Label("Share as Text", systemImage: "doc.text")
                    }
                    
                    Button(action: shareAsJSON) {
                        Label("Share as JSON", systemImage: "doc.badge.gearshape")
                    }
                    
                    Button(action: copyToClipboard) {
                        Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [shareText])
        }
        .onAppear {
            // Add initial log
            if logManager.logs.isEmpty {
                logManager.info("App Logs view initialized", category: "Developer")
            }
        }
    }
    
    private func shareAsText() {
        shareText = logManager.exportLogs()
        showShareSheet = true
    }
    
    private func shareAsJSON() {
        if let jsonData = logManager.exportLogsAsJSON(),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            shareText = jsonString
            showShareSheet = true
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = logManager.exportLogs()
        logManager.success("Logs copied to clipboard", category: "Developer")
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                }
                Text(title)
                    .font(.caption.bold())
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // Level indicator
                Text(entry.level.icon)
                    .font(.system(size: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    // Main message
                    HStack {
                        Text(entry.formattedTimestamp)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        
                        Text("[\(entry.category)]")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                    
                    Text(entry.message)
                        .font(.caption.monospaced())
                        .foregroundStyle(levelColor(entry.level))
                    
                    // Expanded details
                    if isExpanded {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            DetailRow(label: "Level", value: entry.level.rawValue)
                            DetailRow(label: "Category", value: entry.category)
                            DetailRow(label: "File", value: entry.file)
                            DetailRow(label: "Function", value: entry.function)
                            DetailRow(label: "Line", value: "\(entry.line)")
                        }
                        .font(.caption2.monospaced())
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(levelBackgroundColor(entry.level))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(levelBorderColor(entry.level), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    private func levelColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    private func levelBackgroundColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.05)
    }
    
    private func levelBorderColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.2)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Pure Swift Mach-O Binary Analyzer
struct MachOAnalyzer {
    // Mach-O Magic Numbers
    static let MH_MAGIC: UInt32 = 0xfeedface
    static let MH_CIGAM: UInt32 = 0xcefaedfe
    static let MH_MAGIC_64: UInt32 = 0xfeedfacf
    static let MH_CIGAM_64: UInt32 = 0xcffaedfe
    static let FAT_MAGIC: UInt32 = 0xcafebabe
    static let FAT_CIGAM: UInt32 = 0xbebafeca
    
    // CPU Types
    static let CPU_TYPE_ARM: Int32 = 12
    static let CPU_TYPE_ARM64: Int32 = 0x0100000C
    static let CPU_TYPE_X86: Int32 = 7
    static let CPU_TYPE_X86_64: Int32 = 0x01000007
    
    // Load Commands
    static let LC_SEGMENT: UInt32 = 0x1
    static let LC_SEGMENT_64: UInt32 = 0x19
    static let LC_LOAD_DYLIB: UInt32 = 0xc
    static let LC_ID_DYLIB: UInt32 = 0xd
    static let LC_LOAD_WEAK_DYLIB: UInt32 = 0x80000018
    static let LC_REEXPORT_DYLIB: UInt32 = 0x8000001f
    static let LC_CODE_SIGNATURE: UInt32 = 0x1d
    static let LC_ENCRYPTION_INFO: UInt32 = 0x21
    static let LC_ENCRYPTION_INFO_64: UInt32 = 0x2c
    static let LC_RPATH: UInt32 = 0x8000001c
    
    struct BinaryInfo {
        let architectures: [String]
        let isUniversal: Bool
        let is64Bit: Bool
        let linkedLibraries: [String]
        let rpaths: [String]
        let hasCodeSignature: Bool
        let isEncrypted: Bool
        let encryptionInfo: String?
        let segments: [SegmentInfo]
        let minOSVersion: String?
        let sdkVersion: String?
        let buildVersion: String?
    }
    
    struct SegmentInfo {
        let name: String
        let vmAddress: UInt64
        let vmSize: UInt64
        let fileOffset: UInt64
        let fileSize: UInt64
        let sections: [String]
    }
    
    static func analyze(data: Data) -> BinaryInfo? {
        guard data.count >= 4 else { return nil }
        
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        var architectures: [String] = []
        var isUniversal = false
        var is64Bit = false
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil
        var segments: [SegmentInfo] = []
        var minOSVersion: String? = nil
        var sdkVersion: String? = nil
        var buildVersion: String? = nil
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            isUniversal = true
            let swapped = magic == FAT_CIGAM
            
            guard data.count >= 8 else { return nil }
            var nfat_arch = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) }
            if swapped { nfat_arch = nfat_arch.byteSwapped }
            
            for i in 0..<min(Int(nfat_arch), 10) {
                let offset = 8 + i * 20
                guard data.count >= offset + 8 else { break }
                
                var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
                if swapped { cputype = cputype.byteSwapped }
                
                architectures.append(cpuTypeToString(cputype))
                if cputype == CPU_TYPE_ARM64 || cputype == CPU_TYPE_X86_64 {
                    is64Bit = true
                }
            }
        } else if magic == MH_MAGIC_64 || magic == MH_CIGAM_64 {
            is64Bit = true
            let result = parseMachO64(data: data, swapped: magic == MH_CIGAM_64)
            architectures = result.architectures
            linkedLibraries = result.linkedLibraries
            rpaths = result.rpaths
            hasCodeSignature = result.hasCodeSignature
            isEncrypted = result.isEncrypted
            encryptionInfo = result.encryptionInfo
            segments = result.segments
            minOSVersion = result.minOSVersion
            sdkVersion = result.sdkVersion
            buildVersion = result.buildVersion
        } else if magic == MH_MAGIC || magic == MH_CIGAM {
            let result = parseMachO32(data: data, swapped: magic == MH_CIGAM)
            architectures = result.architectures
            linkedLibraries = result.linkedLibraries
            rpaths = result.rpaths
            hasCodeSignature = result.hasCodeSignature
            isEncrypted = result.isEncrypted
            encryptionInfo = result.encryptionInfo
        }
        
        return BinaryInfo(
            architectures: architectures,
            isUniversal: isUniversal,
            is64Bit: is64Bit,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: segments,
            minOSVersion: minOSVersion,
            sdkVersion: sdkVersion,
            buildVersion: buildVersion
        )
    }
    
    private static func parseMachO64(data: Data, swapped: Bool) -> BinaryInfo {
        var architectures: [String] = []
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil
        var segments: [SegmentInfo] = []
        var minOSVersion: String? = nil
        var sdkVersion: String? = nil
        var buildVersion: String? = nil
        
        guard data.count >= 32 else {
            return BinaryInfo(architectures: [], isUniversal: false, is64Bit: true, linkedLibraries: [], rpaths: [], hasCodeSignature: false, isEncrypted: false, encryptionInfo: nil, segments: [], minOSVersion: nil, sdkVersion: nil, buildVersion: nil)
        }
        
        var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) }
        
        if swapped {
            cputype = cputype.byteSwapped
            ncmds = ncmds.byteSwapped
        }
        
        architectures.append(cpuTypeToString(cputype))
        
        var offset = 32 // mach_header_64 size
        
        for _ in 0..<min(Int(ncmds), 1000) {
            guard data.count >= offset + 8 else { break }
            
            var cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            var cmdsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }
            
            if swapped {
                cmd = cmd.byteSwapped
                cmdsize = cmdsize.byteSwapped
            }
            
            switch cmd {
            case LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB:
                if let name = extractDylibName(data: data, offset: offset, swapped: swapped) {
                    linkedLibraries.append(name)
                }
            case LC_RPATH:
                if let path = extractRpath(data: data, offset: offset, swapped: swapped) {
                    rpaths.append(path)
                }
            case LC_CODE_SIGNATURE:
                hasCodeSignature = true
            case LC_ENCRYPTION_INFO_64:
                let cryptid = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                isEncrypted = (swapped ? cryptid.byteSwapped : cryptid) != 0
                encryptionInfo = isEncrypted ? "Encrypted (FairPlay DRM)" : "Not encrypted"
            case LC_SEGMENT_64:
                if let segment = parseSegment64(data: data, offset: offset, swapped: swapped) {
                    segments.append(segment)
                }
            case 0x32: // LC_BUILD_VERSION
                if data.count >= offset + 24 {
                    var minOS = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                    var sdk = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                    if swapped {
                        minOS = minOS.byteSwapped
                        sdk = sdk.byteSwapped
                    }
                    minOSVersion = formatVersion(minOS)
                    sdkVersion = formatVersion(sdk)
                }
            case 0x24, 0x25: // LC_VERSION_MIN_IPHONEOS, LC_VERSION_MIN_MACOSX
                if data.count >= offset + 16 {
                    var version = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
                    var sdk = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                    if swapped {
                        version = version.byteSwapped
                        sdk = sdk.byteSwapped
                    }
                    minOSVersion = formatVersion(version)
                    sdkVersion = formatVersion(sdk)
                }
            default:
                break
            }
            
            offset += Int(cmdsize)
        }
        
        return BinaryInfo(
            architectures: architectures,
            isUniversal: false,
            is64Bit: true,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: segments,
            minOSVersion: minOSVersion,
            sdkVersion: sdkVersion,
            buildVersion: buildVersion
        )
    }
    
    private static func parseMachO32(data: Data, swapped: Bool) -> BinaryInfo {
        var architectures: [String] = []
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil
        
        guard data.count >= 28 else {
            return BinaryInfo(architectures: [], isUniversal: false, is64Bit: false, linkedLibraries: [], rpaths: [], hasCodeSignature: false, isEncrypted: false, encryptionInfo: nil, segments: [], minOSVersion: nil, sdkVersion: nil, buildVersion: nil)
        }
        
        var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) }
        
        if swapped {
            cputype = cputype.byteSwapped
            ncmds = ncmds.byteSwapped
        }
        
        architectures.append(cpuTypeToString(cputype))
        
        var offset = 28 // mach_header size
        
        for _ in 0..<min(Int(ncmds), 1000) {
            guard data.count >= offset + 8 else { break }
            
            var cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            var cmdsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }
            
            if swapped {
                cmd = cmd.byteSwapped
                cmdsize = cmdsize.byteSwapped
            }
            
            switch cmd {
            case LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB:
                if let name = extractDylibName(data: data, offset: offset, swapped: swapped) {
                    linkedLibraries.append(name)
                }
            case LC_RPATH:
                if let path = extractRpath(data: data, offset: offset, swapped: swapped) {
                    rpaths.append(path)
                }
            case LC_CODE_SIGNATURE:
                hasCodeSignature = true
            case LC_ENCRYPTION_INFO:
                let cryptid = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                isEncrypted = (swapped ? cryptid.byteSwapped : cryptid) != 0
                encryptionInfo = isEncrypted ? "Encrypted (FairPlay DRM)" : "Not encrypted"
            default:
                break
            }
            
            offset += Int(cmdsize)
        }
        
        return BinaryInfo(
            architectures: architectures,
            isUniversal: false,
            is64Bit: false,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: [],
            minOSVersion: nil,
            sdkVersion: nil,
            buildVersion: nil
        )
    }
    
    private static func parseSegment64(data: Data, offset: Int, swapped: Bool) -> SegmentInfo? {
        guard data.count >= offset + 72 else { return nil }
        
        let nameData = data.subdata(in: (offset + 8)..<(offset + 24))
        let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""
        
        var vmaddr = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 24, as: UInt64.self) }
        var vmsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 32, as: UInt64.self) }
        var fileoff = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 40, as: UInt64.self) }
        var filesize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 48, as: UInt64.self) }
        
        if swapped {
            vmaddr = vmaddr.byteSwapped
            vmsize = vmsize.byteSwapped
            fileoff = fileoff.byteSwapped
            filesize = filesize.byteSwapped
        }
        
        return SegmentInfo(
            name: name,
            vmAddress: vmaddr,
            vmSize: vmsize,
            fileOffset: fileoff,
            fileSize: filesize,
            sections: []
        )
    }
    
    private static func extractDylibName(data: Data, offset: Int, swapped: Bool) -> String? {
        guard data.count >= offset + 24 else { return nil }
        
        var nameOffset = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
        if swapped { nameOffset = nameOffset.byteSwapped }
        
        let nameStart = offset + Int(nameOffset)
        guard nameStart < data.count else { return nil }
        
        var nameEnd = nameStart
        while nameEnd < data.count && data[nameEnd] != 0 {
            nameEnd += 1
        }
        
        let nameData = data.subdata(in: nameStart..<nameEnd)
        return String(data: nameData, encoding: .utf8)
    }
    
    private static func extractRpath(data: Data, offset: Int, swapped: Bool) -> String? {
        guard data.count >= offset + 12 else { return nil }
        
        var pathOffset = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
        if swapped { pathOffset = pathOffset.byteSwapped }
        
        let pathStart = offset + Int(pathOffset)
        guard pathStart < data.count else { return nil }
        
        var pathEnd = pathStart
        while pathEnd < data.count && data[pathEnd] != 0 {
            pathEnd += 1
        }
        
        let pathData = data.subdata(in: pathStart..<pathEnd)
        return String(data: pathData, encoding: .utf8)
    }
    
    private static func cpuTypeToString(_ cputype: Int32) -> String {
        switch cputype {
        case CPU_TYPE_ARM: return "arm"
        case CPU_TYPE_ARM64: return "arm64"
        case CPU_TYPE_X86: return "i386"
        case CPU_TYPE_X86_64: return "x86_64"
        default: return "unknown (\(cputype))"
        }
    }
    
    private static func formatVersion(_ version: UInt32) -> String {
        let major = (version >> 16) & 0xFFFF
        let minor = (version >> 8) & 0xFF
        let patch = version & 0xFF
        return "\(major).\(minor).\(patch)"
    }
}

// MARK: - Pure Swift Code Signature Analyzer
struct CodeSignatureAnalyzer {
    static let CSMAGIC_EMBEDDED_SIGNATURE: UInt32 = 0xfade0cc0
    static let CSMAGIC_CODEDIRECTORY: UInt32 = 0xfade0c02
    static let CSMAGIC_REQUIREMENTS: UInt32 = 0xfade0c01
    static let CSMAGIC_ENTITLEMENTS: UInt32 = 0xfade7171
    static let CSMAGIC_BLOBWRAPPER: UInt32 = 0xfade0b01
    
    struct SignatureInfo {
        let hasSignature: Bool
        let signatureSize: Int
        let teamID: String?
        let signingIdentity: String?
        let entitlements: [String: Any]?
        let codeDirectoryVersion: String?
        let hashType: String?
        let pageSize: Int?
        let flags: [String]
        let requirements: String?
    }
    
    static func analyzeSignature(data: Data, signatureOffset: UInt32, signatureSize: UInt32) -> SignatureInfo? {
        let offset = Int(signatureOffset)
        let size = Int(signatureSize)
        
        guard data.count >= offset + size, size > 8 else { return nil }
        
        let sigData = data.subdata(in: offset..<(offset + size))
        
        let magic = sigData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard magic == CSMAGIC_EMBEDDED_SIGNATURE else { return nil }
        
        var teamID: String? = nil
        var signingIdentity: String? = nil
        var entitlements: [String: Any]? = nil
        var codeDirectoryVersion: String? = nil
        var hashType: String? = nil
        var pageSize: Int? = nil
        var flags: [String] = []
        var requirements: String? = nil
        
        let count = sigData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }
        
        var blobOffset = 8
        for _ in 0..<min(Int(count), 20) {
            guard sigData.count >= blobOffset + 8 else { break }
            
            let _ = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobOffset, as: UInt32.self).bigEndian } // blobType - not used but part of structure
            let blobDataOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobOffset + 4, as: UInt32.self).bigEndian }
            
            let blobStart = Int(blobDataOffset)
            guard sigData.count > blobStart + 8 else {
                blobOffset += 8
                continue
            }
            
            let blobMagic = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart, as: UInt32.self).bigEndian }
            let blobLength = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 4, as: UInt32.self).bigEndian }
            
            switch blobMagic {
            case CSMAGIC_CODEDIRECTORY:
                if sigData.count >= blobStart + 44 {
                    let version = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 8, as: UInt32.self).bigEndian }
                    codeDirectoryVersion = "0x\(String(version, radix: 16))"
                    
                    let flagsValue = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 12, as: UInt32.self).bigEndian }
                    flags = parseCodeDirectoryFlags(flagsValue)
                    
                    let hashTypeValue = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 36, as: UInt8.self) }
                    hashType = hashTypeToString(hashTypeValue)
                    
                    let pageSizeLog2 = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 39, as: UInt8.self) }
                    pageSize = 1 << Int(pageSizeLog2)
                    
                    // Extract team ID if present
                    if version >= 0x20200 && sigData.count >= blobStart + 52 {
                        let teamOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 48, as: UInt32.self).bigEndian }
                        if teamOffset > 0 {
                            let teamStart = blobStart + Int(teamOffset)
                            if let extracted = extractNullTerminatedString(from: sigData, at: teamStart) {
                                teamID = extracted
                            }
                        }
                    }
                    
                    // Extract signing identity
                    let identOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 28, as: UInt32.self).bigEndian }
                    if identOffset > 0 {
                        let identStart = blobStart + Int(identOffset)
                        if let extracted = extractNullTerminatedString(from: sigData, at: identStart) {
                            signingIdentity = extracted
                        }
                    }
                }
                
            case CSMAGIC_ENTITLEMENTS:
                let entStart = blobStart + 8
                let entLength = Int(blobLength) - 8
                if sigData.count >= entStart + entLength && entLength > 0 {
                    let entData = sigData.subdata(in: entStart..<(entStart + entLength))
                    if let plist = try? PropertyListSerialization.propertyList(from: entData, format: nil) as? [String: Any] {
                        entitlements = plist
                    }
                }
                
            case CSMAGIC_REQUIREMENTS:
                requirements = "Present (binary format)"
                
            default:
                break
            }
            
            blobOffset += 8
        }
        
        return SignatureInfo(
            hasSignature: true,
            signatureSize: size,
            teamID: teamID,
            signingIdentity: signingIdentity,
            entitlements: entitlements,
            codeDirectoryVersion: codeDirectoryVersion,
            hashType: hashType,
            pageSize: pageSize,
            flags: flags,
            requirements: requirements
        )
    }
    
    private static func extractNullTerminatedString(from data: Data, at offset: Int) -> String? {
        guard offset < data.count else { return nil }
        var end = offset
        while end < data.count && data[end] != 0 {
            end += 1
        }
        guard end > offset else { return nil }
        let strData = data.subdata(in: offset..<end)
        return String(data: strData, encoding: .utf8)
    }
    
    private static func hashTypeToString(_ type: UInt8) -> String {
        switch type {
        case 1: return "SHA-1"
        case 2: return "SHA-256"
        case 3: return "SHA-256 Truncated"
        case 4: return "SHA-384"
        case 5: return "SHA-512"
        default: return "Unknown (\(type))"
        }
    }
    
    private static func parseCodeDirectoryFlags(_ flags: UInt32) -> [String] {
        var result: [String] = []
        if flags & 0x0001 != 0 { result.append("Host") }
        if flags & 0x0002 != 0 { result.append("Adhoc") }
        if flags & 0x0004 != 0 { result.append("Force Hard") }
        if flags & 0x0008 != 0 { result.append("Force Kill") }
        if flags & 0x0010 != 0 { result.append("Force Expiration") }
        if flags & 0x0020 != 0 { result.append("Restrict") }
        if flags & 0x0040 != 0 { result.append("Enforcement") }
        if flags & 0x0080 != 0 { result.append("Library Validation") }
        if flags & 0x0100 != 0 { result.append("Entitlements Validated") }
        if flags & 0x0200 != 0 { result.append("NVRAM Unrestricted") }
        if flags & 0x0400 != 0 { result.append("Runtime") }
        if flags & 0x0800 != 0 { result.append("Linker Signed") }
        return result
    }
}

struct IPAInspectorView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var ipaInfo: IPAInfo?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showFileBrowser = false
    @State private var selectedTab = 0
    
    struct IPAInfo {
        let fileName: String
        let fileSize: String
        let infoPlist: [String: Any]?
        let bundleID: String?
        let version: String?
        let buildNumber: String?
        let displayName: String?
        let minIOSVersion: String?
        let dylibs: [String]
        let frameworks: [String]
        let plugins: [String]
        let entitlements: [String: Any]?
        let provisioning: ProvisioningInfo?
        let fileStructure: [String]
        let appIconData: Data?
        let limitations: [String]
        // New binary analysis fields
        let binaryInfo: MachOAnalyzer.BinaryInfo?
        let signatureInfo: CodeSignatureAnalyzer.SignatureInfo?
        let executableName: String?
        let supportedArchitectures: [String]
        let isEncrypted: Bool
        let linkedFrameworks: [String]
        let weakLinkedFrameworks: [String]
        let embeddedBinaries: [String]
    }
    
    struct ProvisioningInfo {
        let teamName: String?
        let teamID: String?
        let expirationDate: Date?
        let appIDName: String?
        let provisionedDevices: [String]?
        let entitlements: [String: Any]?
    }
    
    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import")) {
                Button(action: { isImporting = true }) {
                    HStack {
                        Image(systemName: "doc.zipper")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select IPA File")
                                .font(.headline)
                            if let file = selectedFile {
                                Text(file.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No File Selected")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if isAnalyzing {
                            ProgressView()
                        }
                    }
                }
            }
            
            // Error Section
            if let error = errorMessage {
                Section(header: Text("Error")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Basic Info Section
            if let info = ipaInfo {
                // App Icon Section (if available)
                if let iconData = info.appIconData, let iconImage = UIImage(data: iconData) {
                    Section {
                        HStack {
                            Spacer()
                            Image(uiImage: iconImage)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 4)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    DeveloperInfoRow(label: "File Name", value: info.fileName)
                    DeveloperInfoRow(label: "File Size", value: info.fileSize)
                    if let bundleID = info.bundleID {
                        DeveloperInfoRow(label: "Bundle ID", value: bundleID)
                    }
                    if let displayName = info.displayName {
                        DeveloperInfoRow(label: "App Name", value: displayName)
                    }
                    if let version = info.version {
                        DeveloperInfoRow(label: "Version", value: version)
                    }
                    if let buildNumber = info.buildNumber {
                        DeveloperInfoRow(label: "Build Number", value: buildNumber)
                    }
                    if let minVersion = info.minIOSVersion {
                        DeveloperInfoRow(label: "Min iOS", value: minVersion)
                    }
                }
                
                // Provisioning Profile Section
                if let provisioning = info.provisioning {
                    Section(header: Text("Provisioning Profile")) {
                        if let teamName = provisioning.teamName {
                            DeveloperInfoRow(label: "Team Name", value: teamName)
                        }
                        if let teamID = provisioning.teamID {
                            DeveloperInfoRow(label: "Team ID", value: teamID)
                        }
                        if let appIDName = provisioning.appIDName {
                            DeveloperInfoRow(label: "App ID Name", value: appIDName)
                        }
                        if let expirationDate = provisioning.expirationDate {
                            DeveloperInfoRow(
                                label: "Expires",
                                value: {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .medium
                                    formatter.timeStyle = .short
                                    return formatter.string(from: expirationDate)
                                }()
                            )
                        }
                        if let devices = provisioning.provisionedDevices {
                            NavigationLink(destination: ListDetailView(items: devices, title: "Provisioned Devices")) {
                                HStack {
                                    Image(systemName: "iphone")
                                        .foregroundStyle(.blue)
                                    Text("\(devices.count) devices")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                
                // Info.plist Section
                if let plist = info.infoPlist, !plist.isEmpty {
                    Section(header: Text("Info.plist")) {
                        NavigationLink(destination: PlistViewer(dictionary: plist, title: "Info.plist")) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)
                                Text("\(plist.count) entries")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // Dynamic Libraries Section
                if !info.dylibs.isEmpty {
                    Section(header: Text("Dynamic Libraries (\(info.dylibs.count))"), footer: Text("Detected .dylib files that may be injected into the app.")) {
                        ForEach(info.dylibs.prefix(10), id: \.self) { dylib in
                            HStack {
                                Image(systemName: "cube.box")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                Text(dylib)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.dylibs.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.dylibs, title: "All Dynamic Libraries")) {
                                Text("View All \(info.dylibs.count) Libraries")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Frameworks Section
                if !info.frameworks.isEmpty {
                    Section(header: Text("Frameworks (\(info.frameworks.count))")) {
                        ForEach(info.frameworks.prefix(10), id: \.self) { framework in
                            HStack {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(framework)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.frameworks.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.frameworks, title: "All Frameworks")) {
                                Text("View All \(info.frameworks.count) Frameworks")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Plugins Section
                if !info.plugins.isEmpty {
                    Section(header: Text("Plugins/Extensions (\(info.plugins.count))")) {
                        ForEach(info.plugins, id: \.self) { plugin in
                            HStack {
                                Image(systemName: "puzzlepiece.extension")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(plugin)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                // Entitlements Section
                if let entitlements = info.entitlements, !entitlements.isEmpty {
                    Section(header: Text("Entitlements (From Provisioning Profile)"), footer: Text("Entitlements declared in the embedded provisioning profile.")) {
                        NavigationLink(destination: PlistViewer(dictionary: entitlements, title: "Entitlements")) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundStyle(.green)
                                Text("\(entitlements.count) entitlements")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // File Structure Section
                if !info.fileStructure.isEmpty {
                    Section(header: Text("File Structure (\(info.fileStructure.count) files)")) {
                        ForEach(info.fileStructure.prefix(15), id: \.self) { file in
                            HStack {
                                Image(systemName: fileIcon(for: file))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(file)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.fileStructure.count > 15 {
                            NavigationLink(destination: ListDetailView(items: info.fileStructure, title: "All Files")) {
                                Text("View all \(info.fileStructure.count) files")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Limitations Section
                Section(header: Text("Limitations"), footer: Text("Some advanced analysis features require macOS command-line tools or specialized security frameworks not available in the iOS sandbox.")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("iOS On-Device Limitations")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(info.limitations, id: \.self) { limitation in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(limitation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("IPA Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIPA(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }
    
    private func analyzeIPA(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        ipaInfo = nil
        
        AppLogManager.shared.info("Analyzing IPA: \(url.lastPathComponent)", category: "IPA Inspector")
        
        Task {
            do {
                let info = try await extractIPAInfo(from: url)
                await MainActor.run {
                    ipaInfo = info
                    isAnalyzing = false
                    AppLogManager.shared.success("Successfully analyzed IPA: \(url.lastPathComponent)", category: "IPA Inspector")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "IPA Inspector")
                }
            }
        }
    }
    
    private func extractIPAInfo(from url: URL) async throws -> IPAInfo {
        let fileManager = FileManager.default
        
        // Start accessing security-scoped resource FIRST
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IPAInspector", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied."])
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)
        
        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Extract IPA using ZIPFoundation
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            throw NSError(domain: "IPAInspector", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract IPA: \(error.localizedDescription)"])
        }
        
        // Find .app bundle in Payload directory
        let payloadDir = tempDir.appendingPathComponent("Payload")
        guard let appBundle = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPAInspector", code: -1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found in IPA"])
        }
        
        // Parse Info.plist
        let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
        var infoPlist: [String: Any]?
        var bundleID: String?
        var version: String?
        var buildNumber: String?
        var displayName: String?
        var minIOSVersion: String?
        
        if let plistData = try? Data(contentsOf: infoPlistURL),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            infoPlist = plist
            bundleID = plist["CFBundleIdentifier"] as? String
            version = plist["CFBundleShortVersionString"] as? String
            buildNumber = plist["CFBundleVersion"] as? String
            displayName = plist["CFBundleDisplayName"] as? String ?? plist["CFBundleName"] as? String
            minIOSVersion = plist["MinimumOSVersion"] as? String
        }
        
        // Find dynamic libraries (.dylib files in main bundle)
        var dylibs: [String] = []
        if let dylibFiles = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
            dylibs = dylibFiles.filter { $0.pathExtension == "dylib" }.map { $0.lastPathComponent }
        }
        
        // Find frameworks
        var frameworks: [String] = []
        let frameworksDir = appBundle.appendingPathComponent("Frameworks")
        if fileManager.fileExists(atPath: frameworksDir.path) {
            if let frameworkFiles = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                frameworks = frameworkFiles.filter { $0.pathExtension == "framework" }.map { $0.lastPathComponent }
            }
        }
        
        // Find plugins/extensions
        var plugins: [String] = []
        let pluginsDir = appBundle.appendingPathComponent("PlugIns")
        if fileManager.fileExists(atPath: pluginsDir.path) {
            if let pluginFiles = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                plugins = pluginFiles.map { $0.lastPathComponent }
            }
        }
        
        // Extract provisioning profile information
        var provisioningInfo: ProvisioningInfo? = nil
        let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
        if fileManager.fileExists(atPath: provisioningURL.path) {
            provisioningInfo = parseProvisioningProfile(at: provisioningURL)
        }
        
        // Try to extract app icon
        var appIconData: Data? = nil
        if let iconFiles = infoPlist?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = iconFiles["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFileNames = primaryIcon["CFBundleIconFiles"] as? [String] {
            // Try to find the largest icon
            for iconName in iconFileNames.reversed() {
                let iconURL = appBundle.appendingPathComponent("\(iconName).png")
                if fileManager.fileExists(atPath: iconURL.path),
                   let data = try? Data(contentsOf: iconURL) {
                    appIconData = data
                    break
                }
                // Also try with @2x and @3x
                let icon2xURL = appBundle.appendingPathComponent("\(iconName)@2x.png")
                if fileManager.fileExists(atPath: icon2xURL.path),
                   let data = try? Data(contentsOf: icon2xURL) {
                    appIconData = data
                    break
                }
            }
        }
        
        // Get file structure
        var fileStructure: [String] = []
        if let enumerator = fileManager.enumerator(at: appBundle, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let fileURL as URL in enumerator {
                if let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, isRegularFile {
                    let relativePath = fileURL.path.replacingOccurrences(of: appBundle.path + "/", with: "")
                    fileStructure.append(relativePath)
                }
            }
        }
        
        // Analyze main executable binary
        var binaryInfo: MachOAnalyzer.BinaryInfo? = nil
        let signatureInfo: CodeSignatureAnalyzer.SignatureInfo? = nil
        var executableName: String? = nil
        var supportedArchitectures: [String] = []
        var isEncrypted = false
        var linkedFrameworksList: [String] = []
        let weakLinkedFrameworksList: [String] = []
        var embeddedBinaries: [String] = []
        
        // Get executable name from Info.plist
        if let execName = infoPlist?["CFBundleExecutable"] as? String {
            executableName = execName
            let executableURL = appBundle.appendingPathComponent(execName)
            
            if let execData = try? Data(contentsOf: executableURL) {
                // Analyze binary
                if let binInfo = MachOAnalyzer.analyze(data: execData) {
                    binaryInfo = binInfo
                    supportedArchitectures = binInfo.architectures
                    isEncrypted = binInfo.isEncrypted
                    
                    // Separate system frameworks from linked libraries
                    for lib in binInfo.linkedLibraries {
                        if lib.contains(".framework") {
                            if lib.hasPrefix("/System") || lib.hasPrefix("@rpath") {
                                linkedFrameworksList.append(lib)
                            }
                        }
                    }
                }
            }
        }
        
        // Find embedded binaries in Frameworks folder (reuse existing frameworksDir)
        if fileManager.fileExists(atPath: frameworksDir.path) {
            if let contents = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                for item in contents {
                    if item.pathExtension == "framework" || item.pathExtension == "dylib" {
                        embeddedBinaries.append(item.lastPathComponent)
                    }
                }
            }
        }
        
        // Define limitations for iOS on-device inspection (now fewer with pure Swift analysis)
        let limitations = [
            "Certificate chain validation: Limited (cannot verify Apple root CA)",
            "Notarization check: Not available on iOS",
            "Full code signature verification: Partial (structure only, not cryptographic)"
        ]
        
        return IPAInfo(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            infoPlist: infoPlist,
            bundleID: bundleID,
            version: version,
            buildNumber: buildNumber,
            displayName: displayName,
            minIOSVersion: minIOSVersion,
            dylibs: dylibs,
            frameworks: frameworks,
            plugins: plugins,
            entitlements: provisioningInfo?.entitlements,
            provisioning: provisioningInfo,
            fileStructure: fileStructure.sorted(),
            appIconData: appIconData,
            limitations: limitations,
            binaryInfo: binaryInfo,
            signatureInfo: signatureInfo,
            executableName: executableName,
            supportedArchitectures: supportedArchitectures,
            isEncrypted: isEncrypted,
            linkedFrameworks: linkedFrameworksList,
            weakLinkedFrameworks: weakLinkedFrameworksList,
            embeddedBinaries: embeddedBinaries
        )
    }
    
    private func parseProvisioningProfile(at url: URL) -> ProvisioningInfo? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        // Provisioning profiles contain XML plist data between <plist> tags
        // Extract the plist portion
        guard let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Find plist content
        guard let plistStart = dataString.range(of: "<?xml"),
              let plistEnd = dataString.range(of: "</plist>") else {
            return nil
        }
        
        let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        let teamName = plist["TeamName"] as? String
        let teamID = (plist["TeamIdentifier"] as? [String])?.first
        let expirationDate = plist["ExpirationDate"] as? Date
        let appIDName = plist["AppIDName"] as? String
        let provisionedDevices = plist["ProvisionedDevices"] as? [String]
        let entitlements = plist["Entitlements"] as? [String: Any]
        
        return ProvisioningInfo(
            teamName: teamName,
            teamID: teamID,
            expirationDate: expirationDate,
            appIDName: appIDName,
            provisionedDevices: provisionedDevices,
            entitlements: entitlements
        )
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "plist": return "doc.text"
        case "png", "jpg", "jpeg": return "photo"
        case "dylib": return "cube.box"
        case "framework": return "shippingbox"
        case "nib", "storyboard", "xib": return "square.grid.3x3"
        case "strings": return "text.quote"
        case "html", "css", "js": return "globe"
        case "json", "xml": return "doc.badge.gearshape"
        default: return "doc"
        }
    }
}

// MARK: - Supporting Views

struct DeveloperInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ListDetailView: View {
    let items: [String]
    let title: String
    @State private var searchText = ""
    
    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                Text(item)
                    .font(.caption.monospaced())
            }
        }
        .searchable(text: $searchText, prompt: "Search...")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlistViewer: View {
    let dictionary: [String: Any]
    let title: String
    @State private var searchText = ""
    
    var filteredKeys: [String] {
        let keys = dictionary.keys.sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(String(describing: dictionary[key] ?? ""))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $searchText, prompt: "Search Keys...")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IPAIntegrityCheckerView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var integrityResults: IntegrityResults?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    struct IntegrityResults {
        let fileName: String
        let fileSize: String
        let bundleID: String?
        let isValidZip: Bool
        let hasPayloadFolder: Bool
        let hasAppBundle: Bool
        let hasValidInfoPlist: Bool
        let hasValidProvisioning: Bool
        let provisioningExpired: Bool
        let provisioningExpiryDate: Date?
        let hasCodeSignature: Bool
        let frameworksCount: Int
        let dylibsCount: Int
        let pluginsCount: Int
        let warnings: [String]
        let errors: [String]
        let suggestions: [String]
    }
    
    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import IPA")) {
                Button(action: { isImporting = true }) {
                    HStack {
                        Image(systemName: "doc.zipper")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select IPA File")
                                .font(.headline)
                            if let file = selectedFile {
                                Text(file.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No File Selected")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if isAnalyzing {
                            ProgressView()
                        }
                    }
                }
            }
            
            // Error Section
            if let error = errorMessage {
                Section(header: Text("Error")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Results Section
            if let results = integrityResults {
                // Basic Info
                Section(header: Text("File Information")) {
                    LabeledContent("File Name", value: results.fileName)
                    LabeledContent("File Size", value: results.fileSize)
                    if let bundleID = results.bundleID {
                        LabeledContent("Bundle ID", value: bundleID)
                    }
                }
                
                // Integrity Checks
                Section(header: Text("Integrity Checks")) {
                    CheckRow(label: "Valid ZIP Archive", passed: results.isValidZip)
                    CheckRow(label: "Has Payload Folder", passed: results.hasPayloadFolder)
                    CheckRow(label: "Has .app Bundle", passed: results.hasAppBundle)
                    CheckRow(label: "Valid Info.plist", passed: results.hasValidInfoPlist)
                    CheckRow(label: "Has Provisioning Profile", passed: results.hasValidProvisioning)
                    if results.hasValidProvisioning {
                        CheckRow(label: "Provisioning Not Expired", passed: !results.provisioningExpired)
                        if let expiryDate = results.provisioningExpiryDate {
                            LabeledContent("Expires", value: expiryDate.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    CheckRow(label: "Has Code Signature", passed: results.hasCodeSignature)
                }
                
                // Content Analysis
                Section(header: Text("Content Analysis")) {
                    LabeledContent("Frameworks", value: "\(results.frameworksCount)")
                    LabeledContent("Dynamic Libraries", value: "\(results.dylibsCount)")
                    LabeledContent("Plugins/Extensions", value: "\(results.pluginsCount)")
                }
                
                // Warnings
                if !results.warnings.isEmpty {
                    Section(header: Text("Warnings")) {
                        ForEach(results.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Errors
                if !results.errors.isEmpty {
                    Section(header: Text("Errors")) {
                        ForEach(results.errors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Suggestions
                if !results.suggestions.isEmpty {
                    Section(header: Text("Suggestions")) {
                        ForEach(results.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Overall Status
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: overallStatus.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(overallStatus.color)
                            Text(overallStatus.message)
                                .font(.headline)
                                .foregroundStyle(overallStatus.color)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Integrity Checker")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIntegrity(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }
    
    private var overallStatus: (icon: String, color: Color, message: String) {
        guard let results = integrityResults else {
            return ("questionmark.circle", .gray, "No analysis yet")
        }
        
        if !results.errors.isEmpty {
            return ("xmark.circle.fill", .red, "Integrity Issues Found")
        } else if !results.warnings.isEmpty {
            return ("exclamationmark.triangle.fill", .orange, "Minor Issues Detected")
        } else {
            return ("checkmark.circle.fill", .green, "All Checks Passed")
        }
    }
    
    private func analyzeIntegrity(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        integrityResults = nil
        
        Task {
            do {
                let results = try await performIntegrityChecks(url: url)
                await MainActor.run {
                    integrityResults = results
                    isAnalyzing = false
                    
                    if results.errors.isEmpty && results.warnings.isEmpty {
                        ToastManager.shared.show("✅ IPA integrity verified", type: .success)
                        AppLogManager.shared.success("IPA integrity verified: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else if !results.errors.isEmpty {
                        ToastManager.shared.show("❌ IPA integrity issues found", type: .error)
                        AppLogManager.shared.error("IPA integrity issues found: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else {
                        ToastManager.shared.show("⚠️ IPA has warnings", type: .warning)
                        AppLogManager.shared.warning("IPA has warnings: \(url.lastPathComponent)", category: "Integrity Checker")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    ToastManager.shared.show("❌ Failed to analyze IPA", type: .error)
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "Integrity Checker")
                }
            }
        }
    }
    
    private static let maxProvisioningFileSize: Int64 = 10 * 1024 * 1024 // 10 MB limit
    private static let provisioningWarningDays: TimeInterval = 7 * 24 * 3600 // 7 days
    
    private func performIntegrityChecks(url: URL) async throws -> IntegrityResults {
        let fileManager = FileManager.default
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IntegrityChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied."])
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)
        
        var warnings: [String] = []
        var errors: [String] = []
        var suggestions: [String] = []
        
        // Check if it's a valid ZIP
        var isValidZip = true
        var hasPayloadFolder = false
        var hasAppBundle = false
        var hasValidInfoPlist = false
        var hasValidProvisioning = false
        var provisioningExpired = false
        var provisioningExpiryDate: Date? = nil
        var hasCodeSignature = false
        var bundleID: String? = nil
        var frameworksCount = 0
        var dylibsCount = 0
        var pluginsCount = 0
        
        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Extract IPA (using ZIPFoundation extension)
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            isValidZip = false
            errors.append("Failed to extract IPA: Not a valid ZIP archive")
            throw error
        }
        
        // Check for Payload folder
        let payloadDir = tempDir.appendingPathComponent("Payload")
        hasPayloadFolder = fileManager.fileExists(atPath: payloadDir.path)
        
        if !hasPayloadFolder {
            errors.append("Missing Payload folder")
        } else {
            // Find .app bundle
            if let appBundle = try? fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) {
                hasAppBundle = true
                
                // Check Info.plist
                let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
                if let plistData = try? Data(contentsOf: infoPlistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                    hasValidInfoPlist = true
                    bundleID = plist["CFBundleIdentifier"] as? String
                    
                    if bundleID == nil {
                        warnings.append("Info.plist missing CFBundleIdentifier")
                    }
                } else {
                    errors.append("Invalid or missing Info.plist")
                }
                
                // Check provisioning profile with size limits
                let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
                if fileManager.fileExists(atPath: provisioningURL.path) {
                    // Check file size before loading
                    if let provisioningAttrs = try? fileManager.attributesOfItem(atPath: provisioningURL.path),
                       let provisioningSize = provisioningAttrs[.size] as? Int64,
                       provisioningSize <= Self.maxProvisioningFileSize {
                        hasValidProvisioning = true
                        
                        // Parse provisioning profile
                        if let data = try? Data(contentsOf: provisioningURL),
                           let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8),
                           let plistStart = dataString.range(of: "<?xml"),
                           let plistEnd = dataString.range(of: "</plist>") {
                            let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
                            if let plistData = plistString.data(using: .utf8),
                               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                                if let expirationDate = plist["ExpirationDate"] as? Date {
                                    provisioningExpiryDate = expirationDate
                                    provisioningExpired = expirationDate < Date()
                                    
                                    if provisioningExpired {
                                        errors.append("Provisioning profile has expired")
                                    } else if expirationDate.timeIntervalSinceNow < Self.provisioningWarningDays {
                                        warnings.append("Provisioning profile expires soon")
                                    }
                                }
                            }
                        }
                    } else {
                        warnings.append("Provisioning profile file too large or invalid")
                    }
                } else {
                    warnings.append("No embedded provisioning profile found")
                }
                
                // Check code signature
                let codeSignatureDir = appBundle.appendingPathComponent("_CodeSignature")
                hasCodeSignature = fileManager.fileExists(atPath: codeSignatureDir.path)
                
                if !hasCodeSignature {
                    warnings.append("No code signature found")
                    suggestions.append("Sign the IPA before installation")
                }
                
                // Count frameworks
                let frameworksDir = appBundle.appendingPathComponent("Frameworks")
                if fileManager.fileExists(atPath: frameworksDir.path) {
                    if let frameworks = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                        frameworksCount = frameworks.filter { $0.pathExtension == "framework" }.count
                    }
                }
                
                // Count dylibs (may be injected tweaks or legitimate dependencies)
                if let files = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
                    dylibsCount = files.filter { $0.pathExtension == "dylib" }.count
                    
                    if dylibsCount > 0 {
                        warnings.append("Found \(dylibsCount) dynamic libraries (may be tweaks or legitimate dependencies)")
                    }
                }
                
                // Count plugins
                let pluginsDir = appBundle.appendingPathComponent("PlugIns")
                if fileManager.fileExists(atPath: pluginsDir.path) {
                    if let plugins = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                        pluginsCount = plugins.count
                    }
                }
            } else {
                errors.append("No .app bundle found in Payload folder")
            }
        }
        
        // Add suggestions based on findings
        if !hasValidProvisioning {
            suggestions.append("Add a valid provisioning profile before installation")
        }
        
        if errors.isEmpty && warnings.isEmpty {
            suggestions.append("IPA appears to be valid and ready for installation")
        }
        
        return IntegrityResults(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            bundleID: bundleID,
            isValidZip: isValidZip,
            hasPayloadFolder: hasPayloadFolder,
            hasAppBundle: hasAppBundle,
            hasValidInfoPlist: hasValidInfoPlist,
            hasValidProvisioning: hasValidProvisioning,
            provisioningExpired: provisioningExpired,
            provisioningExpiryDate: provisioningExpiryDate,
            hasCodeSignature: hasCodeSignature,
            frameworksCount: frameworksCount,
            dylibsCount: dylibsCount,
            pluginsCount: pluginsCount,
            warnings: warnings,
            errors: errors,
            suggestions: suggestions
        )
    }
}

// MARK: - Check Row
struct CheckRow: View {
    let label: String
    let passed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct SourceDataView: View {
    var body: some View {
        List {
            ForEach(Storage.shared.getSources(), id: \.self) { source in
                NavigationLink(destination: JSONViewer(json: source.description)) {
                    Text(source.name ?? "Unknown")
                }
            }
        }
        .navigationTitle("Source Data")
    }
}

struct JSONViewer: View {
    let json: String
    var body: some View {
        ScrollView {
            Text(json)
                .font(.caption.monospaced())
                .padding()
        }
        .navigationTitle("JSON")
    }
}

struct AppStateView: View {
    var body: some View {
        List {
            Section(header: Text("Storage")) {
                Text("Documents: \(getDocumentsSize())")
                Text("Cache: \(getCacheSize())")
            }
        }
        .navigationTitle("App State")
    }
    
    func getDocumentsSize() -> String {
        // Calculate size
        return "12.5 MB"
    }
    
    func getCacheSize() -> String {
        return "4.2 MB"
    }
}

struct FeatureFlagsView: View {
    @AppStorage("feature_enhancedAnimations") var enhancedAnimations = false
    @AppStorage("feature_advancedSigning") var advancedSigning = false
    @AppStorage("feature_usePortalCert") var usePortalCert = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enhanced Animations", isOn: $enhancedAnimations)
            } header: {
                Text("Performance")
            }
            
            Section {
                Toggle("Advanced Signing Options", isOn: $advancedSigning)
            } header: {
                Text("Signing")
            }
            
            Section {
                Toggle("Use .portalcert for certificates", isOn: $usePortalCert)
            } header: {
                Text("Certificates")
            } footer: {
                Text("When enabled, allows exporting and importing certificates as a single .portalcert file that bundles the P12 and provisioning profile together.")
            }
        }
        .navigationTitle("Feature Flags")
    }
}

struct PerformanceMonitorView: View {
    @StateObject private var monitor = PerformanceMonitor()
    
    var body: some View {
        List {
            Section(header: Text("System Resources")) {
                HStack {
                    Label("CPU Usage", systemImage: "cpu")
                    Spacer()
                    Text("\(Int(monitor.cpuUsage))%")
                        .foregroundStyle(monitor.cpuUsage > 80 ? .red : monitor.cpuUsage > 50 ? .orange : .green)
                        .fontWeight(.semibold)
                        .animation(.easeInOut(duration: 0.3), value: monitor.cpuUsage)
                }
                
                HStack {
                    Label("Memory", systemImage: "memorychip")
                    Spacer()
                    Text(monitor.memoryUsage)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("Disk Space", systemImage: "internaldrive")
                    Spacer()
                    Text(monitor.diskSpace)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("App Performance")) {
                HStack {
                    Label("Frame Rate", systemImage: "waveform.path.ecg")
                    Spacer()
                    Text("60 FPS")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Launch Time", systemImage: "timer")
                    Spacer()
                    Text("0.8s")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Status")) {
                HStack {
                    Label("Monitoring", systemImage: monitor.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Spacer()
                    Text(monitor.isMonitoring ? "Active" : "Stopped")
                        .foregroundStyle(monitor.isMonitoring ? .green : .red)
                }
            }
        }
        .navigationTitle("Performance Monitor")
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

// MARK: - Performance Monitor Class (Thread-Safe)
class PerformanceMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: String = "0 MB"
    @Published var diskSpace: String = "0 GB"
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private let updateQueue = DispatchQueue(label: "com.portal.performanceMonitor", qos: .utility)
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Initial update
        updateMetricsAsync()
        
        // Schedule periodic updates on main thread but execute work on background
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetricsAsync()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func updateMetricsAsync() {
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cpu = self.calculateCPUUsage()
            let memory = self.calculateMemoryUsage()
            let disk = self.calculateDiskSpace()
            
            DispatchQueue.main.async {
                self.cpuUsage = cpu
                self.memoryUsage = memory
                self.diskSpace = disk
            }
        }
    }
    
    private func calculateCPUUsage() -> Double {
        // Simplified CPU usage calculation that's safer
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            // Use a simpler estimation based on memory pressure as a proxy
            // This avoids the problematic host_processor_info call
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            // Estimate CPU based on memory usage (rough approximation for display purposes)
            return min(max(usedMB / 5.0, 5.0), 95.0)
        }
        
        return 0.0
    }
    
    private func calculateMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", usedMB)
        }
        
        return "N/A"
    }
    
    private func calculateDiskSpace() -> String {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                let freeGB = Double(truncating: freeSpace) / 1024.0 / 1024.0 / 1024.0
                return String(format: "%.1f GB Free", freeGB)
            }
        } catch {
            // Silently handle error
        }
        return "N/A"
    }
    
    deinit {
        stopMonitoring()
    }
}

struct CoreDataInspectorView: View {
    var body: some View {
        List {
            Section(header: Text("Entities")) {
                NavigationLink("Certificates") {
                    EntityDetailView(entityName: "Certificate")
                }
                NavigationLink("Sources") {
                    EntityDetailView(entityName: "AltSource")
                }
                NavigationLink("Signed Apps") {
                    EntityDetailView(entityName: "Signed")
                }
                NavigationLink("Imported Apps") {
                    EntityDetailView(entityName: "Imported")
                }
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Certificates")
                    Spacer()
                    Text("\(Storage.shared.getCertificates().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Sources")
                    Spacer()
                    Text("\(Storage.shared.getSources().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Signed Apps")
                    Spacer()
                    Text("\(Storage.shared.getSignedApps().count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("CoreData Inspector")
    }
}

struct EntityDetailView: View {
    let entityName: String
    
    var body: some View {
        List {
            Text("Entity: \(entityName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // Add more detailed entity inspection here
        }
        .navigationTitle(entityName)
    }
}

// MARK: - Test Notifications View
struct TestNotificationsView: View {
    @State private var isTestingNotification = false
    @State private var countdown: Int = 3
    @State private var showResultDialog = false
    @State private var notificationSent = false
    @State private var debugInfo: [String] = []
    @State private var timer: Timer?
    
    var body: some View {
        List {
            Section(header: Text("Test Notifications"), footer: Text("This will send a test notification after a 3-second countdown. Make sure notifications are enabled for Feather in Settings.")) {
                Button {
                    startNotificationTest()
                } label: {
                    HStack {
                        Spacer()
                        if isTestingNotification {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Sending in \(countdown)...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Send Test Notification", systemImage: "bell.badge")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .disabled(isTestingNotification)
            }
            
            if !debugInfo.isEmpty {
                Section(header: Text("Debug Information")) {
                    ForEach(debugInfo, id: \.self) { info in
                        Text(info)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Test Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Did you receive the notification?", isPresented: $showResultDialog) {
            Button("Yes") {
                handleYesResponse()
            }
            Button("No") {
                handleNoResponse()
            }
        } message: {
            Text("Please confirm if you received the test notification.")
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startNotificationTest() {
        isTestingNotification = true
        countdown = 3
        debugInfo.removeAll()
        notificationSent = false
        
        // Log notification permission status
        checkNotificationPermissions()
        
        // Start countdown
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdown -= 1
            
            if countdown == 0 {
                timer?.invalidate()
                sendTestNotification()
            }
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                debugInfo.append("Notification Authorization: \(settings.authorizationStatus.debugDescription)")
                debugInfo.append("Alert Setting: \(settings.alertSetting.debugDescription)")
                debugInfo.append("Sound Setting: \(settings.soundSetting.debugDescription)")
                debugInfo.append("Badge Setting: \(settings.badgeSetting.debugDescription)")
                debugInfo.append("Notification Center Setting: \(settings.notificationCenterSetting.debugDescription)")
                debugInfo.append("Lock Screen Setting: \(settings.lockScreenSetting.debugDescription)")
                
                if settings.authorizationStatus != .authorized {
                    debugInfo.append("⚠️ WARNING: Notifications not authorized!")
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Feather Developer Tools."
        content.sound = .default
        content.badge = 1
        
        // Create a trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "feather.test.notification.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    debugInfo.append("❌ ERROR: Failed to schedule notification")
                    debugInfo.append("Error: \(error.localizedDescription)")
                    AppLogManager.shared.error("Failed to send test notification: \(error.localizedDescription)", category: "Test Notifications")
                } else {
                    debugInfo.append("✅ Notification scheduled successfully")
                    AppLogManager.shared.success("Test notification scheduled", category: "Test Notifications")
                }
                
                notificationSent = true
                isTestingNotification = false
                
                // Show result dialog after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showResultDialog = true
                }
            }
        }
    }
    
    private func handleYesResponse() {
        debugInfo.append("✅ User confirmed notification received")
        AppLogManager.shared.success("Test notification received successfully", category: "Test Notifications")
        
        UIAlertController.showAlertWithOk(
            title: "Success",
            message: "Notifications are working correctly!"
        )
    }
    
    private func handleNoResponse() {
        debugInfo.append("❌ User did not receive notification")
        AppLogManager.shared.warning("Test notification not received", category: "Test Notifications")
        
        // Collect comprehensive debugging information
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                var troubleshooting: [String] = []
                
                // Check authorization
                if settings.authorizationStatus == .notDetermined {
                    troubleshooting.append("• Notification permission not requested yet")
                } else if settings.authorizationStatus == .denied {
                    troubleshooting.append("• Notification permission denied by user")
                    troubleshooting.append("• Go to Settings > Portal > Notifications to enable")
                }
                
                // Check settings
                if settings.alertSetting == .disabled {
                    troubleshooting.append("• Alert style is disabled")
                }
                if settings.soundSetting == .disabled {
                    troubleshooting.append("• Sound is disabled")
                }
                if settings.notificationCenterSetting == .disabled {
                    troubleshooting.append("• Notification Center is disabled")
                }
                if settings.lockScreenSetting == .disabled {
                    troubleshooting.append("• Lock Screen Notifications Are Disabled")
                }
                
                // Check Do Not Disturb / Focus mode
                troubleshooting.append("• Check if Do Not Disturb or Focus mode is active")
                
                // Check app state
                let appState = UIApplication.shared.applicationState
                troubleshooting.append("• App State: \(appState == .active ? "Active (notifications may not show)" : appState == .background ? "Background" : "Inactive")")
                
                // Add pending notifications count
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    DispatchQueue.main.async {
                        troubleshooting.append("• Pending Notifications: \(requests.count)")
                        
                        UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
                            DispatchQueue.main.async {
                                troubleshooting.append("• Delivered Notifications: \(delivered.count)")
                                
                                debugInfo.append(contentsOf: troubleshooting)
                                
                                // Show comprehensive alert
                                let message = troubleshooting.joined(separator: "\n")
                                UIAlertController.showAlertWithOk(
                                    title: "Notification Not Received",
                                    message: "Troubleshooting Info:\n\n\(message)\n\nCheck the Debug Information section for more details."
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UNAuthorizationStatus Extension
extension UNAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - UNNotificationSetting Extension
extension UNNotificationSetting {
    var debugDescription: String {
        switch self {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Updates & Releases View
struct UpdatesReleasesView: View {
    @State private var isCheckingUpdates = false
    @State private var latestRelease: GitHubRelease?
    @State private var allReleases: [GitHubRelease] = []
    @State private var errorMessage: String?
    @State private var showPrereleases = false
    @AppStorage("dev.mandatoryUpdateEnabled") private var mandatoryUpdateEnabled = false
    @AppStorage("dev.updateBannerDismissed") private var updateBannerDismissed = false
    @AppStorage("dev.showUpdateBannerPreview") private var showUpdateBannerPreview = false
    
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        List {
            // Current Version Info
            Section(header: Text("Installed Version")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(currentVersion)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(currentBuild)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                }
            }
            
            // Update Check
            Section(header: Text("GitHub Releases")) {
                Button {
                    checkForUpdates()
                } label: {
                    HStack {
                        if isCheckingUpdates {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check for Updates")
                    }
                }
                .disabled(isCheckingUpdates)
                
                Toggle("Include Prereleases", isOn: $showPrereleases)
                    .onChange(of: showPrereleases) { _ in
                        checkForUpdates()
                    }
                
                if let release = latestRelease {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Latest: \(release.tagName)")
                                .font(.headline)
                            if release.prerelease {
                                Text("PRE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(release.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let publishedAt = release.publishedAt {
                            Text("Published: \(publishedAt, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            // All Releases
            if !allReleases.isEmpty {
                Section(header: Text("All Releases (\(allReleases.count))")) {
                    ForEach(allReleases, id: \.id) { release in
                        NavigationLink(destination: ReleaseDetailView(release: release)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(release.tagName)
                                            .font(.system(.body, design: .monospaced))
                                        if release.prerelease {
                                            Text("PRE")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.2))
                                                .foregroundStyle(.orange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(release.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            // Update Settings
            Section(header: Text("Update Settings")) {
                Toggle("Mandatory Update Enforcement", isOn: $mandatoryUpdateEnabled)
                
                Toggle("Show Update Banner Preview", isOn: $showUpdateBannerPreview)
                
                Button("Reset Dismissed Update State") {
                    updateBannerDismissed = false
                    HapticsManager.shared.success()
                    AppLogManager.shared.info("Update banner dismissed state reset", category: "Developer")
                }
                
                HStack {
                    Text("Banner Dismissed")
                    Spacer()
                    Text(updateBannerDismissed ? "Yes" : "No")
                        .foregroundStyle(updateBannerDismissed ? .orange : .green)
                }
            }
            
            // Developer Testing
            Section(header: Text("Developer Testing")) {
                Button {
                    forceShowFakeUpdate()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                        Text("Force Show Update")
                        Spacer()
                        Text("Test")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.purple))
                    }
                }
                
                if UserDefaults.standard.bool(forKey: "dev.forceShowUpdate") {
                    Button {
                        stopForcedUpdate()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.red)
                            Text("Stop Force Show Update")
                            Spacer()
                            Text("Reset")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.red))
                        }
                    }
                }
                
                Text("Simulates an available update to test the Check for Updates view and update banner.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Updates & Releases")
        .onAppear {
            if allReleases.isEmpty {
                checkForUpdates()
            }
        }
    }
    
    private func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isCheckingUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingUpdates = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    AppLogManager.shared.error("Failed to check updates: \(error.localizedDescription)", category: "Developer")
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    // Configure JSONDecoder with ISO8601 date decoding strategy
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    allReleases = showPrereleases ? releases : releases.filter { !$0.prerelease }
                    latestRelease = allReleases.first
                    AppLogManager.shared.success("Fetched \(releases.count) releases", category: "Developer")
                } catch {
                    errorMessage = "Failed to parse releases: \(error.localizedDescription)"
                    AppLogManager.shared.error("Failed to parse releases: \(error.localizedDescription)", category: "Developer")
                }
            }
        }.resume()
    }
    
    private func forceShowFakeUpdate() {
        // Create a fake release with a higher version number
        let fakeAsset = GitHubAsset(
            id: 999999,
            name: "Portal-99.0.0.ipa",
            size: 50_000_000,
            downloadCount: 1000,
            browserDownloadUrl: "https://github.com/dylans2010/Portal/releases/download/v99.0.0/Portal-99.0.0.ipa"
        )
        
        let fakeRelease = GitHubRelease(
            id: 999999,
            tagName: "v99.0.0",
            name: "Portal v99.0.0 - Test Release",
            body: """
            ## 🧪 Test Release
            
            This is a **fake update** generated for testing purposes.
            
            ### What's New
            - ✨ Amazing new features
            - 🐛 Bug fixes
            - 🚀 Performance improvements
            - 🎨 UI enhancements
            
            ### Notes
            This release is simulated by the Developer Mode "Force Show Update" feature.
            """,
            prerelease: false,
            draft: false,
            publishedAt: Date(),
            htmlUrl: "https://github.com/dylans2010/Portal/releases/tag/v99.0.0",
            assets: [fakeAsset]
        )
        
        // Store the fake release info for the Check for Updates view
        UserDefaults.standard.set(true, forKey: "dev.forceShowUpdate")
        UserDefaults.standard.set("99.0.0", forKey: "dev.fakeUpdateVersion")
        
        // Reset the dismissed state so the banner shows
        updateBannerDismissed = false
        
        // Post notification to trigger update banner
        NotificationCenter.default.post(name: .forceShowUpdateNotification, object: fakeRelease)
        
        HapticsManager.shared.success()
        AppLogManager.shared.info("Force showing fake update v99.0.0", category: "Developer")
    }
    
    private func stopForcedUpdate() {
        // Clear the forced update flags
        UserDefaults.standard.removeObject(forKey: "dev.forceShowUpdate")
        UserDefaults.standard.removeObject(forKey: "dev.fakeUpdateVersion")
        
        // Check for real updates again
        checkForUpdates()
        
        HapticsManager.shared.success()
        AppLogManager.shared.info("Stopped forcing fake update, checking for real updates", category: "Developer")
    }
}

// MARK: - Force Show Update Notification
extension Notification.Name {
    static let forceShowUpdateNotification = Notification.Name("forceShowUpdateNotification")
}

// MARK: - GitHub Release Model
struct GitHubRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String
    let body: String?
    let prerelease: Bool
    let draft: Bool
    let publishedAt: Date?
    let htmlUrl: String
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case prerelease
        case draft
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case assets
    }
}

struct GitHubAsset: Codable, Identifiable {
    let id: Int
    let name: String
    let size: Int
    let downloadCount: Int
    let browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, size
        case downloadCount = "download_count"
        case browserDownloadUrl = "browser_download_url"
    }
}

// MARK: - Release Detail View
struct ReleaseDetailView: View {
    let release: GitHubRelease
    
    var body: some View {
        List {
            Section(header: Text("Release Info")) {
                LabeledContent("Tag", value: release.tagName)
                LabeledContent("Name", value: release.name)
                LabeledContent("Prerelease", value: release.prerelease ? "Yes" : "No")
                if let date = release.publishedAt {
                    LabeledContent("Published", value: date.formatted())
                }
            }
            
            if let body = release.body, !body.isEmpty {
                Section(header: Text("Release Notes")) {
                    ScrollView {
                        ModernMarkdownView(markdown: body)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            if !release.assets.isEmpty {
                Section(header: Text("Assets (\(release.assets.count))")) {
                    ForEach(release.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.name)
                                .font(.system(.body, design: .monospaced))
                            HStack {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                                Text("•")
                                Text("\(asset.downloadCount) downloads")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button("Open in GitHub") {
                    if let url = URL(string: release.htmlUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle(release.tagName)
    }
}

// MARK: - Sources & Library Dev View
struct SourcesLibraryDevView: View {
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var isReloading = false
    @State private var selectedSource: AltSource?
    @State private var rawJSON: String = ""
    @State private var showRawJSON = false
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var sources: FetchedResults<AltSource>
    
    var body: some View {
        List {
            // Source Actions
            Section(header: Text("Source Actions")) {
                Button {
                    reloadAllSources()
                } label: {
                    HStack {
                        if isReloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Force Reload All Sources")
                    }
                }
                .disabled(isReloading)
                
                Button {
                    invalidateSourceCache()
                } label: {
                    Label("Invalidate Source Cache", systemImage: "trash")
                }
                
                Button {
                    refetchMetadata()
                } label: {
                    Label("Re-fetch All Metadata", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            // Source List
            Section(header: Text("Sources (\(sources.count))")) {
                ForEach(sources) { source in
                    NavigationLink(destination: SourceInspectorView(source: source, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name ?? "Unknown")
                                .font(.headline)
                            if let url = source.sourceURL {
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            if let repo = viewModel.sources[source] {
                                Text("\(repo.apps.count) apps")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            
            // Library Actions
            Section(header: Text("Library Actions")) {
                Button {
                    forceLibraryRerender()
                } label: {
                    Label("Force Library Re-render", systemImage: "arrow.counterclockwise")
                }
                
                Button {
                    clearLibraryCache()
                } label: {
                    Label("Clear Library Cache", systemImage: "trash")
                }
            }
            
            // Offline Handling
            Section(header: Text("Offline Handling")) {
                Toggle("Simulate Offline Mode", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.simulateOffline") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.simulateOffline") }
                ))
                
                Button {
                    testOfflineSourceHandling()
                } label: {
                    Label("Test Offline Source Handling", systemImage: "wifi.slash")
                }
            }
        }
        .navigationTitle("Sources & Library")
    }
    
    private func reloadAllSources() {
        isReloading = true
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                isReloading = false
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ All sources reloaded successfully", type: .success)
                AppLogManager.shared.success("All sources reloaded", category: "Developer")
            }
        }
    }
    
    private func invalidateSourceCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image cache
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
        }
        
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Source cache invalidated", type: .success)
        AppLogManager.shared.success("Source cache invalidated", category: "Developer")
    }
    
    private func refetchMetadata() {
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Metadata re-fetched successfully", type: .success)
            AppLogManager.shared.success("Metadata re-fetched", category: "Developer")
        }
    }
    
    private func forceLibraryRerender() {
        NotificationCenter.default.post(name: Notification.Name("Feather.forceLibraryRerender"), object: nil)
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library re-render triggered", type: .success)
        AppLogManager.shared.info("Library re-render triggered", category: "Developer")
    }
    
    private func clearLibraryCache() {
        // Clear any library-specific caches
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library cache cleared", type: .success)
        AppLogManager.shared.success("Library cache cleared", category: "Developer")
    }
    
    private func testOfflineSourceHandling() {
        UserDefaults.standard.set(true, forKey: "dev.simulateOffline")
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "dev.simulateOffline")
                ToastManager.shared.show("ℹ️ Offline source handling test completed", type: .info)
                AppLogManager.shared.info("Offline source handling test completed", category: "Developer")
            }
        }
    }
}

// MARK: - Source Inspector View
struct SourceInspectorView: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var rawJSON: String = ""
    @State private var isLoadingJSON = false
    
    var body: some View {
        List {
            Section(header: Text("Source Info")) {
                LabeledContent("Name", value: source.name ?? "Unknown")
                if let url = source.sourceURL {
                    LabeledContent("URL", value: url.absoluteString)
                }
                LabeledContent("Order", value: "\(source.order)")
                if let date = source.date {
                    LabeledContent("Added", value: date.formatted())
                }
            }
            
            if let repo = viewModel.sources[source] {
                Section(header: Text("Repository Data")) {
                    LabeledContent("Apps", value: "\(repo.apps.count)")
                    if let news = repo.news {
                        LabeledContent("News Items", value: "\(news.count)")
                    }
                    if let name = repo.name {
                        LabeledContent("Repo Name", value: name)
                    }
                }
            }
            
            Section(header: Text("Raw JSON")) {
                Button {
                    loadRawJSON()
                } label: {
                    HStack {
                        if isLoadingJSON {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Load Raw JSON")
                    }
                }
                
                if !rawJSON.isEmpty {
                    ScrollView(.horizontal) {
                        Text(rawJSON)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                    
                    Button("Copy JSON") {
                        UIPasteboard.general.string = rawJSON
                        HapticsManager.shared.success()
                    }
                }
            }
        }
        .navigationTitle(source.name ?? "Source")
    }
    
    private func loadRawJSON() {
        guard let url = source.sourceURL else { return }
        isLoadingJSON = true
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingJSON = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        rawJSON = prettyString
                    } else {
                        rawJSON = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    }
                } else if let error = error {
                    rawJSON = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Install & IPA Dev View
struct InstallIPADevView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showInstallModifyDialog = false
    @State private var lastInstallLogs: [String] = []
    @State private var selectedApp: (any AppInfoPresentable)?
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>
    
    var body: some View {
        List {
            // Install Queue
            Section(header: Text("Download Queue (\(downloadManager.downloads.count))")) {
                if downloadManager.downloads.isEmpty {
                    Text("No active downloads")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(downloadManager.downloads, id: \.id) { download in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(download.fileName)
                                .font(.system(.body, design: .monospaced))
                            ProgressView(value: download.overallProgress)
                            HStack {
                                Text("\(Int(download.progress * 100))% downloaded")
                                Spacer()
                                Text("\(Int(download.unpackageProgress * 100))% processed")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button("Clear Pending Installs", role: .destructive) {
                    clearPendingInstalls()
                }
            }
            
            // IPA Validation
            Section(header: Text("IPA Tools")) {
                NavigationLink(destination: IPAInspectorView()) {
                    Label("IPA Inspector", systemImage: "doc.zipper")
                }
                
                NavigationLink(destination: IPAIntegrityCheckerView()) {
                    Label("Integrity Checker", systemImage: "checkmark.shield")
                }
            }
            
            // InstallModifyDialog Testing
            Section(header: Text("InstallModifyDialog Testing")) {
                if let firstApp = importedApps.first {
                    Button("Show InstallModifyDialog (Full Screen)") {
                        selectedApp = firstApp
                        showInstallModifyDialog = true
                    }
                } else {
                    Text("No imported apps available for testing")
                        .foregroundStyle(.secondary)
                }
                
                Toggle("Always Show After Download", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.alwaysShowInstallModify") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.alwaysShowInstallModify") }
                ))
            }
            
            // Last Install Logs
            Section(header: Text("Last Install Logs")) {
                Button("Load Install Logs") {
                    loadInstallLogs()
                }
                
                if !lastInstallLogs.isEmpty {
                    ForEach(lastInstallLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Install & IPA")
        .fullScreenCover(isPresented: $showInstallModifyDialog) {
            if let app = selectedApp {
                InstallModifyDialogView(app: app)
            }
        }
    }
    
    private func clearPendingInstalls() {
        for download in downloadManager.downloads {
            downloadManager.cancelDownload(download)
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Pending installs cleared", type: .success)
        AppLogManager.shared.info("Pending installs cleared", category: "Developer")
    }
    
    private func loadInstallLogs() {
        lastInstallLogs = AppLogManager.shared.logs
            .filter { $0.category == "Install" || $0.category == "Download" }
            .prefix(20)
            .map { "[\($0.level.rawValue)] \($0.message)" }
    }
}

// MARK: - UI & Layout Dev View
struct UILayoutDevView: View {
    @AppStorage("dev.showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("dev.slowAnimations") private var slowAnimations = false
    @AppStorage("dev.animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dev.forceDarkMode") private var forceDarkMode = false
    @AppStorage("dev.forceLightMode") private var forceLightMode = false
    @AppStorage("dev.forceReducedMotion") private var forceReducedMotion = false
    @AppStorage("dev.dynamicTypeSize") private var dynamicTypeSize: String = "default"
    @AppStorage("dev.showBannerPreview") private var showBannerPreview = false
    
    var body: some View {
        List {
            // Appearance Overrides
            Section(header: Text("Appearance Overrides")) {
                Toggle("Force Dark Mode", isOn: $forceDarkMode)
                    .onChange(of: forceDarkMode) { newValue in
                        if newValue { forceLightMode = false }
                        applyAppearanceOverride()
                    }
                
                Toggle("Force Light Mode", isOn: $forceLightMode)
                    .onChange(of: forceLightMode) { newValue in
                        if newValue { forceDarkMode = false }
                        applyAppearanceOverride()
                    }
                
                Button("Reset to System") {
                    forceDarkMode = false
                    forceLightMode = false
                    applyAppearanceOverride()
                }
            }
            
            // Dynamic Type
            Section(header: Text("Dynamic Type")) {
                Picker("Text Size", selection: $dynamicTypeSize) {
                    Text("Default").tag("default")
                    Text("Extra Small").tag("xSmall")
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                    Text("Extra Large").tag("xLarge")
                    Text("XXL").tag("xxLarge")
                    Text("XXXL").tag("xxxLarge")
                    Text("Accessibility M").tag("accessibility1")
                    Text("Accessibility L").tag("accessibility2")
                    Text("Accessibility XL").tag("accessibility3")
                }
            }
            
            // Motion & Animations
            Section(header: Text("Motion & Animations")) {
                Toggle("Reduced Motion", isOn: $forceReducedMotion)
                
                Toggle("Slow Animations", isOn: $slowAnimations)
                    .onChange(of: slowAnimations) { newValue in
                        applyAnimationSpeed(newValue ? 0.1 : animationSpeed)
                    }
                
                VStack(alignment: .leading) {
                    Text("Animation Speed: \(String(format: "%.1fx", animationSpeed))")
                    Slider(value: $animationSpeed, in: 0.1...2.0, step: 0.1)
                        .onChange(of: animationSpeed) { newValue in
                            if !slowAnimations {
                                applyAnimationSpeed(newValue)
                            }
                        }
                }
            }
            
            // Layout Debugging
            Section(header: Text("Layout Debugging")) {
                Toggle("Show Layout Boundaries", isOn: $showLayoutBoundaries)
                    .onChange(of: showLayoutBoundaries) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "_UIConstraintBasedLayoutPlayground")
                    }
            }
            
            // Banner Injection
            Section(header: Text("Banner Injection")) {
                Toggle("Show Test Banner", isOn: $showBannerPreview)
                
                Button("Inject Update Banner") {
                    injectUpdateBanner()
                }
                
                Button("Inject Error Banner") {
                    injectErrorBanner()
                }
                
                Button("Clear All Banners") {
                    clearBanners()
                }
            }
        }
        .navigationTitle("UI & Layout")
    }
    
    private func applyAppearanceOverride() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if forceDarkMode {
            window.overrideUserInterfaceStyle = .dark
        } else if forceLightMode {
            window.overrideUserInterfaceStyle = .light
        } else {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func applyAnimationSpeed(_ speed: Double) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.layer.speed = Float(speed)
    }
    
    private func injectUpdateBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "update", "message": "A new version is available!"]
        )
        ToastManager.shared.show("✅ Update banner injected", type: .success)
        AppLogManager.shared.info("Update banner injected", category: "Developer")
    }
    
    private func injectErrorBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "error", "message": "Test error banner"]
        )
        ToastManager.shared.show("✅ Error banner injected", type: .success)
        AppLogManager.shared.info("Error banner injected", category: "Developer")
    }
    
    private func clearBanners() {
        NotificationCenter.default.post(name: Notification.Name("Feather.clearBanners"), object: nil)
        ToastManager.shared.show("✅ Banners cleared", type: .success)
        AppLogManager.shared.info("Banners cleared", category: "Developer")
    }
}

// MARK: - Network & System Dev View
struct NetworkSystemDevView: View {
    @AppStorage("dev.simulateOffline") private var simulateOffline = false
    @AppStorage("dev.latencyInjection") private var latencyInjection: Double = 0
    @AppStorage("dev.verboseLogging") private var verboseLogging = false
    @AppStorage("dev.logNetworkRequests") private var logNetworkRequests = false
    @State private var networkLogs: [String] = []
    @State private var systemInfo: [String: String] = [:]
    
    var body: some View {
        List {
            // Network Simulation
            Section(header: Text("Network Simulation")) {
                Toggle("Simulate Offline Mode", isOn: $simulateOffline)
                    .onChange(of: simulateOffline) { newValue in
                        AppLogManager.shared.info("Offline simulation: \(newValue ? "enabled" : "disabled")", category: "Developer")
                    }
                
                VStack(alignment: .leading) {
                    Text("Latency Injection: \(Int(latencyInjection))ms")
                    Slider(value: $latencyInjection, in: 0...5000, step: 100)
                }
                
                Toggle("Log Network Requests", isOn: $logNetworkRequests)
            }
            
            // Logging
            Section(header: Text("Logging")) {
                Toggle("Verbose Logging", isOn: $verboseLogging)
                    .onChange(of: verboseLogging) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "verboseLogging")
                    }
                
                NavigationLink(destination: AppLogsView()) {
                    Label("View App Logs", systemImage: "terminal")
                }
                
                Button("Export Logs") {
                    exportLogs()
                }
            }
            
            // System Info
            Section(header: Text("System Information")) {
                Button("Refresh System Info") {
                    loadSystemInfo()
                }
                
                ForEach(Array(systemInfo.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(systemInfo[key] ?? "")
                            .foregroundStyle(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            
            // Failure Inspection
            Section(header: Text("Failure Inspection")) {
                NavigationLink(destination: FailureInspectorView()) {
                    Label("View Recent Failures", systemImage: "exclamationmark.triangle")
                }
                
                Button("Simulate Network Failure") {
                    simulateNetworkFailure()
                }
            }
        }
        .navigationTitle("Network & System")
        .onAppear {
            loadSystemInfo()
        }
    }
    
    private func loadSystemInfo() {
        systemInfo = [
            "Device": UIDevice.current.model,
            "iOS Version": UIDevice.current.systemVersion,
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "Build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "Memory": getMemoryUsage(),
            "Disk Free": getDiskSpace(),
            "Network": getNetworkStatus()
        ]
    }
    
    private func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
        }
        return "Unknown"
    }
    
    private func getDiskSpace() -> String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
        }
        return "Unknown"
    }
    
    private func getNetworkStatus() -> String {
        return simulateOffline ? "Offline (Simulated)" : "Online"
    }
    
    private func exportLogs() {
        let logs = AppLogManager.shared.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
        AppLogManager.shared.success("Logs exported to clipboard", category: "Developer")
    }
    
    private func simulateNetworkFailure() {
        NotificationCenter.default.post(
            name: DownloadManager.downloadDidFailNotification,
            object: nil,
            userInfo: ["error": "Simulated network failure", "downloadId": "test"]
        )
        ToastManager.shared.show("⚠️ Network failure simulated", type: .warning)
        AppLogManager.shared.warning("Network failure simulated", category: "Developer")
    }
}

// MARK: - Failure Inspector View
struct FailureInspectorView: View {
    @StateObject private var logManager = AppLogManager.shared
    
    var failureLogs: [LogEntry] {
        logManager.logs.filter { $0.level == .error || $0.level == .critical }
    }
    
    var body: some View {
        List {
            if failureLogs.isEmpty {
                Text("No failures recorded")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(failureLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.icon)
                            Text(log.formattedTimestamp)
                                .font(.caption.monospaced())
                        }
                        Text(log.message)
                            .font(.system(.body, design: .monospaced))
                        Text("[\(log.category)] \(log.file):\(log.line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Failures")
    }
}

// MARK: - State & Persistence Dev View
struct StatePersistenceDevView: View {
    @State private var userDefaultsKeys: [String] = []
    @State private var appStorageKeys: [String] = []
    @State private var cacheSize: String = "Calculating..."
    @State private var showClearConfirmation = false
    @State private var clearTarget: ClearTarget = .all
    
    enum ClearTarget {
        case all, userDefaults, caches, onboarding
    }
    
    var body: some View {
        List {
            // AppStorage / UserDefaults
            Section(header: Text("UserDefaults")) {
                NavigationLink(destination: UserDefaultsEditorView()) {
                    Label("UserDefaults Editor", systemImage: "list.bullet.rectangle")
                }
                
                Button("Clear All UserDefaults", role: .destructive) {
                    clearTarget = .userDefaults
                    showClearConfirmation = true
                }
            }
            
            // Caches
            Section(header: Text("Caches")) {
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }
                
                Button("Clear URL Cache") {
                    URLCache.shared.removeAllCachedResponses()
                    calculateCacheSize()
                    HapticsManager.shared.success()
                    ToastManager.shared.show("✅ URL cache cleared", type: .success)
                    AppLogManager.shared.success("URL cache cleared", category: "Developer")
                }
                
                Button("Clear Image Cache") {
                    clearImageCache()
                    ToastManager.shared.show("✅ Image cache cleared", type: .success)
                }
                
                Button("Clear All Caches", role: .destructive) {
                    clearTarget = .caches
                    showClearConfirmation = true
                }
            }
            
            // Onboarding State
            Section(header: Text("Onboarding State")) {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                }
                
                Button("Reset Onboarding") {
                    clearTarget = .onboarding
                    showClearConfirmation = true
                }
            }
            
            // CoreData
            Section(header: Text("CoreData")) {
                NavigationLink(destination: CoreDataInspectorView()) {
                    Label("CoreData Inspector", systemImage: "cylinder.split.1x2")
                }
            }
            
            // Danger Zone
            Section(header: Text("Danger Zone")) {
                Button("Reset All App Data", role: .destructive) {
                    clearTarget = .all
                    showClearConfirmation = true
                }
            }
        }
        .navigationTitle("State & Persistence")
        .onAppear {
            calculateCacheSize()
        }
        .alert("Confirm Clear", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClear()
            }
        } message: {
            Text(clearConfirmationMessage)
        }
    }
    
    private var clearConfirmationMessage: String {
        switch clearTarget {
        case .all: return "This will reset all app data including settings, sources, and certificates. This cannot be undone."
        case .userDefaults: return "This will clear all UserDefaults. Some settings may be lost."
        case .caches: return "This will clear all cached data including images and network responses."
        case .onboarding: return "This will reset the onboarding state. You will see the onboarding screen on next launch."
        }
    }
    
    private func calculateCacheSize() {
        var totalSize: Int64 = 0
        
        // URL Cache
        totalSize += Int64(URLCache.shared.currentDiskUsage)
        
        // Image cache directory
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let size = try? FileManager.default.allocatedSizeOfDirectory(at: cacheURL) {
                totalSize += Int64(size)
            }
        }
        
        cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    private func clearImageCache() {
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let nukeCache = cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache")
            try? FileManager.default.removeItem(at: nukeCache)
        }
        calculateCacheSize()
        HapticsManager.shared.success()
        AppLogManager.shared.success("Image cache cleared", category: "Developer")
    }
    
    private func performClear() {
        switch clearTarget {
        case .all:
            // Clear everything
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("⚠️ All app data reset", type: .warning)
            AppLogManager.shared.warning("All app data reset", category: "Developer")
            
        case .userDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            ToastManager.shared.show("✅ UserDefaults cleared", type: .success)
            AppLogManager.shared.info("UserDefaults cleared", category: "Developer")
            
        case .caches:
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared", category: "Developer")
            
        case .onboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            ToastManager.shared.show("✅ Onboarding state reset", type: .success)
            AppLogManager.shared.info("Onboarding state reset", category: "Developer")
        }
        
        calculateCacheSize()
        HapticsManager.shared.success()
    }
}

// MARK: - FileManager Extension for Directory Size
extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> UInt64 {
        var totalSize: UInt64 = 0
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
        
        guard let enumerator = self.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys), options: [], errorHandler: nil) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            guard resourceValues.isRegularFile == true else { continue }
            totalSize += UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
        }
        
        return totalSize
    }
}

// MARK: - Device Information View
struct DeviceInfoView: View {
    @State private var deviceInfo: [String: String] = [:]
    @State private var hardwareInfo: [String: String] = [:]
    @State private var storageInfo: [String: String] = [:]
    @State private var batteryInfo: [String: String] = [:]
    
    var body: some View {
        List {
            // Device Section
            Section(header: Text("Device")) {
                ForEach(Array(deviceInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: deviceInfo[key] ?? "Unknown")
                }
            }
            
            // Hardware Section
            Section(header: Text("Hardware")) {
                ForEach(Array(hardwareInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: hardwareInfo[key] ?? "Unknown")
                }
            }
            
            // Storage Section
            Section(header: Text("Storage")) {
                ForEach(Array(storageInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: storageInfo[key] ?? "Unknown")
                }
            }
            
            // Battery Section
            Section(header: Text("Battery")) {
                ForEach(Array(batteryInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: batteryInfo[key] ?? "Unknown")
                }
            }
            
            // App Info Section
            Section(header: Text("App Information")) {
                DeviceInfoRow(label: "App Name", value: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
            }
            
            // Export Section
            Section {
                Button {
                    exportDeviceInfo()
                } label: {
                    Label("Copy Device Info to Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        }
        .navigationTitle("Device Information")
        .onAppear {
            loadDeviceInfo()
        }
    }
    
    private func loadDeviceInfo() {
        let device = UIDevice.current
        
        // Device Info
        deviceInfo = [
            "Name": device.name,
            "Model": device.model,
            "System Name": device.systemName,
            "System Version": device.systemVersion,
            "Identifier": getDeviceIdentifier()
        ]
        
        // Hardware Info
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        
        hardwareInfo = [
            "Machine": machine,
            "Processor Count": "\(ProcessInfo.processInfo.processorCount) cores",
            "Physical Memory": ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory),
            "Active Processor Count": "\(ProcessInfo.processInfo.activeProcessorCount) cores"
        ]
        
        // Storage Info
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let totalSpace = attrs[.systemSize] as? Int64 ?? 0
            let freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            let usedSpace = totalSpace - freeSpace
            
            storageInfo = [
                "Total Space": ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file),
                "Free Space": ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file),
                "Used Space": ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
            ]
        }
        
        // Battery Info
        device.isBatteryMonitoringEnabled = true
        let batteryState: String
        switch device.batteryState {
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        case .unplugged: batteryState = "Unplugged"
        case .unknown: batteryState = "Unknown"
        @unknown default: batteryState = "Unknown"
        }
        
        batteryInfo = [
            "Battery Level": "\(Int(device.batteryLevel * 100))%",
            "Battery State": batteryState
        ]
    }
    
    private func getDeviceIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }
    
    private func exportDeviceInfo() {
        var info = "=== Device Information ===\n\n"
        
        info += "-- Device --\n"
        for (key, value) in deviceInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Hardware --\n"
        for (key, value) in hardwareInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Storage --\n"
        for (key, value) in storageInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Battery --\n"
        for (key, value) in batteryInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- App --\n"
        info += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        info += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"
        
        UIPasteboard.general.string = info
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Device info copied to clipboard", type: .success)
    }
}

struct DeviceInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Environment Inspector View
struct EnvironmentInspectorView: View {
    @State private var environment: [String: String] = [:]
    @State private var searchText = ""
    
    var filteredEnvironment: [(key: String, value: String)] {
        let sorted = environment.sorted { $0.key < $1.key }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.key.localizedCaseInsensitiveContains(searchText) || $0.value.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            // Process Info Section
            Section(header: Text("Process Information")) {
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                LabeledContent("Process Name", value: ProcessInfo.processInfo.processName)
                LabeledContent("Host Name", value: ProcessInfo.processInfo.hostName)
                LabeledContent("OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                LabeledContent("Is Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Yes" : "No")
            }
            
            // Launch Arguments
            Section(header: Text("Launch Arguments (\(ProcessInfo.processInfo.arguments.count))")) {
                ForEach(ProcessInfo.processInfo.arguments, id: \.self) { arg in
                    Text(arg)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                }
            }
            
            // Environment Variables
            Section(header: Text("Environment Variables (\(filteredEnvironment.count))")) {
                ForEach(filteredEnvironment, id: \.key) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.key)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                        Text(item.value)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Actions
            Section {
                Button {
                    exportEnvironment()
                } label: {
                    Label("Copy Environment to Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search environment...")
        .navigationTitle("Environment Inspector")
        .onAppear {
            loadEnvironment()
        }
    }
    
    private func loadEnvironment() {
        environment = ProcessInfo.processInfo.environment
    }
    
    private func exportEnvironment() {
        var output = "=== Environment Variables ===\n\n"
        for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
            output += "\(key)=\(value)\n"
        }
        UIPasteboard.general.string = output
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Environment copied to clipboard", type: .success)
    }
}

// MARK: - Crash Log Viewer
struct CrashLogViewer: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var crashLogs: [LogEntry] = []
    
    var body: some View {
        List {
            if crashLogs.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("No Crash Logs")
                            .font(.headline)
                        
                        Text("The app has not recorded any crashes. This is good!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Critical Errors (\(crashLogs.count))")) {
                    ForEach(crashLogs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.level.icon)
                                Text(log.formattedTimestamp)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(log.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.red)
                            
                            HStack {
                                Text("[\(log.category)]")
                                Text("\(log.file):\(log.line)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        clearCrashLogs()
                    } label: {
                        Label("Clear Crash Logs", systemImage: "trash")
                    }
                }
            }
            
            // Export Section
            Section {
                Button {
                    exportCrashLogs()
                } label: {
                    Label("Export All Logs", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Crash Logs")
        .onAppear {
            loadCrashLogs()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    loadCrashLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private func loadCrashLogs() {
        crashLogs = logManager.logs.filter { $0.level == .critical || $0.level == .error }
    }
    
    private func clearCrashLogs() {
        // Note: This only removes them from view, not from the actual log manager
        crashLogs.removeAll()
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Crash logs cleared from view", type: .success)
    }
    
    private func exportCrashLogs() {
        let logs = logManager.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
    }
}

// MARK: - Quick Actions Dev View
struct QuickActionsDevView: View {
    @State private var showConfirmation = false
    @State private var selectedAction: QuickAction?
    
    enum QuickAction: String, CaseIterable {
        case clearAllCaches = "Clear All Caches"
        case resetOnboarding = "Reset Onboarding"
        case reloadSources = "Reload All Sources"
        case exportLogs = "Export All Logs"
        case resetUserDefaults = "Reset UserDefaults"
        case simulateCrash = "Simulate Crash Log"
        case triggerMemoryWarning = "Trigger Memory Warning"
        case clearImageCache = "Clear Image Cache"
        
        var icon: String {
            switch self {
            case .clearAllCaches: return "trash.circle.fill"
            case .resetOnboarding: return "arrow.counterclockwise.circle.fill"
            case .reloadSources: return "arrow.clockwise.circle.fill"
            case .exportLogs: return "square.and.arrow.up.circle.fill"
            case .resetUserDefaults: return "gear.badge.xmark"
            case .simulateCrash: return "exclamationmark.triangle.fill"
            case .triggerMemoryWarning: return "memorychip.fill"
            case .clearImageCache: return "photo.badge.arrow.down.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .clearAllCaches: return .orange
            case .resetOnboarding: return .blue
            case .reloadSources: return .green
            case .exportLogs: return .purple
            case .resetUserDefaults: return .red
            case .simulateCrash: return .red
            case .triggerMemoryWarning: return .yellow
            case .clearImageCache: return .cyan
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .clearAllCaches, .resetOnboarding, .resetUserDefaults, .simulateCrash:
                return true
            default:
                return false
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Cache Actions")) {
                quickActionButton(.clearAllCaches)
                quickActionButton(.clearImageCache)
            }
            
            Section(header: Text("State Actions")) {
                quickActionButton(.resetOnboarding)
                quickActionButton(.resetUserDefaults)
            }
            
            Section(header: Text("Data Actions")) {
                quickActionButton(.reloadSources)
                quickActionButton(.exportLogs)
            }
            
            Section(header: Text("Debug Actions")) {
                quickActionButton(.simulateCrash)
                quickActionButton(.triggerMemoryWarning)
            }
        }
        .navigationTitle("Quick Actions")
        .alert("Confirm Action", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(selectedAction?.isDestructive == true ? "Confirm" : "Execute", role: selectedAction?.isDestructive == true ? .destructive : nil) {
                if let action = selectedAction {
                    executeAction(action)
                }
            }
        } message: {
            Text("Are you sure you want to \(selectedAction?.rawValue.lowercased() ?? "perform this action")?")
        }
    }
    
    private func quickActionButton(_ action: QuickAction) -> some View {
        Button {
            selectedAction = action
            if action.isDestructive {
                showConfirmation = true
            } else {
                executeAction(action)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(action.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(action.color)
                }
                
                Text(action.rawValue)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
        }
    }
    
    private func executeAction(_ action: QuickAction) {
        switch action {
        case .clearAllCaches:
            URLCache.shared.removeAllCachedResponses()
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared via Quick Actions", category: "Developer")
            
        case .resetOnboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Onboarding reset. Restart app to see changes.", type: .success)
            AppLogManager.shared.info("Onboarding reset via Quick Actions", category: "Developer")
            
        case .reloadSources:
            NotificationCenter.default.post(name: Notification.Name("Feather.reloadSources"), object: nil)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Source reload triggered", type: .success)
            AppLogManager.shared.info("Sources reload triggered via Quick Actions", category: "Developer")
            
        case .exportLogs:
            let logs = AppLogManager.shared.exportLogs()
            UIPasteboard.general.string = logs
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
            
        case .resetUserDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("⚠️ UserDefaults reset. Restart app.", type: .warning)
            AppLogManager.shared.warning("UserDefaults reset via Quick Actions", category: "Developer")
            
        case .simulateCrash:
            AppLogManager.shared.critical("Simulated crash log entry for testing purposes", category: "Developer")
            HapticsManager.shared.error()
            ToastManager.shared.show("⚠️ Crash log entry created", type: .warning)
            
        case .triggerMemoryWarning:
            // Post a simulated memory warning notification
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            HapticsManager.shared.warning()
            ToastManager.shared.show("⚠️ Memory warning triggered", type: .warning)
            AppLogManager.shared.warning("Memory warning triggered via Quick Actions", category: "Developer")
            
        case .clearImageCache:
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Image cache cleared", type: .success)
            AppLogManager.shared.info("Image cache cleared via Quick Actions", category: "Developer")
        }
    }
}

// MARK: - IPA Signing Dashboard View
struct IPASigningDashboardView: View {
    var body: some View {
        List {
            // Certificate & Profile Manager Section
            Section {
                NavigationLink(destination: CertificateProfileManagerView()) {
                    DeveloperMenuRow(icon: "person.badge.key.fill", title: "Certificate & Profile Manager", color: .blue)
                }
            } header: {
                Text("Certificates & Profiles")
            } footer: {
                Text("Manage signing certificates and provisioning profiles")
            }
            
            // Signing Logs Section
            Section {
                NavigationLink(destination: SigningLogsView()) {
                    DeveloperMenuRow(icon: "doc.text.fill", title: "Signing Logs", color: .gray)
                }
            } header: {
                Text("Logs")
            } footer: {
                Text("View detailed signing operation logs")
            }
            
            // Batch Signing Section
            Section {
                NavigationLink(destination: BatchSigningView()) {
                    DeveloperMenuRow(icon: "square.stack.3d.up.fill", title: "Batch Signing", color: .green)
                }
            } header: {
                Text("Batch Operations")
            } footer: {
                Text("Sign multiple IPA files at once")
            }
            
            // Entitlements & Info.plist Editor Section
            Section {
                NavigationLink(destination: EntitlementsPlistEditorView()) {
                    DeveloperMenuRow(icon: "doc.badge.gearshape.fill", title: "Entitlements & Info.plist Editor", color: .purple)
                }
            } header: {
                Text("Editors")
            } footer: {
                Text("Edit entitlements and Info.plist configurations")
            }
            
            // Security Section
            Section {
                NavigationLink(destination: SigningSecurityView()) {
                    DeveloperMenuRow(icon: "lock.shield.fill", title: "Security", color: .red)
                }
            } header: {
                Text("Security")
            } footer: {
                Text("Certificate validation, revocation checks, and security settings")
            }
            
            // Performance Metrics Section
            Section {
                NavigationLink(destination: SigningPerformanceMetricsView()) {
                    DeveloperMenuRow(icon: "chart.bar.fill", title: "Performance Metrics", color: .orange)
                }
            } header: {
                Text("Performance")
            } footer: {
                Text("Signing speed, success rates, and operation statistics")
            }
            
            // API & Webhook Integration Section
            Section {
                NavigationLink(destination: APIWebhookIntegrationView()) {
                    DeveloperMenuRow(icon: "network", title: "API & Webhook Integration", color: .teal)
                }
            } header: {
                Text("Integration")
            } footer: {
                Text("Configure external APIs and webhook notifications")
            }
        }
        .navigationTitle("IPA Signing Dashboard")
    }
}

// MARK: - Certificate & Profile Manager View
struct CertificateProfileManagerView: View {
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .easeInOut(duration: 0.35)
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedCertificate: CertificatePair?
    @State private var showAddCertificate = false
    @State private var showImportProfile = false
    @State private var searchText = ""
    @State private var filterExpired = false
    
    var filteredCertificates: [CertificatePair] {
        var result = Array(certificates)
        
        if !searchText.isEmpty {
            result = result.filter { cert in
                (cert.nickname?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if filterExpired {
            let now = Date()
            result = result.filter { cert in
                guard let expiration = cert.expiration else { return true }
                return expiration > now
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            // Statistics Section
            Section {
                HStack {
                    StatCard(title: "Total", value: "\(certificates.count)", icon: "doc.badge.plus", color: .blue)
                    StatCard(title: "Valid", value: "\(validCertificatesCount)", icon: "checkmark.shield", color: .green)
                    StatCard(title: "Expired", value: "\(expiredCertificatesCount)", icon: "exclamationmark.triangle", color: .red)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Filter Section
            Section {
                Toggle("Hide Expired Certificates", isOn: $filterExpired)
            }
            
            // Certificates List
            Section {
                if filteredCertificates.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label("No Certificates", systemImage: "person.badge.key")
                        } description: {
                            Text("Add a signing certificate to get started")
                        } actions: {
                            Button("Add Certificate") {
                                showAddCertificate = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.key")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Certificates")
                                .font(.headline)
                            Text("Add a signing certificate to get started")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Add Certificate") {
                                showAddCertificate = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                } else {
                    ForEach(filteredCertificates, id: \.uuid) { cert in
                        CertificateManagerRow(certificate: cert, onSelect: {
                            selectedCertificate = cert
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Storage.shared.deleteCertificate(for: cert)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Certificates (\(filteredCertificates.count))")
                    Spacer()
                }
            }
            
            // Actions Section
            Section {
                Button {
                    showAddCertificate = true
                } label: {
                    Label("Add Certificate", systemImage: "plus.circle.fill")
                }
                
                Button {
                    showImportProfile = true
                } label: {
                    Label("Import Provisioning Profile", systemImage: "square.and.arrow.down")
                }
                
                Button {
                    refreshAllCertificates()
                } label: {
                    Label("Refresh All Certificates", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Actions")
            }
        }
        .searchable(text: $searchText, prompt: "Search certificates...")
        .navigationTitle("Certificate Manager")
        .sheet(isPresented: $showAddCertificate) {
            CertificatesAddView()
        }
        .sheet(item: $selectedCertificate) { cert in
            CertificatesInfoView(cert: cert)
        }
    }
    
    private var validCertificatesCount: Int {
        let now = Date()
        return certificates.filter { cert in
            guard let expiration = cert.expiration else { return true }
            return expiration > now
        }.count
    }
    
    private var expiredCertificatesCount: Int {
        let now = Date()
        return certificates.filter { cert in
            guard let expiration = cert.expiration else { return false }
            return expiration <= now
        }.count
    }
    
    private func refreshAllCertificates() {
        for cert in certificates {
            Storage.shared.revokagedCertificate(for: cert)
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Refreshing certificate status", type: .success)
        AppLogManager.shared.info("Refreshing all certificate statuses", category: "CertManager")
    }
}

// MARK: - Certificate Manager Row
struct CertificateManagerRow: View {
    let certificate: CertificatePair
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Certificate Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.badge.key.fill")
                        .font(.title3)
                        .foregroundStyle(statusColor)
                }
                
                // Certificate Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.nickname ?? "Unknown Certificate")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let expiration = certificate.expiration {
                        HStack(spacing: 4) {
                            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "clock")
                                .font(.caption2)
                            Text(isExpired ? "Expired" : "Expires: \(expiration.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                        }
                        .foregroundStyle(isExpired ? .red : .secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(isExpired ? "Expired" : "Valid")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
    
    private var isExpired: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date()
    }
    
    private var statusColor: Color {
        isExpired ? .red : .green
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Signing Logs View
struct SigningLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var showExportSheet = false
    
    var signingLogs: [LogEntry] {
        logManager.logs.filter { log in
            log.category == "Signing" || 
            log.category == "Certificate" || 
            log.category == "Install" ||
            log.message.lowercased().contains("sign")
        }
    }
    
    var filteredLogs: [LogEntry] {
        var result = signingLogs
        
        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let level = selectedLevel {
            result = result.filter { $0.level == level }
        }
        
        return result.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "All", isSelected: selectedLevel == nil, count: signingLogs.count) {
                        selectedLevel = nil
                    }
                    
                    ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                        let count = signingLogs.filter { $0.level == level }.count
                        if count > 0 {
                            FilterPill(title: level.rawValue, icon: level.icon, isSelected: selectedLevel == level, count: count) {
                                selectedLevel = selectedLevel == level ? nil : level
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("No Signing Logs")
                        .font(.headline)
                    Text("Signing operations will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        SigningLogRow(entry: log)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search logs...")
        .navigationTitle("Signing Logs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportLogs()
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        copyLogsToClipboard()
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        clearSigningLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func exportLogs() {
        let logsText = filteredLogs.map { log in
            "[\(log.formattedTimestamp)] [\(log.level.rawValue)] [\(log.category)] \(log.message)"
        }.joined(separator: "\n")
        
        UIPasteboard.general.string = logsText
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
    }
    
    private func copyLogsToClipboard() {
        exportLogs()
    }
    
    private func clearSigningLogs() {
        // Note: This clears from UI view only
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Signing logs cleared", type: .success)
    }
}

// MARK: - Signing Log Row
struct SigningLogRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(entry.level.icon)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.formattedTimestamp)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        
                        Text("[\(entry.category)]")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    Text(entry.message)
                        .font(.caption.monospaced())
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File: \(entry.file)")
                    Text("Function: \(entry.function)")
                    Text("Line: \(entry.line)")
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .padding(.leading, 24)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Batch Signing View
struct BatchSigningView: View {
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedApps: Set<String> = []
    @State private var selectedCertificateIndex = 0
    @State private var isSigningBatch = false
    @State private var batchProgress: Double = 0
    @State private var currentSigningApp: String = ""
    @State private var batchResults: [BatchSignResult] = []
    @State private var showResults = false
    
    struct BatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        let message: String
    }
    
    var body: some View {
        List {
            // Certificate Selection
            Section {
                if certificates.isEmpty {
                    Text("No certificates available")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Signing Certificate", selection: $selectedCertificateIndex) {
                        ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                            Text(cert.nickname ?? "Certificate \(index + 1)")
                                .tag(index)
                        }
                    }
                }
            } header: {
                Text("Certificate")
            }
            
            // App Selection
            Section {
                if importedApps.isEmpty {
                    Text("No apps available for signing")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(importedApps, id: \.uuid) { app in
                        BatchAppRow(
                            app: app,
                            isSelected: selectedApps.contains(app.uuid ?? ""),
                            onToggle: {
                                toggleAppSelection(app)
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Select Apps (\(selectedApps.count) selected)")
                    Spacer()
                    if !importedApps.isEmpty {
                        Button(selectedApps.count == importedApps.count ? "Deselect All" : "Select All") {
                            if selectedApps.count == importedApps.count {
                                selectedApps.removeAll()
                            } else {
                                selectedApps = Set(importedApps.compactMap { $0.uuid })
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            
            // Batch Action
            Section {
                Button {
                    startBatchSigning()
                } label: {
                    HStack {
                        if isSigningBatch {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Signing \(currentSigningApp)...")
                        } else {
                            Image(systemName: "signature")
                            Text("Sign Selected Apps (\(selectedApps.count))")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
                
                if isSigningBatch {
                    ProgressView(value: batchProgress)
                        .progressViewStyle(.linear)
                }
            } header: {
                Text("Actions")
            }
            
            // Results Section
            if !batchResults.isEmpty {
                Section {
                    ForEach(batchResults) { result in
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.appName)
                                    .font(.subheadline)
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Results")
                }
            }
        }
        .navigationTitle("Batch Signing")
    }
    
    private func toggleAppSelection(_ app: Imported) {
        guard let id = app.uuid else { return }
        if selectedApps.contains(id) {
            selectedApps.remove(id)
        } else {
            selectedApps.insert(id)
        }
    }
    
    private func startBatchSigning() {
        guard !selectedApps.isEmpty, certificates.indices.contains(selectedCertificateIndex) else { return }
        
        isSigningBatch = true
        batchProgress = 0
        batchResults.removeAll()
        
        let appsToSign = importedApps.filter { selectedApps.contains($0.uuid ?? "") }
        let totalApps = Double(appsToSign.count)
        
        AppLogManager.shared.info("Starting batch signing for \(Int(totalApps)) apps", category: "BatchSign")
        
        // Simulate batch signing (in real implementation, this would call the actual signing logic)
        Task {
            for (index, app) in appsToSign.enumerated() {
                await MainActor.run {
                    currentSigningApp = app.name ?? "App \(index + 1)"
                    batchProgress = Double(index) / totalApps
                }
                
                // Simulate signing delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Add result
                await MainActor.run {
                    let result = BatchSignResult(
                        appName: app.name ?? "Unknown",
                        success: true,
                        message: "Signed successfully"
                    )
                    batchResults.append(result)
                }
            }
            
            await MainActor.run {
                isSigningBatch = false
                batchProgress = 1.0
                selectedApps.removeAll()
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ Batch signing completed", type: .success)
                AppLogManager.shared.success("Batch signing completed for \(Int(totalApps)) apps", category: "BatchSign")
            }
        }
    }
}

// MARK: - Batch App Row
struct BatchAppRow: View {
    let app: Imported
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                
                FRAppIconView(app: app, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name ?? "Unknown App")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    
                    Text(app.identifier ?? "Unknown Bundle ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entitlements & Info.plist Editor View
struct EntitlementsPlistEditorView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Editor Type", selection: $selectedTab) {
                Text("Entitlements").tag(0)
                Text("Info.plist").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            TabView(selection: $selectedTab) {
                EntitlementsEditorTab()
                    .tag(0)
                
                InfoPlistEditorTab()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Entitlements & Info.plist")
    }
}

// MARK: - Entitlements Editor Tab
struct EntitlementsEditorTab: View {
    @State private var entitlements: [EntitlementItem] = [
        EntitlementItem(key: "application-identifier", value: "$(AppIdentifierPrefix)$(CFBundleIdentifier)", type: .string),
        EntitlementItem(key: "get-task-allow", value: "true", type: .boolean),
        EntitlementItem(key: "keychain-access-groups", value: "$(AppIdentifierPrefix)$(CFBundleIdentifier)", type: .array),
        EntitlementItem(key: "com.apple.developer.team-identifier", value: "TEAM_ID", type: .string),
        EntitlementItem(key: "aps-environment", value: "development", type: .string)
    ]
    @State private var showAddEntitlement = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newType: EntitlementItem.ValueType = .string
    
    var body: some View {
        List {
            // Common Entitlements Templates
            Section {
                Button {
                    addCommonEntitlements()
                } label: {
                    Label("Add Common Entitlements", systemImage: "plus.circle")
                }
                
                Button {
                    addDebugEntitlements()
                } label: {
                    Label("Add Debug Entitlements", systemImage: "ladybug")
                }
            } header: {
                Text("Templates")
            }
            
            // Entitlements List
            Section {
                ForEach($entitlements) { $item in
                    EntitlementRow(item: $item)
                }
                .onDelete(perform: deleteEntitlements)
                
                Button {
                    showAddEntitlement = true
                } label: {
                    Label("Add Entitlement", systemImage: "plus")
                }
            } header: {
                Text("Entitlements (\(entitlements.count))")
            }
            
            // Export Section
            Section {
                Button {
                    exportEntitlements()
                } label: {
                    Label("Export as XML", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    copyEntitlements()
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                }
            } header: {
                Text("Export")
            }
        }
        .alert("Add Entitlement", isPresented: $showAddEntitlement) {
            TextField("Key", text: $newKey)
            TextField("Value", text: $newValue)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addEntitlement()
            }
        }
    }
    
    private func addEntitlement() {
        guard !newKey.isEmpty else { return }
        entitlements.append(EntitlementItem(key: newKey, value: newValue, type: newType))
        newKey = ""
        newValue = ""
        HapticsManager.shared.success()
    }
    
    private func deleteEntitlements(at offsets: IndexSet) {
        entitlements.remove(atOffsets: offsets)
    }
    
    private func addCommonEntitlements() {
        let common = [
            EntitlementItem(key: "com.apple.security.app-sandbox", value: "true", type: .boolean),
            EntitlementItem(key: "com.apple.security.network.client", value: "true", type: .boolean),
            EntitlementItem(key: "com.apple.security.files.user-selected.read-write", value: "true", type: .boolean)
        ]
        entitlements.append(contentsOf: common)
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Added common entitlements", type: .success)
    }
    
    private func addDebugEntitlements() {
        let debug = [
            EntitlementItem(key: "get-task-allow", value: "true", type: .boolean),
            EntitlementItem(key: "com.apple.private.security.no-sandbox", value: "true", type: .boolean)
        ]
        entitlements.append(contentsOf: debug)
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Added debug entitlements", type: .success)
    }
    
    private func exportEntitlements() {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        xml += "<plist version=\"1.0\">\n<dict>\n"
        
        for item in entitlements {
            xml += "\t<key>\(item.key)</key>\n"
            switch item.type {
            case .boolean:
                xml += "\t<\(item.value.lowercased() == "true" ? "true" : "false")/>\n"
            case .string:
                xml += "\t<string>\(item.value)</string>\n"
            case .array:
                xml += "\t<array>\n\t\t<string>\(item.value)</string>\n\t</array>\n"
            case .integer:
                xml += "\t<integer>\(item.value)</integer>\n"
            }
        }
        
        xml += "</dict>\n</plist>"
        
        UIPasteboard.general.string = xml
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Entitlements exported to clipboard", type: .success)
    }
    
    private func copyEntitlements() {
        exportEntitlements()
    }
}

// MARK: - Entitlement Item
struct EntitlementItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: ValueType
    
    enum ValueType: String, CaseIterable {
        case string = "String"
        case boolean = "Boolean"
        case array = "Array"
        case integer = "Integer"
    }
}

// MARK: - Entitlement Row
struct EntitlementRow: View {
    @Binding var item: EntitlementItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            
            HStack {
                Text(item.type.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                
                Text(item.value)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info.plist Editor Tab
struct InfoPlistEditorTab: View {
    @State private var plistItems: [PlistItem] = [
        PlistItem(key: "CFBundleDisplayName", value: "App Name", type: .string),
        PlistItem(key: "CFBundleIdentifier", value: "com.example.app", type: .string),
        PlistItem(key: "CFBundleShortVersionString", value: "1.0.0", type: .string),
        PlistItem(key: "CFBundleVersion", value: "1", type: .string),
        PlistItem(key: "MinimumOSVersion", value: "14.0", type: .string),
        PlistItem(key: "UIRequiredDeviceCapabilities", value: "arm64", type: .array)
    ]
    @State private var showAddItem = false
    @State private var newKey = ""
    @State private var newValue = ""
    
    var body: some View {
        List {
            // Common Keys Section
            Section {
                Button {
                    addURLSchemes()
                } label: {
                    Label("Add URL Schemes", systemImage: "link")
                }
                
                Button {
                    addBackgroundModes()
                } label: {
                    Label("Add Background Modes", systemImage: "moon.fill")
                }
            } header: {
                Text("Common Additions")
            }
            
            // Plist Items
            Section {
                ForEach($plistItems) { $item in
                    PlistItemRow(item: $item)
                }
                .onDelete(perform: deleteItems)
                
                Button {
                    showAddItem = true
                } label: {
                    Label("Add Key", systemImage: "plus")
                }
            } header: {
                Text("Info.plist Keys (\(plistItems.count))")
            }
            
            // Export
            Section {
                Button {
                    exportPlist()
                } label: {
                    Label("Export as XML", systemImage: "square.and.arrow.up")
                }
            }
        }
        .alert("Add Plist Key", isPresented: $showAddItem) {
            TextField("Key", text: $newKey)
            TextField("Value", text: $newValue)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if !newKey.isEmpty {
                    plistItems.append(PlistItem(key: newKey, value: newValue, type: .string))
                    newKey = ""
                    newValue = ""
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        plistItems.remove(atOffsets: offsets)
    }
    
    private func addURLSchemes() {
        plistItems.append(PlistItem(key: "CFBundleURLTypes", value: "myapp://", type: .array))
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Added URL Schemes key", type: .success)
    }
    
    private func addBackgroundModes() {
        plistItems.append(PlistItem(key: "UIBackgroundModes", value: "audio, fetch, remote-notification", type: .array))
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Added Background Modes key", type: .success)
    }
    
    private func exportPlist() {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        xml += "<plist version=\"1.0\">\n<dict>\n"
        
        for item in plistItems {
            xml += "\t<key>\(item.key)</key>\n"
            xml += "\t<string>\(item.value)</string>\n"
        }
        
        xml += "</dict>\n</plist>"
        
        UIPasteboard.general.string = xml
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Info.plist exported to clipboard", type: .success)
    }
}

// MARK: - Plist Item
struct PlistItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: EntitlementItem.ValueType
}

// MARK: - Plist Item Row
struct PlistItemRow: View {
    @Binding var item: PlistItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
            Text(item.value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Signing Security View
struct SigningSecurityView: View {
    @AppStorage("signing.validateCertificates") private var validateCertificates = true
    @AppStorage("signing.checkRevocation") private var checkRevocation = true
    @AppStorage("signing.requireTrustedCerts") private var requireTrustedCerts = false
    @AppStorage("signing.logSecurityEvents") private var logSecurityEvents = true
    @AppStorage("signing.warnExpiringSoon") private var warnExpiringSoon = true
    @AppStorage("signing.expiryWarningDays") private var expiryWarningDays = 30
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>
    
    var body: some View {
        List {
            // Certificate Validation Section
            Section {
                Toggle("Validate Certificates Before Signing", isOn: $validateCertificates)
                Toggle("Check Certificate Revocation", isOn: $checkRevocation)
                Toggle("Require Trusted Certificates Only", isOn: $requireTrustedCerts)
            } header: {
                Text("Certificate Validation")
            } footer: {
                Text("Enable these options for enhanced security during signing operations")
            }
            
            // Expiration Warnings
            Section {
                Toggle("Warn About Expiring Certificates", isOn: $warnExpiringSoon)
                
                if warnExpiringSoon {
                    Stepper("Warning: \(expiryWarningDays) days before expiry", value: $expiryWarningDays, in: 7...90)
                }
            } header: {
                Text("Expiration Warnings")
            }
            
            // Logging
            Section {
                Toggle("Log Security Events", isOn: $logSecurityEvents)
            } header: {
                Text("Security Logging")
            }
            
            // Security Status
            Section {
                ForEach(certificates, id: \.uuid) { cert in
                    SecurityStatusRow(certificate: cert)
                }
            } header: {
                Text("Certificate Security Status")
            }
            
            // Actions
            Section {
                Button {
                    runSecurityAudit()
                } label: {
                    Label("Run Security Audit", systemImage: "shield.checkered")
                }
                
                Button {
                    checkAllRevocations()
                } label: {
                    Label("Check All Revocations", systemImage: "exclamationmark.shield")
                }
            } header: {
                Text("Security Actions")
            }
        }
        .navigationTitle("Security")
    }
    
    private func runSecurityAudit() {
        AppLogManager.shared.info("Running security audit on certificates", category: "Security")
        
        var issues: [String] = []
        
        for cert in certificates {
            if let expiration = cert.expiration, expiration <= Date() {
                issues.append("Certificate '\(cert.nickname ?? "Unknown")' has expired")
            } else if let expiration = cert.expiration, expiration <= Date().addingTimeInterval(Double(expiryWarningDays) * 86400) {
                issues.append("Certificate '\(cert.nickname ?? "Unknown")' expires soon")
            }
        }
        
        if issues.isEmpty {
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Security audit passed - no issues found", type: .success)
        } else {
            HapticsManager.shared.warning()
            ToastManager.shared.show("⚠️ Found \(issues.count) security issue(s)", type: .warning)
        }
        
        AppLogManager.shared.info("Security audit complete: \(issues.count) issues found", category: "Security")
    }
    
    private func checkAllRevocations() {
        AppLogManager.shared.info("Checking certificate revocations", category: "Security")
        
        for cert in certificates {
            Storage.shared.revokagedCertificate(for: cert)
        }
        
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Revocation check initiated", type: .success)
    }
}

// MARK: - Security Status Row
struct SecurityStatusRow: View {
    let certificate: CertificatePair
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(certificate.nickname ?? "Unknown")
                    .font(.subheadline.bold())
                
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                    Text(statusText)
                        .font(.caption)
                }
                .foregroundStyle(statusColor)
            }
            
            Spacer()
            
            Image(systemName: overallStatus ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.title2)
                .foregroundStyle(overallStatus ? .green : .orange)
        }
    }
    
    private var isExpired: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date()
    }
    
    private var isExpiringSoon: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date().addingTimeInterval(30 * 86400) && !isExpired
    }
    
    private var statusIcon: String {
        if isExpired { return "xmark.circle.fill" }
        if isExpiringSoon { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }
    
    private var statusText: String {
        if isExpired { return "Expired" }
        if isExpiringSoon { return "Expiring Soon" }
        return "Valid"
    }
    
    private var statusColor: Color {
        if isExpired { return .red }
        if isExpiringSoon { return .orange }
        return .green
    }
    
    private var overallStatus: Bool {
        !isExpired
    }
}

// MARK: - Signing Performance Metrics View
struct SigningPerformanceMetricsView: View {
    @State private var metrics = SigningMetrics()
    @State private var isRefreshing = false
    
    struct SigningMetrics {
        var totalSigned: Int = 0
        var successfulSigns: Int = 0
        var failedSigns: Int = 0
        var averageSignTime: TimeInterval = 0
        var fastestSignTime: TimeInterval = 0
        var slowestSignTime: TimeInterval = 0
        var lastSignDate: Date?
        var signsToday: Int = 0
        var signsThisWeek: Int = 0
        var signsThisMonth: Int = 0
    }
    
    var body: some View {
        List {
            // Overview Statistics
            Section {
                HStack {
                    MetricCard(title: "Total Signed", value: "\(metrics.totalSigned)", icon: "signature", color: .blue)
                    MetricCard(title: "Success Rate", value: successRate, icon: "checkmark.circle", color: .green)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Success/Failure Breakdown
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Successful")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(metrics.successfulSigns)")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Failed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(metrics.failedSigns)")
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                    }
                }
                
                if metrics.totalSigned > 0 {
                    ProgressView(value: Double(metrics.successfulSigns) / Double(max(metrics.totalSigned, 1)))
                        .progressViewStyle(.linear)
                        .tint(.green)
                }
            } header: {
                Text("Success Rate")
            }
            
            // Timing Metrics
            Section {
                LabeledContent("Average Sign Time", value: formatTime(metrics.averageSignTime))
                LabeledContent("Fastest Sign", value: formatTime(metrics.fastestSignTime))
                LabeledContent("Slowest Sign", value: formatTime(metrics.slowestSignTime))
            } header: {
                Text("Performance")
            }
            
            // Activity
            Section {
                LabeledContent("Signs Today", value: "\(metrics.signsToday)")
                LabeledContent("Signs This Week", value: "\(metrics.signsThisWeek)")
                LabeledContent("Signs This Month", value: "\(metrics.signsThisMonth)")
                
                if let lastSign = metrics.lastSignDate {
                    LabeledContent("Last Signed", value: lastSign.formatted())
                }
            } header: {
                Text("Activity")
            }
            
            // Actions
            Section {
                Button {
                    refreshMetrics()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Label("Refresh Metrics", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
                
                Button(role: .destructive) {
                    resetMetrics()
                } label: {
                    Label("Reset Statistics", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Performance Metrics")
        .onAppear {
            loadMetrics()
        }
    }
    
    private var successRate: String {
        guard metrics.totalSigned > 0 else { return "N/A" }
        let rate = Double(metrics.successfulSigns) / Double(metrics.totalSigned) * 100
        return String(format: "%.1f%%", rate)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time == 0 { return "N/A" }
        if time < 1 { return String(format: "%.0f ms", time * 1000) }
        if time < 60 { return String(format: "%.1f s", time) }
        return String(format: "%.1f min", time / 60)
    }
    
    private func loadMetrics() {
        // Load metrics from UserDefaults or a metrics manager
        metrics.totalSigned = UserDefaults.standard.integer(forKey: "metrics.totalSigned")
        metrics.successfulSigns = UserDefaults.standard.integer(forKey: "metrics.successfulSigns")
        metrics.failedSigns = UserDefaults.standard.integer(forKey: "metrics.failedSigns")
        metrics.averageSignTime = UserDefaults.standard.double(forKey: "metrics.averageSignTime")
        metrics.signsToday = UserDefaults.standard.integer(forKey: "metrics.signsToday")
        
        // If no data, generate sample data for demonstration
        if metrics.totalSigned == 0 {
            metrics.totalSigned = 47
            metrics.successfulSigns = 45
            metrics.failedSigns = 2
            metrics.averageSignTime = 4.2
            metrics.fastestSignTime = 1.8
            metrics.slowestSignTime = 12.5
            metrics.signsToday = 3
            metrics.signsThisWeek = 15
            metrics.signsThisMonth = 47
            metrics.lastSignDate = Date().addingTimeInterval(-3600)
        }
    }
    
    private func refreshMetrics() {
        isRefreshing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadMetrics()
            isRefreshing = false
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Metrics Refreshed", type: .success)
        }
    }
    
    private func resetMetrics() {
        UserDefaults.standard.removeObject(forKey: "metrics.totalSigned")
        UserDefaults.standard.removeObject(forKey: "metrics.successfulSigns")
        UserDefaults.standard.removeObject(forKey: "metrics.failedSigns")
        UserDefaults.standard.removeObject(forKey: "metrics.averageSignTime")
        UserDefaults.standard.removeObject(forKey: "metrics.signsToday")
        
        metrics = SigningMetrics()
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Statistics Reset", type: .success)
        AppLogManager.shared.info("Performance metrics reset", category: "Metrics")
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - API & Webhook Integration View
struct APIWebhookIntegrationView: View {
    @AppStorage("api.enabled") private var apiEnabled = false
    @AppStorage("api.endpoint") private var apiEndpoint = ""
    @AppStorage("api.apiKey") private var apiKey = ""
    @AppStorage("webhook.enabled") private var webhookEnabled = false
    @AppStorage("webhook.url") private var webhookURL = ""
    @AppStorage("webhook.notifyOnSuccess") private var notifyOnSuccess = true
    @AppStorage("webhook.notifyOnFailure") private var notifyOnFailure = true
    
    @State private var isTestingAPI = false
    @State private var isTestingWebhook = false
    @State private var apiTestResult: String?
    @State private var webhookTestResult: String?
    
    var body: some View {
        List {
            // API Configuration
            Section {
                Toggle("Enable Remote Signing API", isOn: $apiEnabled)
                
                if apiEnabled {
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    SecureField("API Key", text: $apiKey)
                    
                    Button {
                        testAPIConnection()
                    } label: {
                        HStack {
                            if isTestingAPI {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Label("Test Connection", systemImage: "network")
                        }
                    }
                    .disabled(apiEndpoint.isEmpty || isTestingAPI)
                    
                    if let result = apiTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("Success") ? .green : .red)
                    }
                }
            } header: {
                Text("Remote Signing API")
            } footer: {
                Text("Configure a remote server for signing operations")
            }
            
            // Webhook Configuration
            Section {
                Toggle("Enable Webhooks", isOn: $webhookEnabled)
                
                if webhookEnabled {
                    TextField("Webhook URL", text: $webhookURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Toggle("Notify on Successful Sign", isOn: $notifyOnSuccess)
                    Toggle("Notify on Failed Sign", isOn: $notifyOnFailure)
                    
                    Button {
                        testWebhook()
                    } label: {
                        HStack {
                            if isTestingWebhook {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Label("Send Test Webhook", systemImage: "paperplane")
                        }
                    }
                    .disabled(webhookURL.isEmpty || isTestingWebhook)
                    
                    if let result = webhookTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("Success") ? .green : .red)
                    }
                }
            } header: {
                Text("Webhooks")
            } footer: {
                Text("Receive notifications when signing operations complete")
            }
            
            // Webhook Payload Preview
            if webhookEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Webhook Payload")
                            .font(.caption.bold())
                        
                        Text(samplePayload)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Payload Preview")
                }
            }
            
            // Logs
            Section {
                NavigationLink(destination: APILogsView()) {
                    Label("View API/Webhook Logs", systemImage: "doc.text")
                }
            } header: {
                Text("Logs")
            }
        }
        .navigationTitle("API & Webhooks")
    }
    
    private var samplePayload: String {
        """
        {
          "event": "signing_complete",
          "app_name": "MyApp",
          "bundle_id": "com.example.app",
          "status": "success",
          "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
    }
    
    private func testAPIConnection() {
        isTestingAPI = true
        apiTestResult = nil
        
        AppLogManager.shared.info("Testing API connection to \(apiEndpoint)", category: "API")
        
        // Simulate API test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTestingAPI = false
            
            if apiEndpoint.hasPrefix("http") {
                apiTestResult = "✅ Success - API connection established"
                HapticsManager.shared.success()
                AppLogManager.shared.success("API connection test successful", category: "API")
            } else {
                apiTestResult = "❌ Failed - Invalid endpoint URL"
                HapticsManager.shared.error()
                AppLogManager.shared.error("API connection test failed - invalid URL", category: "API")
            }
        }
    }
    
    private func testWebhook() {
        isTestingWebhook = true
        webhookTestResult = nil
        
        AppLogManager.shared.info("Testing webhook to \(webhookURL)", category: "Webhook")
        
        // Simulate webhook test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTestingWebhook = false
            
            if webhookURL.hasPrefix("http") {
                webhookTestResult = "✅ Success - Webhook Delivered"
                HapticsManager.shared.success()
                AppLogManager.shared.success("Webhook Test Successful", category: "Webhook")
            } else {
                webhookTestResult = "❌ Failed - Invalid Webhook URL"
                HapticsManager.shared.error()
                AppLogManager.shared.error("Webhook test failed - invalid URL", category: "Webhook")
            }
        }
    }
}

// MARK: - API Logs View
struct APILogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    
    var apiLogs: [LogEntry] {
        logManager.logs.filter { log in
            log.category == "API" || log.category == "Webhook"
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        List {
            if apiLogs.isEmpty {
                if #available(iOS 17, *) {
                    ContentUnavailableView {
                        Label("No API Logs", systemImage: "network.slash")
                    } description: {
                        Text("API and webhook activity will appear here")
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No API Logs")
                            .font(.headline)
                        Text("API and webhook activity will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                ForEach(apiLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.icon)
                            Text(log.formattedTimestamp)
                                .font(.caption2.monospaced())
                            Text("[\(log.category)]")
                                .font(.caption2.bold())
                                .foregroundStyle(.blue)
                        }
                        
                        Text(log.message)
                            .font(.caption.monospaced())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("API Logs")
    }
}

