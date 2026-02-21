import SwiftUI
import PhotosUI
import NimbleViews
import ImageIO

// MARK: - Modern Full Screen Signing View
struct ModernSigningView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @AppStorage("Feather.signingButtonType") private var _signingButtonType: Int = 0
    @AppStorage(UserDefaults.Keys.installTrigger) private var installTrigger: Int = 0
    @AppStorage("feature_advancedSigning") private var _advancedSigningEnabled = false
    @StateObject private var _optionsManager = OptionsManager.shared
    
    @State private var _temporaryOptions: Options = OptionsManager.shared.options
    @State private var _temporaryCertificate: Int
    @State private var _isAltPickerPresenting = false
    @State private var _isFilePickerPresenting = false
    @State private var _isImagePickerPresenting = false
    @State private var _isSigning = false
    @State private var _selectedPhoto: PhotosPickerItem? = nil
    @State var appIcon: UIImage?
    
    @State private var _isNameDialogPresenting = false
    @State private var _isIdentifierDialogPresenting = false
    @State private var _isVersionDialogPresenting = false
    @State private var _isAddingCertificatePresenting = false
    @State private var _selectedTab = 0
    @State private var _showAdvancedDebugSheet = false
    
    @State private var _editingName = ""
    @State private var _editingBundleId = ""
    @State private var _editingVersion = ""
    @State private var _capabilities: [String] = []
    @State private var _metalState: MetalAnimationState = .idle
    @State private var _errorMessage: String? = nil
    
    // Animation states
    @State private var _appearAnimation = false
    @State private var _headerScale: CGFloat = 0.8
    @State private var _contentOpacity: Double = 0
    @State private var _buttonOffset: CGFloat = 50
    @State private var _glowAnimation = false
    @State private var _floatingAnimation = false
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .easeInOut(duration: 0.35)
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func _selectedCert() -> CertificatePair? {
        guard certificates.indices.contains(_temporaryCertificate) else { return nil }
        return certificates[_temporaryCertificate]
    }
    
    var app: AppInfoPresentable
    
    init(app: AppInfoPresentable) {
        self.app = app
        let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        __temporaryCertificate = State(initialValue: storedCert)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                modernBackground
                
                VStack(spacing: 0) {
                    _scrollableContent
                    
                    VStack(spacing: 12) {
                        switch _signingButtonType {
                        case 0:
                            modernSignButton
                        case 1:
                            SwipeToSign(onComplete: { _start() })
                                .padding(.horizontal, 24)
                                .padding(.bottom, 10)
                        case 2:
                            HoldToSign(onComplete: { _start() })
                                .padding(.horizontal, 24)
                                .padding(.bottom, 10)
                        case 3:
                            SlideToConfirm(onComplete: { _start() })
                                .padding(.horizontal, 24)
                                .padding(.bottom, 10)
                        case 4:
                            DoubleTapToSign(onComplete: { _start() })
                                .padding(.horizontal, 24)
                                .padding(.bottom, 10)
                        default:
                            modernSignButton
                        }
                    }
                    .offset(y: _buttonOffset)
                    .opacity(_contentOpacity)
                }
            }
            .disabled(_metalState == .loading)
            .sheet(isPresented: $_isAltPickerPresenting) {
                SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true))
                    .applyGlobalTheme()
            }
            .sheet(isPresented: $_isFilePickerPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.image],
                    onDocumentsPicked: { urls in
                        guard let selectedFileURL = urls.first else { return }
                        self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
                    }
                )
                .ignoresSafeArea()
                .applyGlobalTheme()
            }
            .photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
            .onChange(of: _selectedPhoto) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.resizeToSquare() {
                        appIcon = image
                    }
                }
            }
            .fullScreenCover(isPresented: $_isAddingCertificatePresenting) {
                CertificatesAddView()
                    .applyGlobalTheme()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                _toolbarContent
            }
            .onAppear {
                _onAppearAction()
            }
            .sheet(isPresented: $_isNameDialogPresenting) {
                ModernEditSheet(
                    title: "App Name",
                    icon: "textformat",
                    iconColor: .blue,
                    placeholder: "Enter New App Name",
                    value: $_editingName,
                    onSave: {
                        _temporaryOptions.appName = _editingName.isEmpty ? nil : _editingName
                        _isNameDialogPresenting = false
                    },
                    onCancel: {
                        _isNameDialogPresenting = false
                    }
                )
                .onAppear {
                    _editingName = _temporaryOptions.appName ?? app.name ?? ""
                }
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
                .applyGlobalTheme()
            }
            .sheet(isPresented: $_isIdentifierDialogPresenting) {
                ModernEditSheet(
                    title: "Bundle ID",
                    icon: "barcode",
                    iconColor: .purple,
                    placeholder: "New Bundle ID",
                    value: $_editingBundleId,
                    keyboardType: .URL,
                    onSave: {
                        _temporaryOptions.appIdentifier = _editingBundleId.isEmpty ? nil : _editingBundleId
                        _isIdentifierDialogPresenting = false
                    },
                    onCancel: {
                        _isIdentifierDialogPresenting = false
                    }
                )
                .onAppear {
                    _editingBundleId = _temporaryOptions.appIdentifier ?? app.identifier ?? ""
                }
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
                .applyGlobalTheme()
            }
            .sheet(isPresented: $_isVersionDialogPresenting) {
                ModernEditSheet(
                    title: "Version",
                    icon: "tag",
                    iconColor: .green,
                    placeholder: "New Version",
                    value: $_editingVersion,
                    keyboardType: .numbersAndPunctuation,
                    onSave: {
                        _temporaryOptions.appVersion = _editingVersion.isEmpty ? nil : _editingVersion
                        _isVersionDialogPresenting = false
                    },
                    onCancel: {
                        _isVersionDialogPresenting = false
                    }
                )
                .onAppear {
                    _editingVersion = _temporaryOptions.appVersion ?? app.version ?? ""
                }
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
                .applyGlobalTheme()
            }
        }
        .overlay {
            FullScreenMetalStateView(state: $_metalState, errorMessage: _errorMessage)
                .ignoresSafeArea()
                .zIndex(100)
        }
        .handleStatusBarHiding()
    }

    @ViewBuilder
    private var _scrollableContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                    .scaleEffect(_headerScale)
                    .opacity(_contentOpacity)
                
                unifiedContentSection
                    .opacity(_contentOpacity)

                capabilitiesSection
                    .opacity(_contentOpacity)
            }
            .padding(.bottom, 100)
        }
    }

    @ToolbarContentBuilder
    private var _toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismissWithAnimation()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .opacity(_contentOpacity)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                _temporaryOptions = OptionsManager.shared.options
                appIcon = nil
            } label: {
                Text("Reset")
                    .font(.subheadline.weight(.medium))
            }
            .opacity(_contentOpacity)
        }
    }


    private func _loadCapabilities() {
        guard let appURL = Storage.shared.getAppDirectory(for: app) else { return }
        let infoPlistURL = appURL.appendingPathComponent("Info.plist")
        guard let infoDict = NSDictionary(contentsOf: infoPlistURL) else { return }

        if let caps = infoDict["UIRequiredDeviceCapabilities"] as? [String] {
            _capabilities = caps
        } else if let caps = infoDict["UIRequiredDeviceCapabilities"] as? [String: Bool] {
            _capabilities = caps.keys.sorted()
        }
    }

    private func _onAppearAction() {
        _loadCapabilities()
        if installTrigger == 1 {
            _temporaryOptions.post_installAppAfterSigned = true
        }

        if _optionsManager.options.ppqProtection,
           let identifier = app.identifier,
           let cert = _selectedCert(),
           cert.ppQCheck {
            _temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
        }

        if let currentBundleId = app.identifier,
           let newBundleId = _temporaryOptions.identifiers[currentBundleId] {
            _temporaryOptions.appIdentifier = newBundleId
        }

        if let currentName = app.name,
           let newName = _temporaryOptions.displayNames[currentName] {
            _temporaryOptions.appName = newName
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            _headerScale = 1.0
            _contentOpacity = 1.0
            _buttonOffset = 0
            _appearAnimation = true
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.25)) {
            _headerScale = 0.9
            _contentOpacity = 0
            _buttonOffset = 30
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
    
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                TimelineView(.animation) { timeline in
                    Color.clear
                    }
                }
                .ignoresSafeArea()
            } else {
                LinearGradient(colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.05 : 0.08), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                GeometryReader { geo in
                    Circle().fill(RadialGradient(colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.12 : 0.15), Color.accentColor.opacity(0.05), .clear], center: .center, startRadius: 0, endRadius: 160)).frame(width: 320, height: 320).blur(radius: 70).offset(x: _floatingAnimation ? -40 : 40, y: _floatingAnimation ? -25 : 25).position(x: geo.size.width * 0.15, y: geo.size.height * 0.12)
                    Circle().fill(RadialGradient(colors: [Color.purple.opacity(colorScheme == .dark ? 0.08 : 0.1), Color.purple.opacity(0.03), .clear], center: .center, startRadius: 0, endRadius: 130)).frame(width: 260, height: 260).blur(radius: 55).offset(x: _floatingAnimation ? 35 : -35, y: _floatingAnimation ? 15 : -15).position(x: geo.size.width * 0.88, y: geo.size.height * 0.65)
                }.ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                _floatingAnimation = true
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Menu {
                Button { _isAltPickerPresenting = true } label: { Label("Select Alternative Icon", systemImage: "app.dashed") }
                Button { _isFilePickerPresenting = true } label: { Label("Choose From Files", systemImage: "folder.fill") }
                Button { _isImagePickerPresenting = true } label: { Label("Choose From Photos", systemImage: "photo.fill") }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let icon = appIcon {
                        Image(uiImage: icon).appIconStyle(size: 80)
                    } else {
                        FRAppIconView(app: app, size: 80).modifier(BounceEffectModifier(value: _appearAnimation))
                    }
                    Image(systemName: "pencil.circle.fill").font(.system(size: 24)).foregroundStyle(.white, Color.accentColor).background(Circle().fill(Color.accentColor).frame(width: 20, height: 20)).offset(x: 4, y: 4)
                }.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 6) {
                Text(_temporaryOptions.appName ?? app.name ?? "Unknown").font(.title3.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                HStack(spacing: 8) {
                    if let version = _temporaryOptions.appVersion ?? app.version {
                        Label(version, systemImage: "number.circle.fill").font(.caption.weight(.medium)).foregroundStyle(.secondary).modifier(BounceEffectModifier(value: _appearAnimation))
                    }
                }
                if let bundleId = _temporaryOptions.appIdentifier ?? app.identifier {
                    Text(bundleId).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundStyle(.tertiary).lineLimit(1).truncationMode(.middle).padding(.horizontal, 12).padding(.vertical, 4).background(Capsule().fill(Color(.systemGray6)))
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var capabilitiesSection: some View {
        let displayCapabilities = _capabilities.filter { !_temporaryOptions.removedCapabilities.contains($0) }
        if !displayCapabilities.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "Capabilities", icon: "cpu.fill")
                VStack(spacing: 0) {
                    ForEach(displayCapabilities, id: \.self) { cap in
                        let info = CapabilityMapper.getInfo(for: cap)
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.accentColor.opacity(0.12)).frame(width: 32, height: 32)
                                Image(systemName: info.icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.accentColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.name).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
                                Text(cap).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { withAnimation { _temporaryOptions.removedCapabilities.append(cap) } } label: {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(.secondary.opacity(0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        if cap != displayCapabilities.last { Divider().padding(.leading, 52) }
                    }
                }.background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.clear.opacity(0.4)))
            }.padding(.horizontal, 20).padding(.top, 8)
        }
    }

    @ViewBuilder
    private var unifiedContentSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "App Details", icon: "app.badge.fill")
                VStack(spacing: 0) {
                    cleanEditableRow(title: "Name", value: _temporaryOptions.appName ?? app.name ?? "Unknown", icon: "textformat") { _isNameDialogPresenting = true }
                    Divider().padding(.leading, 52)
                    cleanEditableRow(title: "Bundle ID", value: _temporaryOptions.appIdentifier ?? app.identifier ?? "", icon: "barcode") { _isIdentifierDialogPresenting = true }
                    Divider().padding(.leading, 52)
                    cleanEditableRow(title: "Version", value: _temporaryOptions.appVersion ?? app.version ?? "1.0", icon: "tag") { _isVersionDialogPresenting = true }
                }.background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.clear.opacity(0.4)))
            }
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "Certificate", icon: "checkmark.seal.fill")
                certificateCard
            }
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "Modify", icon: "slider.horizontal.3")
                VStack(spacing: 0) {
                    NavigationLink { ModernSigningOptionsView(options: $_temporaryOptions) } label: { cleanNavigationRow(title: "Signing Options", icon: "gearshape.fill", color: .gray) }
                    Divider().padding(.leading, 52)
                    NavigationLink { AppTweaksView(app: app, options: $_temporaryOptions) } label: { cleanNavigationRow(title: "App Tweaks", icon: "cube.fill", color: .blue) }
                    Divider().padding(.leading, 52)
                    NavigationLink { SigningTweaksView(options: $_temporaryOptions) } label: { cleanNavigationRow(title: "Inject Tweaks", icon: "wrench.and.screwdriver.fill", color: .green) }
                    Divider().padding(.leading, 52)
                    NavigationLink { SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile) } label: { cleanNavigationRow(title: "Entitlements", icon: "lock.shield.fill", color: .orange) }
                    Divider().padding(.leading, 52)
                    NavigationLink { InfoPlistEntriesView(options: $_temporaryOptions) } label: { cleanNavigationRow(title: "Custom Info.plist Entries", icon: "doc.badge.gearshape.fill", color: .indigo) }
                }.background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.clear.opacity(0.4)))
            }
            if _advancedSigningEnabled { AdvancedSigningOptionsSection(app: app, options: $_temporaryOptions, appIcon: $appIcon) }
        }.padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func cleanSectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            Text(title.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
        }.padding(.leading, 4)
    }
    
    @ViewBuilder
    private func cleanEditableRow(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    Text(value).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.quaternary)
            }.padding(.horizontal, 14).padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func cleanNavigationRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(color.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
            Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.quaternary)
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var certificateCard: some View {
        if let cert = _selectedCert() {
            NavigationLink { CertificatesView(selectedCert: $_temporaryCertificate) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.green).frame(width: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cert.nickname ?? "Certificate").font(.body.weight(.medium)).foregroundStyle(.primary)
                        if let expiration = cert.expiration { Label(.localized("Expires \(expiration.formatted(date: .abbreviated, time: .omitted))"), systemImage: "calendar").font(.caption).foregroundStyle(.secondary) }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.quaternary)
                }.padding(14).background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.clear.opacity(0.4)))
            }
        } else {
            Button { _isAddingCertificatePresenting = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.title2).foregroundStyle(.orange).frame(width: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("No Certificate")).font(.body.weight(.medium)).foregroundStyle(.primary)
                        Text(.localized("Tap To Add")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
                }.padding(14).background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.clear.opacity(0.4)))
            }.buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func modernAdvancedRow(title: String, subtitle: String, icon: String, color: Color, isFirst: Bool = false, isLast: Bool = false, isBeta: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 44, height: 44).shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                    if isBeta { Text("Beta").font(.system(size: 9, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.orange)) }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary).padding(8).background(Circle().fill(Color(UIColor.tertiarySystemFill)))
        }.padding(.horizontal, 14).padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var modernSignButton: some View {
        Button { _start() } label: {
            HStack(spacing: 12) {
                Image(systemName: "signature").font(.system(size: 18, weight: .bold))
                Text("Sign App").font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(ZStack {
                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.5), .clear, .black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(RadialGradient(colors: [.white.opacity(0.2), .clear], center: .topLeading, startRadius: 0, endRadius: 100))
            })
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.4), radius: _glowAnimation ? 16 : 10, x: 0, y: _glowAnimation ? 8 : 4)
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(_glowAnimation ? 0.3 : 0), lineWidth: 2).blur(radius: 4))
        }.buttonStyle(SignButtonStyle()).padding(.horizontal, 24).padding(.bottom, 20).padding(.top, 12)
        .onAppear { withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { _glowAnimation = true } }
    }
    
    private func _start() {
        guard let cert = _selectedCert() else {
            UIAlertController.showAlertWithOk(title: .localized("No Certificate"), message: .localized("Please go to Settings and import a certificate then come back here."), isCancel: true)
            return
        }
        HapticsManager.shared.impact()
        AppStateManager.shared.isSigning = true
        _metalState = .loading
        withAnimation(.easeOut(duration: 0.4)) {
            _headerScale = 0.85
            _contentOpacity = 0
            _isSigning = true
        }
        if _serverMethod == 2 {
            FR.remoteSignPackageFile(app, using: _temporaryOptions, certificate: cert) { result in
                DispatchQueue.main.async {
                    _isSigning = false
                    AppStateManager.shared.isSigning = false
                    switch result {
                    case .success(let installLink):
                        _metalState = .success
                        if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") { NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App") }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            let install = UIAlertAction(title: .localized("Install"), style: .default) { _ in if let url = URL(string: installLink) { UIApplication.shared.open(url) } }
                            let copy = UIAlertAction(title: .localized("Copy Link"), style: .default) { _ in UIPasteboard.general.string = installLink }
                            let cancel = UIAlertAction(title: .localized("Cancel"), style: .cancel)
                            UIAlertController.showAlert(title: .localized("Signing Successful"), message: .localized("Your app is ready to install!"), actions: [install, copy, cancel])
                        }
                    case .failure(let error):
                        _errorMessage = error.localizedDescription
                        _metalState = .error
                    }
                }
            }
        } else {
            FR.signPackageFile(app, using: _temporaryOptions, icon: appIcon, certificate: cert) { error in
                DispatchQueue.main.async {
                    AppStateManager.shared.isSigning = false
                    if let error {
                        _errorMessage = error.localizedDescription
                        _metalState = .error
                    } else {
                        _metalState = .success
                        if _temporaryOptions.post_deleteAppAfterSigned, !app.isSigned { Storage.shared.deleteApp(for: app) }
                        if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") { NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App") }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if _temporaryOptions.post_installAppAfterSigned { NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil) }
                            dismissWithAnimation()
                        }
                    }
                }
            }
        }
    }
}
