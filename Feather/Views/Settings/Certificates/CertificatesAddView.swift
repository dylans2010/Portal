import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation
import OSLog

// MARK: - Modern Compact Certificate Add View
struct CertificatesAddView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("feature_usePortalCert") private var usePortalCert = false
    
    @State private var _p12URL: URL? = nil
    @State private var _provisionURL: URL? = nil
    @State private var _p12Password: String = ""
    @State private var _certificateName: String = ""
    @State private var _selectedSegment = 0
    @State private var _isDefault = false
    
    @State private var _isImportingP12Presenting = false
    @State private var _isImportingMobileProvisionPresenting = false
    @State private var _isImportingZipPresenting = false
    @State private var _isImportingPortalCertPresenting = false
    
    var saveButtonDisabled: Bool {
        switch _selectedSegment {
        case 0: return _p12URL == nil || _provisionURL == nil
        case 1: return _p12URL == nil || _provisionURL == nil // Portal cert sets both
        case 2: return _p12URL == nil || _provisionURL == nil // ZIP sets both
        default: return true
        }
    }
    
    var body: some View {
        NavigationView {
            contentView
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mode Picker
                Picker("Mode", selection: $_selectedSegment) {
                    Text("Manual").tag(0)
                    Text("Portal Cert").tag(1)
                    Text("ZIP File").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.top, 8)

                // Files Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        Button {
                            switch _selectedSegment {
                            case 0: _isImportingP12Presenting = true
                            case 1: _isImportingPortalCertPresenting = true
                            case 2: _isImportingZipPresenting = true
                            default: break
                            }
                        } label: {
                            HStack {
                                Text(_selectedSegment == 0 ? "Certificate (.p12)" : (_selectedSegment == 1 ? "Portal Certificate (.portalcert)" : "Certificate ZIP (.zip)"))
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                                if let url = _p12URL {
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                        }

                        if _selectedSegment == 0 {
                            Divider().padding(.leading)

                            Button {
                                _isImportingMobileProvisionPresenting = true
                            } label: {
                                HStack {
                                    Text("Provisioning Profile")
                                        .foregroundStyle(Color.accentColor)
                                    Spacer()
                                    if let url = _provisionURL {
                                        Text(url.lastPathComponent)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding()
                            }
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("Leave blank if no password required", text: $_p12Password)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                // Nickname Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nickname (Optional)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("Nickname (Optional)", text: $_certificateName)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                // Set as Default
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Set as Default")
                        Spacer()
                        Toggle("", isOn: $_isDefault)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    Text("Default certificate will be automatically selected when signing apps")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                Spacer(minLength: 20)

                saveButton
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Add Certificate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        })
        .preferredColorScheme(.dark)
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
    
    // MARK: - Portal Cert Import Sheet
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
    
    // MARK: - Handle Portal Cert Import
    private func _handlePortalCertImport(_ url: URL) {
        Logger.misc.info("[PortalCert Import] Starting import from: \(url.lastPathComponent)")
        
        // FileImporterRepresentableView uses asCopy: true, so the file is already copied
        // and we don't need security-scoped resource access
        do {
            // Extract the .portalcert bundle directly from the copied file
            let (p12URL, provisionURL, metadata) = try PortalCertHandler.extractPortalCert(from: url)
            
            Logger.misc.info("[PortalCert Import] Successfully extracted bundle")
            Logger.misc.debug("[PortalCert Import] P12: \(p12URL.lastPathComponent)")
            Logger.misc.debug("[PortalCert Import] Provision: \(provisionURL.lastPathComponent)")
            
            // Copy files to persistent temporary location
            let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-import-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)
            
            let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
            let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)
            
            try FileManager.default.copyItem(at: p12URL, to: newP12URL)
            try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)
            
            // Set the URLs
            _p12URL = newP12URL
            _provisionURL = newProvisionURL
            
            // Set nickname if available
            if let nickname = metadata.nickname {
                _certificateName = nickname
            }
            
            // Set password hint if available
            if metadata.hasPassword {
                // Show a hint that password is required
            }
            
            Logger.misc.info("[PortalCert Import] Import complete, files ready for saving")
            
            // Show success message
            var message = String.localized("Certificate files extracted successfully from .portalcert bundle.")
            if metadata.hasPassword {
                message += " " + String.localized("This certificate requires a password.")
            }
            
            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: message
            )
            
        } catch let error as PortalCertHandler.PortalCertError {
            Logger.misc.error("[PortalCert Import] Error: \(error.localizedDescription)")
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: error.localizedDescription
            )
        } catch {
            Logger.misc.error("[PortalCert Import] Unexpected error: \(error.localizedDescription)")
            UIAlertController.showAlertWithOk(
                title: .localized("Import Failed"),
                message: .localized("Failed to import .portalcert file: \(error.localizedDescription)")
            )
        }
    }
    
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            _saveCertificate()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Save Certificate")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        saveButtonDisabled
                        ? AnyShapeStyle(Color.gray.opacity(0.5))
                        : AnyShapeStyle(LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
            )
            .shadow(color: saveButtonDisabled ? .clear : .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(saveButtonDisabled)
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
    
}

// MARK: - Extension: View (import)
extension CertificatesAddView {
	private func _saveCertificate() {
		guard
			let p12URL = _p12URL,
			let provisionURL = _provisionURL,
			FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
		else {
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
			dismiss()
		}
	}
	
	private func _handleZipImport(_ zipURL: URL) {
		// Create a temporary directory for extraction
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		do {
			try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
			
			// Extract the ZIP file using ZIPFoundation
			try FileManager.default.unzipItem(at: zipURL, to: tempDir)
			
			// Find .p12 and .mobileprovision files
			var foundP12: URL?
			var foundProvision: URL?
			
			// Search recursively for certificate files
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
			
			// Validate that both files were found
			guard let p12URL = foundP12, let provisionURL = foundProvision else {
				var missingFiles: [String] = []
				if foundP12 == nil { missingFiles.append(".p12") }
				if foundProvision == nil { missingFiles.append(".mobileprovision") }
				
				throw CertificateImportError.missingCertificateFiles(missingFiles.joined(separator: " and "))
			}
			
			// Copy files to a persistent temporary location
			let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("certificates-\(UUID().uuidString)")
			try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)
			
			let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
			let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)
			
			try FileManager.default.copyItem(at: p12URL, to: newP12URL)
			try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)
			
			// Set the URLs
			_p12URL = newP12URL
			_provisionURL = newProvisionURL
			
			// Clean up temporary extraction directory
			try? FileManager.default.removeItem(at: tempDir)
			
			// Show success message
			UIAlertController.showAlertWithOk(
				title: .localized("Success"),
				message: .localized("Certificate files extracted successfully from ZIP. Please enter the password now.")
			)
			
		} catch let error as CertificateImportError {
			// Clean up
			try? FileManager.default.removeItem(at: tempDir)
			
			// Show specific error
			UIAlertController.showAlertWithOk(
				title: .localized("Import Failed"),
				message: error.localizedDescription
			)
		} catch {
			// Clean up
			try? FileManager.default.removeItem(at: tempDir)
			
			// Show generic error
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

