import SwiftUI
import NimbleViews

// MARK: - FilesSettingsView
struct FilesSettingsView: View {
    @AppStorage("files_viewStyle") private var viewStyle: String = "list"
    @AppStorage("files_sortOption") private var sortOption: String = "name"
    @AppStorage("files_showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("files_showFileExtensions") private var showFileExtensions = true
    @AppStorage("files_showFileSize") private var showFileSize = true
    @AppStorage("files_showModificationDate") private var showModificationDate = true
    @AppStorage("files_enableQuickInspect") private var enableQuickInspect = true
    @AppStorage("files_enableOpenInSigner") private var enableOpenInSigner = true
    @AppStorage("files_enableFixStructure") private var enableFixStructure = true
    @AppStorage("files_enableBreadcrumbs") private var enableBreadcrumbs = true
    
    var body: some View {
        NBNavigationView(.localized("Files Settings"), displayMode: .inline) {
            Form {
                // MARK: - View Style Section
                NBSection(.localized("View Style")) {
                    Picker(selection: $viewStyle) {
                        Label(.localized("List View"), systemImage: "list.bullet")
                            .tag("list")
                        Label(.localized("Grid View"), systemImage: "square.grid.2x2")
                            .tag("grid")
                    } label: {
                        ConditionalLabel(title: .localized("Default View"), systemImage: "square.grid.2x2")
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text(.localized("Choose the default view style for the Files tab."))
                }
                
                // MARK: - Sorting Section
                NBSection(.localized("Sorting")) {
                    Picker(selection: $sortOption) {
                        Text(.localized("Name")).tag("name")
                        Text(.localized("Date Modified")).tag("date")
                        Text(.localized("Size")).tag("size")
                        Text(.localized("Type")).tag("type")
                    } label: {
                        ConditionalLabel(title: .localized("Sort By"), systemImage: "arrow.up.arrow.down")
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text(.localized("Default sorting option for files and folders."))
                }
                
                // MARK: - File Metadata Section
                NBSection(.localized("File Metadata")) {
                    Toggle(isOn: $showHiddenFiles) {
                        ConditionalLabel(title: .localized("Show Hidden Files"), systemImage: "eye.slash")
                    }
                    
                    Toggle(isOn: $showFileExtensions) {
                        ConditionalLabel(title: .localized("Show File Extensions"), systemImage: "doc.text")
                    }
                    
                    Toggle(isOn: $showFileSize) {
                        ConditionalLabel(title: .localized("Show File Size"), systemImage: "doc")
                    }
                    
                    Toggle(isOn: $showModificationDate) {
                        ConditionalLabel(title: .localized("Show Modification Date"), systemImage: "clock")
                    }
                } footer: {
                    Text(.localized("Control which file metadata is displayed in the Files tab."))
                }
                
                // MARK: - Navigation Section
                NBSection(.localized("Navigation")) {
                    Toggle(isOn: $enableBreadcrumbs) {
                        ConditionalLabel(title: .localized("Enable Breadcrumbs"), systemImage: "arrow.turn.down.right")
                    }
                } footer: {
                    Text(.localized("Show breadcrumb navigation at the top of the Files tab for quick folder navigation."))
                }
                
                // MARK: - Smart Actions Section
                NBSection(.localized("Smart Actions")) {
                    Toggle(isOn: $enableQuickInspect) {
                        ConditionalLabel(title: .localized("Quick Inspect"), systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Toggle(isOn: $enableOpenInSigner) {
                        ConditionalLabel(title: .localized("Open In Signer"), systemImage: "signature")
                    }
                    
                    Toggle(isOn: $enableFixStructure) {
                        ConditionalLabel(title: .localized("Fix Structure"), systemImage: "wrench.and.screwdriver")
                    }
                } footer: {
                    Text(.localized("Enable or disable smart context actions in the Files tab. Quick Inspect shows detailed file information, Open in Signer opens IPA files in the signer, and Fix Structure attempts to repair corrupted file structures."))
                }
                
                // MARK: - Reset Section
                NBSection(.localized("Reset")) {
                    Button {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text(.localized("Reset To Defaults"))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                } footer: {
                    Text(.localized("Reset all Files settings to their default values."))
                }
            }
        }
    }
    
    private func resetToDefaults() {
        viewStyle = "list"
        sortOption = "name"
        showHiddenFiles = false
        showFileExtensions = true
        showFileSize = true
        showModificationDate = true
        enableQuickInspect = true
        enableOpenInSigner = true
        enableFixStructure = true
        enableBreadcrumbs = true
        
        HapticsManager.shared.success()
    }
}

// MARK: - Preview
struct FilesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        FilesSettingsView()
    }
}
