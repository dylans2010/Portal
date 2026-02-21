import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation
import OSLog

// MARK: - Modern Compact Certificate Add View
struct CertificatesAddView: View {
    @Environment(\.dismiss) private var dismiss
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
    
    var saveButtonDisabled: Bool {
        _p12URL == nil || _provisionURL == nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("", selection: $_selectedMethod) {
                        Label("Manual", systemImage: "hand.tap.fill").tag(0)
                        Label("Portal Cert", systemImage: "shippingbox.fill").tag(1)
                            .disabled(!usePortalCert)
                        Label("ZIP File", systemImage: "doc.zipper").tag(2)
                    }
                    .pickerStyle(.segmented)
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
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        } else if _selectedMethod == 1 {
                            portalCertSection
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            zipSection
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }

                    VStack(spacing: 16) {
                        passwordFieldSection
                        nicknameFieldSection
                        defaultSection
                    }

                    Spacer(minLength: 20)

                    saveButton
                }
                .padding(20)
            }
            .background(Color.clear)
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $_isImportingP12Presenting) {
p12ImportSheet
.applyGlobalTheme()
}
            .sheet(isPresented: $_isImportingMobileProvisionPresenting) {
provisionImportSheet
.applyGlobalTheme()
}
            .sheet(isPresented: $_isImportingZipPresenting) {
zipImportSheet
.applyGlobalTheme()
}
            .sheet(isPresented: $_isImportingPortalCertPresenting) {
portalCertImportSheet
.applyGlobalTheme()
}
        }
    }
    
    // MARK: - Sections
    private var manualFilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                fileRow(title: "Certificate (.p12)", subtitle: _p12URL?.lastPathComponent, icon: "key.fill") {
                    _isImportingP12Presenting = true
                }

                Divider()
                    .padding(.leading, 44)

                fileRow(title: "Provisioning Profile", subtitle: _provisionURL?.lastPathComponent, icon: "doc.badge.gearshape.fill") {
                    _isImportingMobileProvisionPresenting = true
                }
            }
            .background(Color.clear)
            .cornerRadius(12)
        }
    }
    
    private var portalCertSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portal Cert")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            if usePortalCert {
                fileRow(title: "Import .portalcert", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "shippingbox.fill") {
                    _isImportingPortalCertPresenting = true
                }
                .background(Color.clear)
                .cornerRadius(12)
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
                .background(Color.clear)
                .cornerRadius(12)
            }
        }
    }
    
    private var zipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ZIP File")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            fileRow(title: "Import ZIP", subtitle: _p12URL != nil ? "Certificate Loaded" : nil, icon: "doc.zipper") {
                _isImportingZipPresenting = true
            }
            .background(Color.clear)
            .cornerRadius(12)
        }
    }
    
    private var passwordFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("Password")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)

            SecureField("Leave blank if no password required.", text: $_p12Password)
                .padding()
                .background(Color.clear)
                .cornerRadius(12)
        }
    }

    private var nicknameFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                Text("Nickname (Optional)")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)

            TextField("Nickname (Optional)", text: $_certificateName)
                .padding()
                .background(Color.clear)
                .cornerRadius(12)
        }
    }

    private var defaultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("Set As Default")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $_isDefault)
                    .labelsHidden()
            }
            .padding()
            .background(Color.clear)
            .cornerRadius(12)

            Text("Default certificate will be automatically selected when signing apps")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
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
    private func fileRow(title: String, subtitle: String?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding()
        }
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
            
            _p12URL = newP12URL
            _provisionURL = newProvisionURL
            
            if let nickname = metadata.nickname {
                _certificateName = nickname
            }
            
            var message = String.localized("Certificate files extracted successfully from .portalcert bundle.")
            if metadata.hasPassword {
                message += " " + String.localized("This certificate requires a password.")
            }
            
            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: message
            )
            
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
                self._p12URL = selectedFileURL
            }
        )
        .ignoresSafeArea()
    }
    
    private var provisionImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.mobileProvision],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                self._provisionURL = selectedFileURL
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
		
		FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: _p12Password,
			certificateName: _certificateName,
			isDefault: _isDefault
		) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _isSaving = false
                dismiss()
            }
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
			
			_p12URL = newP12URL
			_provisionURL = newProvisionURL
			
			try? FileManager.default.removeItem(at: tempDir)
			
			UIAlertController.showAlertWithOk(
				title: .localized("Success"),
				message: .localized("Certificate files extracted successfully from ZIP. Please enter the password now.")
			)
			
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
