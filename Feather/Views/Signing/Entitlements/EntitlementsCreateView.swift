import SwiftUI
import UniformTypeIdentifiers

struct EntitlementItem: Identifiable {
    let id = UUID()
    var name: String
    var key: String
    var value: Any
    var isEnabled: Bool
}

struct EntitlementsCreateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var _entitlements: [EntitlementItem] = [
        EntitlementItem(name: "Can be debugged", key: "get-task-allow", value: true, isEnabled: true),
        EntitlementItem(name: "App Groups", key: "com.apple.security.application-groups", value: ["group.com.example.app"], isEnabled: false),
        EntitlementItem(name: "Push Notifications", key: "com.apple.developer.aps-environment", value: "development", isEnabled: false),
        EntitlementItem(name: "iCloud Containers", key: "com.apple.developer.icloud-container-identifiers", value: ["iCloud.com.example.app"], isEnabled: false),
        EntitlementItem(name: "Wi-Fi Information", key: "com.apple.developer.networking.wifi-info", value: true, isEnabled: false),
        EntitlementItem(name: "Associated Domains", key: "com.apple.developer.associated-domains", value: ["applinks:example.com"], isEnabled: false),
        EntitlementItem(name: "Inter-App Audio", key: "inter-app-audio", value: true, isEnabled: false),
        EntitlementItem(name: "HealthKit", key: "com.apple.developer.healthkit", value: true, isEnabled: false),
        EntitlementItem(name: "HomeKit", key: "com.apple.developer.homekit", value: true, isEnabled: false),
        EntitlementItem(name: "NFC Tag Reading", key: "com.apple.developer.nfc.readersession.formats", value: ["NDEF"], isEnabled: false),
        EntitlementItem(name: "Sign In with Apple", key: "com.apple.developer.applesignin", value: ["Default"], isEnabled: false),
        EntitlementItem(name: "Siri", key: "com.apple.developer.siri", value: true, isEnabled: false),
        EntitlementItem(name: "Network Extensions", key: "com.apple.developer.networking.networkextension", value: ["dns-proxy", "app-proxy", "content-filter", "packet-tunnel"], isEnabled: false),
        EntitlementItem(name: "Multipath TCP", key: "com.apple.developer.networking.multipath", value: true, isEnabled: false),
        EntitlementItem(name: "AutoFill Credential Provider", key: "com.apple.developer.authentication-services.autofill-credential-provider", value: true, isEnabled: false),
        EntitlementItem(name: "App Attest", key: "com.apple.developer.devicecheck.appattest-environment", value: "development", isEnabled: false),
        EntitlementItem(name: "User Fonts", key: "com.apple.developer.user-fonts", value: ["app-usage"], isEnabled: false),
        EntitlementItem(name: "Push to Talk", key: "com.apple.developer.push-to-talk", value: true, isEnabled: false),
        EntitlementItem(name: "Tap to Pay on iPhone", key: "com.apple.developer.proximity-reader.payment.acceptance", value: true, isEnabled: false),
        EntitlementItem(name: "Increased Memory Limit", key: "com.apple.developer.kernel.increased-memory-limit", value: true, isEnabled: false),
        EntitlementItem(name: "JIT Compilation", key: "dynamic-codesigning", value: true, isEnabled: false),
        EntitlementItem(name: "Critical Alerts", key: "com.apple.developer.critical-alerts", value: true, isEnabled: false),
        EntitlementItem(name: "Time Sensitive Notifications", key: "com.apple.developer.time-sensitive-notifications", value: true, isEnabled: false),
        EntitlementItem(name: "Extended Virtual Address Space", key: "com.apple.developer.kernel.extended-virtual-addressing", value: true, isEnabled: false),
        EntitlementItem(name: "ClassKit", key: "com.apple.developer.ClassKit-environment", value: "development", isEnabled: false)
    ]

    @State private var _customKey = ""
    @State private var _customValue = ""
    @State private var _showExportSheet = false
    @State private var _exportURL: URL?

    var body: some View {
        List {
            Section {
                Text("Your signing certificate needs to have these entitlements available in order for this app to offer these capabilities.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Common Entitlements") {
                ForEach($_entitlements) { $item in
                    Toggle(isOn: $item.isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))

                            Text(item.key)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)

                            if item.isEnabled {
                                if let arrayValue = item.value as? [String] {
                                    TextField("Values (comma separated)", text: Binding(
                                        get: { arrayValue.joined(separator: ", ") },
                                        set: { item.value = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                                    ))
                                    .font(.caption2)
                                    .textFieldStyle(.roundedBorder)
                                } else if let stringValue = item.value as? String {
                                    TextField("Value", text: Binding(
                                        get: { stringValue },
                                        set: { item.value = $0 }
                                    ))
                                    .font(.caption2)
                                    .textFieldStyle(.roundedBorder)
                                } else if let boolValue = item.value as? Bool {
                                    Text(boolValue ? "Enabled (Boolean)" : "Disabled (Boolean)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Custom Entitlement") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Key (e.g. com.apple.security.device.camera)", text: $_customKey)
                        .font(.system(.subheadline, design: .monospaced))

                    TextField("Value (String or Boolean true/false)", text: $_customValue)
                        .font(.subheadline)

                    Button {
                        _addCustomEntitlement()
                    } label: {
                        Label("Add Custom", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .disabled(_customKey.isEmpty || _customValue.isEmpty)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Create Entitlements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Export") { _export() }
                    .fontWeight(.bold)
            }
        }
        .sheet(isPresented: $_showExportSheet) {
            if let url = _exportURL {
                ShareLink(item: url) {
                    Label("Share Entitlements File", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .presentationDetents([.height(240)])
            }
        }
    }

    private func _addCustomEntitlement() {
        let value: Any
        if _customValue.lowercased() == "true" {
            value = true
        } else if _customValue.lowercased() == "false" {
            value = false
        } else {
            value = _customValue
        }

        let newItem = EntitlementItem(name: "Custom Entitlement", key: _customKey, value: value, isEnabled: true)
        _entitlements.append(newItem)
        _customKey = ""
        _customValue = ""
        HapticsManager.shared.success()
    }

    private func _export() {
        let enabledItems = _entitlements.filter { $0.isEnabled }
        var dict: [String: Any] = [:]
        for item in enabledItems {
            dict[item.key] = item.value
        }

        guard let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) else {
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("custom.entitlements")
        try? data.write(to: tempURL)

        _exportURL = tempURL
        _showExportSheet = true
        HapticsManager.shared.success()
    }
}
