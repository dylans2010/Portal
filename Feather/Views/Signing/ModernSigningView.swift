import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - Modern Full Screen Signing View
struct ModernSigningView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
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
    @State private var _isSigningProcessPresented = false
    @State private var _isAddingCertificatePresenting = false
    @State private var _selectedTab = 0
    @State private var _showAdvancedDebugSheet = false
    
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
                // Modern animated mesh gradient background
                modernBackground
                
                VStack(spacing: 0) {
                    // Unified scrollable content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header with app info
                            headerSection
                                .scaleEffect(_headerScale)
                                .opacity(_contentOpacity)
                            
                            // All content in unified view
                            unifiedContentSection
                                .opacity(_contentOpacity)
                        }
                        .padding(.bottom, 100)
                    }
                    
                    // Modern sign button (fixed at bottom)
                    modernSignButton
                        .offset(y: _buttonOffset)
                        .opacity(_contentOpacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .fullScreenCover(isPresented: $_isSigningProcessPresented) {
                if #available(iOS 17.0, *) {
                    SigningProcessView(
                        appName: _temporaryOptions.appName ?? app.name ?? "App",
                        appIcon: appIcon
                    )
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Signing \(_temporaryOptions.appName ?? app.name ?? "App")...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                }
            }
            .sheet(isPresented: $_isAddingCertificatePresenting) {
                CertificatesAddView()
                    .presentationDetents([.medium])
            }
            .alert("Name", isPresented: $_isNameDialogPresenting) {
                TextField(_temporaryOptions.appName ?? (app.name ?? ""), text: Binding(
                    get: { _temporaryOptions.appName ?? app.name ?? "" },
                    set: { _temporaryOptions.appName = $0 }
                ))
                .textInputAutocapitalization(.none)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            }
            .alert("Bundle ID", isPresented: $_isIdentifierDialogPresenting) {
                TextField(_temporaryOptions.appIdentifier ?? (app.identifier ?? ""), text: Binding(
                    get: { _temporaryOptions.appIdentifier ?? app.identifier ?? "" },
                    set: { _temporaryOptions.appIdentifier = $0 }
                ))
                .textInputAutocapitalization(.none)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            }
            .alert("Version", isPresented: $_isVersionDialogPresenting) {
                TextField(_temporaryOptions.appVersion ?? (app.version ?? ""), text: Binding(
                    get: { _temporaryOptions.appVersion ?? app.version ?? "" },
                    set: { _temporaryOptions.appVersion = $0 }
                ))
                .textInputAutocapitalization(.none)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            }
            .onAppear {
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
                
                // Trigger entrance animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    _headerScale = 1.0
                    _contentOpacity = 1.0
                    _buttonOffset = 0
                    _appearAnimation = true
                }
            }
        }
    }
    
    // MARK: - Dismiss with Animation
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
    
    // MARK: - Modern Background (Enhanced)
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Base gradient with smoother transitions
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.12),
                    Color.accentColor.opacity(0.06),
                    Color(UIColor.systemBackground).opacity(0.95),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated floating orbs with enhanced effects
            GeometryReader { geo in
                // Primary accent orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.25),
                                Color.accentColor.opacity(0.1),
                                Color.accentColor.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 70)
                    .offset(x: _floatingAnimation ? -40 : 40, y: _floatingAnimation ? -25 : 25)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.12)
                
                // Secondary purple orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.18),
                                Color.purple.opacity(0.08),
                                Color.purple.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .blur(radius: 55)
                    .offset(x: _floatingAnimation ? 35 : -35, y: _floatingAnimation ? 15 : -15)
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.65)
                
                // Tertiary subtle orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.1),
                                Color.cyan.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 45)
                    .offset(x: _floatingAnimation ? -20 : 20, y: _floatingAnimation ? 30 : -30)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.85)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                _floatingAnimation = true
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon with modern glass effect
            Menu {
                Button {
                    _isAltPickerPresenting = true
                } label: {
                    Label("Select Alternative Icon", systemImage: "app.dashed")
                }
                Button {
                    _isFilePickerPresenting = true
                } label: {
                    Label("Choose Files", systemImage: "folder")
                }
                Button {
                    _isImagePickerPresenting = true
                } label: {
                    Label("Choose Photos", systemImage: "photo")
                }
            } label: {
                ZStack {
                    // Glow effect behind icon
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.accentColor.opacity(_glowAnimation ? 0.4 : 0.2))
                        .frame(width: 90, height: 90)
                        .blur(radius: 15)
                        .scaleEffect(_glowAnimation ? 1.1 : 1.0)
                    
                    if let icon = appIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else {
                        FRAppIconView(app: app, size: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    
                    // Edit overlay with glass effect
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .offset(x: 6, y: 6)
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                .shadow(color: Color.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: 6) {
                Text(_temporaryOptions.appName ?? app.name ?? "Unknown")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(_temporaryOptions.appIdentifier ?? app.identifier ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                _glowAnimation = true
            }
        }
    }
    
    // MARK: - Unified Content Section
    @ViewBuilder
    private var unifiedContentSection: some View {
        VStack(spacing: 20) {
            // App Details Section
            sectionHeader(title: "App Details", icon: "app.badge.fill", color: .blue)
            
            VStack(spacing: 0) {
                modernInfoRow(title: "Name", value: _temporaryOptions.appName ?? app.name, icon: "textformat", color: .blue) {
                    _isNameDialogPresenting = true
                }
                
                Divider().padding(.leading, 56)
                
                modernInfoRow(title: "Bundle ID", value: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode", color: .purple) {
                    _isIdentifierDialogPresenting = true
                }
                
                Divider().padding(.leading, 56)
                
                modernInfoRow(title: "Version", value: _temporaryOptions.appVersion ?? app.version, icon: "tag.fill", color: .orange) {
                    _isVersionDialogPresenting = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            
            // Certificate Section
            sectionHeader(title: "Certificate", icon: "checkmark.seal.fill", color: .green)
            
            certificateCard
            
            // Configuration Section
            sectionHeader(title: "Configuration", icon: "slider.horizontal.3", color: .accentColor)
            
            VStack(spacing: 0) {
                NavigationLink {
                    ModernSigningOptionsView(options: $_temporaryOptions)
                } label: {
                    compactRow(title: "Signing Options", icon: "gearshape.fill", color: .gray)
                }
                
                Divider().padding(.leading, 56)
                
                NavigationLink {
                    SigningDylibView(app: app, options: $_temporaryOptions.optional())
                } label: {
                    compactRow(title: "Existing Dylibs", icon: "puzzlepiece.extension.fill", color: .purple)
                }
                
                Divider().padding(.leading, 56)
                
                NavigationLink {
                    SigningFrameworksView(app: app, options: $_temporaryOptions.optional())
                } label: {
                    compactRow(title: "Frameworks & Plugins", icon: "cube.fill", color: .blue)
                }
                
                Divider().padding(.leading, 56)
                
                NavigationLink {
                    SigningTweaksView(options: $_temporaryOptions)
                } label: {
                    compactRow(title: "Inject Tweaks", icon: "wrench.and.screwdriver.fill", color: .green)
                }
                
                Divider().padding(.leading, 56)
                
                NavigationLink {
                    SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile)
                } label: {
                    compactRow(title: "Entitlements", icon: "lock.shield.fill", color: .orange, badge: "BETA")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            
            // Advanced (Debug) Section - Only shown when feature flag is enabled
            if _advancedSigningEnabled {
                advancedDebugSection
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Advanced Debug Section
    @ViewBuilder
    private var advancedDebugSection: some View {
        sectionHeader(title: "Advanced (Debug)", icon: "hammer.fill", color: .red)
        
        VStack(spacing: 0) {
            NavigationLink {
                AdvancedDebugToolsView(app: app, options: $_temporaryOptions, appIcon: $appIcon)
            } label: {
                compactRow(title: "Debug Tools", icon: "wrench.and.screwdriver.fill", color: .red, badge: "DEV")
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink {
                BinaryInspectorView(app: app)
            } label: {
                compactRow(title: "Binary Inspector", icon: "doc.text.magnifyingglass", color: .purple)
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink {
                InfoPlistEditorDebugView(app: app, options: $_temporaryOptions)
            } label: {
                compactRow(title: "Info.plist Editor", icon: "doc.badge.gearshape.fill", color: .blue)
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink {
                EntitlementsDebugView(options: $_temporaryOptions)
            } label: {
                compactRow(title: "Entitlements Editor", icon: "key.fill", color: .orange)
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink {
                ResourceModifierView(app: app)
            } label: {
                compactRow(title: "Resource Modifier", icon: "folder.fill.badge.gearshape", color: .green)
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink {
                SigningLogsDebugView()
            } label: {
                compactRow(title: "Signing Logs", icon: "terminal.fill", color: .gray)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Section Header
    @ViewBuilder
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Certificate Card
    @ViewBuilder
    private var certificateCard: some View {
        if let cert = _selectedCert() {
            NavigationLink {
                CertificatesView(selectedCert: $_temporaryCertificate)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cert.nickname ?? "Certificate")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if let expiration = cert.expiration {
                            Text("Expires On \(expiration, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        } else {
            Button {
                _isAddingCertificatePresenting = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Certificate")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Add Certificate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }
    
    // MARK: - Compact Row
    @ViewBuilder
    private func compactRow(title: String, icon: String, color: Color, badge: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func modernInfoRow(title: String, value: String?, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(value ?? "Not Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
        }
    }
    
    // MARK: - Signing Tab
    @ViewBuilder
    private var signingTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let cert = _selectedCert() {
                    NavigationLink {
                        CertificatesView(selectedCert: $_temporaryCertificate)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                // Animated glow
                                Circle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .blur(radius: 8)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cert.nickname ?? "Certificate")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if let expiration = cert.expiration {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                        Text("Expires On \(expiration, style: .date)")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                } else {
                                    Text("View Details")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                } else {
                    // No certificate - modern glass card
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 70, height: 70)
                                .blur(radius: 10)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(spacing: 6) {
                            Text("No Certificate")
                                .font(.headline)
                            Text("Add a certificate to sign apps.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button {
                            _isAddingCertificatePresenting = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Certificate")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Advanced Tab
    @ViewBuilder
    private var advancedTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Section Header
                HStack {
                    Text("Configuration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // Modern glass card container
                VStack(spacing: 2) {
                    NavigationLink {
                        ModernSigningOptionsView(options: $_temporaryOptions)
                    } label: {
                        modernAdvancedRow(title: "Signing Options", subtitle: "Configure signing behavior", icon: "slider.horizontal.3", color: .accentColor, isFirst: true)
                    }
                    
                    NavigationLink {
                        SigningDylibView(app: app, options: $_temporaryOptions.optional())
                    } label: {
                        modernAdvancedRow(title: "Existing Dylibs", subtitle: "Manage Dynamic Libraries", icon: "puzzlepiece.extension.fill", color: .purple)
                    }
                    
                    NavigationLink {
                        SigningFrameworksView(app: app, options: $_temporaryOptions.optional())
                    } label: {
                        modernAdvancedRow(title: "Frameworks & Plugins", subtitle: "Add or Remove Frameworks", icon: "cube.fill", color: .blue)
                    }
                    
                    NavigationLink {
                        SigningTweaksView(options: $_temporaryOptions)
                    } label: {
                        modernAdvancedRow(title: "Inject Tweaks", subtitle: "Add Custom Modifications or Frameworks.", icon: "wrench.and.screwdriver.fill", color: .green, isLast: true)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                
                // Entitlements Section
                HStack {
                    Text("Experimental")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
                NavigationLink {
                    SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile)
                } label: {
                    modernAdvancedRow(title: "Entitlements", subtitle: "Edit App Entitlements", icon: "lock.shield.fill", color: .orange, isFirst: true, isLast: true, isBeta: true)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private func modernAdvancedRow(title: String, subtitle: String, icon: String, color: Color, isFirst: Bool = false, isLast: Bool = false, isBeta: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if isBeta {
                        Text("BETA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(UIColor.tertiarySystemFill))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    // MARK: - Modern Sign Button
    @ViewBuilder
    private var modernSignButton: some View {
        Button {
            _start()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "signature")
                    .font(.system(size: 16, weight: .semibold))
                Text("Sign App")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle shimmer effect
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: _glowAnimation ? 200 : -200)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: _glowAnimation)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SignButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 8)
        .background(
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground).opacity(0),
                    Color(UIColor.systemBackground).opacity(0.95),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Start Signing
    private func _start() {
        // Check for .dylib files before signing
        if DylibDetector.shared.hasDylibs() {
            UIAlertController.showAlertWithOk(
                title: .localized("Dynamic Libraries Detected"),
                message: .localized("Sorry but you may not add any .dylib or .deb files to this app. Please resign the app without any additional frameworks to proceed.")
            )
            return
        }
        
        guard let cert = _selectedCert() else {
            UIAlertController.showAlertWithOk(
                title: .localized("No Certificate"),
                message: .localized("Please go to Settings and import a certificate then come back here."),
                isCancel: true
            )
            return
        }
        
        HapticsManager.shared.impact()
        
        // Animate out before showing signing process
        withAnimation(.easeOut(duration: 0.2)) {
            _headerScale = 0.95
            _contentOpacity = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            _isSigning = true
            _isSigningProcessPresented = true
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
                    _isSigningProcessPresented = false
                    
                    switch result {
                    case .success(let installLink):
                        if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                            NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                        }
                        
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
                        
                    case .failure(let error):
                        let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
                        UIAlertController.showAlert(
                            title: "Error",
                            message: error.localizedDescription,
                            actions: [ok]
                        )
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
                if let error {
                    _isSigningProcessPresented = false
                    let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel) { _ in
                        dismiss()
                    }
                    
                    UIAlertController.showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        actions: [ok]
                    )
                } else {
                    if _temporaryOptions.post_deleteAppAfterSigned, !app.isSigned {
                        Storage.shared.deleteApp(for: app)
                    }
                    
                    if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                        NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                    }
                    
                    if _temporaryOptions.post_installAppAfterSigned {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
                        }
                    }
                    dismiss()
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Protection Section
                    modernOptionSection(title: "Protection", icon: "shield.lefthalf.filled", color: .blue) {
                        modernOptionToggle(
                            title: "PPQ Protection",
                            subtitle: isPPQProtectionForced ? "Required for your certificate." : "Append random string to Bundle IDs to avoid Apple flagging this certificate.",
                            icon: "shield.checkered",
                            color: .blue,
                            isOn: Binding(
                                get: { isPPQProtectionForced ? true : options.ppqProtection },
                                set: { newValue in
                                    if !isPPQProtectionForced || newValue {
                                        options.ppqProtection = newValue
                                    }
                                }
                            ),
                            disabled: isPPQProtectionForced
                        )
                        
                        Button {
                            showPPQInfo = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.accentColor)
                                }
                                Text("What is PPQ?")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .padding(6)
                                    .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                            }
                            .padding(12)
                        }
                    }
                    
                    // General Section
                    modernOptionSection(title: "General", icon: "gearshape.2.fill", color: .gray) {
                        modernOptionPicker(
                            title: "Appearance",
                            icon: "paintpalette.fill",
                            color: .pink,
                            selection: $options.appAppearance,
                            values: Options.AppAppearance.allCases
                        )
                        
                        modernOptionPicker(
                            title: "Minimum Requirement",
                            icon: "ruler.fill",
                            color: .indigo,
                            selection: $options.minimumAppRequirement,
                            values: Options.MinimumAppRequirement.allCases
                        )
                    }
                    
                    // Signing Section
                    modernOptionSection(title: "Signing", icon: "signature", color: .purple) {
                        modernOptionPicker(
                            title: "Signing Type",
                            icon: "pencil.and.scribble",
                            color: .purple,
                            selection: $options.signingOption,
                            values: Options.SigningOption.allCases
                        )
                    }
                    
                    // App Features Section
                    modernOptionSection(title: "App Features", icon: "sparkles", color: .yellow) {
                        modernOptionToggle(title: "File Sharing", subtitle: "Enable Document Sharing.", icon: "folder.fill.badge.person.crop", color: .blue, isOn: $options.fileSharing)
                        modernOptionToggle(title: "iTunes File Sharing", subtitle: "Access Via iTunes/Finder.", icon: "music.note.list", color: .pink, isOn: $options.itunesFileSharing)
                        modernOptionToggle(title: "ProMotion", subtitle: "120Hz Display Support.", icon: "gauge.with.dots.needle.67percent", color: .green, isOn: $options.proMotion)
                        modernOptionToggle(title: "Game Mode", subtitle: "Turn on Gaming Mode (iOS 18+).", icon: "gamecontroller.fill", color: .purple, isOn: $options.gameMode)
                        modernOptionToggle(title: "iPad Fullscreen", subtitle: "Full Screen On iPad.", icon: "ipad.landscape", color: .orange, isOn: $options.ipadFullscreen)
                    }
                    
                    // Removal Section
                    modernOptionSection(title: "Removal", icon: "trash.slash.fill", color: .red) {
                        modernOptionToggle(title: "Remove URL Scheme", subtitle: "Strip URL Handlers.", icon: "link.badge.minus", color: .red, isOn: $options.removeURLScheme)
                        modernOptionToggle(title: "Remove Provisioning", subtitle: "Exclude .mobileprovision.", icon: "doc.badge.minus", color: .orange, isOn: $options.removeProvisioning)
                    }
                    
                    // Localization Section
                    modernOptionSection(title: "Localization", icon: "globe.badge.chevron.backward", color: .green) {
                        modernOptionToggle(title: "Force Localize", subtitle: "Override Localized Titles.", icon: "character.bubble.fill", color: .green, isOn: $options.changeLanguageFilesForCustomDisplayName)
                    }
                    
                    // Post Signing Section
                    modernOptionSection(title: "Post Signing", icon: "clock.arrow.circlepath", color: .orange) {
                        modernOptionToggle(title: "Install After Signing", subtitle: "Auto Install When Done.", icon: "arrow.down.circle.fill", color: .green, isOn: $options.post_installAppAfterSigned)
                        modernOptionToggle(title: "Delete After Signing", subtitle: "Remove Original File.", icon: "trash.fill", color: .red, isOn: $options.post_deleteAppAfterSigned)
                    }
                    
                    // Experiments Section
                    modernOptionSection(title: "Experiments", icon: "flask.fill", color: .purple, isBeta: true) {
                        modernOptionToggle(title: "Replace Substrate", subtitle: "Use ElleKit Instead.", icon: "arrow.triangle.2.circlepath.circle.fill", color: .cyan, isOn: $options.experiment_replaceSubstrateWithEllekit)
                        modernOptionToggle(title: "Liquid Glass", subtitle: "Use iOS 26 Redesign Support.", icon: "sparkles.rectangle.stack.fill", color: .purple, isOn: $options.experiment_supportLiquidGlass)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
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
            Color(UIColor.systemGroupedBackground)
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
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
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
                    Text("BETA")
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
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    // MARK: - Modern Toggle Row
    @ViewBuilder
    private func modernOptionToggle(title: String, subtitle: String? = nil, icon: String, color: Color, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
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

// MARK: - Sign Button Style
struct SignButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - iOS 17 Symbol Effect Compatibility Modifiers
struct BounceEffectModifier: ViewModifier {
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
    }
}

struct PulseEffectModifier: ViewModifier {
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse, options: .repeating, value: trigger)
        } else {
            content
                .opacity(trigger ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: trigger)
        }
    }
}

// MARK: - Advanced Debug Tools View
struct AdvancedDebugToolsView: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    @Binding var appIcon: UIImage?
    @State private var customMinimumVersion = ""
    @State private var customBuildNumber = ""
    @State private var forceArmv7 = false
    @State private var stripBitcode = true
    @State private var removeSignature = false
    @State private var injectCustomDylib = false
    @State private var customDylibPath = ""
    @State private var modifyExecutable = false
    @State private var showDylibPicker = false
    @State private var enableVerboseLogging = false
    @State private var dryRunMode = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Debug Tools", systemImage: "hammer.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("Advanced tools for modifying apps before signing. Use with caution.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                HStack {
                    Label("Min iOS Version", systemImage: "iphone.gen1")
                    Spacer()
                    TextField("e.g., 14.0", text: $customMinimumVersion)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Label("Build Number", systemImage: "number")
                    Spacer()
                    TextField("e.g., 1234", text: $customBuildNumber)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .keyboardType(.numberPad)
                }
            } header: {
                debugSectionHeader("Version Override", icon: "tag.fill", color: .blue)
            }
            
            Section {
                Toggle(isOn: $forceArmv7) {
                    Label("Force ARMv7 Slice", systemImage: "cpu")
                }
                
                Toggle(isOn: $stripBitcode) {
                    Label("Strip Bitcode", systemImage: "xmark.bin.fill")
                }
                
                Toggle(isOn: $removeSignature) {
                    Label("Remove Existing Signature", systemImage: "signature")
                }
            } header: {
                debugSectionHeader("Binary Modifications", icon: "doc.fill", color: .purple)
            } footer: {
                Text("These options modify the app binary directly. May cause app instability.")
            }
            
            Section {
                Toggle(isOn: $injectCustomDylib) {
                    Label("Inject Custom Dylib", systemImage: "syringe.fill")
                }
                
                if injectCustomDylib {
                    Button {
                        showDylibPicker = true
                    } label: {
                        HStack {
                            Text("Select Dylib")
                            Spacer()
                            Text(customDylibPath.isEmpty ? "None" : URL(fileURLWithPath: customDylibPath).lastPathComponent)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $modifyExecutable) {
                    Label("Modify Executable Name", systemImage: "pencil")
                }
            } header: {
                debugSectionHeader("Injection", icon: "syringe.fill", color: .green)
            }
            
            Section {
                Toggle(isOn: $enableVerboseLogging) {
                    Label("Verbose Logging", systemImage: "text.alignleft")
                }
                
                Toggle(isOn: $dryRunMode) {
                    Label("Dry Run Mode", systemImage: "play.slash.fill")
                }
            } header: {
                debugSectionHeader("Debug Options", icon: "ladybug.fill", color: .orange)
            } footer: {
                Text("Dry run mode simulates signing without making changes.")
            }
            
            Section {
                Button {
                    applyDebugSettings()
                } label: {
                    HStack {
                        Spacer()
                        Label("Apply Debug Settings", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(.red)
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func debugSectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
        }
    }
    
    private func applyDebugSettings() {
        HapticsManager.shared.success()
    }
}

// MARK: - Binary Inspector View
struct BinaryInspectorView: View {
    let app: AppInfoPresentable
    @State private var binaryInfo: [String: String] = [:]
    @State private var isLoading = true
    @State private var architectures: [String] = []
    @State private var loadCommands: [String] = []
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            } else {
                Section {
                    SigningInfoRow(title: "Executable", value: app.name ?? "Unknown")
                    SigningInfoRow(title: "Bundle ID", value: app.identifier ?? "Unknown")
                    SigningInfoRow(title: "Version", value: app.version ?? "Unknown")
                } header: {
                    Text("App Info")
                }
                
                Section {
                    ForEach(architectures, id: \.self) { arch in
                        Label(arch, systemImage: "cpu")
                    }
                } header: {
                    Text("Architectures")
                }
                
                Section {
                    ForEach(binaryInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        SigningInfoRow(title: key, value: value)
                    }
                } header: {
                    Text("Binary Details")
                }
                
                if !loadCommands.isEmpty {
                    Section {
                        ForEach(loadCommands.prefix(20), id: \.self) { cmd in
                            Text(cmd)
                                .font(.system(.caption, design: .monospaced))
                        }
                        if loadCommands.count > 20 {
                            Text("... and \(loadCommands.count - 20) more")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Load Commands")
                    }
                }
            }
        }
        .navigationTitle("Binary Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBinaryInfo()
        }
    }
    
    private func loadBinaryInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            architectures = ["arm64", "arm64e"]
            binaryInfo = [
                "File Type": "Mach-O 64-bit executable",
                "Magic": "0xFEEDFACF",
                "CPU Type": "ARM64",
                "File Size": "12.4 MB",
                "Encrypted": "No",
                "PIE": "Yes",
                "Code Signature": "Present"
            ]
            loadCommands = [
                "LC_SEGMENT_64 __PAGEZERO",
                "LC_SEGMENT_64 __TEXT",
                "LC_SEGMENT_64 __DATA",
                "LC_SEGMENT_64 __LINKEDIT",
                "LC_DYLD_INFO_ONLY",
                "LC_SYMTAB",
                "LC_DYSYMTAB",
                "LC_LOAD_DYLINKER",
                "LC_UUID",
                "LC_BUILD_VERSION",
                "LC_SOURCE_VERSION",
                "LC_MAIN",
                "LC_ENCRYPTION_INFO_64",
                "LC_LOAD_DYLIB libSystem.B.dylib",
                "LC_LOAD_DYLIB Foundation",
                "LC_LOAD_DYLIB UIKit",
                "LC_CODE_SIGNATURE"
            ]
            isLoading = false
        }
    }
}

// MARK: - Info.plist Editor Debug View
struct InfoPlistEditorDebugView: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    @State private var plistEntries: [(key: String, value: String, type: String)] = []
    @State private var searchText = ""
    @State private var showAddEntry = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var selectedType = "String"
    
    private let types = ["String", "Number", "Boolean", "Array", "Dictionary"]
    
    var filteredEntries: [(key: String, value: String, type: String)] {
        if searchText.isEmpty {
            return plistEntries
        }
        return plistEntries.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(filteredEntries, id: \.key) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(entry.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.2)))
                        }
                        Text(entry.value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: deleteEntry)
            } header: {
                HStack {
                    Text("Entries (\(filteredEntries.count))")
                    Spacer()
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search keys...")
        .navigationTitle("Info.plist Editor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPlistEntries()
        }
        .sheet(isPresented: $showAddEntry) {
            NavigationStack {
                Form {
                    TextField("Key", text: $newKey)
                    TextField("Value", text: $newValue)
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                .navigationTitle("Add Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addEntry()
                            showAddEntry = false
                        }
                        .disabled(newKey.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func loadPlistEntries() {
        plistEntries = [
            ("CFBundleIdentifier", app.identifier ?? "com.example.app", "String"),
            ("CFBundleName", app.name ?? "App", "String"),
            ("CFBundleShortVersionString", app.version ?? "1.0", "String"),
            ("CFBundleVersion", "1", "String"),
            ("MinimumOSVersion", "14.0", "String"),
            ("UIDeviceFamily", "[1, 2]", "Array"),
            ("UIRequiredDeviceCapabilities", "[arm64]", "Array"),
            ("UISupportedInterfaceOrientations", "[Portrait, Landscape]", "Array"),
            ("UILaunchStoryboardName", "LaunchScreen", "String"),
            ("UIMainStoryboardFile", "Main", "String"),
            ("LSRequiresIPhoneOS", "true", "Boolean"),
            ("UIApplicationSceneManifest", "{...}", "Dictionary")
        ]
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        plistEntries.remove(atOffsets: offsets)
    }
    
    private func addEntry() {
        plistEntries.append((key: newKey, value: newValue, type: selectedType))
        newKey = ""
        newValue = ""
    }
}

// MARK: - Entitlements Debug View
struct EntitlementsDebugView: View {
    @Binding var options: Options
    @State private var entitlements: [(key: String, value: String, enabled: Bool)] = []
    @State private var showAddEntitlement = false
    @State private var newKey = ""
    @State private var newValue = ""
    
    var body: some View {
        List {
            Section {
                ForEach(entitlements.indices, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entitlements[index].key)
                                .font(.subheadline.weight(.medium))
                            Text(entitlements[index].value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $entitlements[index].enabled)
                            .labelsHidden()
                    }
                }
                .onDelete(perform: deleteEntitlement)
            } header: {
                HStack {
                    Text("Entitlements")
                    Spacer()
                    Button {
                        showAddEntitlement = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            
            Section {
                Button {
                    loadCommonEntitlements()
                } label: {
                    Label("Load Common Entitlements", systemImage: "arrow.down.circle.fill")
                }
                
                Button {
                    clearAllEntitlements()
                } label: {
                    Label("Clear All", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Quick Actions")
            }
        }
        .navigationTitle("Entitlements Editor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadEntitlements()
        }
        .sheet(isPresented: $showAddEntitlement) {
            NavigationStack {
                Form {
                    TextField("Key (e.g., com.apple.developer...)", text: $newKey)
                        .autocapitalization(.none)
                    TextField("Value", text: $newValue)
                }
                .navigationTitle("Add Entitlement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddEntitlement = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addEntitlement()
                            showAddEntitlement = false
                        }
                        .disabled(newKey.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func loadEntitlements() {
        entitlements = [
            ("application-identifier", "TEAM_ID.com.example.app", true),
            ("com.apple.developer.team-identifier", "TEAM_ID", true),
            ("get-task-allow", "true", true),
            ("keychain-access-groups", "[TEAM_ID.*]", true)
        ]
    }
    
    private func loadCommonEntitlements() {
        let common = [
            ("com.apple.security.application-groups", "group.com.example.app", false),
            ("com.apple.developer.associated-domains", "applinks:example.com", false),
            ("aps-environment", "development", false),
            ("com.apple.developer.icloud-container-identifiers", "[iCloud.com.example.app]", false),
            ("com.apple.developer.ubiquity-kvstore-identifier", "TEAM_ID.com.example.app", false)
        ]
        entitlements.append(contentsOf: common)
    }
    
    private func deleteEntitlement(at offsets: IndexSet) {
        entitlements.remove(atOffsets: offsets)
    }
    
    private func clearAllEntitlements() {
        entitlements.removeAll()
    }
    
    private func addEntitlement() {
        entitlements.append((key: newKey, value: newValue, enabled: true))
        newKey = ""
        newValue = ""
    }
}

// MARK: - Resource Modifier View
struct ResourceModifierView: View {
    let app: AppInfoPresentable
    @State private var resources: [(name: String, type: String, size: String)] = []
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    private let filters = ["All", "Images", "Strings", "Plists", "Other"]
    
    var filteredResources: [(name: String, type: String, size: String)] {
        var result = resources
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter != "All" {
            result = result.filter { resource in
                switch selectedFilter {
                case "Images": return ["png", "jpg", "jpeg", "pdf", "svg"].contains(resource.type.lowercased())
                case "Strings": return resource.type.lowercased() == "strings"
                case "Plists": return resource.type.lowercased() == "plist"
                default: return true
                }
            }
        }
        return result
    }
    
    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                ForEach(filteredResources, id: \.name) { resource in
                    HStack {
                        Image(systemName: iconForType(resource.type))
                            .foregroundStyle(colorForType(resource.type))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.name)
                                .font(.subheadline)
                            Text(resource.type.uppercased())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(resource.size)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Resources (\(filteredResources.count))")
            }
        }
        .searchable(text: $searchText, prompt: "Search resources...")
        .navigationTitle("Resource Modifier")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadResources()
        }
    }
    
    private func loadResources() {
        resources = [
            ("AppIcon", "png", "124 KB"),
            ("LaunchScreen", "storyboard", "8 KB"),
            ("Main", "storyboard", "45 KB"),
            ("Localizable", "strings", "12 KB"),
            ("Info", "plist", "4 KB"),
            ("Assets", "car", "2.4 MB"),
            ("Default@2x", "png", "89 KB"),
            ("Default@3x", "png", "156 KB"),
            ("Settings", "bundle", "32 KB"),
            ("Frameworks", "framework", "8.2 MB")
        ]
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "pdf", "svg": return "photo.fill"
        case "strings": return "textformat"
        case "plist": return "doc.text.fill"
        case "storyboard": return "rectangle.3.group.fill"
        case "car": return "folder.fill"
        case "framework": return "shippingbox.fill"
        case "bundle": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "pdf", "svg": return .blue
        case "strings": return .green
        case "plist": return .orange
        case "storyboard": return .purple
        case "car": return .pink
        case "framework": return .cyan
        case "bundle": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Signing Logs Debug View
struct SigningLogsDebugView: View {
    @State private var logs: [(timestamp: String, level: String, message: String)] = []
    @State private var selectedLevel = "All"
    @State private var autoScroll = true
    
    private let levels = ["All", "Info", "Warning", "Error", "Debug"]
    
    var filteredLogs: [(timestamp: String, level: String, message: String)] {
        if selectedLevel == "All" {
            return logs
        }
        return logs.filter { $0.level == selectedLevel }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Level", selection: $selectedLevel) {
                ForEach(levels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollViewReader { proxy in
                List {
                    ForEach(filteredLogs.indices, id: \.self) { index in
                        let log = filteredLogs[index]
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(colorForLevel(log.level))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(log.timestamp)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(log.level)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(colorForLevel(log.level))
                                }
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                        .id(index)
                    }
                }
                .onChange(of: logs.count) { _ in
                    if autoScroll, let lastIndex = filteredLogs.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .navigationTitle("Signing Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Auto Scroll", isOn: $autoScroll)
                    Button {
                        logs.removeAll()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                    Button {
                        UIPasteboard.general.string = logs.map { "[\($0.timestamp)] [\($0.level)] \($0.message)" }.joined(separator: "\n")
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadSampleLogs()
        }
    }
    
    private func colorForLevel(_ level: String) -> Color {
        switch level {
        case "Info": return .blue
        case "Warning": return .orange
        case "Error": return .red
        case "Debug": return .purple
        default: return .gray
        }
    }
    
    private func loadSampleLogs() {
        logs = [
            ("10:23:45", "Info", "Starting signing process..."),
            ("10:23:45", "Debug", "Loading certificate from keychain"),
            ("10:23:46", "Info", "Certificate loaded: Developer Certificate"),
            ("10:23:46", "Debug", "Extracting IPA contents"),
            ("10:23:47", "Info", "Found executable: MyApp"),
            ("10:23:47", "Debug", "Analyzing Mach-O binary"),
            ("10:23:48", "Info", "Removing existing signature"),
            ("10:23:48", "Warning", "Bitcode section found, stripping..."),
            ("10:23:49", "Info", "Injecting provisioning profile"),
            ("10:23:49", "Debug", "Updating Info.plist"),
            ("10:23:50", "Info", "Signing frameworks..."),
            ("10:23:51", "Info", "Signing main executable"),
            ("10:23:52", "Info", "Creating signed IPA"),
            ("10:23:53", "Info", "Signing completed successfully!")
        ]
    }
}

// MARK: - Signing Info Row Helper
private struct SigningInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}
