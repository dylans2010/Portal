import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct TestNotificationsView: View {
    @State private var isTestingNotification = false
    @State private var countdown: Int = 3
    @State private var showResultDialog = false
    @State private var notificationSent = false
    @State private var debugInfo: [String] = []
    @State private var timer: Timer?

    var body: some View {
        List {
            Section(header: Text("Test Notifications"), footer: Text("This will send a test notification after a 3 second countdown. Make sure notifications are enabled for Portal in Settings.")) {
                Button {
                    startNotificationTest()
                } label: {
                    HStack {
                        Spacer()
                        if isTestingNotification {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Sending In \(countdown)...")
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
            .scrollContentBackground(.hidden)
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
                    debugInfo.append("⚠️ WARNING: Notifications Not Authorized!")
                }
            }
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Portal Developer Tools."
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
