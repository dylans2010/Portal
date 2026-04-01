import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation
import OSLog

// MARK: - Modern Compact Certificate Add View
struct CertificatesAddView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @Namespace private var _namespace
    @AppStorage("feature_usePortalCert") private var usePortalCert = false
    @AppStorage("Feather.certificateExperience") private var _certificateExperience: String = CertificateExperience.developer.rawValue

    private var _isEnterprise: Bool {
        _certificateExperience == CertificateExperience.enterprise.rawValue
    }
    
    @State private var _selectedMethod = 0
    @State private var _p12URL: URL? = nil
    @State private var _provisionURL: URL? = nil
    @State private var _p12Password: String = ""
    @State private var _certificateName: String = ""
    @State private var _isDefault = false
    @State private var _isSaving = false
    
    @State private var _p12Done = false
    @State private var _provisionDone = false
    @State private var _zipDone = false
    @State private var _portalDone = false

    @State private var _isImportingP12Presenting = false
    @State private var _isImportingMobileProvisionPresenting = false
    @State private var _isImportingZipPresenting = false
    @State private var _isImportingPortalCertPresenting = false
    @State private var _isEnterprisePresenting = false

    @State private var _alertMessage = ""
    @State private var _showAlert = false

    var saveButtonDisabled: Bool {
        _p12URL == nil || _provisionURL == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Modern Method Picker with Enhanced Design
                            HStack(spacing: 0) {
                                methodButton(title: "Manual", icon: "hand.tap.fill", tag: 0)
                                methodButton(title: "Portal Cert", icon: "shippingbox.fill", tag: 1, disabled: !usePortalCert)
                                methodButton(title: "ZIP File", icon: "doc.zipper", tag: 2)
                                if _isEnterprise {
                                    enterpriseMethodButton
                                }
                            }
                            .padding(6)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal)

                            if _selectedMethod == 0 {
                                manualFilesSection
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            } else if _selectedMethod == 1 {
                                portalCertSection
                                    .transition(.opacity)
                            } else {
                                zipSection
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(themeManager.accentColor)
                                    Text("Configuration")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.leading, 8)

                                VStack(spacing: 0) {
                                    passwordFieldSection
                                    Divider().padding(.leading, 44)
                                    nicknameFieldSection
                                    Divider().padding(.leading, 44)
                                    defaultSection
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
                                )
                            }
                            .padding(.horizontal)

                            saveButton
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .globalTheme()
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $_isImportingP12Presenting) {
                FileImporterRepresentableView(allowedContentTypes: [.p12]) { urls in
                    if let url = urls.first {
                        withAnimation {
                            self._p12URL = url
                            self._p12Done = true
                        }
                        HapticsManager.shared.softImpact()
                    }
                    _isImportingP12Presenting = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingMobileProvisionPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.mobileProvision]) { urls in
                    if let url = urls.first {
                        withAnimation {
                            self._provisionURL = url
                            self._provisionDone = true
                        }
                        HapticsManager.shared.softImpact()
                    }
                    _isImportingMobileProvisionPresenting = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingZipPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.certificateZip]) { urls in
                    if let url = urls.first {
                        _handleZipImport(url)
                    }
                    _isImportingZipPresenting = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingPortalCertPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.portalCert, .data]) { urls in
                    if let url = urls.first {
                        portalCertImportSheet_picked(url)
                    }
                    _isImportingPortalCertPresenting = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isEnterprisePresenting) {
                CertificateEnterpriseView()
            }
            .alert(.localized("Certificate"), isPresented: $_showAlert) {
                Button(.localized("OK"), role: .cancel) { }
            } message: {
                Text(_alertMessage)
            }
        }
    }
    
    // MARK: - Sections
    private var manualFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certificate Files")
                .font(.subheadline.bold())
                .themedText(.secondary)
                .padding(.leading, 8)

            VStack(spacing: 0) {
                fileRowModern(title: "Certificate (.p12)", subtitle: _p12URL?.lastPathComponent, icon: "key.fill", color: .orange, isDone: _p12Done) {
                    _isImportingP12Presenting = true
                }
                Divider().padding(.leading, 56)
                fileRowModern(title: "Provisioning Profile", subtitle: _provisionURL?.lastPathComponent, icon: "doc.badge.gearshape.fill", color: .blue, isDone: _provisionDone) {
                    _isImportingMobileProvisionPresenting = true
                }
            }
            .themedCard()
        }
        .padding(.horizontal)
    }
    
    private var portalCertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portal Certificate")
                .font(.subheadline.bold())
                .themedText(.secondary)
                .padding(.leading, 8)

            if usePortalCert {
                fileRowModern(title: "Import .portalcert", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "shippingbox.fill", color: .purple, isDone: _portalDone) {
                    _isImportingPortalCertPresenting = true
                }
                .themedCard()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple.gradient)

                    Text("Portal Cert Coming Soon")
                        .font(.headline)
                        .themedText(.primary)

                    Text("This feature is currently in development and will be available in a future update.")
                        .font(.caption)
                        .themedText(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .themedCard()
            }
        }
        .padding(.horizontal)
    }
    
    private var zipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Archive Import")
                .font(.subheadline.bold())
                .themedText(.secondary)
                .padding(.leading, 8)

            fileRowModern(title: "Import ZIP", subtitle: _p12URL != nil ? "Files Extracted" : "Contains .p12 & .mobileprovision", icon: "doc.zipper", color: .green, isDone: _zipDone) {
                _isImportingZipPresenting = true
            }
            .themedCard()
        }
        .padding(.horizontal)
    }
    
    private var passwordFieldSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .frame(width: 24)
                .foregroundStyle(themeManager.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Password")
                    .font(.caption.bold())
                    .themedText(.secondary)

                SecureField("Required if certificate is encrypted", text: $_p12Password)
                    .font(.subheadline)
                    .themedText(.primary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
    }

    private var nicknameFieldSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "tag.fill")
                .font(.system(size: 18))
                .frame(width: 24)
                .foregroundStyle(themeManager.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nickname")
                    .font(.caption.bold())
                    .themedText(.secondary)

                TextField("Custom name for this certificate", text: $_certificateName)
                    .font(.subheadline)
                    .themedText(.primary)
            }
        }
        .padding(16)
    }

    private var defaultSection: some View {
        Toggle(isOn: $_isDefault) {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .frame(width: 24)
                    .foregroundStyle(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set As Default")
                        .font(.subheadline.bold())
                        .themedText(.primary)
                    Text("Auto-select for signing")
                        .font(.caption2)
                        .themedText(.secondary)
                }
            }
        }
        .themedAccent()
        .padding(16)
    }
    
    private var saveButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { _isSaving = true }
            _saveCertificate()
        } label: {
            HStack(spacing: 14) {
                if _isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .symbolEffect(.bounce, value: _isSaving)
                }
                Text(_isSaving ? "Validating Certificate..." : "Add Certificate")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(saveButtonDisabled || _isSaving ? Color.gray.gradient : themeManager.accentColor.gradient)
                    .shadow(color: (saveButtonDisabled || _isSaving ? Color.gray : themeManager.accentColor).opacity(0.4), radius: 12, y: 6)
            )
            .foregroundStyle(Color(hex: themeManager.resolvedColors.buttonText))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(saveButtonDisabled || _isSaving)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: _isSaving)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: saveButtonDisabled)
    }

    // MARK: - Helper Views
    private func methodButton(title: String, icon: String, tag: Int, disabled: Bool = false) -> some View {
        let isSelected = _selectedMethod == tag
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                _selectedMethod = tag
            }
            HapticsManager.shared.softImpact()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .matchedGeometryEffect(id: "methodBackground", in: _namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }

    private var enterpriseMethodButton: some View {
        Button {
            HapticsManager.shared.softImpact()
            _isEnterprisePresenting = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 12))
                Text("Enterprise")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private func fileRowModern(title: String, subtitle: String?, icon: String, color: Color, isDone: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeManager.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .themedText(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .themedText(.secondary)
                            .lineLimit(1)
                            .transition(.opacity)
                    } else {
                        Text("Tap to select file")
                            .font(.caption)
                            .themedText(.secondary)
                            .opacity(0.6)
                    }
                }

                Spacer()

                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(themeManager.accentColor)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.3))
                        .transition(.opacity)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDone)
        .animation(.spring(), value: subtitle)
    }

    // MARK: - Handle Portal Cert Import
    private func _handlePortalCertImport(_ url: URL) {
        Logger.misc.info("[PortalCert Import] Starting import from: \(url.lastPathComponent)")
        
        do {
            let (p12URL, provisionURL, metadata) = try PortalCertHandler.extractPortalCert(from: url)
            
            let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-import-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)
            
            let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
            let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)
            
            try FileManager.default.copyItem(at: p12URL, to: newP12URL)
            try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)
            
            withAnimation {
                _p12URL = newP12URL
                _provisionURL = newProvisionURL

                if let nickname = metadata.nickname {
                    _certificateName = nickname
                }

                _portalDone = true
            }
            
            HapticsManager.shared.success()
            
        } catch let error as PortalCertHandler.PortalCertError {
            Task { @MainActor in
                _alertMessage = error.localizedDescription
                _showAlert = true
            }
        } catch {
            Task { @MainActor in
                _alertMessage = .localized("Failed to import .portalcert file: \(error.localizedDescription)")
                _showAlert = true
            }
        }
    }
    
    private func portalCertImportSheet_picked(_ url: URL) {
        Task.detached {
            await _handlePortalCertImport(url)
        }
    }
}

// MARK: - Extension: View (import)
extension CertificatesAddView {
        private func _saveCertificate() {
        guard let p12URL = _p12URL, let provisionURL = _provisionURL else { return }

        Task.detached {
            // Perform password check in background
            let isPasswordCorrect = await FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)

            await MainActor.run {
                if !isPasswordCorrect {
                    withAnimation { _isSaving = false }
                    _alertMessage = .localized("The password you entered is wrong, please try again to add this certificate. If the password from this certificate is WSF, restart Portal and try again.")
                    _showAlert = true
                    return
                }

                // Continue with saving
                FR.handleCertificateFiles(
                    p12URL: p12URL,
                    provisionURL: provisionURL,
                    p12Password: _p12Password,
                    certificateName: _certificateName,
                    isDefault: _isDefault
                ) { error in
                    Task { @MainActor in
                        if let error = error {
                            _alertMessage = error.localizedDescription
                            _showAlert = true
                        } else {
                            HapticsManager.shared.success()
                            dismiss()
                        }
                        _isSaving = false
                    }
                }
            }
        }
        }
        
        private func _handleZipImport(_ zipURL: URL) {
        Task.detached {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: zipURL, to: tempDir)

                var foundP12: URL?
                var foundProvision: URL?

                func searchDirectory(_ directory: URL) throws {
                    let items = try FileManager.default.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsHiddenFiles]
                    )

                    for item in items {
                        let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
                        if resourceValues.isDirectory == true {
                            try searchDirectory(item)
                        } else {
                            let ext = item.pathExtension.lowercased()
                            if ext == "p12" && foundP12 == nil {
                                foundP12 = item
                            } else if ext == "mobileprovision" && foundProvision == nil {
                                foundProvision = item
                            }
                        }
                    }
                }

                try searchDirectory(tempDir)

                guard let p12URL = foundP12, let provisionURL = foundProvision else {
                    var missingFiles: [String] = []
                    if foundP12 == nil { missingFiles.append(".p12") }
                    if foundProvision == nil { missingFiles.append(".mobileprovision") }
                    throw CertificateImportError.missingCertificateFiles(missingFiles.joined(separator: " and "))
                }

                let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("certificates-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)

                let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
                let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)

                try FileManager.default.copyItem(at: p12URL, to: newP12URL)
                try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)

                await MainActor.run {
                    withAnimation {
                        _p12URL = newP12URL
                        _provisionURL = newProvisionURL
                        _zipDone = true
                    }
                    HapticsManager.shared.success()
                }

                try? FileManager.default.removeItem(at: tempDir)

            } catch let error as CertificateImportError {
                try? FileManager.default.removeItem(at: tempDir)
                await MainActor.run {
                    _alertMessage = error.localizedDescription
                    _showAlert = true
                }
            } catch {
                try? FileManager.default.removeItem(at: tempDir)
                await MainActor.run {
                    _alertMessage = .localized("Failed to extract ZIP file: \(error.localizedDescription)")
                    _showAlert = true
                }
            }
        }
        }
}

// MARK: - Certificate Import Errors
enum CertificateImportError: LocalizedError {
        case invalidZipFile
        case missingCertificateFiles(String)
        case extractionFailed
        
        var errorDescription: String? {
                switch self {
                case .invalidZipFile:
                        return NSLocalizedString("The selected file is not a valid ZIP archive.", comment: "")
                case .missingCertificateFiles(let files):
                        return String(format: NSLocalizedString("Cannot find certificate files in uploaded ZIP. Missing: %@", comment: ""), files)
                case .extractionFailed:
                        return NSLocalizedString("Failed to extract the ZIP file. The file may be corrupted or password protected.", comment: "")
                }
        }
}
