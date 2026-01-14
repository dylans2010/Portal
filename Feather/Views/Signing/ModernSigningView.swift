import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - Modern Full Screen Signing View
struct ModernSigningView: View {
    @Environment(\.dismiss) var dismiss
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
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color(UIColor.systemBackground),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with app info
                    headerSection
                        .scaleEffect(_headerScale)
                        .opacity(_contentOpacity)
                    
                    // Tab selector
                    tabSelector
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
                    
                    // Sign button
                    signButton
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
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
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
                    if let icon = appIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        FRAppIconView(app: app, size: 80)
                    }
                    
                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.accentColor))
                                .offset(x: 4, y: 4)
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                .shadow(color: Color.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 4) {
                Text(_temporaryOptions.appName ?? app.name ?? "Unknown")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(_temporaryOptions.appIdentifier ?? app.identifier ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tab Selector
    @ViewBuilder
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(index: 0)
            tabButton(index: 1)
            tabButton(index: 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let isSelected = _selectedTab == index
        let iconName = tabIcon(for: index)
        let title = tabTitle(for: index)
        
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                _selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "paintbrush.fill"
        case 1: return "signature"
        case 2: return "gearshape.fill"
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
                // App Details Card
                VStack(spacing: 0) {
                    infoRow(title: "Name", value: _temporaryOptions.appName ?? app.name, icon: "pencil") {
                        _isNameDialogPresenting = true
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    infoRow(title: "Bundle ID", value: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode") {
                        _isIdentifierDialogPresenting = true
                    }
                    
                    Divider().padding(.leading, 52)
                    
                    infoRow(title: "Version", value: _temporaryOptions.appVersion ?? app.version, icon: "tag") {
                        _isVersionDialogPresenting = true
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private func infoRow(title: String, value: String?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(value ?? "Not Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
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
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cert.nickname ?? "Certificate")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if let expiration = cert.expiration {
                                    Text("Expires: \(expiration, style: .date)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("View Details")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                } else {
                    // No certificate
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(spacing: 4) {
                            Text("No Certificate")
                                .font(.headline)
                            Text("Add a certificate to sign apps.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(24)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            VStack(spacing: 16) {
                // Signing Options
                NavigationLink {
                    ModernSigningOptionsView(options: $_temporaryOptions)
                } label: {
                    advancedRow(title: "Signing Options", icon: "gearshape.2", color: .accentColor)
                }
                
                NavigationLink {
                    SigningDylibView(app: app, options: $_temporaryOptions.optional())
                } label: {
                    advancedRow(title: "Existing Dylibs", icon: "puzzlepiece", color: .purple)
                }
                
                NavigationLink {
                    SigningFrameworksView(app: app, options: $_temporaryOptions.optional())
                } label: {
                    advancedRow(title: "Frameworks & Plugins", icon: "cube.box", color: .blue)
                }
                
                NavigationLink {
                    SigningTweaksView(options: $_temporaryOptions)
                } label: {
                    advancedRow(title: "Inject Tweaks", icon: "wrench.and.screwdriver", color: .green)
                }
                
                #if NIGHTLY || DEBUG
                NavigationLink {
                    SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile)
                } label: {
                    advancedRow(title: "Entitlements (BETA)", icon: "lock.shield", color: .orange)
                }
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private func advancedRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Sign Button
    @ViewBuilder
    private var signButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground).opacity(0),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            Button {
                _start()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "signature")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Sign App")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color(UIColor.systemBackground))
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
        ScrollView {
            VStack(spacing: 20) {
                // Protection Section
                optionSection(title: "Protection", icon: "shield.lefthalf.filled", color: .blue) {
                    optionToggle(
                        title: "PPQ Protection",
                        subtitle: isPPQProtectionForced ? "Required for your certificate" : "Append random string to Bundle IDs",
                        icon: "shield.checkered",
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
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.accentColor)
                            Text("What is PPQ?")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                
                // General Section
                optionSection(title: "General", icon: "gearshape.2.fill", color: .gray) {
                    optionPicker(
                        title: "Appearance",
                        icon: "paintpalette.fill",
                        selection: $options.appAppearance,
                        values: Options.AppAppearance.allCases
                    )
                    
                    optionPicker(
                        title: "Minimum Requirement",
                        icon: "ruler.fill",
                        selection: $options.minimumAppRequirement,
                        values: Options.MinimumAppRequirement.allCases
                    )
                }
                
                // Signing Section
                optionSection(title: "Signing", icon: "signature", color: .purple) {
                    optionPicker(
                        title: "Signing Type",
                        icon: "pencil.and.scribble",
                        selection: $options.signingOption,
                        values: Options.SigningOption.allCases
                    )
                }
                
                // App Features Section
                optionSection(title: "App Features", icon: "sparkles", color: .yellow) {
                    optionToggle(title: "File Sharing", subtitle: "Enable document sharing", icon: "folder.fill.badge.person.crop", isOn: $options.fileSharing)
                    optionToggle(title: "iTunes File Sharing", subtitle: "Access via iTunes/Finder", icon: "music.note.list", isOn: $options.itunesFileSharing)
                    optionToggle(title: "ProMotion", subtitle: "120Hz display support", icon: "gauge.with.dots.needle.67percent", isOn: $options.proMotion)
                    optionToggle(title: "Game Mode", subtitle: "Optimize for gaming", icon: "gamecontroller.fill", isOn: $options.gameMode)
                    optionToggle(title: "iPad Fullscreen", subtitle: "Full screen on iPad", icon: "ipad.landscape", isOn: $options.ipadFullscreen)
                }
                
                // Removal Section
                optionSection(title: "Removal", icon: "trash.slash.fill", color: .red) {
                    optionToggle(title: "Remove URL Scheme", subtitle: "Strip URL handlers", icon: "link.badge.minus", isOn: $options.removeURLScheme)
                    optionToggle(title: "Remove Provisioning", subtitle: "Exclude .mobileprovision", icon: "doc.badge.minus", isOn: $options.removeProvisioning)
                }
                
                // Localization Section
                optionSection(title: "Localization", icon: "globe.badge.chevron.backward", color: .green) {
                    optionToggle(title: "Force Localize", subtitle: "Override localized titles", icon: "character.bubble.fill", isOn: $options.changeLanguageFilesForCustomDisplayName)
                }
                
                // Post Signing Section
                optionSection(title: "Post Signing", icon: "clock.arrow.circlepath", color: .orange) {
                    optionToggle(title: "Install After Signing", subtitle: "Auto-install when done", icon: "arrow.down.circle.fill", isOn: $options.post_installAppAfterSigned)
                    optionToggle(title: "Delete After Signing", subtitle: "Remove original file", icon: "trash.fill", isOn: $options.post_deleteAppAfterSigned)
                }
                
                // Experiments Section
                optionSection(title: "Experiments", icon: "flask.fill", color: .purple) {
                    optionToggle(title: "Replace Substrate", subtitle: "Use ElleKit instead", icon: "arrow.triangle.2.circlepath.circle.fill", isOn: $options.experiment_replaceSubstrateWithEllekit)
                    optionToggle(title: "Liquid Glass", subtitle: "iOS 26 redesign support", icon: "sparkles.rectangle.stack.fill", isOn: $options.experiment_supportLiquidGlass)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemGroupedBackground))
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
        }
    }
    
    // MARK: - Section Builder
    @ViewBuilder
    private func optionSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 1) {
                content()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    // MARK: - Toggle Row
    @ViewBuilder
    private func optionToggle(title: String, subtitle: String? = nil, icon: String, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    // MARK: - Picker Row
    @ViewBuilder
    private func optionPicker<T: Hashable & LocalizedDescribable>(title: String, icon: String, selection: Binding<T>, values: [T]) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
