import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

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
    @State private var showGlitchView = false
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
                        Color.clear,
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
                    .fullScreenCover(isPresented: $showGlitchView) {
                        GlitchDeveloperModeView()
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
                .onTapGesture(count: 3) {
                    if !authManager.isAuthenticated {
                        ToastManager.shared.show("😏 Nice try, but you need to authenticate!", type: .warning)
                        HapticsManager.shared.error()
                    }
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Subtitle
            Text("Secure Authentication Required")
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
                                      AnyShapeStyle(Color.clear))
                        )
                        .foregroundStyle(authMethod == method ? .white : .primary)
                        .contentShape(Capsule())
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
                .fill(Color.clear)
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
                    SecureField("Enter Passcode", text: $passcode)
                        .textContentType(.password)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
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
                    .contentShape(Rectangle())
                }
                .disabled(passcode.isEmpty || isAuthenticating)
                .opacity(passcode.isEmpty ? 0.6 : 1)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "key.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("No Passcode Configured")
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
                    .background(Color.clear)
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

            Text("Use biometric authentication for quick access. This feature does not work yet.")
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
                TextField("Enter Developer Token", text: $developerToken)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
            )

            // Token hint
            Text("Enter your authorized Developer Token.")
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
                Text("Stay Authenticated For 7 Days")
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
                .fill(Color.clear)
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
            .transition(AnyTransition.asymmetric(
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
        if developerToken.uppercased() == "LEAVE" {
            showGlitchView = true
            developerToken = ""
            return
        }

        if developerToken.uppercased() == "SECRET" {
            showSuccessAnimation = true
            HapticsManager.shared.success()
            developerToken = ""
            ToastManager.shared.show("🌌 Entering Secret Dimension...", type: .success)
            return
        }

        if developerToken.uppercased() == "GLITCH" {
            showGlitchView = true
            developerToken = ""
            return
        }

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
