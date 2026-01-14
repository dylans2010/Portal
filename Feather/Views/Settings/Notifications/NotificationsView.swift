// this view is not needed anymore, useless

import SwiftUI
import NimbleViews

// MARK: - NotificationsView
struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("Feather.notificationsEnabled") private var notificationsEnabled = false
    @State private var showingAlert = false
    
    var body: some View {
        NBList(.localized("Notifications")) {
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label(.localized("Enable Notifications"), systemImage: "bell.fill")
                }
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        // Request permission when enabled
                        notificationManager.requestAuthorization { granted in
                            if !granted {
                                // If denied, disable the toggle
                                notificationsEnabled = false
                                showingAlert = true
                            }
                        }
                    }
                }
            } header: {
                Text(.localized("App Notifications"))
            } footer: {
                Text(.localized("Receive notifications when apps are successfully signed from the Sources tab and ready in the Library tab."))
            }
            
            if notificationsEnabled {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(.localized("Signing Completion"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text(.localized("Notification Types"))
                } footer: {
                    Text(.localized("You'll be notified when an app finishes signing and is ready to install."))
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Downloaded App")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("AppName was downloaded successfully. Check the Library tab to sign the app")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                } header: {
                    Text(.localized("Preview"))
                }
                
                Section {
                    Button {
                        notificationManager.openSettings()
                    } label: {
                        HStack {
                            Label(.localized("Open System Settings"), systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(.localized("Manage notification settings for Feather in System Settings."))
                }
            }
        }
        .alert(.localized("Notification Permission Required"), isPresented: $showingAlert) {
            Button(.localized("Open Settings")) {
                notificationManager.openSettings()
            }
            Button(.localized("Cancel"), role: .cancel) { }
        } message: {
            Text(.localized("Please enable notifications for Feather in System Settings to receive updates when apps are signed."))
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
}
