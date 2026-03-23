import SwiftUI
import UniformTypeIdentifiers

struct EntitlementItem: Identifiable {
    let id = UUID()
    var name: String
    var key: String
    var value: Any
    var isEnabled: Bool
    var symbol: String
}

struct EntitlementsCreateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var _entitlements: [EntitlementItem] = [
        EntitlementItem(name: "Can be debugged", key: "get-task-allow", value: true, isEnabled: true, symbol: "ladybug.fill"),
        EntitlementItem(name: "App Groups", key: "com.apple.security.application-groups", value: ["group.com.example.app"], isEnabled: false, symbol: "rectangle.3.group.fill"),
        EntitlementItem(name: "Push Notifications", key: "com.apple.developer.aps-environment", value: "development", isEnabled: false, symbol: "bell.badge.fill"),
        EntitlementItem(name: "iCloud Containers", key: "com.apple.developer.icloud-container-identifiers", value: ["iCloud.com.example.app"], isEnabled: false, symbol: "icloud.fill"),
        EntitlementItem(name: "Wi-Fi Information", key: "com.apple.developer.networking.wifi-info", value: true, isEnabled: false, symbol: "wifi"),
        EntitlementItem(name: "Associated Domains", key: "com.apple.developer.associated-domains", value: ["applinks:example.com"], isEnabled: false, symbol: "link"),
        EntitlementItem(name: "Inter-App Audio", key: "inter-app-audio", value: true, isEnabled: false, symbol: "waveform"),
        EntitlementItem(name: "HealthKit", key: "com.apple.developer.healthkit", value: true, isEnabled: false, symbol: "heart.fill"),
        EntitlementItem(name: "HomeKit", key: "com.apple.developer.homekit", value: true, isEnabled: false, symbol: "house.fill"),
        EntitlementItem(name: "NFC Tag Reading", key: "com.apple.developer.nfc.readersession.formats", value: ["NDEF"], isEnabled: false, symbol: "contactlesscard.fill"),
        EntitlementItem(name: "Sign In with Apple", key: "com.apple.developer.applesignin", value: ["Default"], isEnabled: false, symbol: "apple.logo"),
        EntitlementItem(name: "Siri", key: "com.apple.developer.siri", value: true, isEnabled: false, symbol: "waveform.circle.fill"),
        EntitlementItem(name: "Network Extensions", key: "com.apple.developer.networking.networkextension", value: ["dns-proxy", "app-proxy", "content-filter", "packet-tunnel"], isEnabled: false, symbol: "network"),
        EntitlementItem(name: "Multipath TCP", key: "com.apple.developer.networking.multipath", value: true, isEnabled: false, symbol: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill"),
        EntitlementItem(name: "AutoFill Credential Provider", key: "com.apple.developer.authentication-services.autofill-credential-provider", value: true, isEnabled: false, symbol: "key.fill"),
        EntitlementItem(name: "App Attest", key: "com.apple.developer.devicecheck.appattest-environment", value: "development", isEnabled: false, symbol: "shield.fill"),
        EntitlementItem(name: "User Fonts", key: "com.apple.developer.user-fonts", value: ["app-usage"], isEnabled: false, symbol: "textformat"),
        EntitlementItem(name: "Push to Talk", key: "com.apple.developer.push-to-talk", value: true, isEnabled: false, symbol: "mic.fill"),
        EntitlementItem(name: "Tap to Pay on iPhone", key: "com.apple.developer.proximity-reader.payment.acceptance", value: true, isEnabled: false, symbol: "creditcard.fill"),
        EntitlementItem(name: "Increased Memory Limit", key: "com.apple.developer.kernel.increased-memory-limit", value: true, isEnabled: false, symbol: "memorychip"),
        EntitlementItem(name: "JIT Compilation", key: "dynamic-codesigning", value: true, isEnabled: false, symbol: "bolt.fill"),
        EntitlementItem(name: "Critical Alerts", key: "com.apple.developer.critical-alerts", value: true, isEnabled: false, symbol: "exclamationmark.triangle.fill"),
        EntitlementItem(name: "Time Sensitive Notifications", key: "com.apple.developer.time-sensitive-notifications", value: true, isEnabled: false, symbol: "clock.badge.fill"),
        EntitlementItem(name: "Extended Virtual Address Space", key: "com.apple.developer.kernel.extended-virtual-addressing", value: true, isEnabled: false, symbol: "cpu"),
        EntitlementItem(name: "ClassKit", key: "com.apple.developer.ClassKit-environment", value: "development", isEnabled: false, symbol: "book.fill"),
        EntitlementItem(name: "Apple Pay", key: "com.apple.developer.in-app-payments", value: ["merchant.com.example"], isEnabled: false, symbol: "applepay"),
        EntitlementItem(name: "Game Center", key: "com.apple.developer.game-center", value: true, isEnabled: false, symbol: "gamecontroller.fill"),
        EntitlementItem(name: "Data Protection", key: "com.apple.developer.default-data-protection", value: "NSFileProtectionComplete", isEnabled: false, symbol: "lock.shield.fill"),
        EntitlementItem(name: "CarPlay", key: "com.apple.developer.carplay", value: true, isEnabled: false, symbol: "car.fill"),
        EntitlementItem(name: "Low Latency Camera Capture", key: "com.apple.developer.camera.low-latency", value: true, isEnabled: false, symbol: "camera.fill"),
        EntitlementItem(name: "Family Controls", key: "com.apple.developer.family-controls", value: true, isEnabled: false, symbol: "person.2.fill"),
        EntitlementItem(name: "Exposure Notification", key: "com.apple.developer.exposure-notification", value: true, isEnabled: false, symbol: "allergens"),
        EntitlementItem(name: "Shared With You", key: "com.apple.developer.shared-with-you", value: true, isEnabled: false, symbol: "person.2.square.stack.fill"),
        EntitlementItem(name: "Communication Notifications", key: "com.apple.developer.usernotifications.communication", value: true, isEnabled: false, symbol: "message.fill"),
        EntitlementItem(name: "Group Activities", key: "com.apple.developer.group-session", value: true, isEnabled: false, symbol: "person.3.fill"),
        EntitlementItem(name: "Fonts", key: "com.apple.developer.user-fonts", value: ["app-usage"], isEnabled: false, symbol: "textformat.size"),
        EntitlementItem(name: "Sensitive Content Analysis", key: "com.apple.developer.sensitivecontentanalysis.client", value: true, isEnabled: false, symbol: "eye.trianglebadge.exclamationmark.fill"),
        EntitlementItem(name: "Journaling Suggestions", key: "com.apple.developer.journal.suggestions", value: true, isEnabled: false, symbol: "pencil.and.outline"),
        EntitlementItem(name: "Accessory Setup", key: "com.apple.developer.accessory-setup-kit", value: true, isEnabled: false, symbol: "plus.circle.fill"),
        EntitlementItem(name: "HealthKit (Clinical Records)", key: "com.apple.developer.healthkit.access.clinical-records", value: true, isEnabled: false, symbol: "cross.fill")
    ]

    @State private var _shortcutsEntitlements: [EntitlementItem] = [
        EntitlementItem(name: "Shortcuts Custom Intent", key: "com.apple.developer.shortcuts.custom-intent", value: true, isEnabled: false, symbol: "bolt.horizontal.fill"),
        EntitlementItem(name: "App Shortcuts", key: "com.apple.developer.app-shortcuts", value: true, isEnabled: false, symbol: "square.2.stack.3d"),
        EntitlementItem(name: "Workflow Management", key: "com.apple.developer.workflow.management", value: true, isEnabled: false, symbol: "arrow.triangle.2.circlepath")
    ]

    @State private var _ios18Entitlements: [EntitlementItem] = [
        EntitlementItem(name: "Control Center Extension", key: "com.apple.developer.controlcenter.extension", value: true, isEnabled: false, symbol: "switch.2"),
        EntitlementItem(name: "Widget Configuration", key: "com.apple.developer.widget-configuration", value: true, isEnabled: false, symbol: "square.grid.2x2.fill"),
        EntitlementItem(name: "Lock Screen Extension", key: "com.apple.developer.lockscreen.extension", value: true, isEnabled: false, symbol: "lock.iphone")
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
                    _entitlementRow(item: $item)
                }
            }

            Section("Shortcuts & Automation") {
                ForEach($_shortcutsEntitlements) { $item in
                    _entitlementRow(item: $item)
                }
            }

            Section("iOS 18+ Features") {
                ForEach($_ios18Entitlements) { $item in
                    _entitlementRow(item: $item)
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

        let newItem = EntitlementItem(name: "Custom Entitlement", key: _customKey, value: value, isEnabled: true, symbol: "questionmark.circle")
        _entitlements.append(newItem)
        _customKey = ""
        _customValue = ""
        HapticsManager.shared.success()
    }

    @ViewBuilder
    private func _entitlementRow(item: Binding<EntitlementItem>) -> some View {
        Toggle(isOn: item.isEnabled) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: item.wrappedValue.symbol)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.wrappedValue.name)
                            .font(.subheadline.weight(.semibold))

                        Text(item.wrappedValue.key)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if item.wrappedValue.isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        if let arrayValue = item.wrappedValue.value as? [String] {
                            TextField("Values (comma separated)", text: Binding(
                                get: { arrayValue.joined(separator: ", ") },
                                set: { item.wrappedValue.value = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                            ))
                            .font(.caption2)
                            .textFieldStyle(.roundedBorder)
                        } else if let stringValue = item.wrappedValue.value as? String {
                            TextField("Value", text: Binding(
                                get: { stringValue },
                                set: { item.wrappedValue.value = $0 }
                            ))
                            .font(.caption2)
                            .textFieldStyle(.roundedBorder)
                        } else if let boolValue = item.wrappedValue.value as? Bool {
                            Text(boolValue ? "Enabled (Boolean)" : "Disabled (Boolean)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func _export() {
        let enabledItems = (_entitlements + _shortcutsEntitlements + _ios18Entitlements).filter { $0.isEnabled }
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
