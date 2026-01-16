import SwiftUI
import NimbleViews

// MARK: - View
struct ConfigurationView: View {
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var isRandomAlertPresenting = false
    @State private var randomString = ""
    
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
