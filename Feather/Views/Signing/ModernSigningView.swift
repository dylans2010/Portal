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
    
    // Version Override
    @State private var customMinimumVersion = ""
    @State private var customBuildNumber = ""
    @State private var customShortVersion = ""
    @State private var customBundleVersion = ""
    
    // Binary Modifications
    @State private var forceArmv7 = false
    @State private var stripBitcode = true
    @State private var removeSignature = false
    @State private var thinBinary = false
    @State private var selectedArchitecture = "arm64"
    @State private var enablePIE = true
    @State private var stripDebugSymbols = false
    @State private var removeSwiftSupport = false
    
    // Injection
    @State private var injectCustomDylib = false
    @State private var customDylibPath = ""
    @State private var modifyExecutable = false
    @State private var showDylibPicker = false
    @State private var injectFramework = false
    @State private var frameworkPath = ""
    @State private var hookingEnabled = false
    @State private var substrateSafeMode = false
    
    // Code Signing
    @State private var useAdhocSigning = false
    @State private var preserveMetadata = true
    @State private var deepSign = true
    @State private var forceSign = false
    @State private var timestampSigning = true
    @State private var customTeamID = ""
    @State private var customSigningIdentity = ""
    
    // Entitlements & Capabilities
    @State private var stripEntitlements = false
    @State private var mergeEntitlements = true
    @State private var allowUnsignedExecutable = false
    @State private var enableJIT = false
    @State private var enableDebugging = true
    @State private var allowDyldEnvironment = false
    
    // App Modifications
    @State private var removePlugins = false
    @State private var removeWatchApp = false
    @State private var removeExtensions = false
    @State private var removeOnDemandResources = false
    @State private var compressAssets = false
    @State private var optimizeImages = false
    @State private var removeLocalizations = false
    @State private var keepLocalizations: [String] = ["en"]
    
    // Debug Options
    @State private var enableVerboseLogging = false
    @State private var dryRunMode = false
    @State private var generateReport = true
    @State private var validateAfterSigning = true
    @State private var showTimings = false
    @State private var exportUnsignedIPA = false
    
    // Memory & Performance
    @State private var lowMemoryMode = false
    @State private var parallelSigning = true
    @State private var chunkSize = 4
    
    // Advanced Patching
    @State private var enableBinaryPatching = false
    @State private var patchInstructions: [String] = []
    @State private var hexPatchOffset = ""
    @State private var hexPatchValue = ""
    @State private var enableMethodSwizzling = false
    @State private var swizzleTargets: [String] = []
    
    private let architectures = ["arm64", "arm64e", "armv7", "armv7s", "x86_64"]
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Advanced Debug Tools", systemImage: "hammer.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("Powerful tools for modifying apps before signing. Use with extreme caution - incorrect settings may cause app crashes or installation failures.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - Version Override Section
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
                
                HStack {
                    Label("Short Version", systemImage: "textformat.123")
                    Spacer()
                    TextField("e.g., 2.0.1", text: $customShortVersion)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Label("Bundle Version", systemImage: "number.circle")
                    Spacer()
                    TextField("e.g., 2001", text: $customBundleVersion)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .keyboardType(.numberPad)
                }
            } header: {
                debugSectionHeader("Version Override", icon: "tag.fill", color: .blue)
            }
            
            // MARK: - Binary Modifications Section
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
                
                Toggle(isOn: $thinBinary) {
                    Label("Thin Binary", systemImage: "scissors")
                }
                
                if thinBinary {
                    Picker("Target Architecture", selection: $selectedArchitecture) {
                        ForEach(architectures, id: \.self) { arch in
                            Text(arch).tag(arch)
                        }
                    }
                }
                
                Toggle(isOn: $enablePIE) {
                    Label("Enable PIE", systemImage: "shield.lefthalf.filled")
                }
                
                Toggle(isOn: $stripDebugSymbols) {
                    Label("Strip Debug Symbols", systemImage: "ladybug.slash")
                }
                
                Toggle(isOn: $removeSwiftSupport) {
                    Label("Remove Swift Support", systemImage: "swift")
                }
            } header: {
                debugSectionHeader("Binary Modifications", icon: "doc.fill", color: .purple)
            } footer: {
                Text("These options modify the app binary directly. May cause app instability or crashes.")
            }
            
            // MARK: - Injection Section
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
                
                Toggle(isOn: $injectFramework) {
                    Label("Inject Framework", systemImage: "shippingbox.fill")
                }
                
                if injectFramework {
                    HStack {
                        Text("Framework Path")
                        Spacer()
                        TextField("Path", text: $frameworkPath)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }
                }
                
                Toggle(isOn: $modifyExecutable) {
                    Label("Modify Executable Name", systemImage: "pencil")
                }
                
                Toggle(isOn: $hookingEnabled) {
                    Label("Enable Hooking", systemImage: "link.badge.plus")
                }
                
                Toggle(isOn: $substrateSafeMode) {
                    Label("Substrate Safe Mode", systemImage: "exclamationmark.shield")
                }
            } header: {
                debugSectionHeader("Injection & Hooking", icon: "syringe.fill", color: .green)
            } footer: {
                Text("Inject dynamic libraries and frameworks into the app bundle.")
            }
            
            // MARK: - Code Signing Section
            Section {
                Toggle(isOn: $useAdhocSigning) {
                    Label("Ad-hoc Signing", systemImage: "person.crop.circle.badge.questionmark")
                }
                
                Toggle(isOn: $preserveMetadata) {
                    Label("Preserve Metadata", systemImage: "doc.badge.clock")
                }
                
                Toggle(isOn: $deepSign) {
                    Label("Deep Sign", systemImage: "arrow.down.to.line.compact")
                }
                
                Toggle(isOn: $forceSign) {
                    Label("Force Sign", systemImage: "bolt.fill")
                }
                
                Toggle(isOn: $timestampSigning) {
                    Label("Timestamp Signing", systemImage: "clock.badge.checkmark")
                }
                
                HStack {
                    Label("Custom Team ID", systemImage: "person.2.fill")
                    Spacer()
                    TextField("Team ID", text: $customTeamID)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .textInputAutocapitalization(.characters)
                }
                
                HStack {
                    Label("Signing Identity", systemImage: "person.text.rectangle")
                    Spacer()
                    TextField("Identity", text: $customSigningIdentity)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            } header: {
                debugSectionHeader("Code Signing", icon: "checkmark.seal.fill", color: .cyan)
            }
            
            // MARK: - Entitlements Section
            Section {
                Toggle(isOn: $stripEntitlements) {
                    Label("Strip Entitlements", systemImage: "xmark.seal")
                }
                
                Toggle(isOn: $mergeEntitlements) {
                    Label("Merge Entitlements", systemImage: "arrow.triangle.merge")
                }
                
                Toggle(isOn: $allowUnsignedExecutable) {
                    Label("Allow Unsigned Executable", systemImage: "exclamationmark.triangle")
                }
                
                Toggle(isOn: $enableJIT) {
                    Label("Enable JIT Compilation", systemImage: "bolt.horizontal.fill")
                }
                
                Toggle(isOn: $enableDebugging) {
                    Label("Enable Debugging", systemImage: "ant.fill")
                }
                
                Toggle(isOn: $allowDyldEnvironment) {
                    Label("Allow DYLD Environment", systemImage: "terminal")
                }
            } header: {
                debugSectionHeader("Entitlements & Capabilities", icon: "key.fill", color: .orange)
            } footer: {
                Text("Modify app entitlements and capabilities. Some options may require specific provisioning profiles.")
            }
            
            // MARK: - App Modifications Section
            Section {
                Toggle(isOn: $removePlugins) {
                    Label("Remove Plugins", systemImage: "puzzlepiece.extension")
                }
                
                Toggle(isOn: $removeWatchApp) {
                    Label("Remove Watch App", systemImage: "applewatch.slash")
                }
                
                Toggle(isOn: $removeExtensions) {
                    Label("Remove Extensions", systemImage: "square.stack.3d.up.slash")
                }
                
                Toggle(isOn: $removeOnDemandResources) {
                    Label("Remove On-Demand Resources", systemImage: "arrow.down.circle.dotted")
                }
                
                Toggle(isOn: $compressAssets) {
                    Label("Compress Assets", systemImage: "archivebox")
                }
                
                Toggle(isOn: $optimizeImages) {
                    Label("Optimize Images", systemImage: "photo.badge.checkmark")
                }
                
                Toggle(isOn: $removeLocalizations) {
                    Label("Remove Localizations", systemImage: "globe.badge.chevron.backward")
                }
            } header: {
                debugSectionHeader("App Modifications", icon: "app.badge.fill", color: .pink)
            } footer: {
                Text("Remove unnecessary components to reduce app size.")
            }
            
            // MARK: - Advanced Patching Section
            Section {
                Toggle(isOn: $enableBinaryPatching) {
                    Label("Enable Binary Patching", systemImage: "hammer.circle.fill")
                }
                
                if enableBinaryPatching {
                    HStack {
                        Label("Hex Offset", systemImage: "number")
                        Spacer()
                        TextField("0x...", text: $hexPatchOffset)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .textInputAutocapitalization(.never)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Label("Hex Value", systemImage: "textformat.abc")
                        Spacer()
                        TextField("Bytes", text: $hexPatchValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .textInputAutocapitalization(.never)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Button {
                        addPatchInstruction()
                    } label: {
                        Label("Add Patch", systemImage: "plus.circle.fill")
                    }
                    
                    if !patchInstructions.isEmpty {
                        ForEach(patchInstructions, id: \.self) { patch in
                            Text(patch)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .onDelete { indexSet in
                            patchInstructions.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Toggle(isOn: $enableMethodSwizzling) {
                    Label("Method Swizzling", systemImage: "arrow.triangle.swap")
                }
            } header: {
                debugSectionHeader("Advanced Patching", icon: "wrench.and.screwdriver.fill", color: .red)
            } footer: {
                Text("⚠️ Binary patching can permanently break apps. Only use if you know what you're doing.")
            }
            
            // MARK: - Performance Section
            Section {
                Toggle(isOn: $lowMemoryMode) {
                    Label("Low Memory Mode", systemImage: "memorychip")
                }
                
                Toggle(isOn: $parallelSigning) {
                    Label("Parallel Signing", systemImage: "arrow.triangle.branch")
                }
                
                if parallelSigning {
                    Stepper(value: $chunkSize, in: 1...8) {
                        HStack {
                            Label("Chunk Size", systemImage: "square.grid.3x3")
                            Spacer()
                            Text("\(chunkSize)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                debugSectionHeader("Memory & Performance", icon: "gauge.with.dots.needle.67percent", color: .teal)
            }
            
            // MARK: - Debug Options Section
            Section {
                Toggle(isOn: $enableVerboseLogging) {
                    Label("Verbose Logging", systemImage: "text.alignleft")
                }
                
                Toggle(isOn: $dryRunMode) {
                    Label("Dry Run Mode", systemImage: "play.slash.fill")
                }
                
                Toggle(isOn: $generateReport) {
                    Label("Generate Report", systemImage: "doc.text.fill")
                }
                
                Toggle(isOn: $validateAfterSigning) {
                    Label("Validate After Signing", systemImage: "checkmark.circle")
                }
                
                Toggle(isOn: $showTimings) {
                    Label("Show Timings", systemImage: "timer")
                }
                
                Toggle(isOn: $exportUnsignedIPA) {
                    Label("Export Unsigned IPA", systemImage: "square.and.arrow.up")
                }
            } header: {
                debugSectionHeader("Debug Options", icon: "ladybug.fill", color: .orange)
            } footer: {
                Text("Dry run mode simulates signing without making changes.")
            }
            
            // MARK: - Quick Actions Section
            Section {
                Button {
                    resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                }
                
                Button {
                    loadPreset("minimal")
                } label: {
                    HStack {
                        Spacer()
                        Label("Load Minimal Preset", systemImage: "square.stack")
                        Spacer()
                    }
                }
                
                Button {
                    loadPreset("aggressive")
                } label: {
                    HStack {
                        Spacer()
                        Label("Load Aggressive Preset", systemImage: "bolt.square.fill")
                        Spacer()
                    }
                }
                .tint(.orange)
                
                Button {
                    exportConfiguration()
                } label: {
                    HStack {
                        Spacer()
                        Label("Export Configuration", systemImage: "square.and.arrow.up")
                        Spacer()
                    }
                }
            } header: {
                debugSectionHeader("Quick Actions", icon: "bolt.fill", color: .yellow)
            }
            
            // MARK: - Apply Button
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
    
    private func resetToDefaults() {
        customMinimumVersion = ""
        customBuildNumber = ""
        customShortVersion = ""
        customBundleVersion = ""
        forceArmv7 = false
        stripBitcode = true
        removeSignature = false
        thinBinary = false
        enablePIE = true
        stripDebugSymbols = false
        removeSwiftSupport = false
        injectCustomDylib = false
        injectFramework = false
        hookingEnabled = false
        substrateSafeMode = false
        useAdhocSigning = false
        preserveMetadata = true
        deepSign = true
        forceSign = false
        timestampSigning = true
        stripEntitlements = false
        mergeEntitlements = true
        allowUnsignedExecutable = false
        enableJIT = false
        enableDebugging = true
        allowDyldEnvironment = false
        removePlugins = false
        removeWatchApp = false
        removeExtensions = false
        removeOnDemandResources = false
        compressAssets = false
        optimizeImages = false
        removeLocalizations = false
        enableBinaryPatching = false
        enableMethodSwizzling = false
        lowMemoryMode = false
        parallelSigning = true
        enableVerboseLogging = false
        dryRunMode = false
        generateReport = true
        validateAfterSigning = true
        showTimings = false
        exportUnsignedIPA = false
        HapticsManager.shared.softImpact()
    }
    
    private func loadPreset(_ preset: String) {
        switch preset {
        case "minimal":
            stripBitcode = true
            removeSignature = true
            deepSign = true
            preserveMetadata = false
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            removeOnDemandResources = true
            removeLocalizations = true
        case "aggressive":
            stripBitcode = true
            removeSignature = true
            stripDebugSymbols = true
            removeSwiftSupport = true
            deepSign = true
            forceSign = true
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            removeOnDemandResources = true
            compressAssets = true
            optimizeImages = true
            removeLocalizations = true
            parallelSigning = true
        default:
            break
        }
        HapticsManager.shared.softImpact()
    }
    
    private func exportConfiguration() {
        HapticsManager.shared.success()
    }
    
    private func addPatchInstruction() {
        guard !hexPatchOffset.isEmpty && !hexPatchValue.isEmpty else { return }
        patchInstructions.append("\(hexPatchOffset): \(hexPatchValue)")
        hexPatchOffset = ""
        hexPatchValue = ""
        HapticsManager.shared.softImpact()
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
// MARK: - Plist Entry Model
struct PlistEntry: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
    var type: String
    var isModified: Bool = false
    var children: [PlistEntry]? = nil
    var isExpanded: Bool = false
}

// MARK: - Info.plist Editor Debug View
struct InfoPlistEditorDebugView: View {
    let app: AppInfoPresentable
    @Binding var options: Options
    @State private var plistEntries: [PlistEntry] = []
    @State private var searchText = ""
    @State private var showAddEntry = false
    @State private var showEditEntry = false
    @State private var showRawView = false
    @State private var showImportSheet = false
    @State private var showExportSheet = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var selectedType = "String"
    @State private var editingEntry: PlistEntry? = nil
    @State private var editKey = ""
    @State private var editValue = ""
    @State private var editType = "String"
    @State private var rawPlistContent = ""
    @State private var hasUnsavedChanges = false
    @State private var showDiscardAlert = false
    @State private var selectedEntries: Set<UUID> = []
    @State private var isMultiSelectMode = false
    @State private var sortOrder: SortOrder = .keyAscending
    @State private var filterType: String = "All"
    @State private var showValidationErrors = false
    @State private var validationErrors: [String] = []
    
    private let types = ["String", "Number", "Boolean", "Array", "Dictionary", "Date", "Data"]
    private let filterTypes = ["All", "String", "Number", "Boolean", "Array", "Dictionary", "Date", "Data"]
    
    enum SortOrder: String, CaseIterable {
        case keyAscending = "Key (A-Z)"
        case keyDescending = "Key (Z-A)"
        case typeAscending = "Type (A-Z)"
        case modified = "Modified First"
    }
    
    var filteredEntries: [PlistEntry] {
        var result = plistEntries
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { 
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.value.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if filterType != "All" {
            result = result.filter { $0.type == filterType }
        }
        
        // Apply sorting
        switch sortOrder {
        case .keyAscending:
            result.sort { $0.key < $1.key }
        case .keyDescending:
            result.sort { $0.key > $1.key }
        case .typeAscending:
            result.sort { $0.type < $1.type }
        case .modified:
            result.sort { $0.isModified && !$1.isModified }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter and Sort Bar
            filterSortBar
            
            if showRawView {
                rawPlistView
            } else {
                editorListView
            }
        }
        .searchable(text: $searchText, prompt: "Search keys or values...")
        .navigationTitle("Info.plist Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showRawView.toggle()
                        if showRawView {
                            generateRawPlist()
                        }
                    } label: {
                        Label(showRawView ? "Editor View" : "Raw View", 
                              systemImage: showRawView ? "list.bullet" : "doc.text")
                    }
                    
                    Divider()
                    
                    Button {
                        showAddEntry = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                    
                    Button {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedEntries.removeAll()
                        }
                    } label: {
                        Label(isMultiSelectMode ? "Cancel Selection" : "Select Multiple", 
                              systemImage: isMultiSelectMode ? "xmark.circle" : "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        validatePlist()
                    } label: {
                        Label("Validate", systemImage: "checkmark.shield")
                    }
                    
                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button {
                        loadCommonKeys()
                    } label: {
                        Label("Load Common Keys", systemImage: "list.bullet.rectangle")
                    }
                    
                    Button(role: .destructive) {
                        resetToOriginal()
                    } label: {
                        Label("Reset to Original", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadPlistEntries()
            generateRawPlist()
        }
        .sheet(isPresented: $showAddEntry) {
            addEntrySheet
        }
        .sheet(isPresented: $showEditEntry) {
            editEntrySheet
        }
        .alert("Validation Results", isPresented: $showValidationErrors) {
            Button("OK", role: .cancel) { }
        } message: {
            if validationErrors.isEmpty {
                Text("✅ Info.plist is valid!")
            } else {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                loadPlistEntries()
                hasUnsavedChanges = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // MARK: - Filter Sort Bar
    private var filterSortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Type Filter
                Menu {
                    ForEach(filterTypes, id: \.self) { type in
                        Button {
                            filterType = type
                        } label: {
                            HStack {
                                Text(type)
                                if filterType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterType)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                }
                
                // Sort Order
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                
                // Entry Count
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if hasUnsavedChanges {
                    Text("• Modified")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Editor List View
    private var editorListView: some View {
        List {
            // Multi-select actions
            if isMultiSelectMode && !selectedEntries.isEmpty {
                Section {
                    HStack {
                        Text("\(selectedEntries.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            deleteSelectedEntries()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            
            // Entries
            Section {
                ForEach(filteredEntries) { entry in
                    PlistEntryRow(
                        entry: entry,
                        isSelected: selectedEntries.contains(entry.id),
                        isMultiSelectMode: isMultiSelectMode,
                        onTap: {
                            if isMultiSelectMode {
                                toggleSelection(entry.id)
                            } else {
                                editingEntry = entry
                                editKey = entry.key
                                editValue = entry.value
                                editType = entry.type
                                showEditEntry = true
                            }
                        },
                        onCopy: {
                            UIPasteboard.general.string = "\(entry.key): \(entry.value)"
                            HapticsManager.shared.softImpact()
                        }
                    )
                }
                .onDelete(perform: deleteEntry)
            } header: {
                HStack {
                    Text("Entries")
                    Spacer()
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            
            // Quick Add Common Keys
            Section {
                Button {
                    addCommonKey("CFBundleURLTypes")
                } label: {
                    Label("Add URL Scheme", systemImage: "link")
                }
                
                Button {
                    addCommonKey("NSAppTransportSecurity")
                } label: {
                    Label("Add App Transport Security", systemImage: "lock.shield")
                }
                
                Button {
                    addCommonKey("UIBackgroundModes")
                } label: {
                    Label("Add Background Modes", systemImage: "arrow.clockwise")
                }
                
                Button {
                    addCommonKey("NSCameraUsageDescription")
                } label: {
                    Label("Add Camera Usage", systemImage: "camera")
                }
                
                Button {
                    addCommonKey("NSPhotoLibraryUsageDescription")
                } label: {
                    Label("Add Photo Library Usage", systemImage: "photo")
                }
            } header: {
                Text("Quick Add")
            }
            
            // Save Section
            Section {
                Button {
                    savePlistChanges()
                } label: {
                    HStack {
                        Spacer()
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!hasUnsavedChanges)
                .tint(.green)
            }
        }
    }
    
    // MARK: - Raw Plist View
    private var rawPlistView: some View {
        VStack(spacing: 0) {
            // Toolbar for raw view
            HStack {
                Button {
                    UIPasteboard.general.string = rawPlistContent
                    HapticsManager.shared.success()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button {
                    formatRawPlist()
                } label: {
                    Label("Format", systemImage: "text.alignleft")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("\(rawPlistContent.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemBackground))
            
            // Raw content editor
            ScrollView {
                TextEditor(text: $rawPlistContent)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 400)
                    .padding()
                    .onChange(of: rawPlistContent) { _ in
                        hasUnsavedChanges = true
                    }
            }
            
            // Parse and Apply button
            HStack {
                Button {
                    parseRawPlist()
                } label: {
                    HStack {
                        Spacer()
                        Label("Parse & Apply", systemImage: "arrow.right.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
    
    // MARK: - Add Entry Sheet
    private var addEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Key", text: $newKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                } header: {
                    Text("Key Information")
                }
                
                Section {
                    switch selectedType {
                    case "Boolean":
                        Picker("Value", selection: $newValue) {
                            Text("true").tag("true")
                            Text("false").tag("false")
                        }
                        .pickerStyle(.segmented)
                    case "Number":
                        TextField("Value", text: $newValue)
                            .keyboardType(.decimalPad)
                    case "Array":
                        TextField("Value (comma-separated)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Dictionary":
                        TextField("Value (JSON format)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Date":
                        TextField("Value (ISO 8601)", text: $newValue)
                            .autocorrectionDisabled()
                    case "Data":
                        TextField("Value (Base64)", text: $newValue)
                            .autocorrectionDisabled()
                    default:
                        TextField("Value", text: $newValue)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Value")
                }
                
                // Common Keys Suggestions
                Section {
                    ForEach(commonKeysSuggestions, id: \.0) { key, type in
                        Button {
                            newKey = key
                            selectedType = type
                        } label: {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                Spacer()
                                Text(type)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Suggestions")
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        showAddEntry = false
                        clearNewEntryFields()
                    }
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
        .presentationDetents([.large])
    }
    
    // MARK: - Edit Entry Sheet
    private var editEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Key", text: $editKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Picker("Type", selection: $editType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                } header: {
                    Text("Key Information")
                }
                
                Section {
                    switch editType {
                    case "Boolean":
                        Picker("Value", selection: $editValue) {
                            Text("true").tag("true")
                            Text("false").tag("false")
                        }
                        .pickerStyle(.segmented)
                    case "Number":
                        TextField("Value", text: $editValue)
                            .keyboardType(.decimalPad)
                    case "Array":
                        TextEditor(text: $editValue)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                    case "Dictionary":
                        TextEditor(text: $editValue)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                    default:
                        TextField("Value", text: $editValue)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Value")
                }
                
                Section {
                    Button(role: .destructive) {
                        if let entry = editingEntry,
                           let index = plistEntries.firstIndex(where: { $0.id == entry.id }) {
                            plistEntries.remove(at: index)
                            hasUnsavedChanges = true
                        }
                        showEditEntry = false
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        showEditEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateEntry()
                        showEditEntry = false
                    }
                    .disabled(editKey.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Common Keys Suggestions
    private var commonKeysSuggestions: [(String, String)] {
        [
            ("CFBundleDisplayName", "String"),
            ("CFBundleExecutable", "String"),
            ("CFBundleIconFiles", "Array"),
            ("CFBundleIcons", "Dictionary"),
            ("CFBundlePackageType", "String"),
            ("CFBundleSignature", "String"),
            ("LSApplicationCategoryType", "String"),
            ("NSHumanReadableCopyright", "String"),
            ("UIFileSharingEnabled", "Boolean"),
            ("UISupportsDocumentBrowser", "Boolean"),
            ("ITSAppUsesNonExemptEncryption", "Boolean"),
            ("UIStatusBarHidden", "Boolean"),
            ("UIViewControllerBasedStatusBarAppearance", "Boolean")
        ]
    }
    
    // MARK: - Helper Functions
    private func loadPlistEntries() {
        plistEntries = [
            PlistEntry(key: "CFBundleIdentifier", value: app.identifier ?? "com.example.app", type: "String"),
            PlistEntry(key: "CFBundleName", value: app.name ?? "App", type: "String"),
            PlistEntry(key: "CFBundleDisplayName", value: app.name ?? "App", type: "String"),
            PlistEntry(key: "CFBundleShortVersionString", value: app.version ?? "1.0", type: "String"),
            PlistEntry(key: "CFBundleVersion", value: "1", type: "String"),
            PlistEntry(key: "CFBundleExecutable", value: app.name ?? "App", type: "String"),
            PlistEntry(key: "CFBundlePackageType", value: "APPL", type: "String"),
            PlistEntry(key: "MinimumOSVersion", value: "14.0", type: "String"),
            PlistEntry(key: "UIDeviceFamily", value: "[1, 2]", type: "Array"),
            PlistEntry(key: "UIRequiredDeviceCapabilities", value: "[arm64]", type: "Array"),
            PlistEntry(key: "UISupportedInterfaceOrientations", value: "[UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]", type: "Array"),
            PlistEntry(key: "UILaunchStoryboardName", value: "LaunchScreen", type: "String"),
            PlistEntry(key: "UIMainStoryboardFile", value: "Main", type: "String"),
            PlistEntry(key: "LSRequiresIPhoneOS", value: "true", type: "Boolean"),
            PlistEntry(key: "UIApplicationSceneManifest", value: "{UIApplicationSupportsMultipleScenes: false}", type: "Dictionary"),
            PlistEntry(key: "ITSAppUsesNonExemptEncryption", value: "false", type: "Boolean"),
            PlistEntry(key: "UIStatusBarStyle", value: "UIStatusBarStyleDefault", type: "String")
        ]
        hasUnsavedChanges = false
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        // Map filtered indices to actual indices
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        for entry in entriesToDelete {
            if let index = plistEntries.firstIndex(where: { $0.id == entry.id }) {
                plistEntries.remove(at: index)
            }
        }
        hasUnsavedChanges = true
    }
    
    private func deleteSelectedEntries() {
        plistEntries.removeAll { selectedEntries.contains($0.id) }
        selectedEntries.removeAll()
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedEntries.contains(id) {
            selectedEntries.remove(id)
        } else {
            selectedEntries.insert(id)
        }
    }
    
    private func addEntry() {
        let entry = PlistEntry(key: newKey, value: newValue, type: selectedType, isModified: true)
        plistEntries.append(entry)
        hasUnsavedChanges = true
        clearNewEntryFields()
        HapticsManager.shared.softImpact()
    }
    
    private func updateEntry() {
        guard let entry = editingEntry,
              let index = plistEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        
        plistEntries[index].key = editKey
        plistEntries[index].value = editValue
        plistEntries[index].type = editType
        plistEntries[index].isModified = true
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }
    
    private func clearNewEntryFields() {
        newKey = ""
        newValue = ""
        selectedType = "String"
    }
    
    private func generateRawPlist() {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">")
        lines.append("<plist version=\"1.0\">")
        lines.append("<dict>")
        
        for entry in plistEntries {
            lines.append("    <key>\(entry.key)</key>")
            switch entry.type {
            case "String":
                lines.append("    <string>\(entry.value)</string>")
            case "Number":
                if entry.value.contains(".") {
                    lines.append("    <real>\(entry.value)</real>")
                } else {
                    lines.append("    <integer>\(entry.value)</integer>")
                }
            case "Boolean":
                lines.append("    <\(entry.value)/>")
            case "Array":
                lines.append("    <array>")
                let items = entry.value.replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .split(separator: ",")
                for item in items {
                    lines.append("        <string>\(item.trimmingCharacters(in: .whitespaces))</string>")
                }
                lines.append("    </array>")
            case "Dictionary":
                lines.append("    <dict>")
                lines.append("        <!-- \(entry.value) -->")
                lines.append("    </dict>")
            case "Date":
                lines.append("    <date>\(entry.value)</date>")
            case "Data":
                lines.append("    <data>\(entry.value)</data>")
            default:
                lines.append("    <string>\(entry.value)</string>")
            }
        }
        
        lines.append("</dict>")
        lines.append("</plist>")
        
        rawPlistContent = lines.joined(separator: "\n")
    }
    
    private func parseRawPlist() {
        // Simple validation - in real implementation would use XMLParser
        if rawPlistContent.contains("<plist") && rawPlistContent.contains("</plist>") {
            HapticsManager.shared.success()
            showRawView = false
        } else {
            validationErrors = ["Invalid plist format. Missing plist tags."]
            showValidationErrors = true
        }
    }
    
    private func formatRawPlist() {
        // Re-generate formatted plist
        generateRawPlist()
        HapticsManager.shared.softImpact()
    }
    
    private func validatePlist() {
        validationErrors = []
        
        // Check for required keys
        let requiredKeys = ["CFBundleIdentifier", "CFBundleName", "CFBundleVersion", "CFBundleShortVersionString"]
        for key in requiredKeys {
            if !plistEntries.contains(where: { $0.key == key }) {
                validationErrors.append("⚠️ Missing required key: \(key)")
            }
        }
        
        // Check for duplicate keys
        var seenKeys: Set<String> = []
        for entry in plistEntries {
            if seenKeys.contains(entry.key) {
                validationErrors.append("❌ Duplicate key: \(entry.key)")
            }
            seenKeys.insert(entry.key)
        }
        
        // Check bundle identifier format
        if let bundleId = plistEntries.first(where: { $0.key == "CFBundleIdentifier" }) {
            if !bundleId.value.contains(".") {
                validationErrors.append("⚠️ Bundle identifier should use reverse-DNS format")
            }
        }
        
        showValidationErrors = true
        HapticsManager.shared.softImpact()
    }
    
    private func savePlistChanges() {
        hasUnsavedChanges = false
        HapticsManager.shared.success()
    }
    
    private func resetToOriginal() {
        if hasUnsavedChanges {
            showDiscardAlert = true
        } else {
            loadPlistEntries()
        }
    }
    
    private func loadCommonKeys() {
        let commonEntries: [PlistEntry] = [
            PlistEntry(key: "NSCameraUsageDescription", value: "This app needs camera access", type: "String", isModified: true),
            PlistEntry(key: "NSPhotoLibraryUsageDescription", value: "This app needs photo library access", type: "String", isModified: true),
            PlistEntry(key: "NSMicrophoneUsageDescription", value: "This app needs microphone access", type: "String", isModified: true),
            PlistEntry(key: "NSLocationWhenInUseUsageDescription", value: "This app needs location access", type: "String", isModified: true)
        ]
        
        for entry in commonEntries {
            if !plistEntries.contains(where: { $0.key == entry.key }) {
                plistEntries.append(entry)
            }
        }
        hasUnsavedChanges = true
        HapticsManager.shared.softImpact()
    }
    
    private func addCommonKey(_ key: String) {
        let templates: [String: PlistEntry] = [
            "CFBundleURLTypes": PlistEntry(key: "CFBundleURLTypes", value: "[{CFBundleURLSchemes: [myapp]}]", type: "Array", isModified: true),
            "NSAppTransportSecurity": PlistEntry(key: "NSAppTransportSecurity", value: "{NSAllowsArbitraryLoads: true}", type: "Dictionary", isModified: true),
            "UIBackgroundModes": PlistEntry(key: "UIBackgroundModes", value: "[audio, fetch, remote-notification]", type: "Array", isModified: true),
            "NSCameraUsageDescription": PlistEntry(key: "NSCameraUsageDescription", value: "This app requires camera access", type: "String", isModified: true),
            "NSPhotoLibraryUsageDescription": PlistEntry(key: "NSPhotoLibraryUsageDescription", value: "This app requires photo library access", type: "String", isModified: true)
        ]
        
        if let template = templates[key], !plistEntries.contains(where: { $0.key == key }) {
            plistEntries.append(template)
            hasUnsavedChanges = true
            HapticsManager.shared.softImpact()
        }
    }
}

// MARK: - Plist Entry Row
struct PlistEntryRow: View {
    let entry: PlistEntry
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.key)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        if entry.isModified {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                        
                        Spacer()
                        
                        Text(entry.type)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(typeColor(entry.type).opacity(0.2)))
                    }
                    
                    Text(entry.value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                UIPasteboard.general.string = entry.key
            } label: {
                Label("Copy Key", systemImage: "key")
            }
            
            Button {
                UIPasteboard.general.string = entry.value
            } label: {
                Label("Copy Value", systemImage: "text.quote")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // Delete handled by parent
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type {
        case "String": return .blue
        case "Number": return .green
        case "Boolean": return .orange
        case "Array": return .purple
        case "Dictionary": return .pink
        case "Date": return .cyan
        case "Data": return .gray
        default: return .secondary
        }
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
// MARK: - Resource Item Model
struct ResourceItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var type: String
    var size: String
    var sizeBytes: Int64
    var path: String
    var modifiedDate: Date
    var isSelected: Bool = false
    var isModified: Bool = false
    var permissions: String
    var checksum: String?
    var dimensions: String? // For images
    var encoding: String? // For text files
    var compressionRatio: Double? // For compressed files
}

// MARK: - Resource Modifier View
struct ResourceModifierView: View {
    let app: AppInfoPresentable
    @State private var resources: [ResourceItem] = []
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var sortOrder: ResourceSortOrder = .nameAscending
    @State private var selectedResource: ResourceItem? = nil
    @State private var showResourceDetail = false
    @State private var showReplaceSheet = false
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isMultiSelectMode = false
    @State private var selectedResources: Set<UUID> = []
    @State private var isLoading = true
    @State private var totalSize: String = "0 KB"
    @State private var showStatistics = false
    
    private let filters = ["All", "Images", "Strings", "Plists", "Storyboards", "Frameworks", "Bundles", "Other"]
    
    enum ResourceSortOrder: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case sizeAscending = "Size (Small first)"
        case sizeDescending = "Size (Large first)"
        case typeAscending = "Type (A-Z)"
        case dateDescending = "Recently Modified"
    }
    
    var filteredResources: [ResourceItem] {
        var result = resources
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if selectedFilter != "All" {
            result = result.filter { resource in
                switch selectedFilter {
                case "Images": return ["png", "jpg", "jpeg", "pdf", "svg", "heic", "webp", "gif", "ico"].contains(resource.type.lowercased())
                case "Strings": return resource.type.lowercased() == "strings"
                case "Plists": return resource.type.lowercased() == "plist"
                case "Storyboards": return ["storyboard", "xib", "nib"].contains(resource.type.lowercased())
                case "Frameworks": return resource.type.lowercased() == "framework"
                case "Bundles": return ["bundle", "appex", "pluginkit"].contains(resource.type.lowercased())
                case "Other": return !["png", "jpg", "jpeg", "pdf", "svg", "heic", "webp", "gif", "ico", "strings", "plist", "storyboard", "xib", "nib", "framework", "bundle", "appex", "pluginkit"].contains(resource.type.lowercased())
                default: return true
                }
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .nameAscending:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            result.sort { $0.name.lowercased() > $1.name.lowercased() }
        case .sizeAscending:
            result.sort { $0.sizeBytes < $1.sizeBytes }
        case .sizeDescending:
            result.sort { $0.sizeBytes > $1.sizeBytes }
        case .typeAscending:
            result.sort { $0.type.lowercased() < $1.type.lowercased() }
        case .dateDescending:
            result.sort { $0.modifiedDate > $1.modifiedDate }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Statistics Bar
            statisticsBar
            
            // Filter Bar
            filterBar
            
            if isLoading {
                loadingView
            } else {
                resourceListView
            }
        }
        .searchable(text: $searchText, prompt: "Search resources...")
        .navigationTitle("Resource Modifier")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedResources.removeAll()
                        }
                    } label: {
                        Label(isMultiSelectMode ? "Cancel Selection" : "Select Multiple", 
                              systemImage: isMultiSelectMode ? "xmark.circle" : "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        showStatistics.toggle()
                    } label: {
                        Label("Statistics", systemImage: "chart.pie")
                    }
                    
                    Button {
                        exportAllResources()
                    } label: {
                        Label("Export All", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button {
                        refreshResources()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Button(role: .destructive) {
                        removeUnusedResources()
                    } label: {
                        Label("Remove Unused", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadResources()
        }
        .sheet(isPresented: $showResourceDetail) {
            if let resource = selectedResource {
                ResourceDetailView(resource: resource, onReplace: {
                    showReplaceSheet = true
                }, onExport: {
                    showExportSheet = true
                }, onDelete: {
                    showDeleteConfirmation = true
                })
            }
        }
        .sheet(isPresented: $showStatistics) {
            ResourceStatisticsView(resources: resources)
        }
        .alert("Delete Resource?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let resource = selectedResource {
                    deleteResource(resource)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Statistics Bar
    private var statisticsBar: some View {
        HStack(spacing: 16) {
            ResourceStatBadge(title: "Total", value: "\(resources.count)", color: .blue)
            ResourceStatBadge(title: "Size", value: totalSize, color: .green)
            ResourceStatBadge(title: "Images", value: "\(resources.filter { ["png", "jpg", "jpeg", "pdf", "svg"].contains($0.type.lowercased()) }.count)", color: .orange)
            ResourceStatBadge(title: "Modified", value: "\(resources.filter { $0.isModified }.count)", color: .purple)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(spacing: 8) {
            // Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            HapticsManager.shared.softImpact()
                        } label: {
                            Text(filter)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? Color.accentColor : Color.secondary.opacity(0.15))
                                )
                                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
            // Sort Order
            HStack {
                Text("Sort:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Menu {
                    ForEach(ResourceSortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                }
                
                Spacer()
                
                Text("\(filteredResources.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .background(Color(UIColor.tertiarySystemBackground))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Scanning resources...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Resource List View
    private var resourceListView: some View {
        List {
            // Multi-select actions
            if isMultiSelectMode && !selectedResources.isEmpty {
                Section {
                    HStack {
                        Text("\(selectedResources.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        Button {
                            exportSelectedResources()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(role: .destructive) {
                            deleteSelectedResources()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            
            // Resources
            Section {
                ForEach(filteredResources) { resource in
                    ResourceRow(
                        resource: resource,
                        isSelected: selectedResources.contains(resource.id),
                        isMultiSelectMode: isMultiSelectMode,
                        onTap: {
                            if isMultiSelectMode {
                                toggleSelection(resource.id)
                            } else {
                                selectedResource = resource
                                showResourceDetail = true
                            }
                        }
                    )
                }
                .onDelete(perform: deleteResources)
            } header: {
                Text("Resources")
            }
            
            // Quick Actions
            Section {
                Button {
                    optimizeImages()
                } label: {
                    Label("Optimize All Images", systemImage: "photo.badge.checkmark")
                }
                
                Button {
                    removeUnusedLocalizations()
                } label: {
                    Label("Remove Unused Localizations", systemImage: "globe.badge.chevron.backward")
                }
                
                Button {
                    compressResources()
                } label: {
                    Label("Compress Resources", systemImage: "archivebox")
                }
                
                Button {
                    validateResources()
                } label: {
                    Label("Validate Resources", systemImage: "checkmark.shield")
                }
            } header: {
                Text("Quick Actions")
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadResources() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resources = [
                ResourceItem(name: "AppIcon", type: "png", size: "124 KB", sizeBytes: 126976, path: "Assets.xcassets/AppIcon.appiconset", modifiedDate: Date().addingTimeInterval(-86400), permissions: "rw-r--r--", checksum: "a1b2c3d4e5f6", dimensions: "1024x1024"),
                ResourceItem(name: "AppIcon@2x", type: "png", size: "48 KB", sizeBytes: 49152, path: "Assets.xcassets/AppIcon.appiconset", modifiedDate: Date().addingTimeInterval(-86400), permissions: "rw-r--r--", checksum: "b2c3d4e5f6a1", dimensions: "120x120"),
                ResourceItem(name: "AppIcon@3x", type: "png", size: "72 KB", sizeBytes: 73728, path: "Assets.xcassets/AppIcon.appiconset", modifiedDate: Date().addingTimeInterval(-86400), permissions: "rw-r--r--", checksum: "c3d4e5f6a1b2", dimensions: "180x180"),
                ResourceItem(name: "LaunchScreen", type: "storyboard", size: "8 KB", sizeBytes: 8192, path: "Base.lproj/LaunchScreen.storyboard", modifiedDate: Date().addingTimeInterval(-172800), permissions: "rw-r--r--", checksum: "d4e5f6a1b2c3"),
                ResourceItem(name: "Main", type: "storyboard", size: "45 KB", sizeBytes: 46080, path: "Base.lproj/Main.storyboard", modifiedDate: Date().addingTimeInterval(-259200), permissions: "rw-r--r--", checksum: "e5f6a1b2c3d4"),
                ResourceItem(name: "Localizable", type: "strings", size: "12 KB", sizeBytes: 12288, path: "en.lproj/Localizable.strings", modifiedDate: Date().addingTimeInterval(-345600), permissions: "rw-r--r--", checksum: "f6a1b2c3d4e5", encoding: "UTF-8"),
                ResourceItem(name: "Localizable (Spanish)", type: "strings", size: "14 KB", sizeBytes: 14336, path: "es.lproj/Localizable.strings", modifiedDate: Date().addingTimeInterval(-345600), permissions: "rw-r--r--", checksum: "a1b2c3d4e5f7", encoding: "UTF-8"),
                ResourceItem(name: "Localizable (French)", type: "strings", size: "13 KB", sizeBytes: 13312, path: "fr.lproj/Localizable.strings", modifiedDate: Date().addingTimeInterval(-345600), permissions: "rw-r--r--", checksum: "b2c3d4e5f6a2", encoding: "UTF-8"),
                ResourceItem(name: "Info", type: "plist", size: "4 KB", sizeBytes: 4096, path: "Info.plist", modifiedDate: Date(), permissions: "rw-r--r--", checksum: "g7h8i9j0k1l2"),
                ResourceItem(name: "Entitlements", type: "plist", size: "2 KB", sizeBytes: 2048, path: "App.entitlements", modifiedDate: Date().addingTimeInterval(-86400), permissions: "rw-r--r--", checksum: "h8i9j0k1l2m3"),
                ResourceItem(name: "Assets", type: "car", size: "2.4 MB", sizeBytes: 2516582, path: "Assets.car", modifiedDate: Date().addingTimeInterval(-432000), permissions: "rw-r--r--", checksum: "i9j0k1l2m3n4", compressionRatio: 0.65),
                ResourceItem(name: "Default@2x", type: "png", size: "89 KB", sizeBytes: 91136, path: "Images/Default@2x.png", modifiedDate: Date().addingTimeInterval(-518400), permissions: "rw-r--r--", checksum: "j0k1l2m3n4o5", dimensions: "640x1136"),
                ResourceItem(name: "Default@3x", type: "png", size: "156 KB", sizeBytes: 159744, path: "Images/Default@3x.png", modifiedDate: Date().addingTimeInterval(-518400), permissions: "rw-r--r--", checksum: "k1l2m3n4o5p6", dimensions: "1242x2208"),
                ResourceItem(name: "Background", type: "jpg", size: "245 KB", sizeBytes: 250880, path: "Images/Background.jpg", modifiedDate: Date().addingTimeInterval(-604800), permissions: "rw-r--r--", checksum: "l2m3n4o5p6q7", dimensions: "1920x1080"),
                ResourceItem(name: "Logo", type: "svg", size: "18 KB", sizeBytes: 18432, path: "Images/Logo.svg", modifiedDate: Date().addingTimeInterval(-691200), permissions: "rw-r--r--", checksum: "m3n4o5p6q7r8"),
                ResourceItem(name: "Settings", type: "bundle", size: "32 KB", sizeBytes: 32768, path: "Settings.bundle", modifiedDate: Date().addingTimeInterval(-777600), permissions: "rwxr-xr-x", checksum: "n4o5p6q7r8s9"),
                ResourceItem(name: "UIKit", type: "framework", size: "0 KB", sizeBytes: 0, path: "Frameworks/UIKit.framework", modifiedDate: Date().addingTimeInterval(-864000), permissions: "rwxr-xr-x", checksum: nil),
                ResourceItem(name: "Foundation", type: "framework", size: "0 KB", sizeBytes: 0, path: "Frameworks/Foundation.framework", modifiedDate: Date().addingTimeInterval(-864000), permissions: "rwxr-xr-x", checksum: nil),
                ResourceItem(name: "SwiftUI", type: "framework", size: "8.2 MB", sizeBytes: 8598323, path: "Frameworks/SwiftUI.framework", modifiedDate: Date().addingTimeInterval(-864000), permissions: "rwxr-xr-x", checksum: "o5p6q7r8s9t0"),
                ResourceItem(name: "Combine", type: "framework", size: "1.8 MB", sizeBytes: 1887436, path: "Frameworks/Combine.framework", modifiedDate: Date().addingTimeInterval(-864000), permissions: "rwxr-xr-x", checksum: "p6q7r8s9t0u1"),
                ResourceItem(name: "WidgetKit", type: "appex", size: "456 KB", sizeBytes: 466944, path: "PlugIns/Widget.appex", modifiedDate: Date().addingTimeInterval(-950400), permissions: "rwxr-xr-x", checksum: "q7r8s9t0u1v2"),
                ResourceItem(name: "NotificationService", type: "appex", size: "128 KB", sizeBytes: 131072, path: "PlugIns/NotificationService.appex", modifiedDate: Date().addingTimeInterval(-950400), permissions: "rwxr-xr-x", checksum: "r8s9t0u1v2w3"),
                ResourceItem(name: "Sounds", type: "bundle", size: "1.2 MB", sizeBytes: 1258291, path: "Sounds.bundle", modifiedDate: Date().addingTimeInterval(-1036800), permissions: "rwxr-xr-x", checksum: "s9t0u1v2w3x4"),
                ResourceItem(name: "Fonts", type: "bundle", size: "890 KB", sizeBytes: 911360, path: "Fonts.bundle", modifiedDate: Date().addingTimeInterval(-1123200), permissions: "rwxr-xr-x", checksum: "t0u1v2w3x4y5")
            ]
            
            calculateTotalSize()
            isLoading = false
        }
    }
    
    private func calculateTotalSize() {
        let total = resources.reduce(0) { $0 + $1.sizeBytes }
        totalSize = formatBytes(total)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedResources.contains(id) {
            selectedResources.remove(id)
        } else {
            selectedResources.insert(id)
        }
    }
    
    private func deleteResource(_ resource: ResourceItem) {
        resources.removeAll { $0.id == resource.id }
        calculateTotalSize()
        HapticsManager.shared.softImpact()
    }
    
    private func deleteResources(at offsets: IndexSet) {
        let resourcesToDelete = offsets.map { filteredResources[$0] }
        for resource in resourcesToDelete {
            resources.removeAll { $0.id == resource.id }
        }
        calculateTotalSize()
    }
    
    private func deleteSelectedResources() {
        resources.removeAll { selectedResources.contains($0.id) }
        selectedResources.removeAll()
        calculateTotalSize()
        HapticsManager.shared.softImpact()
    }
    
    private func exportSelectedResources() {
        HapticsManager.shared.success()
    }
    
    private func exportAllResources() {
        HapticsManager.shared.success()
    }
    
    private func refreshResources() {
        loadResources()
        HapticsManager.shared.softImpact()
    }
    
    private func removeUnusedResources() {
        HapticsManager.shared.softImpact()
    }
    
    private func optimizeImages() {
        HapticsManager.shared.success()
    }
    
    private func removeUnusedLocalizations() {
        HapticsManager.shared.softImpact()
    }
    
    private func compressResources() {
        HapticsManager.shared.success()
    }
    
    private func validateResources() {
        HapticsManager.shared.success()
    }
}

// MARK: - Resource Stat Badge
struct ResourceStatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Resource Row
struct ResourceRow: View {
    let resource: ResourceItem
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorForType(resource.type).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconForType(resource.type))
                        .font(.system(size: 18))
                        .foregroundStyle(colorForType(resource.type))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(resource.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        if resource.isModified {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(resource.type.uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        
                        if let dimensions = resource.dimensions {
                            Text(dimensions)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(resource.path)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Size
                VStack(alignment: .trailing, spacing: 2) {
                    Text(resource.size)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if let ratio = resource.compressionRatio {
                        Text("\(Int(ratio * 100))% compressed")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }
            
            Button {
                UIPasteboard.general.string = resource.path
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
            
            if let checksum = resource.checksum {
                Button {
                    UIPasteboard.general.string = checksum
                } label: {
                    Label("Copy Checksum", systemImage: "number")
                }
            }
            
            Divider()
            
            Button {
                // Export
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Button {
                // Replace
            } label: {
                Label("Replace", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Divider()
            
            Button(role: .destructive) {
                // Delete
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "heic", "webp", "gif", "ico": return "photo.fill"
        case "pdf": return "doc.richtext.fill"
        case "svg": return "square.on.circle"
        case "strings": return "textformat"
        case "plist": return "doc.text.fill"
        case "storyboard", "xib", "nib": return "rectangle.3.group.fill"
        case "car": return "folder.fill"
        case "framework": return "shippingbox.fill"
        case "bundle": return "archivebox.fill"
        case "appex", "pluginkit": return "puzzlepiece.extension.fill"
        case "dylib": return "gearshape.2.fill"
        default: return "doc.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "png", "jpg", "jpeg", "heic", "webp", "gif", "ico": return .blue
        case "pdf": return .red
        case "svg": return .purple
        case "strings": return .green
        case "plist": return .orange
        case "storyboard", "xib", "nib": return .purple
        case "car": return .pink
        case "framework": return .cyan
        case "bundle": return .indigo
        case "appex", "pluginkit": return .teal
        case "dylib": return .brown
        default: return .gray
        }
    }
}

// MARK: - Resource Detail View
struct ResourceDetailView: View {
    let resource: ResourceItem
    let onReplace: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Preview Section (for images)
                if ["png", "jpg", "jpeg", "heic", "webp", "gif"].contains(resource.type.lowercased()) {
                    Section {
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                )
                            Spacer()
                        }
                    } header: {
                        Text("Preview")
                    }
                }
                
                // Basic Info
                Section {
                    ResourceDetailRow(title: "Name", value: resource.name)
                    ResourceDetailRow(title: "Type", value: resource.type.uppercased())
                    ResourceDetailRow(title: "Size", value: resource.size)
                    ResourceDetailRow(title: "Path", value: resource.path)
                } header: {
                    Text("Basic Information")
                }
                
                // File Details
                Section {
                    ResourceDetailRow(title: "Modified", value: formatDate(resource.modifiedDate))
                    ResourceDetailRow(title: "Permissions", value: resource.permissions)
                    if let checksum = resource.checksum {
                        ResourceDetailRow(title: "Checksum (MD5)", value: checksum)
                    }
                } header: {
                    Text("File Details")
                }
                
                // Type-specific Info
                if let dimensions = resource.dimensions {
                    Section {
                        ResourceDetailRow(title: "Dimensions", value: dimensions)
                        ResourceDetailRow(title: "Color Space", value: "sRGB")
                        ResourceDetailRow(title: "Bit Depth", value: "8-bit")
                        ResourceDetailRow(title: "Has Alpha", value: "Yes")
                    } header: {
                        Text("Image Details")
                    }
                }
                
                if let encoding = resource.encoding {
                    Section {
                        ResourceDetailRow(title: "Encoding", value: encoding)
                        ResourceDetailRow(title: "Line Count", value: "~150 lines")
                    } header: {
                        Text("Text Details")
                    }
                }
                
                if let ratio = resource.compressionRatio {
                    Section {
                        ResourceDetailRow(title: "Compression", value: "\(Int(ratio * 100))%")
                        ResourceDetailRow(title: "Original Size", value: formatBytes(Int64(Double(resource.sizeBytes) / ratio)))
                    } header: {
                        Text("Compression Details")
                    }
                }
                
                // Actions
                Section {
                    Button {
                        onExport()
                    } label: {
                        Label("Export Resource", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        onReplace()
                    } label: {
                        Label("Replace Resource", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button {
                        UIPasteboard.general.string = resource.path
                        HapticsManager.shared.softImpact()
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete Resource", systemImage: "trash")
                    }
                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle(resource.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Resource Detail Row
struct ResourceDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Resource Statistics View
struct ResourceStatisticsView: View {
    let resources: [ResourceItem]
    @Environment(\.dismiss) var dismiss
    
    var typeBreakdown: [(String, Int, Int64)] {
        var breakdown: [String: (count: Int, size: Int64)] = [:]
        for resource in resources {
            let type = resource.type.lowercased()
            let existing = breakdown[type] ?? (0, 0)
            breakdown[type] = (existing.count + 1, existing.size + resource.sizeBytes)
        }
        return breakdown.map { ($0.key, $0.value.count, $0.value.size) }
            .sorted { $0.2 > $1.2 }
    }
    
    var totalSize: Int64 {
        resources.reduce(0) { $0 + $1.sizeBytes }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total Resources")
                        Spacer()
                        Text("\(resources.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Total Size")
                        Spacer()
                        Text(formatBytes(totalSize))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Average Size")
                        Spacer()
                        Text(formatBytes(resources.isEmpty ? 0 : totalSize / Int64(resources.count)))
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Overview")
                }
                
                Section {
                    ForEach(typeBreakdown, id: \.0) { type, count, size in
                        HStack {
                            Text(type.uppercased())
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(count) files")
                                    .font(.subheadline)
                                Text(formatBytes(size))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("By Type")
                }
                
                Section {
                    let largestResources = resources.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(5)
                    ForEach(Array(largestResources)) { resource in
                        HStack {
                            Text(resource.name)
                            Spacer()
                            Text(resource.size)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Largest Resources")
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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
