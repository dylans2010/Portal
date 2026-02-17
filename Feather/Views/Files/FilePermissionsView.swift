import SwiftUI
import NimbleViews

struct FilePermissionsView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var fileAttributes: [FileAttributeKey: Any] = [:]
    @State private var permissions: String = ""
    @State private var owner: String = ""
    @State private var group: String = ""
    @State private var fileSize: String = ""
    @State private var creationDate: Date?
    @State private var modificationDate: Date?
    @State private var isReadable: Bool = false
    @State private var isWritable: Bool = false
    @State private var isExecutable: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("File Permissions"), displayMode: .inline) {
            Form {
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    LabeledContent(.localized("Path"), value: fileURL.path)
                        .font(.caption)
                        .textSelection(.enabled)
                    
                    LabeledContent(.localized("Name"), value: fileURL.lastPathComponent)
                        .textSelection(.enabled)
                    
                    if !fileSize.isEmpty {
                        LabeledContent(.localized("Size"), value: fileSize)
                    }
                } header: {
                    Text(.localized("File Information"))
                }
                
                Section {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(isReadable ? .green : .red)
                        Text(.localized("Readable"))
                        Spacer()
                        Text(isReadable ? .localized("Yes") : .localized("No"))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundStyle(isWritable ? .green : .red)
                        Text(.localized("Writable"))
                        Spacer()
                        Text(isWritable ? .localized("Yes") : .localized("No"))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "terminal.fill")
                            .foregroundStyle(isExecutable ? .green : .red)
                        Text(.localized("Executable"))
                        Spacer()
                        Text(isExecutable ? .localized("Yes") : .localized("No"))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(.localized("Access Permissions"))
                }
                
                if !permissions.isEmpty {
                    Section {
                        LabeledContent(.localized("POSIX Permissions"), value: permissions)
                            .font(.system(.body, design: .monospaced))
                    } header: {
                        Text(.localized("System Permissions"))
                    } footer: {
                        Text(.localized("POSIX permissions in octal format"))
                    }
                }
                
                if !owner.isEmpty || !group.isEmpty {
                    Section {
                        if !owner.isEmpty {
                            LabeledContent(.localized("Owner"), value: owner)
                        }
                        if !group.isEmpty {
                            LabeledContent(.localized("Group"), value: group)
                        }
                    } header: {
                        Text(.localized("Ownership"))
                    }
                }
                
                Section {
                    if let date = creationDate {
                        LabeledContent(.localized("Created"), value: date.formatted())
                    }
                    
                    if let date = modificationDate {
                        LabeledContent(.localized("Modified"), value: date.formatted())
                    }
                } header: {
                    Text(.localized("Dates"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPermissions()
        }
    }
    
    private func loadPermissions() {
        do {
            fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            // Get permissions
            if let posixPermissions = fileAttributes[.posixPermissions] as? NSNumber {
                permissions = String(format: "%o", posixPermissions.intValue)
            }
            
            // Get owner and group
            if let ownerName = fileAttributes[.ownerAccountName] as? String {
                owner = ownerName
            }
            
            if let groupName = fileAttributes[.groupOwnerAccountName] as? String {
                group = groupName
            }
            
            // Get file size
            if let size = fileAttributes[.size] as? NSNumber {
                fileSize = ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
            }
            
            // Get dates
            creationDate = fileAttributes[.creationDate] as? Date
            modificationDate = fileAttributes[.modificationDate] as? Date
            
            // Check access permissions
            isReadable = FileManager.default.isReadableFile(atPath: fileURL.path)
            isWritable = FileManager.default.isWritableFile(atPath: fileURL.path)
            isExecutable = FileManager.default.isExecutableFile(atPath: fileURL.path)
            
        } catch {
            errorMessage = String(localized: "Failed to load permissions") + ": \(error.localizedDescription)"
            AppLogManager.shared.error("Failed to load file permissions: \(error.localizedDescription)", category: "Files")
        }
    }
}
