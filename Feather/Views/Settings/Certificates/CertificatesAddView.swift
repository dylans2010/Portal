import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation
import OSLog

struct CertificatesAddView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("feature_usePortalCert") private var usePortalCert = false

    @State private var _selectedSegment = 0 // 0: Manual, 1: Portal Cert, 2: ZIP File
    
    @State private var _p12URL: URL? = nil
    @State private var _provisionURL: URL? = nil
    @State private var _portalCertURL: URL? = nil
    @State private var _zipURL: URL? = nil

    @State private var _p12Password: String = ""
    @State private var _certificateName: String = ""
    @State private var _setAsDefault: Bool = false
    
    @State private var _isImportingP12Presenting = false
    @State private var _isImportingMobileProvisionPresenting = false
    @State private var _isImportingPortalCertPresenting = false
    @State private var _isImportingZipPresenting = false
    
    var saveButtonDisabled: Bool {
        switch _selectedSegment {
        case 0: return _p12URL == nil || _provisionURL == nil
        case 1: return _portalCertURL == nil
        case 2: return _zipURL == nil
        default: return true
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Form {
                    Section {
                        Picker("Import Mode", selection: $_selectedSegment) {
                            Text("Manual").tag(0)
                            Text("Portal Cert").tag(1)
                            Text("ZIP File").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }

                    Section(header: Text("Files")) {
                        VStack(spacing: 0) {
                            if _selectedSegment == 0 {
                                fileRow(title: "Certificate (.p12)", subtitle: _p12URL?.lastPathComponent ?? "Select File", icon: "key.fill") {
                                    _isImportingP12Presenting = true
                                }
                                Divider()
                                fileRow(title: "Provisioning Profile", subtitle: _provisionURL?.lastPathComponent ?? "Select File", icon: "doc.badge.gearshape.fill") {
                                    _isImportingMobileProvisionPresenting = true
                                }
                            } else if _selectedSegment == 1 {
                                if usePortalCert {
                                    fileRow(title: "Portal Certificate (.portalcert)", subtitle: _portalCertURL?.lastPathComponent ?? "Select File", icon: "shippingbox.fill") {
                                        _isImportingPortalCertPresenting = true
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Not Ready")
                                            .font(.headline)
                                        Text("This feature is still under development and will be available in a later Portal release. Thanks for your patience and interest on the new certificate format!")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                }
                            } else {
                                fileRow(title: "Certificate ZIP (.zip)", subtitle: _zipURL?.lastPathComponent ?? "Select File", icon: "doc.zipper") {
                                    _isImportingZipPresenting = true
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            SecureField("Leave blank if no password required", text: $_p12Password)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nickname (Optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            TextField("Enter Nickname", text: $_certificateName)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }

                    Section {
                        Toggle("Set as Default", isOn: $_setAsDefault)
                            .tint(.accentColor)

                        Text("Default certificate will be automatically selected when signing apps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Spacer for bottom button
                    Section {
                        Color.clear.frame(height: 80)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)

                // Bottom Button
                VStack {
                    Button {
                        _saveAction()
                    } label: {
                        Text("Save Certificate")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(saveButtonDisabled ? Color.gray : Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(saveButtonDisabled)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(colors: [Color(uiColor: .systemGroupedBackground).opacity(0), Color(uiColor: .systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                )
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .applyGlobalTheme()
            .sheet(isPresented: $_isImportingP12Presenting) {
                FileImporterRepresentableView(allowedContentTypes: [.p12]) { urls in
                    _p12URL = urls.first
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingMobileProvisionPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.mobileProvision]) { urls in
                    _provisionURL = urls.first
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingPortalCertPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.portalCert, .data]) { urls in
                    if let url = urls.first {
                        _portalCertURL = url
                        _handlePortalCertImport(url)
                    }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isImportingZipPresenting) {
                FileImporterRepresentableView(allowedContentTypes: [.certificateZip]) { urls in
                    if let url = urls.first {
                        _zipURL = url
                        _handleZipImport(url)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func fileRow(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
    
    private func _saveAction() {
        guard let p12 = _p12URL, let provision = _provisionURL else { return }

        if !FR.checkPasswordForCertificate(for: p12, with: _p12Password, using: provision) {
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: .localized("The password you entered is wrong, please try again to add this certificate.")
            )
            return
        }
        
        FR.handleCertificateFiles(
            p12URL: p12,
            provisionURL: provision,
            p12Password: _p12Password,
            certificateName: _certificateName,
            isDefault: _setAsDefault
        ) { _ in
            dismiss()
        }
    }

    // Existing logic for ZIP and PortalCert imports
    private func _handlePortalCertImport(_ url: URL) {
        do {
            let (p12URL, provisionURL, metadata) = try PortalCertHandler.extractPortalCert(from: url)
            
            let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-import-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)
            
            let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
            let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)
            
            try FileManager.default.copyItem(at: p12URL, to: newP12URL)
            try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)
            
            _p12URL = newP12URL
            _provisionURL = newProvisionURL
            
            if let nickname = metadata.nickname {
                _certificateName = nickname
            }
            
            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: .localized("Certificate files extracted successfully from .portalcert bundle.")
            )
        } catch {
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
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
                let items = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                for item in items {
                    let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
                    if resourceValues.isDirectory == true {
                        try searchDirectory(item)
                    } else {
                        let ext = item.pathExtension.lowercased()
                        if ext == "p12" && foundP12 == nil { foundP12 = item }
                        else if ext == "mobileprovision" && foundProvision == nil { foundProvision = item }
                    }
                }
            }
            try searchDirectory(tempDir)
            
            guard let p12URL = foundP12, let provisionURL = foundProvision else {
                throw CertificateImportError.missingCertificateFiles(".p12 and .mobileprovision")
            }
            
            let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("certificates-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)

            let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
            let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)

            try FileManager.default.copyItem(at: p12URL, to: newP12URL)
            try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)

            _p12URL = newP12URL
            _provisionURL = newProvisionURL

            try? FileManager.default.removeItem(at: tempDir)

            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: .localized("Certificate files extracted successfully from ZIP. Please enter the password now.")
            )
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
        }
    }
}

enum CertificateImportError: LocalizedError {
    case missingCertificateFiles(String)
    var errorDescription: String? {
        switch self {
        case .missingCertificateFiles(let files):
            return "Missing certificate files: \(files)"
        }
    }
}
