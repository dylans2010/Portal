import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

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
                Color.clear
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
                                    SecureField("Enter Passcode (Min 6 Characters)", text: $newPasscode)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
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
                                    SecureField("Confirm Passcode", text: $confirmPasscode)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
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
            errorMessage = "Passcode Must Be At Least 6 Characters"
            HapticsManager.shared.error()
            return
        }

        if newPasscode != confirmPasscode {
            errorMessage = "Passcodes do not match. Try again."
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
                errorMessage = "Failed To Set Passcode"
                HapticsManager.shared.error()
            }
            isSettingUp = false
        }
    }
}
