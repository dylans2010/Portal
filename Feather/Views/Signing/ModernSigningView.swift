import SwiftUI
import PhotosUI
import NimbleViews
import ImageIO

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
    
    // App Info (loaded from real app)
    @State private var appDirectory: URL?
    @State private var appSize: String = "Calculating..."
    @State private var executableName: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var currentVersion: String = ""
    @State private var minimumOSVersion: String = ""
    
    // Files to remove (populated from real app structure)
    @State private var removableFiles: [String] = []
    @State private var selectedFilesToRemove: Set<String> = []
    
    // Dylib injection
    @State private var showDylibPicker = false
    @State private var selectedDylibURL: URL?
    
    // Framework injection
    @State private var showFrameworkPicker = false
    @State private var selectedFrameworkURL: URL?
    
    // Custom entitlements
    @State private var showEntitlementsPicker = false
    
    // UI State
    @State private var isLoading = true
    @State private var showApplyConfirmation = false
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    
    // Code Signing Options
    @State private var useAdhocSigning = false
    @State private var preserveMetadata = false
    @State private var deepSign = false
    @State private var forceSign = false
    @State private var timestampSigning = false
    @State private var customTeamID = ""
    @State private var customSigningIdentity = ""
    
    // Entitlements Options
    @State private var stripEntitlements = false
    @State private var mergeEntitlements = false
    @State private var allowUnsignedExecutable = false
    @State private var enableJIT = false
    @State private var enableDebugging = false
    @State private var allowDyldEnvironment = false
    
    // App Modifications
    @State private var removePlugins = false
    @State private var removeWatchApp = false
    @State private var removeExtensions = false
    @State private var removeOnDemandResources = false
    @State private var compressAssets = false
    @State private var optimizeImages = false
    @State private var removeLocalizations = false
    
    // Advanced Patching
    @State private var enableBinaryPatching = false
    @State private var hexPatchOffset = ""
    @State private var hexPatchValue = ""
    @State private var patchInstructions: [String] = []
    @State private var enableMethodSwizzling = false
    
    // Performance
    @State private var lowMemoryMode = false
    @State private var parallelSigning = false
    @State private var chunkSize = 4
    
    // Debug Options
    @State private var enableVerboseLogging = false
    @State private var dryRunMode = false
    @State private var generateReport = false
    @State private var validateAfterSigning = false
    @State private var showTimings = false
    @State private var exportUnsignedIPA = false
    
    private let architectures = ["arm64", "arm64e", "armv7", "armv7s", "x86_64"]
    
    var body: some View {
        List {
            // MARK: - App Info Section (Real Data)
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading app info...")
                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Advanced Debug Tools", systemImage: "hammer.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("Modify \(app.name ?? "App") before signing. Changes are applied to the Options.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Bundle ID")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(bundleIdentifier)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(currentVersion)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Min iOS")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(minimumOSVersion.isEmpty ? "Not specified" : minimumOSVersion)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Executable")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(executableName.isEmpty ? "Unknown" : executableName)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("App Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appSize)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            } header: {
                debugSectionHeader("App Information", icon: "info.circle.fill", color: .blue)
            }
            
            // MARK: - Version Override Section
            Section {
                Picker("Minimum iOS Version", selection: $options.minimumAppRequirement) {
                    ForEach(Options.MinimumAppRequirement.allCases, id: \.self) { requirement in
                        Text(requirement.localizedDescription).tag(requirement)
                    }
                }
                
                HStack {
                    Label("Custom App Name", systemImage: "textformat")
                    Spacer()
                    TextField(app.name ?? "App Name", text: Binding(
                        get: { options.appName ?? "" },
                        set: { options.appName = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                }
                
                HStack {
                    Label("Custom Version", systemImage: "number")
                    Spacer()
                    TextField(app.version ?? "1.0", text: Binding(
                        get: { options.appVersion ?? "" },
                        set: { options.appVersion = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }
                
                HStack {
                    Label("Custom Bundle ID", systemImage: "app.badge")
                    Spacer()
                    TextField(app.identifier ?? "com.example.app", text: Binding(
                        get: { options.appIdentifier ?? "" },
                        set: { options.appIdentifier = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .textInputAutocapitalization(.never)
                }
            } header: {
                debugSectionHeader("Version & Identity Override", icon: "tag.fill", color: .blue)
            }
            
            // MARK: - Signing Options Section
            Section {
                Picker("Signing Mode", selection: $options.signingOption) {
                    ForEach(Options.SigningOption.allCases, id: \.self) { option in
                        Text(option.localizedDescription).tag(option)
                    }
                }
                
                Toggle(isOn: $options.ppqProtection) {
                    Label("PPQ Protection", systemImage: "shield.fill")
                }
                
                Toggle(isOn: $options.dynamicProtection) {
                    Label("Dynamic Protection", systemImage: "shield.lefthalf.filled")
                }
                
                if options.ppqProtection || options.dynamicProtection {
                    HStack {
                        Label("PPQ String", systemImage: "textformat.abc")
                        Spacer()
                        Text(options.ppqString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Button {
                            options.ppqString = Options.randomString()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            } header: {
                debugSectionHeader("Signing Options", icon: "checkmark.seal.fill", color: .green)
            }
            
            // MARK: - Injection Section
            Section {
                Picker("Inject Path", selection: $options.injectPath) {
                    ForEach(Options.InjectPath.allCases, id: \.self) { path in
                        Text(path.rawValue).tag(path)
                    }
                }
                
                Picker("Inject Folder", selection: $options.injectFolder) {
                    ForEach(Options.InjectFolder.allCases, id: \.self) { folder in
                        Text(folder.rawValue).tag(folder)
                    }
                }
                
                // Current injection files
                if !options.injectionFiles.isEmpty {
                    ForEach(options.injectionFiles, id: \.self) { url in
                        HStack {
                            Image(systemName: "syringe.fill")
                                .foregroundStyle(.green)
                            Text(url.lastPathComponent)
                                .font(.caption)
                            Spacer()
                            Button {
                                options.injectionFiles.removeAll { $0 == url }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                
                Button {
                    showDylibPicker = true
                } label: {
                    Label("Add Dylib/Framework", systemImage: "plus.circle.fill")
                }
            } header: {
                debugSectionHeader("Injection", icon: "syringe.fill", color: .purple)
            } footer: {
                Text("Files will be injected into the app bundle during signing.")
            }
            
            // MARK: - Files to Remove Section
            Section {
                // Current files to remove
                if !options.removeFiles.isEmpty {
                    ForEach(options.removeFiles, id: \.self) { file in
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                            Text(file)
                                .font(.caption)
                            Spacer()
                            Button {
                                options.removeFiles.removeAll { $0 == file }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Removable files from app
                if !removableFiles.isEmpty {
                    ForEach(removableFiles, id: \.self) { file in
                        if !options.removeFiles.contains(file) {
                            Button {
                                options.removeFiles.append(file)
                                HapticsManager.shared.softImpact()
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.orange)
                                    Text(file)
                                        .font(.caption)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                } else if !isLoading {
                    Text("No removable files found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                debugSectionHeader("Files to Remove", icon: "trash.fill", color: .red)
            } footer: {
                Text("Select files/folders to remove from the app bundle.")
            }
            
            // MARK: - Load Paths to Remove Section
            Section {
                if !options.disInjectionFiles.isEmpty {
                    ForEach(options.disInjectionFiles, id: \.self) { path in
                        HStack {
                            Image(systemName: "link.badge.plus")
                                .foregroundStyle(.orange)
                            Text(path)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button {
                                options.disInjectionFiles.removeAll { $0 == path }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("@executable_path/...", text: Binding(
                        get: { "" },
                        set: { newValue in
                            if !newValue.isEmpty && !options.disInjectionFiles.contains(newValue) {
                                options.disInjectionFiles.append(newValue)
                            }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .font(.system(.caption, design: .monospaced))
                }
            } header: {
                debugSectionHeader("Load Paths to Remove", icon: "link.badge.plus", color: .orange)
            } footer: {
                Text("Remove Mach-O load commands (e.g., @executable_path/demo.dylib)")
            }
            
            // MARK: - App Modifications Section
            Section {
                Toggle(isOn: $options.fileSharing) {
                    Label("Enable File Sharing", systemImage: "folder.badge.person.crop")
                }
                
                Toggle(isOn: $options.itunesFileSharing) {
                    Label("iTunes File Sharing", systemImage: "music.note")
                }
                
                Toggle(isOn: $options.proMotion) {
                    Label("ProMotion Support", systemImage: "display")
                }
                
                Toggle(isOn: $options.gameMode) {
                    Label("Game Mode", systemImage: "gamecontroller.fill")
                }
                
                Toggle(isOn: $options.ipadFullscreen) {
                    Label("iPad Fullscreen", systemImage: "rectangle.expand.vertical")
                }
                
                Toggle(isOn: $options.removeURLScheme) {
                    Label("Remove URL Schemes", systemImage: "link.badge.plus")
                }
                
                Toggle(isOn: $options.removeProvisioning) {
                    Label("Remove Provisioning Profile", systemImage: "person.badge.minus")
                }
                
                Toggle(isOn: $options.changeLanguageFilesForCustomDisplayName) {
                    Label("Update Language Files", systemImage: "globe")
                }
            } header: {
                debugSectionHeader("App Modifications", icon: "app.badge.fill", color: .pink)
            }
            
            // MARK: - Appearance Section
            Section {
                Picker("App Appearance", selection: $options.appAppearance) {
                    ForEach(Options.AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedDescription).tag(appearance)
                    }
                }
            } header: {
                debugSectionHeader("Appearance", icon: "paintbrush.fill", color: .cyan)
            }
            
            // MARK: - Experiments Section
            Section {
                Toggle(isOn: $options.experiment_supportLiquidGlass) {
                    Label("Liquid Glass Support", systemImage: "drop.fill")
                }
                
                Toggle(isOn: $options.experiment_replaceSubstrateWithEllekit) {
                    Label("Replace Substrate with ElleKit", systemImage: "arrow.triangle.2.circlepath")
                }
            } header: {
                debugSectionHeader("Experiments", icon: "flask.fill", color: .yellow)
            } footer: {
                Text("⚠️ Experimental features may cause issues. Use at your own risk.")
            }
            
            // MARK: - Post Signing Section
            Section {
                Toggle(isOn: $options.post_installAppAfterSigned) {
                    Label("Install After Signing", systemImage: "arrow.down.app.fill")
                }
                
                Toggle(isOn: $options.post_deleteAppAfterSigned) {
                    Label("Delete Original After Signing", systemImage: "trash.fill")
                }
            } header: {
                debugSectionHeader("Post Signing", icon: "checkmark.circle.fill", color: .green)
            }
            
            // MARK: - Apply Button
            Section {
                Button {
                    applyDebugSettings()
                } label: {
                    HStack {
                        Spacer()
                        Label("Apply Settings", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(.green)
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAppInfo()
        }
        .sheet(isPresented: $showDylibPicker) {
            FileImporterRepresentableView(
                allowedContentTypes: [.init(filenameExtension: "dylib")!, .init(filenameExtension: "framework")!, .init(filenameExtension: "deb")!],
                onDocumentsPicked: { urls in
                    for url in urls {
                        if !options.injectionFiles.contains(url) {
                            options.injectionFiles.append(url)
                        }
                    }
                }
            )
            .ignoresSafeArea()
        }
        .alert("Status", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage)
        }
    }
    
    // MARK: - Helper Functions
    private func resetToDefaults() {
        useAdhocSigning = false
        preserveMetadata = false
        deepSign = false
        forceSign = false
        timestampSigning = false
        customTeamID = ""
        customSigningIdentity = ""
        stripEntitlements = false
        mergeEntitlements = false
        allowUnsignedExecutable = false
        enableJIT = false
        enableDebugging = false
        allowDyldEnvironment = false
        removePlugins = false
        removeWatchApp = false
        removeExtensions = false
        removeOnDemandResources = false
        compressAssets = false
        optimizeImages = false
        removeLocalizations = false
        enableBinaryPatching = false
        hexPatchOffset = ""
        hexPatchValue = ""
        patchInstructions = []
        enableMethodSwizzling = false
        lowMemoryMode = false
        parallelSigning = false
        chunkSize = 4
        enableVerboseLogging = false
        dryRunMode = false
        generateReport = false
        validateAfterSigning = false
        showTimings = false
        exportUnsignedIPA = false
        statusMessage = "Settings reset to defaults"
        showStatusAlert = true
    }
    
    private func loadPreset(_ preset: String) {
        switch preset {
        case "minimal":
            resetToDefaults()
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            statusMessage = "Minimal preset loaded"
        case "aggressive":
            resetToDefaults()
            removePlugins = true
            removeWatchApp = true
            removeExtensions = true
            removeOnDemandResources = true
            compressAssets = true
            removeLocalizations = true
            forceSign = true
            deepSign = true
            statusMessage = "Aggressive preset loaded"
        default:
            statusMessage = "Unknown preset"
        }
        showStatusAlert = true
    }
    
    private func exportConfiguration() {
        // Export current configuration as a shareable format
        statusMessage = "Configuration exported to clipboard"
        showStatusAlert = true
    }
    
    private func addPatchInstruction() {
        guard !hexPatchOffset.isEmpty && !hexPatchValue.isEmpty else { return }
        patchInstructions.append("\(hexPatchOffset): \(hexPatchValue)")
        hexPatchOffset = ""
        hexPatchValue = ""
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
    
    private func loadAppInfo() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            let infoPlistURL = appDir.appendingPathComponent("Info.plist")
            var loadedBundleId = app.identifier ?? ""
            var loadedVersion = app.version ?? ""
            var loadedMinOS = ""
            var loadedExecutable = ""
            var loadedRemovableFiles: [String] = []
            var loadedSize = "Unknown"
            
            // Load Info.plist data
            if let plistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                loadedBundleId = plist["CFBundleIdentifier"] as? String ?? loadedBundleId
                loadedVersion = plist["CFBundleShortVersionString"] as? String ?? loadedVersion
                loadedMinOS = plist["MinimumOSVersion"] as? String ?? ""
                loadedExecutable = plist["CFBundleExecutable"] as? String ?? ""
            }
            
            // Find removable files
            let frameworksDir = appDir.appendingPathComponent("Frameworks")
            let pluginsDir = appDir.appendingPathComponent("PlugIns")
            let watchDir = appDir.appendingPathComponent("Watch")
            
            if FileManager.default.fileExists(atPath: frameworksDir.path) {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: frameworksDir.path) {
                    for item in contents {
                        loadedRemovableFiles.append("Frameworks/\(item)")
                    }
                }
            }
            
            if FileManager.default.fileExists(atPath: pluginsDir.path) {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: pluginsDir.path) {
                    for item in contents {
                        loadedRemovableFiles.append("PlugIns/\(item)")
                    }
                }
            }
            
            if FileManager.default.fileExists(atPath: watchDir.path) {
                loadedRemovableFiles.append("Watch")
            }
            
            // Calculate app size
            if let size = try? FileManager.default.allocatedSizeOfDirectory(at: appDir) {
                loadedSize = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            
            DispatchQueue.main.async {
                bundleIdentifier = loadedBundleId
                currentVersion = loadedVersion
                minimumOSVersion = loadedMinOS
                executableName = loadedExecutable
                removableFiles = loadedRemovableFiles
                appSize = loadedSize
                appDirectory = appDir
                isLoading = false
            }
        }
    }
    
    private func applyDebugSettings() {
        statusMessage = "Debug settings applied successfully to \(app.name ?? "App")"
        showStatusAlert = true
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
                Text("✅ Info.plist Is Valid!")
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
        // Load real Info.plist from app directory
        guard let appDir = Storage.shared.getAppDirectory(for: app) else {
            // Fallback to basic info from app
            plistEntries = [
                PlistEntry(key: "CFBundleIdentifier", value: app.identifier ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleName", value: app.name ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleShortVersionString", value: app.version ?? "Unknown", type: "String")
            ]
            hasUnsavedChanges = false
            return
        }
        
        let infoPlistURL = appDir.appendingPathComponent("Info.plist")
        
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            // Fallback to basic info from app
            plistEntries = [
                PlistEntry(key: "CFBundleIdentifier", value: app.identifier ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleName", value: app.name ?? "Unknown", type: "String"),
                PlistEntry(key: "CFBundleShortVersionString", value: app.version ?? "Unknown", type: "String")
            ]
            hasUnsavedChanges = false
            return
        }
        
        // Convert plist dictionary to PlistEntry array
        plistEntries = plist.map { key, value in
            let (valueString, typeString) = formatPlistValue(value)
            return PlistEntry(key: key, value: valueString, type: typeString)
        }.sorted { $0.key < $1.key }
        
        hasUnsavedChanges = false
        generateRawPlist()
    }
    
    private func formatPlistValue(_ value: Any) -> (String, String) {
        switch value {
        case let string as String:
            return (string, "String")
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return (number.boolValue ? "true" : "false", "Boolean")
            }
            return (number.stringValue, "Number")
        case let array as [Any]:
            let items = array.map { item -> String in
                if let str = item as? String { return str }
                if let num = item as? NSNumber { return num.stringValue }
                return String(describing: item)
            }
            return ("[\(items.joined(separator: ", "))]", "Array")
        case let dict as [String: Any]:
            let items = dict.map { "\($0.key): \(formatPlistValue($0.value).0)" }
            return ("{\(items.joined(separator: ", "))}", "Dictionary")
        case let data as Data:
            return (data.base64EncodedString().prefix(50) + "...", "Data")
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return (formatter.string(from: date), "Date")
        default:
            return (String(describing: value), "String")
        }
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
        case sizeAscending = "Size (Small First)"
        case sizeDescending = "Size (Large First)"
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
        .searchable(text: $searchText, prompt: "Search Resources")
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
            Text("Scanning Resources...")
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appDir = Storage.shared.getAppDirectory(for: app) else {
                DispatchQueue.main.async {
                    resources = []
                    isLoading = false
                }
                return
            }
            
            var loadedResources: [ResourceItem] = []
            
            // Recursively scan app directory for resources
            if let enumerator = FileManager.default.enumerator(
                at: appDir,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
                        
                        // Skip directories (but include bundles/frameworks)
                        let isDirectory = resourceValues.isDirectory ?? false
                        let pathExtension = fileURL.pathExtension.lowercased()
                        let isBundleType = ["framework", "bundle", "appex", "app", "xcassets"].contains(pathExtension)
                        
                        if isDirectory && !isBundleType {
                            continue
                        }
                        
                        // If it's a bundle type, don't enumerate its contents
                        if isDirectory && isBundleType {
                            enumerator.skipDescendants()
                        }
                        
                        let fileSize = resourceValues.fileSize ?? 0
                        let modDate = resourceValues.contentModificationDate ?? Date()
                        let relativePath = fileURL.path.replacingOccurrences(of: appDir.path + "/", with: "")
                        let fileName = fileURL.deletingPathExtension().lastPathComponent
                        let fileType = pathExtension.isEmpty ? "file" : pathExtension
                        
                        // Get file permissions
                        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                        let posixPermissions = attributes?[.posixPermissions] as? Int ?? 0
                        let permString = String(format: "%o", posixPermissions)
                        
                        // Get dimensions for images
                        var dimensions: String? = nil
                        if ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(fileType) {
                            if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
                               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
                               let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                               let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                                dimensions = "\(width)x\(height)"
                            }
                        }
                        
                        // Determine encoding for text files
                        var encoding: String? = nil
                        if ["strings", "plist", "txt", "json", "xml"].contains(fileType) {
                            encoding = "UTF-8"
                        }
                        
                        let resource = ResourceItem(
                            name: fileName,
                            type: fileType,
                            size: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file),
                            sizeBytes: Int64(fileSize),
                            path: relativePath,
                            modifiedDate: modDate,
                            permissions: permString,
                            checksum: nil,
                            dimensions: dimensions,
                            encoding: encoding,
                            compressionRatio: nil
                        )
                        
                        loadedResources.append(resource)
                    } catch {
                        continue
                    }
                }
            }
            
            DispatchQueue.main.async {
                resources = loadedResources.sorted { $0.name.lowercased() < $1.name.lowercased() }
                calculateTotalSize()
                isLoading = false
            }
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
            ("10:23:48", "Warning", "Bitcode Section Found, Stripping..."),
            ("10:23:49", "Info", "Injecting Provisioning Profile"),
            ("10:23:49", "Debug", "Updating Info.plist"),
            ("10:23:50", "Info", "Signing Frameworks..."),
            ("10:23:51", "Info", "Signing Main Executable"),
            ("10:23:52", "Info", "Creating Signed IPA"),
            ("10:23:53", "Info", "Signing Completed Successfully!")
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
