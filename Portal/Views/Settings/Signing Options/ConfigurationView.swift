import SwiftUI
import NimbleViews
import Zip

// MARK: - Configuration View
struct ConfigurationView: View {
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var isRandomAlertPresenting = false
    @State private var randomString = ""
    @State private var showInstallationOptions = false
    @AppStorage("Feather.compressionLevel") private var _compressionLevel: Int = ZipCompression.DefaultCompression.rawValue
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    
    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    ConfigurationHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section("Quick Actions") {
                Button {
                    showInstallationOptions = true
                } label: {
                    Label("Installation Options", systemImage: "tray.and.arrow.down.fill")
                }
                .foregroundStyle(.primary)
                
                NavigationLink {
                    DefaultFrameworksView()
                } label: {
                    Label("Default Frameworks", systemImage: "puzzlepiece.extension.fill")
                }
            }

            Section("Signing Options") {
                ModernSigningOptionsCard(options: $optionsManager.options)
            }

            Section("Archive & Compression") {
                Picker(selection: $_compressionLevel) {
                    ForEach(ZipCompression.allCases, id: \.rawValue) { level in
                        Text(level.label).tag(level.rawValue)
                    }
                } label: {
                    Label("Compression", systemImage: "archivebox.fill")
                }
                
                Toggle(isOn: $_useShareSheet) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Share Sheet")
                            Text("Show after exporting").font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Signing Options")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section(optionsManager.options.ppqString) {
                        Button {
                            isRandomAlertPresenting = true
                        } label: {
                            Label("Change PPQ String", systemImage: "pencil")
                        }
                        
                        Button {
                            UIPasteboard.general.string = optionsManager.options.ppqString
                            HapticsManager.shared.success()
                        } label: {
                            Label("Copy PPQ String", systemImage: "doc.on.doc")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showInstallationOptions) {
            ServerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
}

// MARK: - Modern Signing Options Card
struct ModernSigningOptionsCard: View {
    @Binding var options: Options
    @State private var showPPQInfo = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    
    private var hasCertificateWithPPQCheck: Bool {
        let certificates = Storage.shared.getAllCertificates()
        return certificates.contains { $0.ppQCheck }
    }
    
    private var isEnterpriseCertificate: Bool {
        certificateExperience == "Enterprise"
    }
    
    private var isPPQProtectionForced: Bool {
        isEnterpriseCertificate || hasCertificateWithPPQCheck
    }
    
    var body: some View {
        Group {
            Toggle(isOn: Binding(
                get: { isPPQProtectionForced ? true : options.ppqProtection },
                set: { if !isPPQProtectionForced || $0 { options.ppqProtection = $0 } }
            )) {
                Label {
                    VStack(alignment: .leading) {
                        Text("PPQ Protection")
                        Text(isPPQProtectionForced ? "Required for your certificate" : "Protect against revocation").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "shield.checkered").foregroundStyle(.blue)
                }
            }
            .disabled(isPPQProtectionForced)
            
            Toggle(isOn: $options.dynamicProtection) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Dynamic PPQ Protection")
                        Text("Only applies a string to the bundle IDs for apps that are on the App Store.").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "shield.lefthalf.filled").foregroundStyle(.purple)
                }
            }
            
            Toggle(isOn: $options.experiment_supportLiquidGlass) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Liquid Glass")
                        Text("iOS 26 redesign support").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "sparkles.rectangle.stack.fill").foregroundStyle(.cyan)
                }
            }
            
            Picker(selection: $options.signingOption) {
                ForEach(Options.SigningOption.allCases, id: \.self) { option in
                    Text(option.localizedDescription).tag(option)
                }
            } label: {
                Label("Signing Type", systemImage: "signature").foregroundStyle(.purple)
            }
            
            Picker(selection: $options.appAppearance) {
                ForEach(Options.AppAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.localizedDescription).tag(appearance)
                }
            } label: {
                Label("Appearance", systemImage: "paintpalette.fill").foregroundStyle(.pink)
            }
            
            Picker(selection: $options.minimumAppRequirement) {
                ForEach(Options.MinimumAppRequirement.allCases, id: \.self) { req in
                    Text(req.localizedDescription).tag(req)
                }
            } label: {
                Label("Minimum Requirement", systemImage: "ruler.fill").foregroundStyle(.indigo)
            }
            
            Toggle(isOn: $options.fileSharing) {
                Label {
                    VStack(alignment: .leading) {
                        Text("File Sharing")
                        Text("Enable document sharing").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "folder.fill.badge.person.crop").foregroundStyle(.orange)
                }
            }
            
            Toggle(isOn: $options.itunesFileSharing) {
                Label {
                    VStack(alignment: .leading) {
                        Text("iTunes File Sharing")
                        Text("Access via iTunes/Finder").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "music.note.list").foregroundStyle(.pink)
                }
            }
            
            Toggle(isOn: $options.proMotion) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Pro Motion")
                        Text("120Hz display support").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "gauge.with.dots.needle.67percent").foregroundStyle(.green)
                }
            }
            
            Toggle(isOn: $options.gameMode) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Game Mode")
                        Text("Gaming Mode (iOS 18+)").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "gamecontroller.fill").foregroundStyle(.indigo)
                }
            }
            
            Toggle(isOn: $options.ipadFullscreen) {
                Label {
                    VStack(alignment: .leading) {
                        Text("iPad Fullscreen")
                        Text("Full screen on iPad").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "ipad.landscape").foregroundStyle(.teal)
                }
            }
            
            Toggle(isOn: $options.removeURLScheme) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Remove URL Scheme")
                        Text("Strip URL handlers").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "link.badge.minus").foregroundStyle(.red)
                }
            }
            
            Toggle(isOn: $options.removeProvisioning) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Remove Provisioning")
                        Text("Exclude .mobileprovision").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.badge.minus").foregroundStyle(.orange)
                }
            }
            
            Toggle(isOn: $options.changeLanguageFilesForCustomDisplayName) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Force Localize")
                        Text("Override localized titles").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "character.bubble.fill").foregroundStyle(.green)
                }
            }
            
            Toggle(isOn: $options.experiment_replaceSubstrateWithEllekit) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Replace Substrate")
                        Text("Use ElleKit instead").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundStyle(.cyan)
                }
            }

            Toggle(isOn: $options.supportBigApps) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Support Big Apps")
                        Text("Allow signing and installing apps larger than 3GB").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "shippingbox.fill").foregroundStyle(.blue)
                }
            }

            Picker(selection: AppStorage(wrappedValue: 0, "Feather.signingButtonType").projectedValue) {
                ForEach(SigningButtonType.allCases, id: \.self) { type in
                    Text(type.label).tag(type.rawValue)
                }
            } label: {
                Label("Signing Control", systemImage: "hand.tap.fill").foregroundStyle(.pink)
            }
            
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.bool(forKey: "Feather.autoSignAfterDownload") },
                set: { UserDefaults.standard.set($0, forKey: "Feather.autoSignAfterDownload") }
            )) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Auto Sign After Download")
                        Text("Automatically sign and install apps after download").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "bolt.badge.a.fill").foregroundStyle(.orange)
                }
            }

            Toggle(isOn: $options.post_installAppAfterSigned) {
                Label("Install After Signing", systemImage: "arrow.down.circle.fill").foregroundStyle(.cyan)
            }
            
            Toggle(isOn: $options.post_deleteAppAfterSigned) {
                Label("Delete After Signing", systemImage: "trash.fill").foregroundStyle(.red)
            }
        }
        .onAppear {
            if isPPQProtectionForced && !options.ppqProtection {
                options.ppqProtection = true
            }
        }
    }
}
