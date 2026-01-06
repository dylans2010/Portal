import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import ZIPFoundation

// MARK: - View
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
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("New Certificate"), displayMode: .inline) {
			ZStack {
				// Background gradient
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.03),
						Color.clear
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
				
				Form {
					Section {
						_importButton(.localized("Import Certificate File"), file: _p12URL, iconName: "doc.badge.key.fill") {
							_isImportingP12Presenting = true
						}
						_importButton(.localized("Import Provisioning File"), file: _provisionURL, iconName: "doc.fill.badge.gearshape") {
							_isImportingMobileProvisionPresenting = true
						}
						_importButton(.localized("Import ZIP Certificate"), file: nil, iconName: "doc.zipper.fill", showCheckmark: false) {
							_isImportingZipPresenting = true
						}
					} header: {
						HStack(spacing: 8) {
							Image(systemName: "folder.fill.badge.plus")
								.font(.caption)
								.foregroundStyle(Color.accentColor)
							Text(.localized("Files"))
								.font(.subheadline)
								.fontWeight(.medium)
						}
						.textCase(.none)
					}
					
					Section {
						HStack(spacing: 10) {
							Image(systemName: "lock.shield.fill")
								.foregroundStyle(Color.orange)
								.font(.body)
							SecureField(.localized("Password (Optional)"), text: $_p12Password)
						}
						.padding(.vertical, 2)
						
						HStack(spacing: 10) {
							Image(systemName: "tag.fill")
								.foregroundStyle(Color.accentColor)
								.font(.body)
							TextField(.localized("Nickname (Optional)"), text: $_certificateName)
						}
						.padding(.vertical, 2)
					} header: {
						HStack(spacing: 8) {
							Image(systemName: "textformat")
								.font(.caption)
								.foregroundStyle(Color.accentColor)
							Text(.localized("Certificate Details"))
								.font(.subheadline)
								.fontWeight(.medium)
						}
						.textCase(.none)
					}
				}
				.scrollContentBackground(.hidden)
			}
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				NBToolbarButton(
					.localized("Save"),
					style: .text,
					placement: .confirmationAction,
					isDisabled: saveButtonDisabled
				) {
					_saveCertificate()
				}
			}
			.sheet(isPresented: $_isImportingP12Presenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.p12],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._p12URL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isImportingMobileProvisionPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.mobileProvision],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._provisionURL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isImportingZipPresenting) {
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
			return NSLocalizedString("Failed to extract the ZIP file. The file may be corrupted or password-protected.", comment: "")
		}
	}
}

