import SwiftUI
import NimbleViews

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("Feather.notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @State private var showingAlert = false
    
    var body: some View {
        NBList(.localized("Notifications & Live Activities")) {
            if showHeaderViews {
                Section {
                    NotificationHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label(.localized("Enable Notifications"), systemImage: "bell.fill")
                }
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        notificationManager.requestAuthorization { granted in
                            if !granted {
                                notificationsEnabled = false
                                showingAlert = true
                            }
                        }
                    }
                }

                HStack {
                    Text(.localized("Status"))
                    Spacer()
                    Text(authorizationStatusText)
                        .foregroundStyle(authorizationStatusColor)
                }
            } header: {
                Text(.localized("Global Settings"))
            } footer: {
                Text(.localized("Toggle to enable or disable all notifications from Portal."))
            }

            if notificationsEnabled {
                Section {
                    ForEach(NotificationType.allCases, id: \.self) { type in
                        NotificationToggleRow(type: type)
                    }
                } header: {
                    Text(.localized("Notification Preferences"))
                } footer: {
                    Text(.localized("Choose which events you want to be notified about."))
                }

                Section {
                    SettingsRow(icon: "widget.small.badge.plus", title: String.localized("Live Activities"), color: .accentColor, destination: LiveActivitySettingsView())
                } header: {
                    Text(.localized("Services"))
                } footer: {
                    Text(.localized("Customize your Live Activities experience."))
                }

                Section {
                    Button {
                        notificationManager.sendTestNotification()
                    } label: {
                        HStack {
                            Label(.localized("Test Notifications"), systemImage: "paperplane.fill")
                            Spacer()
                        }
                    }
                }

                Section {
                    Button {
                        notificationManager.openSettings()
                    } label: {
                        HStack {
                            Label(.localized("Open iOS Settings"), systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(.localized("Manage system level notification permissions for Portal."))
                }
            }
        }
        .alert(.localized("Permission Required"), isPresented: $showingAlert) {
            Button(.localized("Open Settings")) {
                notificationManager.openSettings()
            }
            Button(.localized("Cancel"), role: .cancel) { }
        } message: {
            Text(.localized("Please enable notifications in iOS Settings to receive updates."))
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }

    private var authorizationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized: return .localized("Enabled")
        case .denied: return .localized("Denied")
        case .notDetermined: return .localized("Not Determined")
        case .provisional: return .localized("Provisional")
        default: return .localized("Unknown")
        }
    }

    private var authorizationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        default: return .secondary
        }
    }
}

struct NotificationToggleRow: View {
    let type: NotificationType
    @State private var isEnabled: Bool

    init(type: NotificationType) {
        self.type = type
        self._isEnabled = State(initialValue: UserDefaults.standard.bool(forKey: type.userDefaultsKey))
    }

    var body: some View {
        Toggle(isOn: $isEnabled) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: type))
                        .font(.body)
                    Text(description(for: type))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: icon(for: type))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .onChange(of: isEnabled) { newValue in
            UserDefaults.standard.set(newValue, forKey: type.userDefaultsKey)
        }
    }

    private func title(for type: NotificationType) -> String {
        switch type {
        case .appDownloaded: return .localized("App Downloaded")
        case .appSigned: return .localized("App Ready")
        case .signingFailed: return .localized("Signing Failed")
        case .downloadStarted: return .localized("Download Started")
        case .downloadFailed: return .localized("Download Failed")
        case .updateAvailable: return .localized("App Updates")
        case .backupSuccess: return .localized("Backup Success")
        case .backupFailed: return .localized("Backup Failed")
        case .certExpiring: return .localized("Certificate Expiry")
        case .lowStorage: return .localized("Low Storage")
        case .securityAlert: return .localized("Security Alerts")
        case .appClosed: return .localized("App Closed")
        case .dataFetched: return .localized("Data Fetched")
        case .test: return .localized("Test Notifications")
        }
    }

    private func description(for type: NotificationType) -> String {
        switch type {
        case .appDownloaded: return .localized("Notify when an app is downloaded.")
        case .appSigned: return .localized("Notify when an app is signed and ready.")
        case .signingFailed: return .localized("Notify when an app fails to sign.")
        case .downloadStarted: return .localized("Notify when a download begins.")
        case .downloadFailed: return .localized("Notify when a download fails.")
        case .updateAvailable: return .localized("Notify when a new Portal update is available.")
        case .backupSuccess: return .localized("Notify when a backup completes successfully.")
        case .backupFailed: return .localized("Notify when a backup fails.")
        case .certExpiring: return .localized("Notify when your certificate is about to expire.")
        case .lowStorage: return .localized("Notify when device storage is low.")
        case .securityAlert: return .localized("Notify about important security events.")
        case .appClosed: return .localized("Notify when Portal is force closed.")
        case .dataFetched: return .localized("Notify when source data has been fetched and cached.")
        case .test: return .localized("Receive test notifications to verify setup.")
        }
    }

    private func icon(for type: NotificationType) -> String {
        switch type {
        case .appDownloaded: return "arrow.down.doc.fill"
        case .appSigned: return "checkmark.seal.fill"
        case .signingFailed: return "xmark.seal.fill"
        case .downloadStarted: return "arrow.down.circle.fill"
        case .downloadFailed: return "exclamationmark.arrow.down.fill"
        case .updateAvailable: return "arrow.up.circle.fill"
        case .backupSuccess: return "externaldrive.fill.badge.checkmark"
        case .backupFailed: return "externaldrive.fill.badge.xmark"
        case .certExpiring: return "clock.badge.exclamationmark.fill"
        case .lowStorage: return "internaldrive.fill"
        case .securityAlert: return "shield.fill"
        case .appClosed: return "xmark.app.fill"
        case .dataFetched: return "arrow.clockwise.circle.fill"
        case .test: return "paperplane.fill"
        }
    }
}
