import SwiftUI
import NimbleViews
import Zip

// MARK: - View
struct ConfigurationView: View {
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var isRandomAlertPresenting = false
    @State private var randomString = ""
    @AppStorage("Feather.compressionLevel") private var _compressionLevel: Int = ZipCompression.DefaultCompression.rawValue
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    
    var body: some View {
        List {
            // Frameworks Section
            Section {
                NavigationLink {
                    DefaultFrameworksView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Default Frameworks")
                                .font(.system(size: 15))
                            Text("Auto-inject into all apps")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                sectionHeader("Injection", icon: "syringe.fill")
            }
            
            // Archive & Compression Section (moved from separate view)
            Section {
                Picker(selection: $_compressionLevel) {
                    ForEach(ZipCompression.allCases, id: \.rawValue) { level in
                        Text(level.label).tag(level.rawValue)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.indigo)
                            .frame(width: 24)
                        Text("Compression Level")
                            .font(.system(size: 15))
                    }
                }
                
                Toggle(isOn: $_useShareSheet) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("Show Sheet When Exporting")
                            .font(.system(size: 15))
                    }
                }
                .tint(.accentColor)
            } header: {
                sectionHeader("Archive & Compression", icon: "archivebox.fill")
            } footer: {
                Text("Toggling show sheet will present a share sheet after exporting to your files.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            // Signing Options
            SigningOptionsView(options: $optionsManager.options)
        }
        .navigationTitle("Signing Options")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section(optionsManager.options.ppqString) {
                        Button {
                            isRandomAlertPresenting = true
                        } label: {
                            Label("Change", systemImage: "pencil")
                        }
                        
                        Button {
                            UIPasteboard.general.string = optionsManager.options.ppqString
                            HapticsManager.shared.success()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                }
            }
        }
        .alert("PPQ String", isPresented: $isRandomAlertPresenting) {
            TextField("String", text: $randomString)
            Button("Save") {
                if !randomString.isEmpty {
                    optionsManager.options.ppqString = randomString
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: optionsManager.options) { _ in
            optionsManager.saveOptions()
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
