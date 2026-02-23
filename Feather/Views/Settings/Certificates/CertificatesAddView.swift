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
    
    @State private var _isImportingP12Presenting = false
    @State private var _isImportingMobileProvisionPresenting = false
    @State private var _isImportingZipPresenting = false
    @State private var _isImportingPortalCertPresenting = false
    
    @State private var _addedCertificate: Certificate? = nil
    @State private var _showSuccessCard = false
    
    var saveButtonDisabled: Bool {
        _p12URL == nil || _provisionURL == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        headerSection
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }

                    Section {
                        HStack(spacing: 0) {
                            methodButton(title: "Manual", icon: "hand.tap.fill", tag: 0)
                            methodButton(title: "Portal Cert", icon: "shippingbox.fill", tag: 1, disabled: !usePortalCert)
                            methodButton(title: "ZIP File", icon: "doc.zipper", tag: 2)
                        }
                        .padding(4)
                        .background(Color(UIColor.secondarySystemFill).opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    .onChange(of: _selectedMethod) { newValue in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if newValue == 1 && !usePortalCert {
                                _selectedMethod = 0
                            }
                        }
                    }

                    Group {
                        if _selectedMethod == 0 {
                            manualFilesSection
                        } else if _selectedMethod == 1 {
                            portalCertSection
                        } else {
                            zipSection
                        }
                    }

                    Section {
                        passwordFieldSection
                        nicknameFieldSection
                        defaultSection
                    } footer: {
                        Text("Default certificate will be automatically selected when signing apps")
                    }

                    Section {
                        saveButton
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Add Certificate")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                if _showSuccessCard, let cert = _addedCertificate {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    successCard(cert: cert)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .sheet(isPresented: $_isImportingP12Presenting) {
                p12ImportSheet
            }
            .sheet(isPresented: $_isImportingMobileProvisionPresenting) {
                provisionImportSheet
            }
            .sheet(isPresented: $_isImportingZipPresenting) {
                zipImportSheet
            }
            .sheet(isPresented: $_isImportingPortalCertPresenting) {
                portalCertImportSheet
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .bounceEffect(_p12URL != nil)
            
            Text("Import Certificate")
                .font(.title2.bold())
            
            Text("Add your signing certificate to start sideloading.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func successCard(cert: Certificate) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .bounceEffectOnce()
                
                Text("Certificate Added!")
                    .font(.title2.bold())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                infoRow(label: "Team ID", value: cert.TeamIdentifier.first ?? "Unknown")
                infoRow(label: "Devices", value: "\(cert.ProvisionedDevices?.count ?? 0) Devices")
                infoRow(label: "Expiry", value: cert.ExpirationDate.formatted(date: .abbreviated, time: .omitted))
                infoRow(label: "PPQ Status", value: (cert.PPQCheck ?? false) ? "Required" : "Not Required")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            Button {
                withAnimation {
                    _showSuccessCard = false
                    dismiss()
                }
            } label: {
                Text("Continue")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 20)
        .padding(30)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    // MARK: - Sections
    private var manualFilesSection: some View {
        Section {
            fileRow(title: "Certificate (.p12)", subtitle: _p12URL?.lastPathComponent, icon: "key.fill") {
                _isImportingP12Presenting = true
            }

            fileRow(title: "Provisioning Profile", subtitle: _provisionURL?.lastPathComponent, icon: "doc.badge.gearshape.fill") {
                _isImportingMobileProvisionPresenting = true
            }
        } header: {
            Text("Files")
        }
    }
    
    private var portalCertSection: some View {
        Section {
            if usePortalCert {
                fileRow(title: "Import .portalcert", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "shippingbox.fill") {
                    _isImportingPortalCertPresenting = true
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)

                    Text("Portal Cert is Unavailable")
                        .font(.headline)

                    Text("Portal Cert is coming soon on a future update")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        } header: {
            Text("Portal Cert")
        }
    }
    
    private var zipSection: some View {
        Section {
            fileRow(title: "Import ZIP", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "doc.zipper") {
                _isImportingZipPresenting = true
            }
        } header: {
            Text("ZIP File")
        }
    }
    
    private var passwordFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Password", systemImage: "lock.fill")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            SecureField("Leave blank if no password required.", text: $_p12Password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 4)
    }

    private var nicknameFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Nickname (Optional)", systemImage: "tag.fill")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            TextField("Nickname (Optional)", text: $_certificateName)
        }
        .padding(.vertical, 4)
    }

    private var defaultSection: some View {
        Toggle(isOn: $_isDefault) {
            Label("Set As Default", systemImage: "star.fill")
                .foregroundColor(.primary)
        }
        .tint(.accentColor)
    }
    
    private var saveButton: some View {
        Button {
            withAnimation { _isSaving = true }
            _saveCertificate()
        } label: {
            HStack(spacing: 8) {
                if _isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(_isSaving ? "Saving..." : "Save Certificate")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(saveButtonDisabled || _isSaving)
    }

    // MARK: - Helper Views
    private func methodButton(title: String, icon: String, tag: Int, disabled: Bool = false) -> some View {
        let isSelected = _selectedMethod == tag
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                _selectedMethod = tag
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .matchedGeometryEffect(id: "methodBackground", in: _namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }

    private func fileRow(title: String, subtitle: String?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 30)
                    .foregroundColor(.accentColor)
                    .bounceEffect(subtitle != nil)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .foregroundStyle(.primary)
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
            
            withAnimation(.spring()) {
                _p12URL = newP12URL
                _provisionURL = newProvisionURL
                
                if let nickname = metadata.nickname {
                    _certificateName = nickname
                }
            }
            
            HapticsManager.shared.success()
            
        } catch let error as PortalCertHandler.PortalCertError {
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: .localized("Failed to import .portalcert file: \(error.localizedDescription)")
            )
        }
    }
    
    // MARK: - Sheet Views
    private var p12ImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.p12],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                withAnimation(.spring()) {
                    self._p12URL = selectedFileURL
                }
                HapticsManager.shared.softImpact()
            }
        )
        .ignoresSafeArea()
    }
    
    private var provisionImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.mobileProvision],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                withAnimation(.spring()) {
                    self._provisionURL = selectedFileURL
                }
                HapticsManager.shared.softImpact()
            }
        )
        .ignoresSafeArea()
    }
    
    private var zipImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.certificateZip],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                _handleZipImport(selectedFileURL)
            }
        )
        .ignoresSafeArea()
    }
    
    private var portalCertImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.portalCert, .data],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                _handlePortalCertImport(selectedFileURL)
            }
        )
        .ignoresSafeArea()
    }
}

// MARK: - Extension: View (import)
extension CertificatesAddView {
        private func _saveCertificate() {
                guard
                        let p12URL = _p12URL,
                        let provisionURL = _provisionURL,
                        FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
                else {
            withAnimation { _isSaving = false }
                        UIAlertController.showAlertWithOk(
                                title: .localized("Error"),
                                message: .localized("The password you entered is wrong, please try again to add this certificate. If the password from this certificate is WSF, restart Portal and try again.")
                        )
                        return
                }
                
                let reader = CertificateReader(provisionURL)
                _addedCertificate = reader.decoded
                
                FR.handleCertificateFiles(
                        p12URL: p12URL,
                        provisionURL: provisionURL,
                        p12Password: _p12Password,
                        certificateName: _certificateName,
                        isDefault: _isDefault
                ) { _ in
                    if #available(iOS 17.0, *) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            _isSaving = false
                            _showSuccessCard = true
                        }
                    } else {
                        withAnimation {
                            _isSaving = false
                            _showSuccessCard = true
                        }
                    }
                    HapticsManager.shared.success()
                }
        }
        
        private func _handleZipImport(_ zipURL: URL) {
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
                        
                        withAnimation(.spring()) {
                            _p12URL = newP12URL
                            _provisionURL = newProvisionURL
                        }
                        
                        try? FileManager.default.removeItem(at: tempDir)
                        HapticsManager.shared.success()
                        
                } catch let error as CertificateImportError {
                        try? FileManager.default.removeItem(at: tempDir)
                        UIAlertController.showAlertWithOk(
                                title: .localized("Import Failed"),
                                message: error.localizedDescription
                        )
                } catch {
                        try? FileManager.default.removeItem(at: tempDir)
                        UIAlertController.showAlertWithOk(
                                title: .localized("Import Failed"),
                                message: .localized("Failed to extract ZIP file: \(error.localizedDescription)")
                        )
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
