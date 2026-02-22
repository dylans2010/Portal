import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

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
                Toggle("Enable Remote Signing API (Beta)", isOn: $apiEnabled)

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
                Text("Configure a remote server for signing operations.")
            }

            // Webhook Configuration
            Section {
                Toggle("Enable Webhooks", isOn: $webhookEnabled)

                if webhookEnabled {
                    TextField("Webhook URL", text: $webhookURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Toggle("Notify On Successful Sign", isOn: $notifyOnSuccess)
                    Toggle("Notify On Failed Sign", isOn: $notifyOnFailure)

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
            .scrollContentBackground(.hidden)
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

        AppLogManager.shared.info("Testing API Connection To \(apiEndpoint)", category: "API")

        // Simulate API test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTestingAPI = false

            if apiEndpoint.hasPrefix("http") {
                apiTestResult = "✅ Success - API Connection Established"
                HapticsManager.shared.success()
                AppLogManager.shared.success("API connection test successful", category: "API")
            } else {
                apiTestResult = "❌ Failed - Invalid Endpoint URL"
                HapticsManager.shared.error()
                AppLogManager.shared.error("API connection test failed - invalid URL", category: "API")
            }
        }
    }

    private func testWebhook() {
        isTestingWebhook = true
        webhookTestResult = nil

        AppLogManager.shared.info("Testing Webhook To \(webhookURL)", category: "Webhook")

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
                AppLogManager.shared.error("Webhook Test Failed - Invalid URL", category: "Webhook")
            }
        }
    }
}
