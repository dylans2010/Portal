import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - Modern Full Screen Signing View
struct ModernSigningView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
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
                    // Header with app info
                    headerSection
                        .scaleEffect(_headerScale)
                        .opacity(_contentOpacity)
                    
                    // Modern tab selector with glass effect
                    modernTabSelector
                        .opacity(_contentOpacity)
                    
                    // Content based on selected tab
                    TabView(selection: $_selectedTab) {
                        customizationTab
                            .tag(0)
                        
                        signingTab
                            .tag(1)
                        
                        advancedTab
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .opacity(_contentOpacity)
                    
                    // Modern sign button
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
    
    // MARK: - Modern Background
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.15),
                    Color.accentColor.opacity(0.05),
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated floating orbs
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: _floatingAnimation ? -50 : 50, y: _floatingAnimation ? -30 : 30)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.15)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.2), Color.purple.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: _floatingAnimation ? 40 : -40, y: _floatingAnimation ? 20 : -20)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
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
    
    // MARK: - Modern Tab Selector
    @ViewBuilder
    private var modernTabSelector: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                modernTabButton(index: index)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func modernTabButton(index: Int) -> some View {
        let isSelected = _selectedTab == index
        let iconName = tabIcon(for: index)
        let title = tabTitle(for: index)
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                _selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .modifier(BounceEffectModifier(trigger: isSelected))
                Text(title)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "paintbrush.fill"
        case 1: return "signature"
        case 2: return "gearshape.2.fill"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Customize"
        case 1: return "Signing"
        case 2: return "Advanced"
        default: return ""
        }
    }
    
    // MARK: - Customization Tab
    @ViewBuilder
    private var customizationTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Details Card with glass effect
                VStack(spacing: 0) {
                    modernInfoRow(title: "Name", value: _temporaryOptions.appName ?? app.name, icon: "textformat", color: .blue) {
                        _isNameDialogPresenting = true
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 56)
                    
                    modernInfoRow(title: "Bundle ID", value: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode", color: .purple) {
                        _isIdentifierDialogPresenting = true
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 56)
                    
                    modernInfoRow(title: "Version", value: _temporaryOptions.appVersion ?? app.version, icon: "tag.fill", color: .orange) {
                        _isVersionDialogPresenting = true
                    }
                }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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
                                        Text("Expires: \(expiration, style: .date)")
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
                        modernAdvancedRow(title: "Existing Dylibs", subtitle: "Manage dynamic libraries", icon: "puzzlepiece.extension.fill", color: .purple)
                    }
                    
                    NavigationLink {
                        SigningFrameworksView(app: app, options: $_temporaryOptions.optional())
                    } label: {
                        modernAdvancedRow(title: "Frameworks & Plugins", subtitle: "Add or remove frameworks", icon: "cube.fill", color: .blue)
                    }
                    
                    NavigationLink {
                        SigningTweaksView(options: $_temporaryOptions)
                    } label: {
                        modernAdvancedRow(title: "Inject Tweaks", subtitle: "Add custom modifications", icon: "wrench.and.screwdriver.fill", color: .green, isLast: true)
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
                    modernAdvancedRow(title: "Entitlements", subtitle: "Edit app entitlements", icon: "lock.shield.fill", color: .orange, isFirst: true, isLast: true, isBeta: true)
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
        VStack(spacing: 0) {
            // Fade gradient at top
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground).opacity(0),
                    Color(UIColor.systemBackground).opacity(0.8),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            
            Button {
                _start()
            } label: {
                ZStack {
                    // Animated glow behind button
                    Capsule()
                        .fill(Color.accentColor.opacity(_glowAnimation ? 0.5 : 0.3))
                        .blur(radius: 20)
                        .scaleEffect(_glowAnimation ? 1.05 : 1.0)
                        .padding(.horizontal, 10)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "signature")
                            .font(.system(size: 18, weight: .bold))
                            .modifier(PulseEffectModifier(trigger: _glowAnimation))
                        Text("Sign App")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            // Main gradient
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.9),
                                    Color.accentColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Shine effect
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .white.opacity(0),
                                    .white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                Color(UIColor.systemBackground)
                    .opacity(0.9)
            )
        }
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
                            subtitle: isPPQProtectionForced ? "Required for your certificate" : "Append random string to Bundle IDs",
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
                        modernOptionToggle(title: "File Sharing", subtitle: "Enable document sharing", icon: "folder.fill.badge.person.crop", color: .blue, isOn: $options.fileSharing)
                        modernOptionToggle(title: "iTunes File Sharing", subtitle: "Access via iTunes/Finder", icon: "music.note.list", color: .pink, isOn: $options.itunesFileSharing)
                        modernOptionToggle(title: "ProMotion", subtitle: "120Hz display support", icon: "gauge.with.dots.needle.67percent", color: .green, isOn: $options.proMotion)
                        modernOptionToggle(title: "Game Mode", subtitle: "Optimize for gaming", icon: "gamecontroller.fill", color: .purple, isOn: $options.gameMode)
                        modernOptionToggle(title: "iPad Fullscreen", subtitle: "Full screen on iPad", icon: "ipad.landscape", color: .orange, isOn: $options.ipadFullscreen)
                    }
                    
                    // Removal Section
                    modernOptionSection(title: "Removal", icon: "trash.slash.fill", color: .red) {
                        modernOptionToggle(title: "Remove URL Scheme", subtitle: "Strip URL handlers", icon: "link.badge.minus", color: .red, isOn: $options.removeURLScheme)
                        modernOptionToggle(title: "Remove Provisioning", subtitle: "Exclude .mobileprovision", icon: "doc.badge.minus", color: .orange, isOn: $options.removeProvisioning)
                    }
                    
                    // Localization Section
                    modernOptionSection(title: "Localization", icon: "globe.badge.chevron.backward", color: .green) {
                        modernOptionToggle(title: "Force Localize", subtitle: "Override localized titles", icon: "character.bubble.fill", color: .green, isOn: $options.changeLanguageFilesForCustomDisplayName)
                    }
                    
                    // Post Signing Section
                    modernOptionSection(title: "Post Signing", icon: "clock.arrow.circlepath", color: .orange) {
                        modernOptionToggle(title: "Install After Signing", subtitle: "Auto-install when done", icon: "arrow.down.circle.fill", color: .green, isOn: $options.post_installAppAfterSigned)
                        modernOptionToggle(title: "Delete After Signing", subtitle: "Remove original file", icon: "trash.fill", color: .red, isOn: $options.post_deleteAppAfterSigned)
                    }
                    
                    // Experiments Section
                    modernOptionSection(title: "Experiments", icon: "flask.fill", color: .purple, isBeta: true) {
                        modernOptionToggle(title: "Replace Substrate", subtitle: "Use ElleKit instead", icon: "arrow.triangle.2.circlepath.circle.fill", color: .cyan, isOn: $options.experiment_replaceSubstrateWithEllekit)
                        modernOptionToggle(title: "Liquid Glass", subtitle: "iOS 26 redesign support", icon: "sparkles.rectangle.stack.fill", color: .purple, isOn: $options.experiment_supportLiquidGlass)
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
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
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
