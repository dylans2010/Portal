import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation

// MARK: - Modern Compact Certificate Add View
struct CertificatesAddView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var _p12URL: URL? = nil
    @State private var _provisionURL: URL? = nil
    @State private var _p12Password: String = ""
    @State private var _certificateName: String = ""
    
    @State private var _isImportingP12Presenting = false
    @State private var _isImportingMobileProvisionPresenting = false
    @State private var _isImportingZipPresenting = false
    
    var saveButtonDisabled: Bool {
        _p12URL == nil || _provisionURL == nil
    }
    
    var body: some View {
        NavigationView {
            contentView
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                fileImportSection
                dividerSection
                inputFieldsSection
                Spacer(minLength: 16)
                saveButton
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("New Certificate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
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
    }
    
    // MARK: - File Import Section
    private var fileImportSection: some View {
        VStack(spacing: 12) {
            compactImportCard(
                title: "P12 Certificate",
                subtitle: _p12URL?.lastPathComponent ?? "Tap to select",
                icon: "key.fill",
                isSelected: _p12URL != nil,
                color: .orange
            ) {
                _isImportingP12Presenting = true
            }
            
            compactImportCard(
                title: "Provisioning Profile",
                subtitle: _provisionURL?.lastPathComponent ?? "Tap to select",
                icon: "doc.badge.gearshape.fill",
                isSelected: _provisionURL != nil,
                color: .blue
            ) {
                _isImportingMobileProvisionPresenting = true
            }
            
            zipImportButton
        }
    }
    
    // MARK: - ZIP Import Button
    private var zipImportButton: some View {
        Button {
            _isImportingZipPresenting = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Import from ZIP")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        Rectangle()
            .fill(Color(UIColor.separator).opacity(0.3))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
    
    // MARK: - Input Fields Section
    private var inputFieldsSection: some View {
        VStack(spacing: 12) {
            passwordField
            nicknameField
        }
    }
    
    // MARK: - Password Field
    private var passwordField: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            
            SecureField("Password (Optional)", text: $_p12Password)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Nickname Field
    private var nicknameField: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "tag.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            
            TextField("Nickname (Optional)", text: $_certificateName)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
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
    
    // MARK: - Compact Import Card
    @ViewBuilder
    private func compactImportCard(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    isSelected ? Color.green.opacity(0.2) : color.opacity(0.2),
                                    isSelected ? Color.green.opacity(0.1) : color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isSelected ? Color.green.opacity(0.3) : color.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isSelected ? .green : color)
                        .shadow(color: isSelected ? .green.opacity(0.3) : color.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? .secondary : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isSelected ? .green : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if !isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    isSelected ? Color.green.opacity(0.08) : color.opacity(0.06),
                                    isSelected ? Color.green.opacity(0.04) : color.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isSelected ? 
                                LinearGradient(
                                    colors: [Color.green.opacity(0.4), Color.green.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [color.opacity(0.2), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 2
                        )
                }
            )
            .shadow(color: isSelected ? .green.opacity(0.2) : color.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .disabled(isSelected)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Extension: View
extension CertificatesAddView {
	@ViewBuilder
	private func _importButton(
		_ title: String,
		file: URL?,
		iconName: String = "square.and.arrow.down.fill",
		showCheckmark: Bool = true,
		action: @escaping () -> Void
	) -> some View {
		Button {
			action()
		} label: {
			HStack(spacing: 10) {
				ZStack {
					Circle()
						.fill(
							file == nil
								? Color.accentColor.opacity(0.12)
								: Color.green.opacity(0.12)
						)
						.frame(width: 32, height: 32)
					
					Image(systemName: showCheckmark && file != nil ? "checkmark.circle.fill" : iconName)
						.font(.system(size: 14))
						.foregroundStyle(file == nil ? Color.accentColor : Color.green)
				}
				
				VStack(alignment: .leading, spacing: 2) {
					Text(title)
						.font(.subheadline)
						.fontWeight(.medium)
						.foregroundStyle(file == nil ? .primary : .secondary)
					
					if let file = file {
						Text(file.lastPathComponent)
							.font(.caption2)
							.foregroundStyle(.secondary)
							.lineLimit(1)
					} else {
						Text(.localized("Tap to select"))
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
				}
				
				Spacer()
				
				if file == nil {
					Image(systemName: "chevron.right")
						.font(.caption2)
						.foregroundStyle(.tertiary)
				}
			}
			.padding(.vertical, 2)
		}
		.disabled(showCheckmark && file != nil)
		.animation(.easeInOut(duration: 0.25), value: file != nil)
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
				title: .localized("Bad Password"),
				message: .localized("Please check the password and try again.")
			)
			return
		}
		
		FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: _p12Password,
			certificateName: _certificateName
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
				message: .localized("Certificate files extracted successfully from ZIP. Please enter the password.")
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

