import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

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
            .scrollContentBackground(.hidden)
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
            Text("Are you sure you want to remove the Developer Passcode?")
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
