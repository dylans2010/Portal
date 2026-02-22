import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

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
                    Label("Export As XML", systemImage: "square.and.arrow.up")
                }

                Button {
                    copyEntitlements()
                } label: {
                    Label("Copy To Clipboard", systemImage: "doc.on.clipboard")
                }
            } header: {
                Text("Export")
            }
        }
            .scrollContentBackground(.hidden)
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
                    Label("Export As XML", systemImage: "square.and.arrow.up")
                }
            }
        }
            .scrollContentBackground(.hidden)
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
        ToastManager.shared.show("✅ Added URL Schemes Key", type: .success)
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
