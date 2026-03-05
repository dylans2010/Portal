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
    @StateObject private var _motionManager = MotionManager.shared
    
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
    @State private var _decodedCertificate: Certificate?
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
                            SwipeToSign(onComplete: {
                                _start()
                            })
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        case 2:
                            HoldToSign(onComplete: {
                                _start()
                            })
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        case 3:
                            SlideToConfirm(onComplete: {
                                _start()
                            })
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        case 4:
                            DoubleTapToSign(onComplete: {
                                _start()
                            })
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
            }
            .onChange(of: _temporaryCertificate) { newValue in
                if let cert = _selectedCert() {
                    _decodedCertificate = Storage.shared.getProvisionFileDecoded(for: cert)
                }
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
            }
        }
        .overlay {
            FullScreenMetalStateView(
                state: $_metalState,
                appName: _temporaryOptions.appName ?? app.name,
                errorMessage: _errorMessage
            )
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
                _motionManager.start()
                _loadCapabilities()
                // Apply global installation trigger setting if not already set
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

                if let cert = _selectedCert() {
                    _decodedCertificate = Storage.shared.getProvisionFileDecoded(for: cert)
                }
                
                // Trigger entrance animation
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                    _headerScale = 1.0
                    _contentOpacity = 1.0
                    _buttonOffset = 0
                    _appearAnimation = true
                }
    }
    
    // MARK: - Dismiss with Animation
    private func dismissWithAnimation() {
        _motionManager.stop()
        withAnimation(.easeOut(duration: 0.25)) {
            _headerScale = 0.9
            _contentOpacity = 0
            _buttonOffset = 30
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
    
    // MARK: - Modern Background (Enhanced)
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Dark base for better glass contrast
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if #available(iOS 17.0, *) {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate

                        context.addFilter(.blur(radius: 80))

                        for i in 0..<4 {
                            let speed = Double(i + 1) * 0.15
                            let motionOffset = CGFloat(i + 1) * 20
                            let x = (sin(time * speed + Double(i)) + 1) / 2 * size.width + (_motionManager.roll * motionOffset)
                            let y = (cos(time * speed * 0.8 + Double(i)) + 1) / 2 * size.height + (_motionManager.pitch * motionOffset)

                            let colors: [Color] = [.accentColor, .purple, .cyan, .indigo]
                            let color = colors[i % colors.count]

                            context.fill(
                                Path(ellipseIn: CGRect(x: x - 180, y: y - 180, width: 360, height: 360)),
                                with: .radialGradient(
                                    Gradient(colors: [color.opacity(0.2), .clear]),
                                    center: CGPoint(x: x, y: y),
                                    startRadius: 0,
                                    endRadius: 180
                                )
                            )
                        }
                    }
                }
                .ignoresSafeArea()
            } else {
                // Fallback for older iOS
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Header Section (Clean Modern Design)
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon with standard menu
            Menu {
                Button {
                    _isAltPickerPresenting = true
                } label: {
                    Label("Choose App Icon", systemImage: "app.dashed")
                }
                Button {
                    _isFilePickerPresenting = true
                } label: {
                    Label("Choose From Files", systemImage: "folder.fill")
                }
                Button {
                    _isImagePickerPresenting = true
                } label: {
                    Label("Choose From Photos", systemImage: "photo.fill")
                }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let icon = appIcon {
                        Image(uiImage: icon)
                            .appIconStyle(size: 80)
                    } else {
                        FRAppIconView(app: app, size: 80)
                            .modifier(BounceEffectModifier(value: _appearAnimation))
                    }
                    
                    // Simple edit indicator
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white, Color.accentColor)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 20, height: 20)
                        )
                        .offset(x: 4, y: 4)
                }
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            // Compact App Info
            VStack(spacing: 6) {
                Text(_temporaryOptions.appName ?? app.name ?? "Unknown")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let version = _temporaryOptions.appVersion ?? app.version {
                        Label(version, systemImage: "number.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .modifier(BounceEffectModifier(value: _appearAnimation))
                    }
                }
                
                // Simplified Bundle ID
                if let bundleId = _temporaryOptions.appIdentifier ?? app.identifier {
                    Text(bundleId)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Unified Content Section (Clean Modern Design)
    // MARK: - Capabilities Section
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
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: info.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text(cap)
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    _temporaryOptions.removedCapabilities.append(cap)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if cap != displayCapabilities.last {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var unifiedContentSection: some View {
        VStack(spacing: 24) {
            // App Details Section
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "App Details", icon: "app.badge.fill")
                
                VStack(spacing: 0) {
                    cleanEditableRow(title: "Name", value: _temporaryOptions.appName ?? app.name ?? "Unknown", icon: "textformat") {
                        _isNameDialogPresenting = true
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    cleanEditableRow(title: "Bundle ID", value: _temporaryOptions.appIdentifier ?? app.identifier ?? "", icon: "barcode") {
                        _isIdentifierDialogPresenting = true
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    cleanEditableRow(title: "Version", value: _temporaryOptions.appVersion ?? app.version ?? "1.0", icon: "tag") {
                        _isVersionDialogPresenting = true
                    }

                    Divider().padding(.leading, 52)

                    HStack(spacing: 14) {
                        Image(systemName: "plus.square.on.square")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clone App")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Append random string to ID to clone a app.")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Toggle("", isOn: $_temporaryOptions.cloneApp)
                            .labelsHidden()
                            .tint(.accentColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if _temporaryOptions.cloneApp {
                        Divider().padding(.leading, 52)

                        HStack(spacing: 14) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clone String")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text(_temporaryOptions.cloneString)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            Button {
                                _temporaryOptions.cloneString = Options.randomCloneString()
                                HapticsManager.shared.impact()
                            } label: {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
            
            // Certificate Section
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "Certificate", icon: "checkmark.seal.fill")
                certificateCard
            }
            
            // Configuration Section
            VStack(alignment: .leading, spacing: 12) {
                cleanSectionHeader(title: "Modify", icon: "slider.horizontal.3")
                
                VStack(spacing: 0) {
                    NavigationLink {
                        ModernSigningOptionsView(options: $_temporaryOptions)
                    } label: {
                        cleanNavigationRow(title: "Signing Options", icon: "gearshape.fill", color: .gray)
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    NavigationLink {
                        AppTweaksView(app: app, options: $_temporaryOptions)
                    } label: {
                        cleanNavigationRow(title: "App Tweaks", icon: "cube.fill", color: .blue)
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    NavigationLink {
                        SigningTweaksView(options: $_temporaryOptions)
                    } label: {
                        cleanNavigationRow(title: "Inject Tweaks", icon: "wrench.and.screwdriver.fill", color: .green)
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    NavigationLink {
                        SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile)
                    } label: {
                        cleanNavigationRow(title: "Entitlements", icon: "lock.shield.fill", color: .orange)
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    NavigationLink {
                        InfoPlistEntriesView(options: $_temporaryOptions)
                    } label: {
                        cleanNavigationRow(title: "Custom Info.plist Entries", icon: "doc.badge.gearshape.fill", color: .indigo)
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
            
            // Advanced (Debug) Section
            if _advancedSigningEnabled {
                AdvancedSigningOptionsSection(app: app, options: $_temporaryOptions, appIcon: $appIcon)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Clean Section Header
    @ViewBuilder
    private func cleanSectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
    
    // MARK: - Clean Editable Row
    @ViewBuilder
    private func cleanEditableRow(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Clean Navigation Row
    @ViewBuilder
    private func cleanNavigationRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - Certificate Card
    @ViewBuilder
    private var certificateCard: some View {
        if let cert = _selectedCert() {
            NavigationLink {
                CertificatesView(selectedCert: $_temporaryCertificate)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cert.nickname ?? "Certificate")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            if cert.ppQCheck {
                                Text("PPQ")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.blue))
                            }

                            if _decodedCertificate?.ProvisionedDevices != nil {
                                Text("UDID")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange))
                            }

                            if let team = _decodedCertificate?.TeamName {
                                Text(team)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        if let expiration = cert.expiration {
                            let formattedDate = expiration.formatted(date: .abbreviated, time: .omitted)
                            Label(.localized("Expires \(formattedDate)"), systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.quaternary)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
        } else {
            Button {
                _isAddingCertificatePresenting = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("No Certificate"))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(.localized("Tap To Add"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Modern Sign Button (Clean Design)
    @ViewBuilder
    private var modernSignButton: some View {
        Button {
            _start()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "signature")
                    .font(.system(size: 18, weight: .bold))
                Text("Sign App")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Base accent color with gradient
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Glass highlight for Liquid Glass effect
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear, .black.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    // Inner glow
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.2), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.4), radius: _glowAnimation ? 16 : 10, x: 0, y: _glowAnimation ? 8 : 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(_glowAnimation ? 0.3 : 0), lineWidth: 2)
                    .blur(radius: 4)
            )
        }
        .buttonStyle(SignButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                _glowAnimation = true
            }
        }
    }
    
    // MARK: - Start Signing
    private func _start() {
        guard let cert = _selectedCert() else {
            UIAlertController.showAlertWithOk(
                title: .localized("No Certificate"),
                message: .localized("Please go to Settings and import a certificate then come back here."),
                isCancel: true
            )
            return
        }
        
        HapticsManager.shared.impact()
        AppStateManager.shared.isSigning = true
        
        _metalState = .loading

        // Apply Clone App logic if enabled
        if _temporaryOptions.cloneApp, let identifier = app.identifier {
            _temporaryOptions.appIdentifier = "\(identifier).\(_temporaryOptions.cloneString)"
        }

        // Animate out before showing signing process
        withAnimation(.easeOut(duration: 0.4)) {
            _headerScale = 0.85
            _contentOpacity = 0
            _isSigning = true
        }
        
        if _serverMethod == 2 {
            // Custom API - uses remote signing with custom endpoint
            FR.remoteSignPackageFile(
                app,
                using: _temporaryOptions,
                certificate: cert
            ) { result in
                DispatchQueue.main.async {
                    _isSigning = false
                    AppStateManager.shared.isSigning = false
                    
                    switch result {
                    case .success(let installLink):
                        _metalState = .success

                        if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                            NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            let install = UIAlertAction(title: .localized("Install"), style: .default) { _ in
                                if let url = URL(string: installLink) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            let copy = UIAlertAction(title: .localized("Copy Link"), style: .default) { _ in
                                UIPasteboard.general.string = installLink
                            }
                            let cancel = UIAlertAction(title: .localized("Cancel"), style: .cancel)

                            UIAlertController.showAlert(
                                title: .localized("Signing Successful"),
                                message: .localized("Your app is ready to install!"),
                                actions: [install, copy, cancel]
                            )
                        }
                        
                    case .failure(let error):
                        _errorMessage = error.localizedDescription
                        _metalState = .error
                    }
                }
            }
        } else {
            // Local or Semi-Local
            FR.signPackageFile(
                app,
                using: _temporaryOptions,
                icon: appIcon,
                certificate: cert
            ) { error in
                DispatchQueue.main.async {
                    AppStateManager.shared.isSigning = false
                    
                    if let error {
                        _errorMessage = error.localizedDescription
                        _metalState = .error
                    } else {
                        _metalState = .success

                        if _temporaryOptions.post_deleteAppAfterSigned, !app.isSigned {
                            Storage.shared.deleteApp(for: app)
                        }

                        if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                            NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if _temporaryOptions.post_installAppAfterSigned {
                                NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
                            }
                            dismissWithAnimation()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Modern Signing Options View
struct ModernSigningOptionsView: View {
    @Binding var options: Options
    @State private var showPPQInfo = false
    @State private var floatingAnimation = false
    @State private var newURLScheme = ""
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
        ZStack {
            // Modern animated background
            modernOptionsBackground
            
            List {
                // Protection Section
                modernOptionSection(title: "Protection", icon: "shield.lefthalf.filled", color: .blue) {
                    modernOptionToggle(title: "PPQ Protection", subtitle: isPPQProtectionForced ? "Required for your certificate." : "Append random string to Bundle IDs to avoid Apple flagging this certificate.", icon: "shield.checkered", color: .blue, isOn: Binding(
                        get: { isPPQProtectionForced ? true : options.ppqProtection },
                        set: { newValue in
                            if !isPPQProtectionForced || newValue {
                                options.ppqProtection = newValue
                            }
                        }
                    ), disabled: isPPQProtectionForced)
                    
                    Button {
                        showPPQInfo = true
                    } label: {
                        HStack {
                            Label("What is PPQ?", systemImage: "questionmark.circle.fill")
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // General Section
                modernOptionSection(title: "General", icon: "gearshape.2.fill", color: .gray) {
                    modernOptionPicker(title: "Appearance", icon: "paintpalette.fill", color: .purple, selection: $options.appAppearance, values: Options.AppAppearance.allCases)
                    
                    Divider().padding(.leading, 52)

                    modernOptionPicker(title: "Minimum Requirement", icon: "ruler.fill", color: .blue, selection: $options.minimumAppRequirement, values: Options.MinimumAppRequirement.allCases)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // Signing Section
                modernOptionSection(title: "Signing", icon: "signature", color: .accentColor) {
                    modernOptionPicker(title: "Signing Type", icon: "pencil.and.scribble", color: .accentColor, selection: $options.signingOption, values: Options.SigningOption.allCases)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // App Features Section
                modernOptionSection(title: "App Features", icon: "sparkles", color: .orange) {
                    modernOptionToggle(title: "File Sharing", icon: "folder.fill", color: .blue, isOn: $options.fileSharing)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "iTunes File Sharing", icon: "music.note.list", color: .pink, isOn: $options.itunesFileSharing)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "ProMotion", icon: "bolt.fill", color: .yellow, isOn: $options.proMotion)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "Game Mode", icon: "gamecontroller.fill", color: .green, isOn: $options.gameMode)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "iPad Fullscreen", icon: "ipad.landscape", color: .indigo, isOn: $options.ipadFullscreen)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // Removal Section
                modernOptionSection(title: "Removal", icon: "trash.slash.fill", color: .red) {
                    modernOptionToggle(title: "Remove URL Scheme", icon: "link.badge.plus", color: .blue, isOn: $options.removeURLScheme)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "Remove Provisioning", icon: "doc.badge.gearshape", color: .orange, isOn: $options.removeProvisioning)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // URL Schemes Section
                modernOptionSection(title: "URL Schemes", icon: "link", color: .blue) {
                    ForEach(options.customURLSchemes, id: \.self) { scheme in
                        HStack {
                            Text(scheme + "://")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button(role: .destructive) {
                                withAnimation {
                                    options.customURLSchemes.removeAll(where: { $0 == scheme })
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)

                        Divider().padding(.leading, 14)
                    }
                    
                    HStack {
                        TextField("Enter Scheme (e.g. test-app://)", text: $newURLScheme)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Add") {
                            if !newURLScheme.isEmpty {
                                let cleanScheme = newURLScheme.replacingOccurrences(of: "://", with: "")
                                if !options.customURLSchemes.contains(cleanScheme) {
                                    withAnimation {
                                        options.customURLSchemes.append(cleanScheme)
                                    }
                                }
                                newURLScheme = ""
                            }
                        }
                        .disabled(newURLScheme.isEmpty)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // Localization Section
                modernOptionSection(title: "Localization", icon: "globe.badge.chevron.backward", color: .cyan) {
                    modernOptionToggle(title: "Force Localize", icon: "character.bubble.fill", color: .cyan, isOn: $options.changeLanguageFilesForCustomDisplayName)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // Post Signing Section
                modernOptionSection(title: "Post Signing", icon: "clock.arrow.circlepath", color: .green) {
                    modernOptionToggle(title: "Install After Signing", icon: "arrow.down.app.fill", color: .green, isOn: $options.post_installAppAfterSigned)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "Delete After Signing", icon: "trash.fill", color: .red, isOn: $options.post_deleteAppAfterSigned)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // Experiments Section
                modernOptionSection(title: "Experiments", icon: "flask.fill", color: .purple, isBeta: true) {
                    modernOptionToggle(title: "Replace Substrate", icon: "square.2.layers.3d.bottom.filled", color: .purple, isOn: $options.experiment_replaceSubstrateWithEllekit)
                    Divider().padding(.leading, 52)
                    modernOptionToggle(title: "Enable Liquid Glass", icon: "drop.fill", color: .blue, isOn: $options.experiment_supportLiquidGlass)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .hideScrollContentBackground()
        }
        .navigationTitle("Signing Options")
        .navigationBarTitleDisplayMode(.inline)
        .alert("What is PPQ?", isPresented: $showPPQInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PPQ is a check Apple has added to certificates. If you have this check on the certificate, change your Bundle IDs when signing apps to avoid Apple revoking your certificates.")
        }
        .onAppear {
            if isPPQProtectionForced && !options.ppqProtection {
                options.ppqProtection = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }
    
    // MARK: - Modern Options Background
    @ViewBuilder
    private var modernOptionsBackground: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.1), Color.purple.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? 20 : -20, y: floatingAnimation ? 15 : -15)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Modern Section Builder
    @ViewBuilder
    private func modernOptionSection<Content: View>(title: String, icon: String, color: Color, isBeta: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                if isBeta {
                    Text("Beta")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color))
                }
                
                Spacer()
            }
            .padding(.leading, 4)
            
            VStack(spacing: 2) {
                content()
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Modern Toggle Row
    @ViewBuilder
    private func modernOptionToggle(title: String, subtitle: String? = nil, icon: String, color: Color, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .disabled(disabled)
                .tint(.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    // MARK: - Modern Picker Row
    @ViewBuilder
    private func modernOptionPicker<T: Hashable & LocalizedDescribable>(title: String, icon: String, color: Color, selection: Binding<T>, values: [T]) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value.localizedDescription).tag(value)
                }
            }
            .labelsHidden()
            .tint(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Swipe To Sign Component
struct SwipeToSign: View {
    var onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isCompleted = false
    @State private var isWaiting = true
    @State private var rotation: Double = 0
    @State private var lastHapticOffset: CGFloat = 0

    private let thumbWidth: CGFloat = 60
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        GeometryReader { geo in
            let maxWidth = geo.size.width
            ZStack(alignment: .leading) {
                // Track with waiting animation
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(height: 60)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        ZStack {
                            if isWaiting && !isCompleted && offset == 0 {
                                Capsule()
                                    .stroke(
                                        AngularGradient(
                                            colors: [.clear, Color.accentColor.opacity(0.5), .clear],
                                            center: .center,
                                            angle: .degrees(rotation)
                                        ),
                                        lineWidth: 3
                                    )
                            }

                            Text(isCompleted ? "Signing..." : "Swipe To Sign")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isCompleted ? .primary : .secondary)
                                .opacity(isCompleted ? 1.0 : Double(1 - (offset / (maxWidth - thumbWidth))))
                        }
                    )

                // Thumb
                ZStack {
                    Capsule()
                        .fill(isCompleted ? Color.green : Color.accentColor)
                        .frame(width: thumbWidth + offset, height: 60)
                        .shadow(color: (isCompleted ? Color.green : Color.accentColor).opacity(0.3), radius: 10, x: 0, y: 0)

                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 52, height: 52)
                                .shadow(radius: 2)

                            Image(systemName: isCompleted ? "checkmark" : "chevron.right.2")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(isCompleted ? Color.green : Color.accentColor)
                        }
                        .padding(.trailing, 4)
                    }
                    .frame(width: thumbWidth + offset)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isCompleted {
                                isWaiting = false
                                let dragAmount = value.translation.width
                                if dragAmount > 0 && dragAmount < maxWidth - thumbWidth {
                                    offset = dragAmount

                                    // Increasing haptic feedback
                                    if abs(offset - lastHapticOffset) > (maxWidth / 10) {
                                        hapticGenerator.impactOccurred(intensity: CGFloat(offset / (maxWidth - thumbWidth)))
                                        lastHapticOffset = offset
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            if !isCompleted {
                                if offset > (maxWidth - thumbWidth) * 0.8 {
                                    hapticGenerator.impactOccurred(intensity: 1.0)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        offset = maxWidth - thumbWidth
                                        isCompleted = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onComplete()
                                        // Reset after a delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            withAnimation {
                                                offset = 0
                                                isCompleted = false
                                                isWaiting = true
                                            }
                                        }
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        offset = 0
                                        isWaiting = true
                                    }
                                }
                            }
                        }
                )
            }
        }
        .frame(height: 60)
        .clipShape(Capsule())
        .onAppear {
            hapticGenerator.prepare()
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Sign Button Style
struct SignButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Hold To Sign
struct HoldToSign: View {
    var onComplete: () -> Void
    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var timer: Timer?
    @State private var isCompleted = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
                .frame(height: 60)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )

            // Progress Fill
            GeometryReader { geo in
                Capsule()
                    .fill(isCompleted ? Color.green : Color.accentColor.opacity(0.3))
                    .frame(width: geo.size.width * progress, height: 60)
            }
            .clipShape(Capsule())

            HStack(spacing: 12) {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Text("Signed!")
                        .font(.headline.bold())
                } else {
                    Image(systemName: "hand.tap.fill")
                        .font(.title3.bold())
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(isHolding ? 1.2 : 1.0)
                    Text(isHolding ? "Keep Holding..." : "Hold 5s To Sign")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(height: 60)
        .onLongPressGesture(minimumDuration: 5, maximumDistance: 50) {
            // Triggered when successfully held for 5s
            HapticsManager.shared.success()
            withAnimation(.spring()) {
                progress = 1.0
                isCompleted = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
                // Reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    progress = 0
                    isCompleted = false
                }
            }
        } onPressingChanged: { pressing in
            isHolding = pressing
            if pressing {
                withAnimation(.linear(duration: 5)) {
                    progress = 1.0
                }
            } else {
                if !isCompleted {
                    withAnimation(.easeOut(duration: 0.3)) {
                        progress = 0
                    }
                }
            }
        }
    }
}

// MARK: - Slide To Confirm
struct SlideToConfirm: View {
    var onComplete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var isCompleted = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(height: 60)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                Text("Slide To Confirm")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                // Track fill
                Capsule()
                    .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: offset + 60, height: 60)

                // Handle
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 52, height: 52)
                        .shadow(radius: 2)

                    Image(systemName: isCompleted ? "checkmark" : "arrow.right")
                        .font(.title3.bold())
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.leading, 4)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isCompleted {
                                let drag = value.translation.width
                                if drag >= 0 && drag <= width - 60 {
                                    offset = drag
                                }
                            }
                        }
                        .onEnded { value in
                            if !isCompleted {
                                if offset > width * 0.7 {
                                    withAnimation(.spring()) {
                                        offset = width - 60
                                        isCompleted = true
                                    }
                                    HapticsManager.shared.success()
                                    onComplete()

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            offset = 0
                                            isCompleted = false
                                        }
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        offset = 0
                                    }
                                }
                            }
                        }
                )
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Double Tap To Sign
struct DoubleTapToSign: View {
    var onComplete: () -> Void
    @State private var isAnimate = false
    @State private var isCompleted = false

    var body: some View {
        Button {
            // This button handles the taps via gesture below
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: isCompleted ? "checkmark" : "hand.tap.fill")
                        .font(.title3.bold())
                        .foregroundStyle(isCompleted ? .green : .accentColor)
                        .scaleEffect(isAnimate ? 1.2 : 1.0)
                }

                Text(isCompleted ? "Signing..." : "Double Tap To Sign")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isCompleted ? Color.green.opacity(0.3) : Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    if !isCompleted {
                        HapticsManager.shared.success()
                        withAnimation(.spring()) {
                            isCompleted = true
                            isAnimate = true
                        }
                        onComplete()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCompleted = false
                            isAnimate = false
                        }
                    }
                }
        )
    }
}


// MARK: - Advanced Debug Tools View
struct ModernEditSheet: View {
    let title: String
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var iconScale: CGFloat = 1.0
    @State private var contentOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 20
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.clear,
                        iconColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        // Modern animated icon with glow effect
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [iconColor.opacity(0.3), iconColor.opacity(0.1), .clear],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .scaleEffect(iconScale)

                            // Icon background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [iconColor.opacity(0.25), iconColor.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .shadow(color: iconColor.opacity(0.4), radius: 10, x: 0, y: 4)

                            // Icon
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [iconColor, iconColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolRenderingMode(.hierarchical)
                        }
                        .scaleEffect(iconScale)
                        
                        // Title section
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Enter New \(title)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)

                    // Modern text field with enhanced design
                    VStack(alignment: .leading, spacing: 6) {
                        TextField(placeholder, text: $value)
                            .font(.system(size: 16, weight: .medium))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(keyboardType)
                            .focused($isFocused)
                            .padding(14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                    
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: isFocused ? [iconColor.opacity(0.05), .clear] : [.clear, .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: isFocused ? [iconColor.opacity(0.6), iconColor.opacity(0.3)] : [Color.clear, Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isFocused ? 2 : 0
                                    )
                            )
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)
                    
                    // Modern action buttons with enhanced design
                    HStack(spacing: 12) {
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onSave()
                        } label: {
                            Text("Save")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [iconColor, iconColor.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .offset(y: buttonsOffset)
                    .opacity(contentOpacity)
                    
                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Smooth entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                contentOpacity = 1.0
                buttonsOffset = 0
            }
            
            withAnimation(.easeIn(duration: 0.8)) {
                iconScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    iconScale = 1.05
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }
}
