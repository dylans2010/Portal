import SwiftUI

struct AdvancedPermissionsView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var permissions: Int = 0
    @State private var owner: String = ""
    @State private var group: String = ""

    // User, Group, Others
    @State private var uRead = false
    @State private var uWrite = false
    @State private var uExec = false
    @State private var gRead = false
    @State private var gWrite = false
    @State private var gExec = false
    @State private var oRead = false
    @State private var oWrite = false
    @State private var oExec = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(.localized("Octal Permissions"))) {
                    HStack {
                        Text(String(format: "%o", calculateOctal()))
                            .font(.title.monospaced())
                        Spacer()
                    }
                }

                Section(header: Text(.localized("User"))) {
                    Toggle("Read", isOn: $uRead)
                    Toggle("Write", isOn: $uWrite)
                    Toggle("Execute", isOn: $uExec)
                }

                Section(header: Text(.localized("Group"))) {
                    Toggle("Read", isOn: $gRead)
                    Toggle("Write", isOn: $gWrite)
                    Toggle("Execute", isOn: $gExec)
                }

                Section(header: Text(.localized("Others"))) {
                    Toggle("Read", isOn: $oRead)
                    Toggle("Write", isOn: $oWrite)
                    Toggle("Execute", isOn: $oExec)
                }

                Section {
                    Button {
                        apply()
                    } label: {
                        Text(.localized("Apply Permissions"))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Advanced Permissions"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPermissions()
            }
        }
    }

    private func loadPermissions() {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let posixPerms = attrs[.posixPermissions] as? Int {
            permissions = posixPerms

            uRead = (posixPerms & 0o400) != 0
            uWrite = (posixPerms & 0o200) != 0
            uExec = (posixPerms & 0o100) != 0

            gRead = (posixPerms & 0o040) != 0
            gWrite = (posixPerms & 0o020) != 0
            gExec = (posixPerms & 0o010) != 0

            oRead = (posixPerms & 0o004) != 0
            oWrite = (posixPerms & 0o002) != 0
            oExec = (posixPerms & 0o001) != 0
        }
    }

    private func calculateOctal() -> Int {
        var octal = 0
        if uRead { octal += 0o400 }
        if uWrite { octal += 0o200 }
        if uExec { octal += 0o100 }
        if gRead { octal += 0o040 }
        if gWrite { octal += 0o020 }
        if gExec { octal += 0o010 }
        if oRead { octal += 0o004 }
        if oWrite { octal += 0o002 }
        if oExec { octal += 0o001 }
        return octal
    }

    private func apply() {
        let octal = calculateOctal()
        do {
            try FileManager.default.setAttributes([.posixPermissions: octal], ofItemAtPath: fileURL.path)
            HapticsManager.shared.success()
            dismiss()
        } catch {
            HapticsManager.shared.error()
            // Show alert
        }
    }
}
