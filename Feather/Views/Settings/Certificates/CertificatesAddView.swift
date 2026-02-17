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
    
    @State private var _showAlert = false
    @State private var _alertTitle = ""
    @State private var _alertMessage = ""

    @State private var _statusMessage: String? = nil
    @State private var _statusType: StatusType = .info
    @State private var _isProcessing = false

    enum StatusType {
        case info, success, error

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    var saveButtonDisabled: Bool {
        if _isProcessing { return true }
        switch _selectedSegment {
        case 0: return _p12URL == nil || _provisionURL == nil
        case 1: return !usePortalCert || _p12URL == nil || _provisionURL == nil
        case 2: return _p12URL == nil || _provisionURL == nil
        default: return true
        }
    }
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        let isPortalUnavailable = _selectedSegment == 1 && !usePortalCert

        return Form {
            // Status Section
            if let message = _statusMessage, !isPortalUnavailable {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: _statusType.icon)
                            .foregroundStyle(_statusType.color)
                            .font(.title3)

                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            // Mode Section
            Section {
                Picker("Mode", selection: $_selectedSegment) {
                    Text("Manual").tag(0)
                    Text("Portal Cert").tag(1)
                    Text("ZIP File").tag(2)
                }
                .pickerStyle(.segmented)
            } header: {
                Label("Import Mode", systemImage: "switch.2")
            }

            // Files Section
            Section {
                if isPortalUnavailable {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)

                        Text("Portal Cert is Unavailable")
                            .font(.headline)

                        Text("Portal Cert is coming soon on a future update")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        withAnimation {
                            switch _selectedSegment {
                            case 0: _isImportingP12Presenting = true
                            case 1: _isImportingPortalCertPresenting = true
                            case 2: _isImportingZipPresenting = true
                            default: break
                            }
                        }
                    } label: {
                        HStack {
                            Label(_selectedSegment == 0 ? "Certificate (.p12)" : (_selectedSegment == 1 ? "Portal Certificate (.portalcert)" : "Certificate ZIP (.zip)"),
                                  systemImage: _selectedSegment == 1 ? "person.badge.key.fill" : "doc.fill")

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
                    }

                    if _selectedSegment == 0 {
                        Button {
                            _isImportingMobileProvisionPresenting = true
                        } label: {
                            HStack {
                                Label("Provisioning Profile", systemImage: "shield.fill")

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
                        }
                    }
                }
            } header: {
                Label("Required Files", systemImage: "folder.fill")
            }

            if !isPortalUnavailable {
                // Password Section
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Password (if required)", text: $_p12Password)
                            .textContentType(.password)
                    }
                } header: {
                    Label("Password", systemImage: "lock.fill")
                }

                // Details Section
                Section {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Nickname (Optional)", text: $_certificateName)
                    }

                    Toggle(isOn: $_isDefault) {
                        Label("Set as Default", systemImage: "star.fill")
                    }
                } header: {
                    Label("Details", systemImage: "info.circle.fill")
                } footer: {
                    Text("Default certificate will be automatically selected when signing apps")
                }

                // Save Section
                Section {
                    saveButton
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Add Certificate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            if _isProcessing {
                ToolbarItem(placement: .confirmationAction) {
                    ProgressView()
                }
            }
        })
        .alert(_alertTitle, isPresented: $_showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(_alertMessage)
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
        _isProcessing = true
        _statusMessage = "Extracting Portal Certificate..."
        _statusType = .info
        
        // FileImporterRepresentableView uses asCopy: true, so the file is already copied
        // and we don't need security-scoped resource access
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Extract the .portalcert bundle directly from the copied file
                let (p12URL, provisionURL, metadata) = try PortalCertHandler.extractPortalCert(from: url)

                Logger.misc.info("[PortalCert Import] Successfully extracted bundle")

                // Copy files to persistent temporary location
                let persistentTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-import-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: persistentTempDir, withIntermediateDirectories: true)

                let newP12URL = persistentTempDir.appendingPathComponent(p12URL.lastPathComponent)
                let newProvisionURL = persistentTempDir.appendingPathComponent(provisionURL.lastPathComponent)

                try FileManager.default.copyItem(at: p12URL, to: newP12URL)
                try FileManager.default.copyItem(at: provisionURL, to: newProvisionURL)

                withAnimation {
                    // Set the URLs
                    _p12URL = newP12URL
                    _provisionURL = newProvisionURL

                    // Set nickname if available
                    if let nickname = metadata.nickname {
                        _certificateName = nickname
                    }

                    _isProcessing = false
                    _statusType = .success
                    var message = String.localized("Portal Certificate extracted successfully.")
                    if metadata.hasPassword {
                        message += " " + String.localized("Password required.")
                    }
                    _statusMessage = message
                }

                HapticsManager.shared.success()

            } catch {
                Logger.misc.error("[PortalCert Import] Error: \(error.localizedDescription)")
                withAnimation {
                    _isProcessing = false
                    _statusType = .error
                    _statusMessage = error.localizedDescription
                }
                HapticsManager.shared.error()
            }
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
		_isProcessing = true
		_statusMessage = .localized("Verifying Certificate...")
		_statusType = .info
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			guard
				let p12URL = _p12URL,
				let provisionURL = _provisionURL,
				FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
			else {
				withAnimation {
					_isProcessing = false
					_statusType = .error
					_statusMessage = .localized("Invalid password or certificate files.")

					_alertTitle = .localized("Error")
					_alertMessage = .localized("The password you entered is wrong, please try again to add this certificate.")
					_showAlert = true
				}
				HapticsManager.shared.error()
				return
			}

			FR.handleCertificateFiles(
				p12URL: p12URL,
				provisionURL: provisionURL,
				p12Password: _p12Password,
				certificateName: _certificateName,
				isDefault: _isDefault
			) { _ in
				_isProcessing = false
				dismiss()
			}
		}
	}
	
	private func _handleZipImport(_ zipURL: URL) {
		_isProcessing = true
		_statusMessage = .localized("Extracting ZIP...")
		_statusType = .info

		// Create a temporary directory for extraction
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

				withAnimation {
					// Set the URLs
					_p12URL = newP12URL
					_provisionURL = newProvisionURL

					_isProcessing = false
					_statusType = .success
					_statusMessage = .localized("Certificate files extracted successfully from ZIP.")
				}

				// Clean up temporary extraction directory
				try? FileManager.default.removeItem(at: tempDir)
				HapticsManager.shared.success()

			} catch {
				// Clean up
				try? FileManager.default.removeItem(at: tempDir)

				withAnimation {
					_isProcessing = false
					_statusType = .error
					_statusMessage = error.localizedDescription
				}
				HapticsManager.shared.error()
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

