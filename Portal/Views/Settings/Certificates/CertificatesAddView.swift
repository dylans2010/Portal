import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation
import OSLog

// MARK: - Modern Compact Certificate Add View
struct CertificatesAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var _namespace
    @AppStorage("feature_usePortalCert") private var usePortalCert = false
    
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
    
    @State private var _alertMessage = ""
    @State private var _showAlert = false

    var saveButtonDisabled: Bool {
        _p12URL == nil || _provisionURL == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Method Picker
                            HStack(spacing: 0) {
                                methodButton(title: "Manual", icon: "hand.tap.fill", tag: 0)
                                methodButton(title: "Portal Cert", icon: "shippingbox.fill", tag: 1, disabled: !usePortalCert)
                                methodButton(title: "ZIP File", icon: "doc.zipper", tag: 2)
                            }
                            .padding(4)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
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
                                Text("Configuration")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 8)

                                VStack(spacing: 0) {
                                    passwordFieldSection
                                    Divider().padding(.leading, 40)
                                    nicknameFieldSection
                                    Divider().padding(.leading, 40)
                                    defaultSection
                                }
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .foregroundStyle(.secondary)
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal)
    }
    
    private var portalCertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portal Certificate")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            if usePortalCert {
                fileRowModern(title: "Import .portalcert", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "shippingbox.fill", color: .purple, isDone: _portalDone) {
                    _isImportingPortalCertPresenting = true
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple.gradient)

                    Text("Portal Cert Coming Soon")
                        .font(.headline)

                    Text("This feature is currently in development and will be available in a future update.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(.horizontal)
    }
    
    private var zipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Archive Import")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            fileRowModern(title: "Import ZIP", subtitle: _p12URL != nil ? "Files Extracted" : "Contains .p12 & .mobileprovision", icon: "doc.zipper", color: .green, isDone: _zipDone) {
                _isImportingZipPresenting = true
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal)
    }
    
    private var passwordFieldSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .frame(width: 24)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Password")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                SecureField("Required if certificate is encrypted", text: $_p12Password)
                    .font(.subheadline)
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
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nickname")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextField("Custom name for this certificate", text: $_certificateName)
                    .font(.subheadline)
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
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set As Default")
                        .font(.subheadline.bold())
                    Text("Auto-select for signing")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.accentColor)
        .padding(16)
    }
    
    private var saveButton: some View {
        Button {
            withAnimation { _isSaving = true }
            _saveCertificate()
        } label: {
            HStack(spacing: 12) {
                if _isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3.bold())
                }
                Text(_isSaving ? "Validating..." : "Add Certificate")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(saveButtonDisabled || _isSaving ? Color.gray : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(saveButtonDisabled || _isSaving)
        .animation(.spring(), value: _isSaving)
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

    private func fileRowModern(title: String, subtitle: String?, icon: String, color: Color, isDone: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .transition(.opacity)
                    } else {
                        Text("Tap to select file")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }

                Spacer()

                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.3))
                        .transition(.opacity)
                }
            }
            .padding(12)
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
            _handlePortalCertImport(url)
        }
    }
}

// MARK: - Extension: View (import)
extension CertificatesAddView {
	private func _saveCertificate() {
        guard let p12URL = _p12URL, let provisionURL = _provisionURL else { return }

        Task.detached {
            // Perform password check in background
            let isPasswordCorrect = FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)

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
